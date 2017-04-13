# frozen_string_literal: true

require 'active_record'

module Fitl
  class Location < ActiveRecord::Base
    # TODO: add validations

    scope :vc_per_location, -> {
      where('vc_guerrilla + vc_base + vc_tunnel_base > 0')
    }

    scope :nva_per_location, -> {
      where('nva_troop + nva_guerrilla + nva_base + nva_tunnel_base > 0')
    }

    scope :arvn_per_location, -> {
      #where('arvn_troop + arvn_ranger + arvn_base + arvn_police > 0')
      select('arvn_troop + arvn_ranger + arvn_base + arvn_police as arvn_total')
    }

    scope :us_per_location, -> {
      select('us_troop + us_irregular + us_base as us_total')
    }

    scope :fwa_totals, -> {
      arvn_per_location.us_per_location.where('us_total + arvn_total > 0')
    }

    scope :nlf_total, -> {
      all.where("nva_troop + nva_guerrilla + nva_base + vc_guerrilla + vc_base + vc_tunnel_base > \
                us_troop + us_base + us_irregular + arvn_base + arvn_troop + arvn_ranger")
    }

    scope :province_or_city, -> { where("location_type = 'province' OR location_type = 'city'") }

    def self.case_for_control

      sql = "locations.name, CASE
          WHEN us_troop + us_base + us_irregular + arvn_troop + arvn_base + arvn_ranger + arvn_police
            > nva_troop + nva_base + nva_tunnel_base + nva_guerrilla + vc_guerrilla + vc_base + vc_tunnel_base THEN 'COIN'
          WHEN nva_base + nva_tunnel_base + nva_guerrilla
            > us_base + us_irregular + arvn_troop + arvn_base + arvn_ranger + arvn_police + vc_guerrilla + vc_base + vc_tunnel_base THEN 'NVA'
          ELSE 'NONE'
          END as control"
      query = sanitize_sql_array([sql].flatten)
      select(query).province_or_city
    end

    def self.airlift_eligible_sources
      _locations = Location.where('us_troop > 0')
    end

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
