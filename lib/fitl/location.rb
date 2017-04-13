# frozen_string_literal: true

require 'active_record'

module Fitl
  class Location < ActiveRecord::Base

=begin
    PROPERTIES = %i[name population terrain type country value].freeze
    PROPERTIES.each { |p| attr_accessor p }

    attr_accessor :support, :control
    attr_accessor :us_troop, :us_irregular, :arvn_troop, :arvn_ranger, :arvn_police
    attr_accessor :nva_troop, :nva_guerrilla, :vc_guerrilla
    attr_accessor :us_base, :arvn_base, :vc_base, :vc_tunnel_base, :nva_base, :nva_tunnel_base
=end

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
