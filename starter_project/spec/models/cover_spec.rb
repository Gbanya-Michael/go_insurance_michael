# frozen_string_literal: true

require "rails_helper"

# Comprehensive tests for Cover model
# Tests cover validations, associations, and business logic
RSpec.describe Cover, type: :model do
  describe "validations" do
    it "requires cover_type" do
      cover = Cover.new(label: "Basic", multiplier: 1.0)
      expect(cover).not_to be_valid
      expect(cover.errors[:cover_type]).to include("can't be blank")
    end

    it "requires label" do
      cover = Cover.new(cover_type: "basic", multiplier: 1.0)
      expect(cover).not_to be_valid
      expect(cover.errors[:label]).to include("can't be blank")
    end

    it "validates cover_type uniqueness" do
      create(:cover, cover_type: "basic")
      cover = Cover.new(cover_type: "basic", label: "Another Basic", multiplier: 1.0)
      expect(cover).not_to be_valid
      expect(cover.errors[:cover_type]).to include("has already been taken")
    end

    it "validates multiplier is greater than 0" do
      cover = Cover.new(cover_type: "basic", label: "Basic", multiplier: 0)
      expect(cover).not_to be_valid
      expect(cover.errors[:multiplier]).to include("must be greater than 0")
    end

    it "allows nil multiplier" do
      cover = Cover.new(cover_type: "basic", label: "Basic", multiplier: nil)
      expect(cover).to be_valid
    end

    it "allows valid cover" do
      cover = Cover.new(cover_type: "basic", label: "Basic", multiplier: 1.0)
      expect(cover).to be_valid
    end
  end

  describe "associations" do
    it "has many quotes" do
      cover = create(:cover)
      quote1 = create(:quote, cover: cover)
      quote2 = create(:quote, cover: cover)

      expect(cover.quotes).to include(quote1, quote2)
    end

    it "destroys associated quotes when cover is destroyed" do
      cover = create(:cover)
      quote = create(:quote, cover: cover)

      expect { cover.destroy }.to change { Quote.count }.by(-1)
      expect(Quote.find_by(id: quote.id)).to be_nil
    end
  end
end
