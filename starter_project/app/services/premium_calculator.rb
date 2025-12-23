# frozen_string_literal: true

class PremiumCalculator
  MAX_AGE = 84
  ADULT_AGE = 21
  CHILD_AGE = 16
  MAX_TRIP_DURATION_YEARS = 2
  MAX_ADVANCE_BOOKING_MONTHS = 18

  def initialize(quote_params)
    @travellers = quote_params[:travellers] || []
    @start_date = parse_date(quote_params[:start_date])
    @end_date = parse_date(quote_params[:end_date])
    @destination_ids = quote_params[:destination_ids] || []
    @trip_type_id = quote_params[:trip_type_id]
    @excess_id = quote_params[:excess_id]
    @cruise = to_boolean(quote_params[:cruise])
    @snow = to_boolean(quote_params[:snow])
    @snow_start_date = parse_date(quote_params[:snow_start_date])
    @snow_end_date = parse_date(quote_params[:snow_end_date])
  end

  def calculate_premiums
    return {} if invalid_inputs?

    base_premium = find_base_premium
    return {} unless base_premium

    Cover.all.each_with_object({}) do |cover, results|
      results[cover.id] = calculate_for_cover(cover, base_premium)
    end
  end

  def highest_zone_destination
    return nil if @destination_ids.blank?

    Destination.where(id: @destination_ids).order(zone: :desc).first
  end

  def trip_duration_days
    return 0 unless @start_date && @end_date

    (@end_date - @start_date).to_i + 1
  end

  private

  def invalid_inputs?
    @travellers.blank? || @start_date.nil? || @end_date.nil? || 
      @destination_ids.blank? || @trip_type_id.nil? || @excess_id.nil?
  end

  def find_base_premium
    Premium.find_by(premium_type: 'base')
  end

  def calculate_for_cover(cover, base_premium)
    total_base = calculate_total_base_premium(cover, base_premium)
    cruise_add_on = calculate_cruise_add_on
    snow_add_on = calculate_snow_add_on
    final_premium = total_base + cruise_add_on + snow_add_on

    {
      base_premium: total_base.round(2),
      cruise_add_on: cruise_add_on.round(2),
      snow_add_on: snow_add_on.round(2),
      final_premium: final_premium.round(2)
    }
  end

  def calculate_total_base_premium(cover, base_premium)
    @travellers.sum do |traveller|
      calculate_traveller_premium(traveller, cover, base_premium)
    end
  end

  def calculate_traveller_premium(traveller, cover, base_premium)
    age = traveller[:age].to_i
    age_multiplier = find_age_multiplier(age)
    return 0.0 unless age_multiplier

    duration_multiplier = find_duration_multiplier(trip_duration_days)
    return 0.0 unless duration_multiplier

    destination_multiplier = find_destination_multiplier
    return 0.0 unless destination_multiplier

    trip_type = TripType.find_by(id: @trip_type_id)
    return 0.0 unless trip_type

    excess = Excess.find_by(id: @excess_id)
    return 0.0 unless excess

    base_premium.multiplier *
      excess.multiplier *
      age_multiplier.multiplier *
      duration_multiplier.multiplier *
      destination_multiplier *
      trip_type.multiplier *
      cover.multiplier
  end

  def calculate_cruise_add_on
    return 0.0 unless @cruise

    destination = highest_zone_destination
    return 0.0 unless destination

    destination.cruise_add_on_amount * @travellers.count
  end

  def calculate_snow_add_on
    return 0.0 unless @snow
    return 0.0 unless @snow_start_date && @snow_end_date

    destination = highest_zone_destination
    return 0.0 unless destination&.ski_per_day_amount

    snow_days = (@snow_end_date - @snow_start_date).to_i + 1
    return 0.0 if snow_days <= 0

    destination.ski_per_day_amount * snow_days * @travellers.count
  end

  def find_age_multiplier(age)
    Age.where('age_minimum <= ? AND age_maximum >= ?', age, age).first
  end

  def find_duration_multiplier(days)
    Duration.where('minimum_days <= ? AND maximum_days >= ?', days, days).first
  end

  def find_destination_multiplier
    destination = highest_zone_destination
    destination&.multiplier&.to_f
  end

  def to_boolean(value)
    case value
    when true, "true", "1", 1
      true
    else
      false
    end
  end

  def parse_date(date_string)
    return nil unless date_string.present?

    stripped = date_string.to_s.strip
    Date.parse(stripped) if stripped.present?
  rescue ArgumentError
    nil
  end
end

