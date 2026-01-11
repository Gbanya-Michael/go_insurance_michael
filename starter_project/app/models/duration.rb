# typed: false
# frozen_string_literal: true

class Duration < ApplicationRecord
  validates :minimum_days, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :maximum_days, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :multiplier, presence: true, numericality: { greater_than: 0 }

  validate :duration_range_valid

  private

  def duration_range_valid
    return unless minimum_days.present? && maximum_days.present?

    if maximum_days < minimum_days
      errors.add(:maximum_days, "must be at least #{minimum_days}")
      errors.add(:minimum_days, "must be at most #{maximum_days}")
    end
  end
end
