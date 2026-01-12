# frozen_string_literal: true

FactoryBot.define do
  factory :destination do
    # Find next available code number to avoid uniqueness conflicts
    # This handles cases where the database isn't fully cleaned between test runs
    sequence(:code) do |n|
      # Start from n, but if that code exists, find the next available
      code = "TEST#{n}"
      counter = n
      while Destination.exists?(code: code)
        counter += 1
        code = "TEST#{counter}"
      end
      code
    end
    zone { 1 }
    label { "Test Destination" }
    multiplier { 1.4 }
    cruise_add_on_amount { 25.0 }
    ski_per_day_amount { 25.0 }
  end
end
