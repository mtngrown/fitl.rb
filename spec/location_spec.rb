# frozen_string_literal: true

require 'spec_helper'

module Fitl
  RSpec.describe Location do
    subject(:location) { Location.new }

    it { expect(location).not_to be nil }

    describe '.build_from_yaml' do
      it 'builds from a yaml file' do
        file = File.join(__dir__, 'fixtures/locations.yaml')
        expect(Location.build_from_yaml(file)).not_to be nil
      end
    end
  end
end
