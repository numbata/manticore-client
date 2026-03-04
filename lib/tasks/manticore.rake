# frozen_string_literal: true

namespace :manticore do
  namespace :schema do
    desc "Create all ManticoreClient tables"
    task create: :environment do
      ManticoreClient::Rails::Registry.instance.all.each do |index|
        puts "Creating table: #{index.table_name}"
        ManticoreClient::Rails::Schema.create_table(index)
      end
    end

    desc "Drop all ManticoreClient tables"
    task drop: :environment do
      ManticoreClient::Rails::Registry.instance.all.each do |index|
        puts "Dropping table: #{index.table_name}"
        ManticoreClient::Rails::Schema.drop_table(index)
      end
    end

    desc "Rebuild all ManticoreClient tables (drop + create)"
    task rebuild: :environment do
      Rake::Task["manticore:schema:drop"].invoke
      Rake::Task["manticore:schema:create"].invoke
    end
  end

  namespace :index do
    desc "Rebuild ManticoreClient index (all or specific table)"
    task :rebuild, [:table] => :environment do |_t, args|
      indexes = if args[:table]
        [ManticoreClient::Rails::Registry.instance.find_by_table(args[:table])]
      else
        ManticoreClient::Rails::Registry.instance.all
      end

      ManticoreClient::Rails.no_auto_indexing do
        indexes.compact.each do |index|
          puts "Reindexing: #{index.table_name}"
          ManticoreClient::Rails::Indexer.new(index).reindex_all
        end
      end
    end
  end
end
