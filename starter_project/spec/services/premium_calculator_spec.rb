# frozen_string_literal: true

require "rails_helper"

# Comprehensive tests for PremiumCalculator service
# This is a critical component that calculates insurance premiums based on multiple factors.
# Tests verify exact calculations, edge cases, and business logic compliance.
RSpec.describe PremiumCalculator do
  # Test data setup - using factories for maintainability
  let(:base_premium) { create(:premium, premium_type: "base", multiplier: 1.92) }
  let(:trip_type) { create(:trip_type, multiplier: 1.0) }
  let(:excess) { create(:excess, multiplier: 0.9) }
  let(:destination) { create(:destination, zone: 1, multiplier: 1.4, cruise_add_on_amount: 25.0, ski_per_day_amount: 30.0) }
  let(:cover_basic) { create(:cover, cover_type: "basic", multiplier: 1.0) }
  let(:cover_plus) { create(:cover, cover_type: "plus", multiplier: 1.2) }
  let(:cover_elite) { create(:cover, cover_type: "elite", multiplier: 1.5) }
  let(:age_range) { create(:age, age_minimum: 18, age_maximum: 30, multiplier: 1.0) }
  let(:duration_range) { create(:duration, minimum_days: 1, maximum_days: 14, multiplier: 1.0) }

  let(:valid_params) do
    {
      travellers: [ { age: 25 } ],
      start_date: (Date.today + 1.month).to_s,
      end_date: (Date.today + 1.month + 7.days).to_s,
      destination_ids: [ destination.id ],
      trip_type_id: trip_type.id,
      excess_id: excess.id
    }
  end

  before do
    # Ensure required data exists
    base_premium
    age_range
    duration_range
    cover_basic
    cover_plus
    cover_elite
  end

  describe "#initialize" do
    it "initializes with valid parameters" do
      calculator = PremiumCalculator.new(valid_params)
      expect(calculator).to be_a(PremiumCalculator)
    end

    it "parses date strings correctly" do
      calculator = PremiumCalculator.new(valid_params)
      expect(calculator.trip_duration_days).to eq(8)
    end

    it "converts boolean values correctly" do
      params = valid_params.merge(cruise: "true", snow: "1")
      calculator = PremiumCalculator.new(params)
      # Access private methods via send for testing
      expect(calculator.send(:instance_variable_get, :@cruise)).to be true
      expect(calculator.send(:instance_variable_get, :@snow)).to be true
    end
  end

  describe "#calculate_premiums" do
    context "with valid inputs" do
      it "returns premiums for all covers" do
        calculator = PremiumCalculator.new(valid_params)
        premiums = calculator.calculate_premiums

        expect(premiums).to be_a(Hash)
        expect(premiums.keys.length).to eq(Cover.count)
        expect(premiums.keys).to include(cover_basic.id, cover_plus.id, cover_elite.id)
      end

      it "calculates base premium correctly with exact formula" do
        # Formula: base × excess × age × duration × destination × trip_type × cover
        # Expected: 1.92 × 0.9 × 1.0 × 1.0 × 1.4 × 1.0 × 1.0 = 2.4192
        calculator = PremiumCalculator.new(valid_params)
        premiums = calculator.calculate_premiums

        basic_premium = premiums[cover_basic.id]
        expected_base = 1.92 * 0.9 * 1.0 * 1.0 * 1.4 * 1.0 * 1.0

        expect(basic_premium[:base_premium]).to be_within(0.01).of(expected_base)
        expect(basic_premium[:base_premium]).to be > 0
        expect(basic_premium[:final_premium]).to be >= basic_premium[:base_premium]
      end

      it "calculates different premiums for different cover levels" do
        calculator = PremiumCalculator.new(valid_params)
        premiums = calculator.calculate_premiums

        basic = premiums[cover_basic.id][:base_premium]
        plus = premiums[cover_plus.id][:base_premium]
        elite = premiums[cover_elite.id][:base_premium]

        # Plus should be higher than basic (1.2x multiplier)
        expect(plus).to be > basic
        # Elite should be highest (1.5x multiplier)
        expect(elite).to be > plus
        # Verify exact ratios
        expect(plus / basic).to be_within(0.01).of(1.2)
        expect(elite / basic).to be_within(0.01).of(1.5)
      end

      it "calculates premiums for multiple travellers correctly" do
        params = valid_params.merge(
          travellers: [ { age: 25 }, { age: 30 } ]
        )
        calculator = PremiumCalculator.new(params)
        premiums = calculator.calculate_premiums

        single_traveller_calc = PremiumCalculator.new(valid_params)
        single_premiums = single_traveller_calc.calculate_premiums

        # Two travellers should cost exactly 2x one traveller
        premiums.each do |cover_id, premium_data|
          single_premium = single_premiums[cover_id]
          expect(premium_data[:base_premium]).to be_within(0.01).of(single_premium[:base_premium] * 2)
        end
      end

      it "uses highest zone destination when multiple destinations selected" do
        # Create age and duration ranges that match the test data
        # Trip duration is 8 days (start_date + 1 month to end_date + 1 month + 7 days)
        create(:age, age_minimum: 18, age_maximum: 30, multiplier: 1.0)
        create(:duration, minimum_days: 1, maximum_days: 14, multiplier: 1.0)

        destination_zone_1 = create(:destination, zone: 1, multiplier: 1.2)
        destination_zone_3 = create(:destination, zone: 3, multiplier: 1.8)
        destination_zone_2 = create(:destination, zone: 2, multiplier: 1.5)

        params = valid_params.merge(
          destination_ids: [ destination_zone_1.id, destination_zone_2.id, destination_zone_3.id ]
        )
        calculator = PremiumCalculator.new(params)
        premiums = calculator.calculate_premiums

        # Should use zone 3 multiplier (1.8), not zone 1 or 2
        basic_premium = premiums[cover_basic.id]
        expected_base = 1.92 * 0.9 * 1.0 * 1.0 * 1.8 * 1.0 * 1.0

        expect(basic_premium[:base_premium]).to be_within(0.01).of(expected_base)
      end
    end

    context "with cruise add-on" do
      it "includes cruise add-on in final premium" do
        params_with_cruise = valid_params.merge(cruise: true)
        calculator = PremiumCalculator.new(params_with_cruise)
        premiums = calculator.calculate_premiums

        premiums.each do |_cover_id, premium_data|
          expect(premium_data[:cruise_add_on]).to eq(25.0) # cruise_add_on_amount × 1 traveller
          expect(premium_data[:final_premium]).to eq(premium_data[:base_premium] + 25.0)
        end
      end

      it "calculates cruise add-on for multiple travellers" do
        params = valid_params.merge(
          cruise: true,
          travellers: [ { age: 25 }, { age: 30 } ]
        )
        calculator = PremiumCalculator.new(params)
        premiums = calculator.calculate_premiums

        premiums.each do |_cover_id, premium_data|
          expect(premium_data[:cruise_add_on]).to eq(50.0) # 25.0 × 2 travellers
        end
      end

      it "returns zero cruise add-on when cruise is false" do
        calculator = PremiumCalculator.new(valid_params)
        premiums = calculator.calculate_premiums

        premiums.each do |_cover_id, premium_data|
          expect(premium_data[:cruise_add_on]).to eq(0.0)
        end
      end
    end

    context "with snow add-on" do
      it "includes snow add-on in final premium" do
        params_with_snow = valid_params.merge(
          snow: true,
          snow_start_date: (Date.today + 1.month + 2.days).to_s,
          snow_end_date: (Date.today + 1.month + 5.days).to_s
        )
        calculator = PremiumCalculator.new(params_with_snow)
        premiums = calculator.calculate_premiums

        # 4 days (2nd, 3rd, 4th, 5th) × 30.0 per day × 1 traveller = 120.0
        snow_days = 4
        expected_snow_add_on = 30.0 * snow_days * 1

        premiums.each do |_cover_id, premium_data|
          expect(premium_data[:snow_add_on]).to eq(expected_snow_add_on)
          expect(premium_data[:final_premium]).to eq(premium_data[:base_premium] + expected_snow_add_on)
        end
      end

      it "calculates snow add-on for multiple travellers" do
        params = valid_params.merge(
          snow: true,
          snow_start_date: (Date.today + 1.month + 2.days).to_s,
          snow_end_date: (Date.today + 1.month + 5.days).to_s,
          travellers: [ { age: 25 }, { age: 30 } ]
        )
        calculator = PremiumCalculator.new(params)
        premiums = calculator.calculate_premiums

        # 4 days × 30.0 per day × 2 travellers = 240.0
        expected_snow_add_on = 30.0 * 4 * 2

        premiums.each do |_cover_id, premium_data|
          expect(premium_data[:snow_add_on]).to eq(expected_snow_add_on)
        end
      end

      it "returns zero snow add-on when snow is false" do
        calculator = PremiumCalculator.new(valid_params)
        premiums = calculator.calculate_premiums

        premiums.each do |_cover_id, premium_data|
          expect(premium_data[:snow_add_on]).to eq(0.0)
        end
      end

      it "returns zero snow add-on when snow dates are missing" do
        params = valid_params.merge(snow: true, snow_start_date: nil, snow_end_date: nil)
        calculator = PremiumCalculator.new(params)
        premiums = calculator.calculate_premiums

        premiums.each do |_cover_id, premium_data|
          expect(premium_data[:snow_add_on]).to eq(0.0)
        end
      end

      it "handles single day snow coverage correctly" do
        params = valid_params.merge(
          snow: true,
          snow_start_date: (Date.today + 1.month + 2.days).to_s,
          snow_end_date: (Date.today + 1.month + 2.days).to_s
        )
        calculator = PremiumCalculator.new(params)
        premiums = calculator.calculate_premiums

        # 1 day × 30.0 per day × 1 traveller = 30.0
        expected_snow_add_on = 30.0 * 1 * 1

        premiums.each do |_cover_id, premium_data|
          expect(premium_data[:snow_add_on]).to eq(expected_snow_add_on)
        end
      end
    end

    context "with both add-ons" do
      it "includes both cruise and snow add-ons in final premium" do
        params = valid_params.merge(
          cruise: true,
          snow: true,
          snow_start_date: (Date.today + 1.month + 2.days).to_s,
          snow_end_date: (Date.today + 1.month + 5.days).to_s
        )
        calculator = PremiumCalculator.new(params)
        premiums = calculator.calculate_premiums

        premiums.each do |_cover_id, premium_data|
          expected_final = premium_data[:base_premium] + premium_data[:cruise_add_on] + premium_data[:snow_add_on]
          expect(premium_data[:final_premium]).to be_within(0.01).of(expected_final)
        end
      end
    end

    context "with different age ranges" do
      it "uses correct age multiplier for traveller age" do
        # Create duration range that matches the trip duration (8 days)
        create(:duration, minimum_days: 1, maximum_days: 14, multiplier: 1.0)

        create(:age, age_minimum: 18, age_maximum: 30, multiplier: 1.0)
        create(:age, age_minimum: 31, age_maximum: 50, multiplier: 1.2)
        create(:age, age_minimum: 51, age_maximum: 84, multiplier: 1.5)

        params_young = valid_params.merge(travellers: [ { age: 25 } ])
        params_middle = valid_params.merge(travellers: [ { age: 40 } ])
        params_older = valid_params.merge(travellers: [ { age: 60 } ])

        calc_young = PremiumCalculator.new(params_young)
        calc_middle = PremiumCalculator.new(params_middle)
        calc_older = PremiumCalculator.new(params_older)

        young_premium = calc_young.calculate_premiums[cover_basic.id][:base_premium]
        middle_premium = calc_middle.calculate_premiums[cover_basic.id][:base_premium]
        older_premium = calc_older.calculate_premiums[cover_basic.id][:base_premium]

        # Older should be more expensive than middle, which should be more than young
        expect(middle_premium).to be > young_premium
        expect(older_premium).to be > middle_premium
        # Verify exact ratios
        expect(middle_premium / young_premium).to be_within(0.01).of(1.2)
        expect(older_premium / young_premium).to be_within(0.01).of(1.5)
      end
    end

    context "with different trip durations" do
      it "uses correct duration multiplier" do
        # Create age range for the traveller (age 25)
        create(:age, age_minimum: 18, age_maximum: 30, multiplier: 1.0)

        # Ensure no overlapping ranges exist that could interfere
        Duration.where("minimum_days <= 30").destroy_all
        create(:duration, minimum_days: 1, maximum_days: 7, multiplier: 1.0)
        create(:duration, minimum_days: 8, maximum_days: 14, multiplier: 1.2)
        create(:duration, minimum_days: 15, maximum_days: 30, multiplier: 1.5)

        # Short trip: 6 days (start + 1 month to start + 1 month + 5 days) = 1-7 range
        # Medium trip: 11 days (start + 1 month to start + 1 month + 10 days) = 8-14 range
        # Long trip: 21 days (start + 1 month to start + 1 month + 20 days) = 15-30 range
        params_short = valid_params.merge(
          end_date: (Date.today + 1.month + 5.days).to_s
        )
        params_medium = valid_params.merge(
          end_date: (Date.today + 1.month + 10.days).to_s
        )
        params_long = valid_params.merge(
          end_date: (Date.today + 1.month + 20.days).to_s
        )

        calc_short = PremiumCalculator.new(params_short)
        calc_medium = PremiumCalculator.new(params_medium)
        calc_long = PremiumCalculator.new(params_long)

        short_premium = calc_short.calculate_premiums[cover_basic.id][:base_premium]
        medium_premium = calc_medium.calculate_premiums[cover_basic.id][:base_premium]
        long_premium = calc_long.calculate_premiums[cover_basic.id][:base_premium]

        # Longer trips should cost more
        expect(medium_premium).to be > short_premium
        expect(long_premium).to be > medium_premium
      end
    end

    context "with invalid inputs" do
      it "returns empty hash when travellers are missing" do
        invalid_params = valid_params.merge(travellers: [])
        calculator = PremiumCalculator.new(invalid_params)
        expect(calculator.calculate_premiums).to eq({})
      end

      it "returns empty hash when start_date is missing" do
        invalid_params = valid_params.merge(start_date: nil)
        calculator = PremiumCalculator.new(invalid_params)
        expect(calculator.calculate_premiums).to eq({})
      end

      it "returns empty hash when end_date is missing" do
        invalid_params = valid_params.merge(end_date: nil)
        calculator = PremiumCalculator.new(invalid_params)
        expect(calculator.calculate_premiums).to eq({})
      end

      it "returns empty hash when destination_ids are missing" do
        invalid_params = valid_params.merge(destination_ids: [])
        calculator = PremiumCalculator.new(invalid_params)
        expect(calculator.calculate_premiums).to eq({})
      end

      it "returns empty hash when trip_type_id is missing" do
        invalid_params = valid_params.merge(trip_type_id: nil)
        calculator = PremiumCalculator.new(invalid_params)
        expect(calculator.calculate_premiums).to eq({})
      end

      it "returns empty hash when excess_id is missing" do
        invalid_params = valid_params.merge(excess_id: nil)
        calculator = PremiumCalculator.new(invalid_params)
        expect(calculator.calculate_premiums).to eq({})
      end

      it "returns empty hash when base premium is not found" do
        Premium.destroy_all
        calculator = PremiumCalculator.new(valid_params)
        expect(calculator.calculate_premiums).to eq({})
      end
    end

    context "edge cases" do
      it "handles age outside valid range gracefully" do
        params = valid_params.merge(travellers: [ { age: 100 } ])
        calculator = PremiumCalculator.new(params)
        premiums = calculator.calculate_premiums

        # Should return 0.0 for traveller with no matching age range
        premiums.each do |_cover_id, premium_data|
          expect(premium_data[:base_premium]).to eq(0.0)
        end
      end

      it "handles duration outside valid range gracefully" do
        params = valid_params.merge(
          end_date: (Date.today + 1.month + 100.days).to_s
        )
        calculator = PremiumCalculator.new(params)
        premiums = calculator.calculate_premiums

        # Should return 0.0 for duration with no matching range
        premiums.each do |_cover_id, premium_data|
          expect(premium_data[:base_premium]).to eq(0.0)
        end
      end

      it "rounds all monetary values to 2 decimal places" do
        calculator = PremiumCalculator.new(valid_params)
        premiums = calculator.calculate_premiums

        premiums.each do |_cover_id, premium_data|
          expect(premium_data[:base_premium].to_s.split(".").last.length).to be <= 2
          expect(premium_data[:cruise_add_on].to_s.split(".").last.length).to be <= 2
          expect(premium_data[:snow_add_on].to_s.split(".").last.length).to be <= 2
          expect(premium_data[:final_premium].to_s.split(".").last.length).to be <= 2
        end
      end
    end
  end

  describe "#highest_zone_destination" do
    it "returns destination with highest zone" do
      destination1 = create(:destination, zone: 1)
      destination2 = create(:destination, zone: 3)
      destination3 = create(:destination, zone: 2)

      params = valid_params.merge(destination_ids: [ destination1.id, destination2.id, destination3.id ])
      calculator = PremiumCalculator.new(params)
      expect(calculator.highest_zone_destination.zone).to eq(3)
      expect(calculator.highest_zone_destination.id).to eq(destination2.id)
    end

    it "returns nil when no destinations selected" do
      params = valid_params.merge(destination_ids: [])
      calculator = PremiumCalculator.new(params)
      expect(calculator.highest_zone_destination).to be_nil
    end

    it "returns the destination when only one is selected" do
      params = valid_params.merge(destination_ids: [ destination.id ])
      calculator = PremiumCalculator.new(params)
      expect(calculator.highest_zone_destination.id).to eq(destination.id)
    end
  end

  describe "#trip_duration_days" do
    it "calculates correct duration including both start and end dates" do
      start_date = Date.today + 1.month
      end_date = start_date + 7.days
      params = valid_params.merge(
        start_date: start_date.to_s,
        end_date: end_date.to_s
      )
      calculator = PremiumCalculator.new(params)
      expect(calculator.trip_duration_days).to eq(8) # Inclusive: 0, 1, 2, 3, 4, 5, 6, 7 = 8 days
    end

    it "returns 1 for same day start and end" do
      start_date = Date.today + 1.month
      params = valid_params.merge(
        start_date: start_date.to_s,
        end_date: start_date.to_s
      )
      calculator = PremiumCalculator.new(params)
      expect(calculator.trip_duration_days).to eq(1)
    end

    it "returns 0 when dates are missing" do
      params = valid_params.merge(start_date: nil, end_date: nil)
      calculator = PremiumCalculator.new(params)
      expect(calculator.trip_duration_days).to eq(0)
    end
  end
end
