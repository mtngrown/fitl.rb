# frozen_string_literal: true

require 'active_record'

module Fitl
  class Location < ActiveRecord::Base
    # TODO: think about using in-memory sqlite3 for handling queries on this data
    # kludgy
    def self.build_from_yaml(file)
      require 'yaml'
      locations = YAML.load_file file
      locations_hash = {}
      locations.each do |location|
        locations_hash[location['name']] = Location.create(location)
      end
      locations_hash
    end
  end
end
