FactoryBot.define do
  factory :location, class: Fitl::Location do
    country 'South Vietnam'
  end

  factory :cambodia_location, class: Fitl::Location do
    country 'Cambodia'
  end

  factory :laos_location, class: Fitl::Location do
    country 'Laos'
  end
end
