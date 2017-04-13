# frozen_string_literal: true

require 'active_record'

module Fitl
  class Location < ActiveRecord::Base
    # TODO: add validations

    scope :province_or_city, -> { where("location_type = 'province' OR location_type = 'city'") }

    def self.case_for_control
      sql = "locations.name, CASE
          WHEN #{us_count} + #{arvn_count} > #{nva_count} + #{vc_count} THEN 'COIN'
          WHEN #{nva_count} > #{us_count} + #{arvn_count} + #{vc_count} THEN 'NVA'
          ELSE 'NONE'
          END as control"
      query = sanitize_sql_array([sql].flatten)
      select(query).province_or_city
    end

    def self.us_count
      'us_troop + us_base + us_irregular'
    end

    def self.arvn_count
      'arvn_troop + arvn_base + arvn_ranger + arvn_police'
    end

    def self.nva_count
      'nva_troop + nva_base + nva_tunnel_base + nva_guerrilla'
    end

    def self.vc_count
      'vc_guerrilla + vc_base + vc_tunnel_base'
    end

    # Here's what the rules say in 8.8.2 AIRLIFT, page 19:
    # "Air Lift forces from 2 spaces - 1 in Monsoon - first from Laos/Cambodia,
    # then from South Vietnam spaces where there are the most US Troops beyond
    # those needed to keep COIN Control or those that would remove or Activate
    # enemies in any current accompanying Operation there."
    #
    # The English is ambiguous, so let's assume US forces bug out of Laos and
    # Cambodia regardless of COIN Control.
    #
    # The other way of reading the sentence is:
    # "Air Lift forces from 2 spaces - 1 in Monsoon - first from spaces in Laos/Cambodia,
    # then from spaces in South Vietnam, where there are the most US Troops
    # beyond those needed to keep COIN Control..."
    #
    # This means we have either 2 spaces in Laos or Cambodia, 1 space in Laos
    # or Cambodia, or 0 spaces in Laos or Cambodia. The conditions do not speak
    # to having US Bases or US Irregulars in Laos or Cambodia.

    scope :us_troops_in_cambodia_or_laos, -> {
      # where("us_troops > 0 AND country = 'Cambodia'")
      us_troops_present.laos_or_cambodia
    }

    scope :us_troops_present, -> { where('us_troop > 0') }
    scope :laos_or_cambodia, -> { where("country = 'Cambodia' OR country = 'Laos'") }

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
