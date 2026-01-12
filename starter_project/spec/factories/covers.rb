# frozen_string_literal: true

FactoryBot.define do
  factory :cover do
    sequence(:cover_type) { |n| "cover_type_#{n}" }
    label { "Basic" }
    multiplier { 1.0 }
  end
end
