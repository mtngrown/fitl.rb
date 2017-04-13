# frozen_string_literal: true

require 'bundler/setup'
require 'fitl'
require 'pry'


require_relative '../config/db'

dbconfig = YAML.safe_load(File.read('config/database.yml'))
puts "RACK_ENV: #{ENV['RACK_ENV']}"
# puts "dbconfig: #{dbconfig[ENV['RACK_ENV']]}"
# TODO: refactor ENV['RACK_ENV'] and initialize it elsewhere
ActiveRecord::Base.establish_connection dbconfig[ENV['RACK_ENV']]

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
