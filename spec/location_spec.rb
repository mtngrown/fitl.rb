# frozen_string_literal: true

require 'spec_helper'

module Fitl
  RSpec.describe Location do
    let(:file) { File.join(__dir__, 'fixtures/locations.yaml') }

    subject(:location) { Location.new }

    it { expect(location).not_to be nil }

    describe '.build_from_yaml' do
      it 'builds from a yaml file' do
        actual = Location.build_from_yaml file
        expect(actual.size).to eq 36
      end
    end
  end
end
