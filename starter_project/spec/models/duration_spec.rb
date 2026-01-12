# frozen_string_literal: true

require "rails_helper"

# Comprehensive tests for Duration model
# Tests cover validations, business logic, and edge cases
RSpec.describe Duration, type: :model do
  describe "validations" do
    describe "presence validations" do
      it "requires minimum_days" do
        duration = Duration.new(maximum_days: 30, multiplier: 1.0)
        expect(duration).not_to be_valid
        expect(duration.errors[:minimum_days]).to include("can't be blank")
      end

      it "requires maximum_days" do
        duration = Duration.new(minimum_days: 1, multiplier: 1.0)
        expect(duration).not_to be_valid
        expect(duration.errors[:maximum_days]).to include("can't be blank")
      end

      it "requires multiplier" do
        duration = Duration.new(minimum_days: 1, maximum_days: 30)
        expect(duration).not_to be_valid
        expect(duration.errors[:multiplier]).to include("can't be blank")
      end
    end

    describe "numericality validations" do
      it "validates minimum_days is an integer" do
        duration = Duration.new(minimum_days: 1.5, maximum_days: 30, multiplier: 1.0)
        expect(duration).not_to be_valid
        expect(duration.errors[:minimum_days]).to include("must be an integer")
      end

      it "validates maximum_days is an integer" do
        duration = Duration.new(minimum_days: 1, maximum_days: 30.5, multiplier: 1.0)
        expect(duration).not_to be_valid
        expect(duration.errors[:maximum_days]).to include("must be an integer")
      end

      it "validates minimum_days is greater than 0" do
        duration = Duration.new(minimum_days: 0, maximum_days: 30, multiplier: 1.0)
        expect(duration).not_to be_valid
        expect(duration.errors[:minimum_days]).to include("must be greater than 0")
      end

      it "validates maximum_days is greater than 0" do
        duration = Duration.new(minimum_days: 1, maximum_days: 0, multiplier: 1.0)
        expect(duration).not_to be_valid
        expect(duration.errors[:maximum_days]).to include("must be greater than 0")
      end

      it "validates multiplier is greater than 0" do
        duration = Duration.new(minimum_days: 1, maximum_days: 30, multiplier: 0)
        expect(duration).not_to be_valid
        expect(duration.errors[:multiplier]).to include("must be greater than 0")
      end
    end

    describe "custom validations" do
      it "validates maximum_days is at least minimum_days" do
        duration = Duration.new(minimum_days: 30, maximum_days: 7, multiplier: 1.0)
        expect(duration).not_to be_valid
        expect(duration.errors[:maximum_days]).to be_present
        expect(duration.errors[:minimum_days]).to be_present
        # Check that error messages contain the key information
        expect(duration.errors[:maximum_days].first).to include("30")
        expect(duration.errors[:minimum_days].first).to include("7")
      end

      it "allows maximum_days equal to minimum_days" do
        duration = Duration.new(minimum_days: 7, maximum_days: 7, multiplier: 1.0)
        expect(duration).to be_valid
      end

      it "allows valid duration range" do
        duration = Duration.new(minimum_days: 1, maximum_days: 7, multiplier: 1.0)
        expect(duration).to be_valid
      end
    end
  end

  describe "edge cases" do
    it "handles single day duration" do
      duration = Duration.new(minimum_days: 1, maximum_days: 1, multiplier: 1.0)
      expect(duration).to be_valid
    end

    it "handles long duration ranges" do
      duration = Duration.new(minimum_days: 1, maximum_days: 730, multiplier: 2.0)
      expect(duration).to be_valid
    end

    it "handles decimal multipliers" do
      duration = Duration.new(minimum_days: 1, maximum_days: 30, multiplier: 1.25)
      expect(duration).to be_valid
    end
  end
end
