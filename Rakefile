# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

require 'pry'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

require 'active_record'

include ActiveRecord::Tasks

class Seeder
  def initialize(seed_file)
    @seed_file = seed_file
  end

  def load_seed
    raise "Seed file '#{@seed_file}' does not exist" unless File.file?(@seed_file)
    load @seed_file
  end
end

root = File.expand_path '..', __FILE__
DatabaseTasks.env = ENV['ENV'] || 'development'
DatabaseTasks.database_configuration = YAML.safe_load(File.read(File.join(root, 'config/database.yml')))
DatabaseTasks.db_dir = File.join root, 'db'
DatabaseTasks.fixtures_path = File.join root, 'test/fixtures'
DatabaseTasks.migrations_paths = [File.join(root, 'db/migrate')]
DatabaseTasks.seed_loader = Seeder.new File.join root, 'db/seeds.rb'
DatabaseTasks.root = root

task :environment do
  ActiveRecord::Base.configurations = DatabaseTasks.database_configuration
  ActiveRecord::Base.establish_connection DatabaseTasks.env.to_sym
end
load 'active_record/railties/databases.rake'

namespace :db do
  desc 'Create a migration (parameters: NAME, VERSION)'
  task :create_migration do
    unless ENV['NAME']
      puts 'No NAME specified. Example usage: `rake db:create_migration NAME=create_users`'
      exit
    end

    name    = ENV['NAME']
    version = ENV['VERSION'] || Time.now.utc.strftime('%Y%m%d%H%M%S')

    ActiveRecord::Migrator.migrations_paths.each do |directory|
      next unless File.exist?(directory)
      migration_files = Pathname(directory).children
      if duplicate = migration_files.find { |path| path.basename.to_s.include?(name) }
        puts "Another migration is already named \"#{name}\": #{duplicate}."
        exit
      end
    end

    filename = "#{version}_#{name}.rb"
    dirname  = ActiveRecord::Migrator.migrations_paths.first
    path     = File.join(dirname, filename)
    ar_maj   = ActiveRecord::VERSION::MAJOR
    ar_min   = ActiveRecord::VERSION::MINOR
    base     = 'ActiveRecord::Migration'
    base    += "[#{ar_maj}.#{ar_min}]" if ar_maj >= 5

    FileUtils.mkdir_p(dirname)
    File.write path, <<-MIGRATION.strip_heredoc
      class #{name.camelize} < #{base}
        def change
        end
      end
    MIGRATION

    puts path
  end
end
