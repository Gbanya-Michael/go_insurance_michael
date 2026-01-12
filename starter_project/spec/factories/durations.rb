# frozen_string_literal: true

FactoryBot.define do
  factory :duration do
    minimum_days { 1 }
    maximum_days { 7 }
    multiplier { 1.0 }
  end
end
