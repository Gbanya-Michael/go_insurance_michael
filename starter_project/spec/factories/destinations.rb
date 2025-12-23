# frozen_string_literal: true

FactoryBot.define do
  factory :destination do
    zone { 1 }
    label { "Test Destination" }
    code { "TEST" }
    multiplier { 1.4 }
    cruise_add_on_amount { 25.0 }
    ski_per_day_amount { 25.0 }
  end
end



