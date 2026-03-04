# frozen_string_literal: true

namespace :manticore do
  namespace :schema do
    desc "Create all ManticoreSearch tables"
    task create: :environment do
      Manticore::Rails::Registry.instance.all.each do |index|
        puts "Creating table: #{index.table_name}"
        Manticore::Rails::Schema.create_table(index)
      end
    end

    desc "Drop all ManticoreSearch tables"
    task drop: :environment do
      Manticore::Rails::Registry.instance.all.each do |index|
        puts "Dropping table: #{index.table_name}"
        Manticore::Rails::Schema.drop_table(index)
      end
    end

    desc "Rebuild all ManticoreSearch tables (drop + create)"
    task rebuild: :environment do
      Rake::Task["manticore:schema:drop"].invoke
      Rake::Task["manticore:schema:create"].invoke
    end
  end

  namespace :index do
    desc "Rebuild ManticoreSearch index (all or specific table)"
    task :rebuild, [:table] => :environment do |_t, args|
      indexes = if args[:table]
        [Manticore::Rails::Registry.instance.find_by_table(args[:table])]
      else
        Manticore::Rails::Registry.instance.all
      end

      Manticore::Rails.no_auto_indexing do
        indexes.compact.each do |index|
          puts "Reindexing: #{index.table_name}"
          Manticore::Rails::Indexer.new(index).reindex_all
        end
      end
    end
  end
end
