# frozen_string_literal: true

require "rails_helper"

# Comprehensive tests for TripType model
# Tests cover validations, associations, and business logic
RSpec.describe TripType, type: :model do
  describe "validations" do
    it "requires trip_type" do
      trip_type = TripType.new(label: "One Way", multiplier: 1.0)
      expect(trip_type).not_to be_valid
      expect(trip_type.errors[:trip_type]).to include("can't be blank")
    end

    it "requires label" do
      trip_type = TripType.new(trip_type: "one_way", multiplier: 1.0)
      expect(trip_type).not_to be_valid
      expect(trip_type.errors[:label]).to include("can't be blank")
    end

    it "validates trip_type uniqueness" do
      create(:trip_type, trip_type: "unique_trip_type_test")
      trip_type = TripType.new(trip_type: "unique_trip_type_test", label: "Another One Way", multiplier: 1.0)
      expect(trip_type).not_to be_valid
      expect(trip_type.errors[:trip_type]).to include("has already been taken")
    end

    it "validates multiplier is greater than 0" do
      trip_type = TripType.new(trip_type: "one_way", label: "One Way", multiplier: 0)
      expect(trip_type).not_to be_valid
      expect(trip_type.errors[:multiplier]).to include("must be greater than 0")
    end

    it "allows nil multiplier" do
      trip_type = TripType.new(trip_type: "nil_multiplier_test", label: "One Way", multiplier: nil)
      expect(trip_type).to be_valid
    end

    it "allows valid trip type" do
      trip_type = TripType.new(trip_type: "valid_trip_type_test", label: "One Way", multiplier: 1.0)
      expect(trip_type).to be_valid
    end
  end

  describe "associations" do
    it "has many quotes" do
      trip_type = create(:trip_type)
      destination = create(:destination)
      quote1 = create(:quote, trip_type: trip_type, destination_ids: [ destination.id ])
      quote2 = create(:quote, trip_type: trip_type, destination_ids: [ destination.id ])

      expect(trip_type.quotes).to include(quote1, quote2)
    end

    it "destroys associated quotes when trip_type is destroyed" do
      trip_type = create(:trip_type)
      destination = create(:destination)
      quote = create(:quote, trip_type: trip_type, destination_ids: [ destination.id ])

      expect { trip_type.destroy }.to change { Quote.count }.by(-1)
      expect(Quote.find_by(id: quote.id)).to be_nil
    end
  end
end
