# frozen_string_literal: true

namespace :manticore do
  namespace :schema do
    desc "Create all ManticoreSearch tables"
    task create: :environment do
      each_index do |index|
        puts "Creating table: #{index.table_name}"
        ManticoreRails::Schema.create_table(index)
      end
    end

    desc "Drop all ManticoreSearch tables"
    task drop: :environment do
      each_index do |index|
        puts "Dropping table: #{index.table_name}"
        ManticoreRails::Schema.drop_table(index)
      end
    end

    desc "Rebuild all ManticoreSearch tables (drop + create)"
    task rebuild: :environment do
      Rake::Task["manticore:schema:drop"].invoke
      Rake::Task["manticore:schema:create"].invoke
    end
  end

  namespace :index do
    desc "Reindex all data (or specific table) into ManticoreSearch"
    task :rebuild, [:table] => :environment do |_t, args|
      load_all_indexed_models
      indexes = if args[:table]
        [ManticoreRails::Registry.instance.find_by_table(args[:table])].compact
      else
        ManticoreRails::Registry.instance.all
      end

      abort "No indexes found" if indexes.empty?

      ManticoreRails.no_auto_indexing do
        indexes.each do |index|
          reindex_with_progress(index)
        end
      end
    end
  end

  desc "Full setup: create tables and populate all indexes from scratch"
  task setup: :environment do
    load_all_indexed_models
    indexes = ManticoreRails::Registry.instance.all
    abort "No indexes registered" if indexes.empty?

    ManticoreRails.no_auto_indexing do
      indexes.each do |index|
        puts "==> #{index.model_class.name} (#{index.table_name})"

        print "    Dropping table... "
        begin
          ManticoreRails::Schema.drop_table(index)
        rescue StandardError
          nil
        end
        puts "done"

        print "    Creating table... "
        ManticoreRails::Schema.create_table(index)
        puts "done"

        reindex_with_progress(index)
        puts
      end
    end

    puts "Setup complete."
  end
end

def each_index(&block)
  load_all_indexed_models
  ManticoreRails::Registry.instance.all.each(&block)
end

def load_all_indexed_models
  Rails.application.eager_load! if defined?(Rails)
end

def reindex_with_progress(index)
  model = index.model_class
  total_records = model.count
  puts "    Indexing #{model.name}: #{total_records} records"

  if total_records.zero?
    puts "    Nothing to index."
    return
  end

  started_at = Time.now
  indexed = ManticoreRails::Indexer.new(index).reindex_all do |count|
    elapsed = Time.now - started_at
    rate = count / elapsed
    print "\r    Indexed #{count}/#{total_records} (#{format('%.0f', rate)} docs/s)"
  end

  elapsed = Time.now - started_at
  puts "\r    Indexed #{indexed}/#{total_records} in #{format('%.1f', elapsed)}s"
end
