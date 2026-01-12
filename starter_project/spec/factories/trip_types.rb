# frozen_string_literal: true

FactoryBot.define do
  factory :trip_type do
    sequence(:trip_type) { |n| "trip_type_#{n}" }
    label { "One Way" }
    multiplier { 1.0 }
  end
end
