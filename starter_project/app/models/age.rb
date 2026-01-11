# typed: false
# frozen_string_literal: true

class Age < ApplicationRecord
  validates :age_minimum, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :age_maximum, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :multiplier, presence: true, numericality: { greater_than: 0 }

  validate :age_range_valid

  private

  def age_range_valid
    return unless age_minimum.present? && age_maximum.present?

    if age_maximum < age_minimum
      errors.add(:age_maximum, "must be at least #{age_minimum} (currently #{age_maximum})")
      errors.add(:age_minimum, "must be at most #{age_maximum} (currently #{age_minimum})")
    end
  end
end
