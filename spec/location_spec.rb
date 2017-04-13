# frozen_string_literal: true

require 'spec_helper'

module Fitl
  RSpec.describe Location do
    let(:file) { File.join(__dir__, 'fixtures/playbook-4.yaml') }

    subject(:location) { Location.new }

    it { expect(location).not_to be nil }

    describe '.build_from_yaml' do
      it 'builds from a yaml file' do
        actual = Location.build_from_yaml file
        expect(actual.size).to eq 36

        nva_controlled = Location.where(control: 'nva')
        expect(nva_controlled.size).to eq 7
        nva_bases = Location.where('nva_base > 0')
        expect(nva_bases.size).to eq 8
      end

      it 'deals with the case statement' do
        Location.build_from_yaml file
        control = Location.case_for_control

        expected = [
          'Quang Tri',
          'Hue',
          'Da Nang',
          'Qui Nhon',
          'Cam Ranh',
          'Quang Tin',
          'Kontum',
          'Binh Dinh',
          'Pleiku',
          'Khanh Hoa',
          'Phu Bon',
          'Binh Tuy',
          'Saigon',
          'Quang Duc',
          'Tay Ninh',
          'An Loc',
          'Can Tho',
          'Kien Giang'
        ]
        coin = control.select { |e| e.control == 'COIN' }.map { |e| e.name }
        expect(coin).to eq expected

        expected = [
          "North Vietnam",
          "Central Laos",
          "Southern Laos",
          "Northeast Cambodia",
          "The Fishhook",
          "The Parrot's Beak",
          "Sihnoukville"
        ]
        nva = control.select { |e| e.control == 'NVA' }.map { |e| e.name }
        expect(nva).to eq expected

        expected = [
          "Quang Nam",
          "Phuoc Long",
          "Kien Phong",
          "Kien Hoa",
          "Ba Xuyen"
        ]
        none = control.select { |e| e.control == 'NONE' }.map { |e| e.name }
        expect(none).to eq expected
      end

      xit 'finds us airlift eligible source locations' do
        Location.build_from_yaml file
        expect(Location.airlift_eligible_sources.size).to eq 15

        vc_locations = Location.vc_per_location
        expect(vc_locations.size).to eq 13

        us_locations = Location.us_per_location
        expect(us_locations.size).to eq 15

        arvn_locations = Location.arvn_per_location
        expect(arvn_locations.size).to eq 20

        nva_locations = Location.nva_per_location
        expect(nva_locations.size).to eq 10

        fwa_totals = Location.fwa_totals

        # expect(Location.nlf_total).to eq 14
      end
    end
  end
end
