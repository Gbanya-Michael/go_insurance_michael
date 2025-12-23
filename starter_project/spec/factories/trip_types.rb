# frozen_string_literal: true

FactoryBot.define do
  factory :trip_type do
    label { "One Way" }
    trip_type { "one_way" }
    multiplier { 1.0 }
  end
end



