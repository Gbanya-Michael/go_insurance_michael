# frozen_string_literal: true

FactoryBot.define do
  factory :excess do
    sequence(:label) { |n| "$#{200 + n * 100}" }
    value { 200 }
    multiplier { 1.0 }
  end
end
