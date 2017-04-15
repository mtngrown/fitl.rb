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
        coin = control.select { |e| e.control == 'COIN' }.map(&:name)
        expect(coin).to eq expected

        expected = [
          'North Vietnam',
          'Central Laos',
          'Southern Laos',
          'Northeast Cambodia',
          'The Fishhook',
          "The Parrot's Beak",
          'Sihnoukville'
        ]
        nva = control.select { |e| e.control == 'NVA' }.map(&:name)
        expect(nva).to eq expected

        expected = [
          'Quang Nam',
          'Phuoc Long',
          'Kien Phong',
          'Kien Hoa',
          'Ba Xuyen'
        ]
        none = control.select { |e| e.control == 'NONE' }.map(&:name)
        expect(none).to eq expected
      end

      describe '.us_troops_in_cambodia' do
        subject(:troops) { Location.us_troops_in_cambodia_or_laos }

        it 'finds no troops by default' do
          expect(troops).to eq []
        end

        it 'finds some US Troops in Laos' do
          create :laos_location, us_troop: 5
          expect(troops.size).to eq 1
        end

        it 'finds US Troops in Laos and Cambodia' do
          create :laos_location, us_troop: 5
          create :cambodia_location, us_troop: 2
          expect(troops.size).to eq 2
        end
      end

      describe '.us_troops_in_south_vietnam' do
        context 'default yaml configuration' do
          it 'finds some troops in South Vietnam' do
            Location.build_from_yaml file
            expect(Location.us_troops_in_south_vietnam.size).to eq 15
          end
        end

        context 'custom' do
          subject(:troops) { Location.us_troops_in_south_vietnam }

          it 'finds no US Troops in South Vietnam' do
            expect(troops.size).to eq 0
          end

          it 'finds some US Troops in South Vietnam' do
            create :location, name: 'Saigon', us_troop: 3
            expect(troops.size).to eq 1
          end
        end
      end
    end

    describe '#coin_control?' do
      context 'true' do
        it 'correctly determines COIN control' do
          location = build :location,
                            us_troop: 3, us_base: 1, us_irregular_hidden: 1,
                            arvn_troop: 1, arvn_police: 3,
                            nva_troop: 2,
                            vc_base: 1, vc_guerrilla_hidden: 3
          expect(location.coin_control?).to be true
        end
      end

      context 'false' do
        context 'nva controlled' do
          it 'correctly determines COIN does not control' do
            location = build :location,
                              us_troop: 1, us_base: 1, us_irregular_hidden: 1,
                              arvn_troop: 1, arvn_police: 3,
                              nva_troop: 8,
                              vc_base: 1, vc_guerrilla_hidden: 2
            expect(location.coin_control?).to be false
          end
        end

        context 'uncontrolled with only VC units present' do
          it 'correctly determines location is not under NVA or COIN control' do
            location = build :location,
                              vc_base: 1, vc_guerrilla_hidden: 2
            expect(location.coin_control?).to be false
          end
        end
      end
    end

    describe '#nva_control?' do
      context 'true' do
        it 'correctly determines NVA control' do
          location = build :location,
                            us_troop: 1, us_base: 1, us_irregular_hidden: 1,
                            arvn_troop: 1, arvn_police: 2,
                            nva_troop: 8, nva_base: 1, nva_guerrilla_hidden: 3,
                            vc_base: 1, vc_guerrilla_hidden: 2
          expect(location.nva_control?).to be true
        end
      end

      context 'false' do
        context 'coin_controlled' do
          it 'correctly determines NVA does not control' do
            location = build :location,
                              us_troop: 3, us_base: 1, us_irregular_hidden: 1,
                              arvn_troop: 1, arvn_police: 3,
                              nva_troop: 2,
                              vc_base: 1, vc_guerrilla_hidden: 2
            expect(location.nva_control?).to be false
          end
        end

        context 'uncontrolled with equal numbers of FWA and PAVN' do
          it 'correctly determines location is not under NVA or COIN control' do
            location = build :location,
                              nva_base: 0, nva_troop: 3,
                              vc_base: 1, vc_guerrilla_hidden: 2
            expect(location.coin_control?).to be false
            expect(location.nva_control?).to be false
          end
        end
      end
    end

    describe '#us_troops_available' do
      context 'COIN control' do
        it 'has an excess of COIN units' do
          location = build :location,
                            us_troop: 3, us_base: 1, us_irregular_hidden: 1,
                            arvn_troop: 1, arvn_police: 3,
                            nva_troop: 2,
                            vc_base: 1, vc_guerrilla_hidden: 2
          expect(location.excess).to eq 3
          expect(location.us_troops_available).to eq 3
        end

        it 'does not have an excess of COIN units' do
          location = build :location,
                            us_troop: 0, us_base: 1, us_irregular_hidden: 1,
                            arvn_troop: 1, arvn_police: 3,
                            nva_troop: 2,
                            vc_base: 1, vc_guerrilla_hidden: 2
          expect(location.excess).to eq 0
          expect(location.us_troops_available).to eq 0
        end
      end

      context 'medium scenario setup' do
        it 'finds 3 extra US Troops in Phu Bon and Can Tho' do
          Location.build_from_yaml file
          locations = Location.where("name IN ('Phu Bon', 'Can Tho')")
          locations.each do |location|
            expect(location.us_troops_available).to eq 3
          end
        end

        it 'finds 4 extra us troops in Quang Tin' do
          Location.build_from_yaml file
          quang_tri = Location.where(name: 'Quang Tin').first
          expect(quang_tri.us_troops_available).to eq 2
        end

        it 'finds 4 extra us troops in quang tri' do
          Location.build_from_yaml file
          quang_tri = Location.where(name: 'Quang Tri').first
          expect(quang_tri.us_troops_available).to eq 4
        end

        it 'finds no extra US Troops in Tay Ninh' do
          Location.build_from_yaml file
          tay_ninh = Location.where(name: 'Tay Ninh').first
          expect(tay_ninh.us_troops_available).to eq 0
        end
      end
    end

    describe '.excess' do
      it 'finds a list of locations with excess US Troops' do
        Location.build_from_yaml file
        expected = [
          'Quang Tri',
          'Hue',
          'Da Nang',
          'Qui Nhon',
          'Cam Ranh',
          'Quang Tin',
          'Kontum',
          'Phu Bon',
          'Binh Tuy',
          'Saigon',
          'Quang Duc',
          'An Loc',
          'Can Tho',
          'Kien Giang'
        ]
        actual = Location.excess.map(&:name)
        expect(actual).to eq expected
      end
    end

    describe '#excess' do
      context 'coin controlled' do
        it 'has an excess of COIN units' do
          location = build :location,
                           us_troop: 3, us_base: 1, us_irregular_hidden: 1,
                           arvn_troop: 1, arvn_police: 3,
                           nva_troop: 2,
                           vc_base: 1, vc_guerrilla_hidden: 2
          expect(location.fwa_count).to eq 9
          expect(location.pavn_count).to eq 5
          expect(location.excess).to eq 3
        end
      end

      it 'does not have an excess of COIN units' do
        location = build :location,
                         us_troop: 0, us_base: 1, us_irregular_hidden: 1,
                         arvn_troop: 1, arvn_police: 3,
                         nva_troop: 2,
                         vc_base: 1, vc_guerrilla_hidden: 2
        expect(location.excess).to eq 0
      end

      context 'nva controlled' do
        it 'finds no excess when NVA controlled' do
          location = build :location,
                           us_troop: 0, us_base: 1, us_irregular_hidden: 1,
                           arvn_troop: 1, arvn_police: 3,
                           nva_troop: 10,
                           vc_base: 1, vc_guerrilla_hidden: 2

          expect(location.excess).to eq 0
        end
      end

      context 'uncontrolled' do
        it 'finds no excess when uncontrolled' do
          location = build :location,
                           us_base: 1, us_irregular_hidden: 1,
                           vc_base: 1, vc_guerrilla_hidden: 2

          expect(location.excess).to eq 0
        end
      end
    end

    context 'total faction counts' do
      let(:location) do
        build :location,
              us_troop: 0, us_base: 1, us_irregular_hidden: 1,
              arvn_troop: 1, arvn_police: 3,
              nva_troop: 2,
              vc_base: 1, vc_guerrilla_hidden: 2
      end

      describe '#fwa_count' do
        it 'counts fwa units in location' do
          expect(location.fwa_count).to eq 6
        end
      end

      describe '#pavn_count' do
        it 'counts pavn units in location' do
          expect(location.pavn_count).to eq 5
        end
      end
    end

    describe '#us_count' do
      subject(:troops) { build :location, us_troop: 3, us_base: 1, us_irregular_hidden: 2 }

      it { expect(troops.us_count).to eq 6 }
    end

    describe '#vc_count' do
      subject(:troops) do
        build :location,
              vc_guerrilla_hidden: 3,
              vc_base: 1,
              vc_tunnel_base: 1
      end

      it { expect(troops.vc_count).to eq 5 }
    end

    describe '#nva_count' do
      subject(:troops) do
        build :location, nva_troop: 9, nva_guerrilla_hidden: 1, nva_base: 1, nva_tunnel_base: 0
      end

      it { expect(troops.nva_count).to eq 11 }
    end

    describe '#arvn_count' do
      subject(:troops) do
        build :location, arvn_troop: 3, arvn_base: 1, arvn_ranger_hidden: 2, arvn_police: 3
      end

      it { expect(troops.arvn_count).to eq 9 }
    end
  end
end
