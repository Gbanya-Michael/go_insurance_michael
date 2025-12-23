# frozen_string_literal: true

FactoryBot.define do
  factory :excess do
    label { "$200" }
    value { 200 }
    multiplier { 1.0 }
  end
end



