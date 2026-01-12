# frozen_string_literal: true

require "rails_helper"

# Comprehensive tests for Destination model
# Tests cover validations, associations, and business logic
RSpec.describe Destination, type: :model do
  describe "validations" do
    it "requires code" do
      destination = Destination.new(label: "Test", zone: 1, multiplier: 1.4)
      expect(destination).not_to be_valid
      expect(destination.errors[:code]).to include("can't be blank")
    end

    it "requires label" do
      destination = Destination.new(code: "TEST", zone: 1, multiplier: 1.4)
      expect(destination).not_to be_valid
      expect(destination.errors[:label]).to include("can't be blank")
    end

    it "requires zone" do
      destination = Destination.new(code: "TEST", label: "Test", multiplier: 1.4)
      expect(destination).not_to be_valid
      expect(destination.errors[:zone]).to include("can't be blank")
    end

    it "requires multiplier" do
      destination = Destination.new(code: "TEST", label: "Test", zone: 1)
      expect(destination).not_to be_valid
      expect(destination.errors[:multiplier]).to include("can't be blank")
    end

    it "validates code uniqueness" do
      create(:destination, code: "UNIQUE_TEST")
      destination = Destination.new(code: "UNIQUE_TEST", label: "Another Test", zone: 1, multiplier: 1.4)
      expect(destination).not_to be_valid
      expect(destination.errors[:code]).to include("has already been taken")
    end

    it "validates zone is an integer" do
      destination = Destination.new(code: "TEST", label: "Test", zone: 1.5, multiplier: 1.4)
      expect(destination).not_to be_valid
      expect(destination.errors[:zone]).to include("must be an integer")
    end

    it "validates zone is greater than 0" do
      destination = Destination.new(code: "TEST", label: "Test", zone: 0, multiplier: 1.4)
      expect(destination).not_to be_valid
      expect(destination.errors[:zone]).to include("must be greater than 0")
    end

    it "validates multiplier is greater than 0" do
      destination = Destination.new(code: "TEST", label: "Test", zone: 1, multiplier: 0)
      expect(destination).not_to be_valid
      expect(destination.errors[:multiplier]).to include("must be greater than 0")
    end

    it "validates cruise_add_on_amount is greater than or equal to 0" do
      destination = Destination.new(code: "TEST", label: "Test", zone: 1, multiplier: 1.4, cruise_add_on_amount: -1)
      expect(destination).not_to be_valid
      expect(destination.errors[:cruise_add_on_amount]).to include("must be greater than or equal to 0")
    end

    it "validates ski_per_day_amount is greater than or equal to 0" do
      destination = Destination.new(code: "TEST", label: "Test", zone: 1, multiplier: 1.4, ski_per_day_amount: -1)
      expect(destination).not_to be_valid
      expect(destination.errors[:ski_per_day_amount]).to include("must be greater than or equal to 0")
    end

    it "allows valid destination" do
      destination = Destination.new(code: "VALID_TEST", label: "Test", zone: 1, multiplier: 1.4, cruise_add_on_amount: 25.0, ski_per_day_amount: 30.0)
      expect(destination).to be_valid
    end
  end

  describe "associations" do
    it "has many quotes_to_destinations" do
      destination = create(:destination)
      quote = create(:quote)
      QuotesToDestination.create(quote: quote, destination: destination)

      expect(destination.quotes_to_destinations.count).to eq(1)
    end

    it "has many quotes through quotes_to_destinations" do
      destination = create(:destination)
      quote1 = create(:quote)
      quote2 = create(:quote)
      QuotesToDestination.create(quote: quote1, destination: destination)
      QuotesToDestination.create(quote: quote2, destination: destination)

      expect(destination.quotes).to include(quote1, quote2)
    end
  end
end
