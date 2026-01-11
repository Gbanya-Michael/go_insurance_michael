# typed: false
# frozen_string_literal: true

class Destination < ApplicationRecord
  has_many :quotes_to_destinations, class_name: "QuotesToDestination"
  has_many :quotes, through: :quotes_to_destinations, source: :quote, join_table: :quotes_to_destinations, class_name: "Quote"

  validates :code, presence: true, uniqueness: true
  validates :label, presence: true
  validates :zone, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :multiplier, presence: true, numericality: { greater_than: 0 }
  validates :cruise_add_on_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :ski_per_day_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
