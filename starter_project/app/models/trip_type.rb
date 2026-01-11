# typed: false
# frozen_string_literal: true

class TripType < ApplicationRecord
  has_many :quotes, class_name: "Quote", dependent: :destroy, foreign_key: :id

  validates :trip_type, presence: true, uniqueness: true
  validates :label, presence: true
  validates :multiplier, numericality: { greater_than: 0 }, allow_nil: true
end
