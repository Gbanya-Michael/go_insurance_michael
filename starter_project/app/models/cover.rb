# typed: false
# frozen_string_literal: true

class Cover < ApplicationRecord
  has_many :quotes, class_name: "Quote", dependent: :destroy

  validates :cover_type, presence: true, uniqueness: true
  validates :label, presence: true
  validates :multiplier, numericality: { greater_than: 0 }, allow_nil: true
end
