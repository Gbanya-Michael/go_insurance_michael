# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PremiumCalculator do
  let(:base_premium) { Premium.find_by(premium_type: 'base') || create(:premium, premium_type: 'base', multiplier: 1.92) }
  let(:trip_type) { TripType.first || create(:trip_type, multiplier: 1.0) }
  let(:excess) { Excess.first || create(:excess, multiplier: 1.0) }
  let(:destination) { Destination.first || create(:destination, zone: 1, multiplier: 1.4) }
  let(:cover) { Cover.first || create(:cover, multiplier: 1.0) }

  let(:valid_params) do
    {
      travellers: [{ age: 30 }],
      start_date: (Date.today + 1.month).to_s,
      end_date: (Date.today + 1.month + 7.days).to_s,
      destination_ids: [destination.id],
      trip_type_id: trip_type.id,
      excess_id: excess.id
    }
  end

  describe '#initialize' do
    it 'initializes with valid parameters' do
      calculator = PremiumCalculator.new(valid_params)
      expect(calculator).to be_a(PremiumCalculator)
    end
  end

  describe '#calculate_premiums' do
    context 'with valid inputs' do
      it 'returns premiums for all covers' do
        calculator = PremiumCalculator.new(valid_params)
        premiums = calculator.calculate_premiums
        
        expect(premiums).to be_a(Hash)
        expect(premiums.keys.length).to eq(Cover.count)
      end

      it 'calculates base premium correctly' do
        calculator = PremiumCalculator.new(valid_params)
        premiums = calculator.calculate_premiums
        
        premiums.each do |_cover_id, premium_data|
          expect(premium_data[:base_premium]).to be > 0
          expect(premium_data[:final_premium]).to be >= premium_data[:base_premium]
        end
      end
    end

    context 'with cruise add-on' do
      it 'includes cruise add-on in final premium' do
        params_with_cruise = valid_params.merge(cruise: true)
        calculator = PremiumCalculator.new(params_with_cruise)
        premiums = calculator.calculate_premiums
        
        premiums.each do |_cover_id, premium_data|
          expect(premium_data[:cruise_add_on]).to be > 0
          expect(premium_data[:final_premium]).to be > premium_data[:base_premium]
        end
      end
    end

    context 'with snow add-on' do
      it 'includes snow add-on in final premium' do
        params_with_snow = valid_params.merge(
          snow: true,
          snow_start_date: (Date.today + 1.month + 2.days).to_s,
          snow_end_date: (Date.today + 1.month + 5.days).to_s
        )
        calculator = PremiumCalculator.new(params_with_snow)
        premiums = calculator.calculate_premiums
        
        premiums.each do |_cover_id, premium_data|
          expect(premium_data[:snow_add_on]).to be > 0
          expect(premium_data[:final_premium]).to be > premium_data[:base_premium]
        end
      end
    end

    context 'with invalid inputs' do
      it 'returns empty hash when travellers are missing' do
        invalid_params = valid_params.merge(travellers: [])
        calculator = PremiumCalculator.new(invalid_params)
        expect(calculator.calculate_premiums).to eq({})
      end

      it 'returns empty hash when dates are missing' do
        invalid_params = valid_params.merge(start_date: nil, end_date: nil)
        calculator = PremiumCalculator.new(invalid_params)
        expect(calculator.calculate_premiums).to eq({})
      end
    end
  end

  describe '#highest_zone_destination' do
    let(:destination1) { create(:destination, zone: 1) }
    let(:destination2) { create(:destination, zone: 3) }
    let(:destination3) { create(:destination, zone: 2) }

    it 'returns destination with highest zone' do
      params = valid_params.merge(destination_ids: [destination1.id, destination2.id, destination3.id])
      calculator = PremiumCalculator.new(params)
      expect(calculator.highest_zone_destination.zone).to eq(3)
    end
  end

  describe '#trip_duration_days' do
    it 'calculates correct duration' do
      start_date = Date.today + 1.month
      end_date = start_date + 7.days
      params = valid_params.merge(
        start_date: start_date.to_s,
        end_date: end_date.to_s
      )
      calculator = PremiumCalculator.new(params)
      expect(calculator.trip_duration_days).to eq(8)
    end
  end
end



