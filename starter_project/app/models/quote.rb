# typed: false
# frozen_string_literal: true

class Quote < ApplicationRecord
  # Associations with presence validation (optional: false validates foreign key presence)
  belongs_to :trip_type, class_name: "TripType", optional: false
  belongs_to :excess, class_name: "Excess", optional: false
  belongs_to :cover, class_name: "Cover", optional: false # Schema requires cover_id

  has_many :quotes_to_destinations, class_name: "QuotesToDestination", dependent: :destroy
  has_many :destinations, through: :quotes_to_destinations, source: :destination, join_table: :quotes_to_destinations, class_name: "Destination"

  # Active Record validations - server-side data integrity
  # Note: trip_type_id, excess_id, and cover_id are validated by belongs_to associations
  validates :start_date, :end_date, presence: true
  validates :age, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: PremiumCalculator::MAX_AGE }
  validates :travellers, presence: true

  validate :end_date_after_start_date
  validate :start_date_not_in_past
  validate :start_date_within_advance_booking_limit
  validate :trip_duration_limit
  validate :at_least_one_destination
  validate :travellers_age_range
  validate :children_have_adult_companion
  validate :snow_dates_present_if_snow_enabled
  validate :snow_dates_within_trip_range

  # Virtual attribute for handling destination_ids in forms
  after_save :update_destinations

  def destination_ids
    return @destination_ids if defined?(@destination_ids) && @destination_ids
    destinations.pluck(:id)
  end

  def destination_ids=(ids)
    @destination_ids = ids.is_a?(Array) ? ids.reject(&:blank?) : ids
  end

  private

  def end_date_after_start_date
    return unless start_date.present? && end_date.present?

    errors.add(:end_date, "must be after start date") if end_date < start_date
  end

  def start_date_not_in_past
    return unless start_date.present?

    errors.add(:start_date, "cannot be in the past") if start_date < Date.current
  end

  def start_date_within_advance_booking_limit
    return unless start_date.present?

    max_advance_date = Date.current + PremiumCalculator::MAX_ADVANCE_BOOKING_MONTHS.months
    errors.add(:start_date, "cannot be more than #{PremiumCalculator::MAX_ADVANCE_BOOKING_MONTHS} months ahead") if start_date > max_advance_date
  end

  def trip_duration_limit
    return unless start_date.present? && end_date.present?

    max_duration_days = PremiumCalculator::MAX_TRIP_DURATION_YEARS * 365
    errors.add(:base, "Trip cannot exceed #{PremiumCalculator::MAX_TRIP_DURATION_YEARS} years") if (end_date - start_date).to_i > max_duration_days
  end

  def at_least_one_destination
    has_destinations = if @destination_ids.present?
                         @destination_ids.reject(&:blank?).any?
    else
                         destinations.any?
    end

    errors.add(:base, "Please select at least one destination") unless has_destinations
  end

  def travellers_age_range
    return unless travellers.present?

    travellers.each_with_index do |traveller, index|
      age = extract_traveller_age(traveller)
      unless age.between?(1, PremiumCalculator::MAX_AGE)
        errors.add(:travellers, "Traveller #{index + 1}: Age must be 1-#{PremiumCalculator::MAX_AGE}")
      end
    end
  end

  def children_have_adult_companion
    return unless travellers.present?

    children_present = travellers.any? { |t| extract_traveller_age(t) < PremiumCalculator::CHILD_AGE }
    return unless children_present

    adult_present = travellers.any? { |t| extract_traveller_age(t) >= PremiumCalculator::ADULT_AGE }
    errors.add(:travellers, "Children under #{PremiumCalculator::CHILD_AGE} need an adult #{PremiumCalculator::ADULT_AGE}+") unless adult_present
  end

  def snow_dates_present_if_snow_enabled
    return unless snow

    errors.add(:snow_start_date, "required when snow coverage is selected") if snow_start_date.blank?
    errors.add(:snow_end_date, "required when snow coverage is selected") if snow_end_date.blank?
  end

  def snow_dates_within_trip_range
    return unless snow && snow_start_date.present? && snow_end_date.present? && start_date.present? && end_date.present?

    errors.add(:snow_start_date, "must be within trip dates") if snow_start_date < start_date
    errors.add(:snow_end_date, "must be within trip dates") if snow_end_date > end_date
    errors.add(:snow_end_date, "must be after start date") if snow_end_date < snow_start_date
  end

  def extract_traveller_age(traveller)
    return 0 unless traveller

    traveller_hash = if traveller.is_a?(Hash) || traveller.is_a?(ActionController::Parameters)
                      traveller
    elsif traveller.is_a?(String)
                      JSON.parse(traveller) rescue {}
    else
                      {}
    end

    (traveller_hash["age"] || traveller_hash[:age] || traveller_hash["age"] || 0).to_i
  end

  def update_destinations
    return unless @destination_ids

    quotes_to_destinations.destroy_all
    @destination_ids.each do |destination_id|
      quotes_to_destinations.create(destination_id: destination_id)
    end
  end
end
