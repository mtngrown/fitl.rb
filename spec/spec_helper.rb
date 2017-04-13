# frozen_string_literal: true

require 'bundler/setup'
require 'fitl'
require 'pry'

# TODO: this is a kludge to use RACK_ENV when we're not running Rack.
ENV['RACK_ENV'] = 'test'
require_relative '../config/db'
dbconfig = YAML.safe_load(File.read('config/database.yml'))

# TODO: refactor ENV['RACK_ENV'] and initialize it elsewhere
ActiveRecord::Base.establish_connection dbconfig[ENV['RACK_ENV']]

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
