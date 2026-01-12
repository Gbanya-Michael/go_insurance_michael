# frozen_string_literal: true

FactoryBot.define do
  factory :quote do
    travellers { [ { age: 30 } ] }
    age { 30 }
    start_date { Date.today + 1.month }
    end_date { Date.today + 1.month + 7.days }
    cruise { false }
    snow { false }
    association :trip_type
    association :excess
    association :cover, factory: :cover

    after(:build) do |quote|
      # Ensure at least one destination is set via destination_ids
      # This bypasses validation during factory build
      destination = create(:destination)
      quote.destination_ids = [ destination.id ]
    end

    after(:create) do |quote|
      # Ensure destinations are actually associated after creation
      if quote.destinations.empty? && quote.destination_ids.present?
        quote.destination_ids.each do |dest_id|
          quote.quotes_to_destinations.create(destination_id: dest_id)
        end
      end
    end

    trait :with_destinations do
      after(:create) do |quote|
        quote.destinations << create_list(:destination, 2)
      end
    end
  end
end
