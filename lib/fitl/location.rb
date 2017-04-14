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
      'us_troop + us_base + us_irregular_hidden + us_irregular_activated'
    end

    def self.arvn_count
      'arvn_troop + arvn_base + arvn_ranger_hidden + arvn_ranger_activated + arvn_police'
    end

    def self.nva_count
      'nva_troop + nva_base + nva_tunnel_base + nva_guerrilla_hidden + nva_guerrilla_activated'
    end

    def self.vc_count
      'vc_guerrilla_hidden + vc_guerrilla_activated + vc_base + vc_tunnel_base'
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

    # Some initial scopes to get started.
    scope :us_troops_in_cambodia_or_laos, -> { us_troops_present.in_laos_or_cambodia }
    scope :us_troops_in_south_vietnam, -> { us_troops_present.in_south_vietnam }

    scope :us_troops_present, -> { where('us_troop > 0') }
    scope :in_laos_or_cambodia, -> { where("country = 'Cambodia' OR country = 'Laos'") }
    scope :in_south_vietnam, -> { where(country: 'South Vietnam') }

    # Air Lift allows drawing US Troops, then US Irregulars and ARVN Rangers
    # from up to 2 spaces, for deployment into 2 spaces.
    # For now, let's assume there are no spaces in Laos or Cambodia to draw from,
    # which is convenient as this is the situation Playbook Example #4.

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

    # I do not yet know how to do these computations directly in the database, in
    # part because I'm not sure exactly what the computations are. Once I get the
    # air lift available implemented correctly, then it should be possible to move
    # most of it into the database.

    def us_troops_available
      # return 0 if us_troop == 0 # redundant
      available = us_troop < excess ? us_troop : excess
      update_attribute(:us_troop, us_troop - available)
      available
    end

    def excess
      excess = fwa_count - pavn_count - 1
      @excess ||= excess > 0 ? excess : 0
    end

    # TODO: test
    def fwa_count
      us_count + arvn_count
    end

    # TODO: test
    def pavn_count
      nva_count + vc_count
    end

    def coin_control?
      @coin_control ||= us_count + arvn_count > nva_count + vc_count
    end

    def nva_control?
      @nva_control ||= nva_count > us_count + arvn_count + vc_count
    end

    def uncontrolled?
      @uncontrolled ||= !nva_control? && !coin_control?
    end

    def us_count
      us_troop + us_base + us_irregular_hidden + us_irregular_activated
    end

    def vc_count
      vc_guerrilla_hidden + vc_guerrilla_activated + vc_base + vc_tunnel_base
    end

    def nva_count
      nva_troop + nva_guerrilla_hidden + nva_guerrilla_activated + nva_base + nva_tunnel_base
    end

    def arvn_count
      arvn_troop + arvn_ranger_hidden + arvn_ranger_activated + arvn_base + arvn_police
    end
  end
end
