# frozen_string_literal: true

FactoryBot.define do
  factory :age do
    age_minimum { 0 }
    age_maximum { 17 }
    multiplier { 1.5 }
  end
end
