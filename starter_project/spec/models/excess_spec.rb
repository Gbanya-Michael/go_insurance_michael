# frozen_string_literal: true

require "rails_helper"

# Comprehensive tests for Excess model
# Tests cover validations, associations, and business logic
RSpec.describe Excess, type: :model do
  describe "validations" do
    it "requires label" do
      excess = Excess.new(value: 200, multiplier: 1.0)
      expect(excess).not_to be_valid
      expect(excess.errors[:label]).to include("can't be blank")
    end

    it "requires value" do
      excess = Excess.new(label: "$200", multiplier: 1.0)
      expect(excess).not_to be_valid
      expect(excess.errors[:value]).to include("can't be blank")
    end

    it "validates label uniqueness" do
      existing = create(:excess, label: "UNIQUE_LABEL_TEST")
      excess = Excess.new(label: "UNIQUE_LABEL_TEST", value: 200, multiplier: 1.0)
      expect(excess).not_to be_valid
      expect(excess.errors[:label]).to include("has already been taken")
    end

    it "validates value is greater than or equal to 0" do
      excess = Excess.new(label: "$200", value: -1, multiplier: 1.0)
      expect(excess).not_to be_valid
      expect(excess.errors[:value]).to include("must be greater than or equal to 0")
    end

    it "validates multiplier is greater than 0" do
      excess = Excess.new(label: "$200", value: 200, multiplier: 0)
      expect(excess).not_to be_valid
      expect(excess.errors[:multiplier]).to include("must be greater than 0")
    end

    it "allows nil multiplier" do
      excess = Excess.new(label: "NIL_MULT_TEST", value: 200, multiplier: nil)
      expect(excess).to be_valid
    end

    it "allows valid excess" do
      excess = Excess.new(label: "VALID_EXCESS_TEST", value: 200, multiplier: 1.0)
      expect(excess).to be_valid
    end
  end

  describe "associations" do
    it "has many quotes" do
      excess = create(:excess)
      quote1 = create(:quote, excess: excess)
      quote2 = create(:quote, excess: excess)

      expect(excess.quotes).to include(quote1, quote2)
    end

    it "destroys associated quotes when excess is destroyed" do
      excess = create(:excess)
      quote = create(:quote, excess: excess)

      expect { excess.destroy }.to change { Quote.count }.by(-1)
      expect(Quote.find_by(id: quote.id)).to be_nil
    end
  end
end
