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
    # The next step is to acquire Locations which have hidden guerrillas.
    scope :hidden_guerrillas, -> { where('nva_guerrilla_hidden > 0 OR vc_guerrilla_hidden > 0') }

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

    # How to determine which are eligible?
    # First we get the excess, which is relation to COIN control.
    # Then we check to see if there are operational needs.
    # First crack we'll just send back the whole list...
    #
    # I think this is going about it the wrong way for getting started.
    # A better way to do this is use an instance method and filter out
    # all the locations with operational needs, starting with Sweep needs
    # first, then generalizing the technique to support Air Lift for Assaults.
    #
    # One of the benefits of doing it with instance methods is being able
    # to construct tests for each method.
    #
    # If it's possible to set precedence without outside context, then
    # each Location should be "scoreable" in the sense that some index
    # can be constructed to order the suitability for choosing a set of
    # Locations.
    def self.operational_needs
      coin_control_excess.select do |e|
        # How many hidden PAVN?
        hidden = e.pavn_hidden_count
      end
    end

    def self.coin_control_excess
      all.select do |location|
        location.has_coin_control_excess?
      end
    end

    # Suppose we want to determine if and how many troops are available
    # when a location is operational, where we also need to maintain COIN
    # control. I think this method will need to return a hash of the available
    # troop and irregular counts. The way to do this is break it down into
    # cases, add a spec for each case, then kludge the implementation
    # together here. I can make it pretty once it's working, then move the
    # computations into the database once it's cleaned up.
    def coin_available_after_sweep_needs
      # excess = coin_control_excess

      available = {}

      if us_troop <= coin_control_excess
        available[:us_troop] = us_troop - hidden_guerrilla_count
      end

      if us_irregular_count > 0
        if coin_control_excess - us_troop > 0
          available[:us_irregular_hidden] = us_irregular_hidden
          available[:us_irregular_activated] = us_irregular_activated
        end
      end

      available
    end

    def us_irregular_count
      us_irregular_hidden + us_irregular_activated
    end

    def hidden_guerrilla_count
      nva_guerrilla_hidden + vc_guerrilla_hidden
    end

    # I do not yet know how to do these computations directly in the database, in
    # part because I'm not sure exactly what the computations are. Once I get the
    # air lift available implemented correctly, then it should be possible to move
    # most of it into the database.

    # TODO: this should be COIN troops, not US troops.
    def us_troops_available
      us_troop < coin_control_excess ? us_troop : coin_control_excess
    end

    def has_coin_control_excess?
      coin_control_excess > 0
    end

    def coin_control_excess
      excess = fwa_count - pavn_count - 1
      @excess ||= excess > 0 ? excess : 0
    end

    def fwa_count
      us_count + arvn_count
    end

    def pavn_count
      nva_count + vc_count
    end

    def pavn_hidden_count
      nva_guerrilla_hidden + vc_guerrilla_hidden
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
