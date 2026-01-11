# typed: false
# frozen_string_literal: true

class Premium < ApplicationRecord
  validates :label, presence: true
  validates :premium_type, presence: true, uniqueness: true
  validates :multiplier, numericality: { greater_than: 0 }, allow_nil: true
end
