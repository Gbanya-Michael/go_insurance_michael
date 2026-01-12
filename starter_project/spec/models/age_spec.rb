# frozen_string_literal: true

require "rails_helper"

# Comprehensive tests for Age model
# Tests cover validations, business logic, and edge cases
RSpec.describe Age, type: :model do
  describe "validations" do
    describe "presence validations" do
      it "requires age_minimum" do
        age = Age.new(age_maximum: 30, multiplier: 1.0)
        expect(age).not_to be_valid
        expect(age.errors[:age_minimum]).to include("can't be blank")
      end

      it "requires age_maximum" do
        age = Age.new(age_minimum: 0, multiplier: 1.0)
        expect(age).not_to be_valid
        expect(age.errors[:age_maximum]).to include("can't be blank")
      end

      it "requires multiplier" do
        age = Age.new(age_minimum: 0, age_maximum: 30)
        expect(age).not_to be_valid
        expect(age.errors[:multiplier]).to include("can't be blank")
      end
    end

    describe "numericality validations" do
      it "validates age_minimum is an integer" do
        age = Age.new(age_minimum: 1.5, age_maximum: 30, multiplier: 1.0)
        expect(age).not_to be_valid
        expect(age.errors[:age_minimum]).to include("must be an integer")
      end

      it "validates age_maximum is an integer" do
        age = Age.new(age_minimum: 0, age_maximum: 30.5, multiplier: 1.0)
        expect(age).not_to be_valid
        expect(age.errors[:age_maximum]).to include("must be an integer")
      end

      it "validates age_minimum is greater than or equal to 0" do
        age = Age.new(age_minimum: -1, age_maximum: 30, multiplier: 1.0)
        expect(age).not_to be_valid
        expect(age.errors[:age_minimum]).to include("must be greater than or equal to 0")
      end

      it "validates age_maximum is greater than or equal to 0" do
        age = Age.new(age_minimum: 0, age_maximum: -1, multiplier: 1.0)
        expect(age).not_to be_valid
        expect(age.errors[:age_maximum]).to include("must be greater than or equal to 0")
      end

      it "validates multiplier is greater than 0" do
        age = Age.new(age_minimum: 0, age_maximum: 30, multiplier: 0)
        expect(age).not_to be_valid
        expect(age.errors[:multiplier]).to include("must be greater than 0")
      end

      it "validates multiplier is greater than 0 (negative)" do
        age = Age.new(age_minimum: 0, age_maximum: 30, multiplier: -1)
        expect(age).not_to be_valid
        expect(age.errors[:multiplier]).to include("must be greater than 0")
      end
    end

    describe "custom validations" do
      it "validates age_maximum is at least age_minimum" do
        age = Age.new(age_minimum: 30, age_maximum: 15, multiplier: 1.0)
        expect(age).not_to be_valid
        expect(age.errors[:age_maximum]).to include("must be at least 30 (currently 15)")
        expect(age.errors[:age_minimum]).to include("must be at most 15 (currently 30)")
      end

      it "allows age_maximum equal to age_minimum" do
        age = Age.new(age_minimum: 25, age_maximum: 25, multiplier: 1.0)
        expect(age).to be_valid
      end

      it "allows valid age range" do
        age = Age.new(age_minimum: 0, age_maximum: 17, multiplier: 1.5)
        expect(age).to be_valid
      end
    end
  end

  describe "edge cases" do
    it "handles zero values correctly" do
      age = Age.new(age_minimum: 0, age_maximum: 0, multiplier: 1.0)
      expect(age).to be_valid
    end

    it "handles large age values" do
      age = Age.new(age_minimum: 80, age_maximum: 84, multiplier: 2.0)
      expect(age).to be_valid
    end

    it "handles decimal multipliers" do
      age = Age.new(age_minimum: 0, age_maximum: 30, multiplier: 1.25)
      expect(age).to be_valid
    end
  end
end
