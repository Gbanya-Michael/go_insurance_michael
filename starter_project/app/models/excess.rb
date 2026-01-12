# typed: false
# frozen_string_literal: true

class Excess < ApplicationRecord
  has_many :quotes, class_name: "Quote", dependent: :destroy

  validates :label, presence: true, uniqueness: true
  validates :value, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :multiplier, numericality: { greater_than: 0 }, allow_nil: true
end
