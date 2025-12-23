# frozen_string_literal: true

FactoryBot.define do
  factory :quote do
    age { 30 }
    start_date { Date.today + 1.month }
    end_date { Date.today + 1.month + 7.days }
    cruise { false }
    snow { false }
    association :trip_type
    association :excess
    association :cover, factory: :cover

    trait :with_destinations do
      after(:create) do |quote|
        quote.destinations << create_list(:destination, 2)
      end
    end
  end
end



