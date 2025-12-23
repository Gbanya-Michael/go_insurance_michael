# frozen_string_literal: true

# Controller for managing travel insurance quotes
# Handles quote creation, display, and updates with comprehensive validation
class QuotesController < ApplicationController
  before_action :set_quote, only: [ :show, :update ]
  before_action :load_form_data, only: [ :new ]

  def new
    @quote = Quote.new
  end

  def create
    @quote = Quote.new(quote_params.except(:travellers, :destination_ids))
    @quote.cover_id = Cover.first.id if @quote.cover_id.nil? && Cover.any?

    validation_passed, travellers_data = validate_quote

    if validation_passed
      @quote.travellers = travellers_data
      @quote.age = travellers_data.first[:age].to_i if travellers_data.any?
    end

    if validation_passed && @quote.save
      redirect_to quote_path(@quote), notice: "Quote created successfully."
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def show
    setup_premium_calculator
  end

  def update
    update_params = normalize_update_params(quote_update_params)

    if @quote.update(update_params)
      redirect_to quote_path(@quote), notice: "Quote updated successfully."
    else
      setup_premium_calculator
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_quote
    @quote = Quote.find(params[:id])
  end

  def load_form_data
    @trip_types = TripType.all
    @excesses = Excess.all
    @destinations = Destination.all.order(:label)
  end

  def setup_premium_calculator
    @calculator = build_premium_calculator
    @premiums = @calculator.calculate_premiums
    @covers = Cover.all.order(:id)
    @highest_zone_destination = @calculator.highest_zone_destination
  end

  def build_premium_calculator
    PremiumCalculator.new(
      travellers: build_travellers_from_quote,
      start_date: @quote.start_date.to_s,
      end_date: @quote.end_date.to_s,
      destination_ids: @quote.destination_ids,
      trip_type_id: @quote.trip_type_id,
      excess_id: @quote.excess_id,
      cruise: @quote.cruise,
      snow: @quote.snow,
      snow_start_date: @quote.snow_start_date&.to_s,
      snow_end_date: @quote.snow_end_date&.to_s
    )
  end

  def normalize_update_params(params)
    params[:snow_start_date] = nil if params[:snow_start_date].blank?
    params[:snow_end_date] = nil if params[:snow_end_date].blank?
    params
  end

  def build_travellers_from_quote
    if @quote.travellers.present? && @quote.travellers.is_a?(Array)
      @quote.travellers.map { |t| { age: t["age"] || t[:age] || @quote.age } }
    else
      [ { age: @quote.age } ]
    end
  end

  def quote_params
    params.require(:quote).permit(
      :start_date, :end_date, :trip_type_id, :excess_id,
      :cruise, :snow, :snow_start_date, :snow_end_date,
      destination_ids: [],
      travellers: [ :age ]
    )
  end

  def quote_update_params
    params.require(:quote).permit(
      :cruise, :snow, :snow_start_date, :snow_end_date, :cover_id
    )
  end

  # Validates quote data and returns [success, travellers_data]
  def validate_quote
    errors = []
    travellers_data = []
    travellers = normalize_travellers(params[:quote][:travellers] || [])

    validate_travellers(travellers, errors, travellers_data)
    validate_dates(errors)
    validate_destinations(errors)
    validate_required_fields(errors)

    if errors.any?
      errors.each { |error| @quote.errors.add(:base, error) }
      return [ false, [] ]
    end

    @quote.destination_ids = params[:quote][:destination_ids] if params[:quote][:destination_ids].present?
    [ true, travellers_data ]
  end

  def normalize_travellers(travellers_param)
    travellers = if travellers_param.is_a?(Hash)
                   travellers_param.values
    elsif travellers_param.is_a?(Array)
      travellers_param
    else
      []
    end

    travellers.compact.reject do |t|
      if t.is_a?(Hash) || t.is_a?(ActionController::Parameters)
        (t[:age] || t["age"]).blank?
      else
        t.blank?
      end
    end
  end

  def validate_travellers(travellers, errors, travellers_data)
    errors << "At least one traveller is required." if travellers.empty?

    travellers.each_with_index do |traveller, index|
      age = extract_traveller_age(traveller)
      validate_traveller_age(age, index + 1, errors)
      validate_child_has_adult(age, travellers, index + 1, errors)
      travellers_data << { age: age } if age.between?(1, PremiumCalculator::MAX_AGE)
    end
  end

  def extract_traveller_age(traveller)
    traveller_hash = if traveller.is_a?(Hash) || traveller.is_a?(ActionController::Parameters)
                       traveller
    else
      {}
    end
    (traveller_hash[:age] || traveller_hash["age"]).to_i
  end

  def validate_traveller_age(age, index, errors)
    return if age.between?(1, PremiumCalculator::MAX_AGE)

    errors << "Traveller #{index}: Age must be between 1 and #{PremiumCalculator::MAX_AGE}."
  end

  def validate_child_has_adult(age, travellers, index, errors)
    return unless age < PremiumCalculator::CHILD_AGE

    has_adult = travellers.any? { |t| extract_traveller_age(t) >= PremiumCalculator::ADULT_AGE }
    return if has_adult

    errors << "Traveller #{index}: Children under #{PremiumCalculator::CHILD_AGE} must travel with an adult (21+)."
  end

  def validate_dates(errors)
    start_date = parse_date(params[:quote][:start_date])
    end_date = parse_date(params[:quote][:end_date])

    if start_date.nil? || end_date.nil?
      errors << "Start date and end date are required."
      return
    end

    errors << "End date must be after start date." if end_date < start_date
    errors << "Start date cannot be in the past." if start_date < Date.today
    errors << "Start date cannot be more than #{PremiumCalculator::MAX_ADVANCE_BOOKING_MONTHS} months in advance." if start_date > Date.today + PremiumCalculator::MAX_ADVANCE_BOOKING_MONTHS.months
    errors << "Trip duration cannot exceed #{PremiumCalculator::MAX_TRIP_DURATION_YEARS} years." if (end_date - start_date).to_i > (PremiumCalculator::MAX_TRIP_DURATION_YEARS * 365)
  end

  def validate_destinations(errors)
    destination_ids = params[:quote][:destination_ids]
    if destination_ids.blank? || destination_ids.reject(&:blank?).empty?
      errors << "At least one destination must be selected."
    end
  end

  def validate_required_fields(errors)
    errors << "Trip type is required." unless params[:quote][:trip_type_id].present?
    errors << "Excess is required." unless params[:quote][:excess_id].present?
  end

  def parse_date(date_string)
    Date.parse(date_string) if date_string.present?
  rescue ArgumentError
    nil
  end
end
