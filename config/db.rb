# frozen_string_literal: true

require 'yaml'
require 'active_record'

dbconfig = YAML.safe_load(File.read('config/database.yml'))
# puts "RACK_ENV: #{ENV['RACK_ENV']}"
# puts "dbconfig: #{dbconfig[ENV['RACK_ENV']]}"
# TODO: refactor ENV['RACK_ENV'] and initialize it elsewhere
ActiveRecord::Base.establish_connection dbconfig[ENV['RACK_ENV']]
