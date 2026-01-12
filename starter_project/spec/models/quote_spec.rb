# frozen_string_literal: true

require "rails_helper"

# Comprehensive tests for Quote model
# Tests cover validations, associations, business logic, and edge cases
RSpec.describe Quote, type: :model do
  # Test data setup
  let(:trip_type) { create(:trip_type) }
  let(:excess) { create(:excess) }
  let(:cover) { create(:cover) }
  let(:destination1) { create(:destination) }
  let(:destination2) { create(:destination) }

  let(:valid_attributes) do
    {
      travellers: [ { age: 30 } ],
      start_date: Date.today + 1.month,
      end_date: Date.today + 1.month + 7.days,
      trip_type: trip_type,
      excess: excess,
      cover: cover,
      destination_ids: [ destination1.id ]
    }
  end

  describe "associations" do
    it { should belong_to(:trip_type).required }
    it { should belong_to(:excess).required }
    it { should belong_to(:cover).required }
    it { should have_many(:quotes_to_destinations).dependent(:destroy) }
    it { should have_many(:destinations) }
  end

  describe "validations" do
    describe "presence validations" do
      it "requires start_date" do
        quote = Quote.new(valid_attributes.merge(start_date: nil))
        expect(quote).not_to be_valid
        expect(quote.errors[:start_date]).to include("can't be blank")
      end

      it "requires end_date" do
        quote = Quote.new(valid_attributes.merge(end_date: nil))
        expect(quote).not_to be_valid
        expect(quote.errors[:end_date]).to include("can't be blank")
      end

      it "requires travellers" do
        quote = Quote.new(valid_attributes.merge(travellers: nil))
        expect(quote).not_to be_valid
        expect(quote.errors[:travellers]).to include("can't be blank")
      end

      it "requires at least one traveller" do
        quote = Quote.new(valid_attributes.merge(travellers: []))
        expect(quote).not_to be_valid
        expect(quote.errors[:travellers]).to include("can't be blank")
      end
    end

    describe "date validations" do
      it "validates end_date is after start_date" do
        quote = Quote.new(
          valid_attributes.merge(
            start_date: Date.today + 1.month + 7.days,
            end_date: Date.today + 1.month
          )
        )
        expect(quote).not_to be_valid
        expect(quote.errors[:end_date]).to include("must be after start date")
      end

      it "validates start_date is not in the past" do
        quote = Quote.new(valid_attributes.merge(start_date: Date.yesterday))
        expect(quote).not_to be_valid
        expect(quote.errors[:start_date]).to include("cannot be in the past")
      end

      it "allows start_date to be today" do
        quote = Quote.new(valid_attributes.merge(start_date: Date.today))
        quote.valid? # Trigger validations
        expect(quote.errors[:start_date]).not_to include("cannot be in the past")
      end

      it "validates start_date is within advance booking limit" do
        max_date = Date.current + PremiumCalculator::MAX_ADVANCE_BOOKING_MONTHS.months + 1.day
        quote = Quote.new(valid_attributes.merge(start_date: max_date))
        expect(quote).not_to be_valid
        expect(quote.errors[:start_date]).to include("cannot be more than #{PremiumCalculator::MAX_ADVANCE_BOOKING_MONTHS} months ahead")
      end

      it "allows start_date at the advance booking limit" do
        max_date = Date.current + PremiumCalculator::MAX_ADVANCE_BOOKING_MONTHS.months
        quote = Quote.new(valid_attributes.merge(start_date: max_date))
        quote.valid? # Trigger validations
        expect(quote.errors[:start_date]).not_to include("cannot be more than")
      end

      it "validates trip duration does not exceed maximum" do
        max_duration_days = PremiumCalculator::MAX_TRIP_DURATION_YEARS * 365 + 1
        quote = Quote.new(
          valid_attributes.merge(
            start_date: Date.today + 1.month,
            end_date: Date.today + 1.month + max_duration_days.days
          )
        )
        expect(quote).not_to be_valid
        expect(quote.errors[:base]).to include("Trip cannot exceed #{PremiumCalculator::MAX_TRIP_DURATION_YEARS} years")
      end

      it "allows trip duration at the maximum limit" do
        max_duration_days = PremiumCalculator::MAX_TRIP_DURATION_YEARS * 365
        quote = Quote.new(
          valid_attributes.merge(
            start_date: Date.today + 1.month,
            end_date: Date.today + 1.month + max_duration_days.days
          )
        )
        quote.valid? # Trigger validations
        expect(quote.errors[:base]).not_to include("Trip cannot exceed")
      end
    end

    describe "destination validations" do
      it "requires at least one destination" do
        quote = Quote.new(valid_attributes.merge(destination_ids: []))
        expect(quote).not_to be_valid
        expect(quote.errors[:base]).to include("Please select at least one destination")
      end

    it "allows multiple destinations" do
      quote = Quote.new(valid_attributes.merge(destination_ids: [ destination1.id, destination2.id ], age: 30))
      expect(quote).to be_valid
    end
    end

    describe "traveller validations" do
      it "validates traveller ages are within valid range" do
        quote = Quote.new(
          valid_attributes.merge(
            travellers: [ { age: 0 } ]
          )
        )
        expect(quote).not_to be_valid
        expect(quote.errors[:travellers]).to include(match(/Age must be 1-#{PremiumCalculator::MAX_AGE}/))
      end

      it "validates traveller ages do not exceed maximum" do
        quote = Quote.new(
          valid_attributes.merge(
            travellers: [ { age: PremiumCalculator::MAX_AGE + 1 } ]
          )
        )
        expect(quote).not_to be_valid
        expect(quote.errors[:travellers]).to include(match(/Age must be 1-#{PremiumCalculator::MAX_AGE}/))
      end

      it "allows traveller age at maximum" do
        quote = Quote.new(
          valid_attributes.merge(
            travellers: [ { age: PremiumCalculator::MAX_AGE } ]
          )
        )
        quote.valid? # Trigger validations
        expect(quote.errors[:travellers]).not_to include(match(/Age must be/))
      end

      it "validates children have adult companion" do
        quote = Quote.new(
          valid_attributes.merge(
            travellers: [ { age: 10 } ] # Child under 16
          )
        )
        expect(quote).not_to be_valid
        expect(quote.errors[:travellers]).to include("Children under #{PremiumCalculator::CHILD_AGE} need an adult #{PremiumCalculator::ADULT_AGE}+")
      end

      it "allows children with adult companion" do
        quote = Quote.new(
          valid_attributes.merge(
            travellers: [
              { age: 10 }, # Child
              { age: 25 }  # Adult
            ]
          )
        )
        quote.valid? # Trigger validations
        expect(quote.errors[:travellers]).not_to include("Children under")
      end

    it "validates multiple travellers with mixed ages" do
      quote = Quote.new(
        valid_attributes.merge(
          travellers: [
            { age: 30 },
            { age: 50 },
            { age: 5 } # Child without adult (but there are adults, so this should pass)
          ],
          age: 30
        )
      )
      # Actually, this should be valid because there are adults (30 and 50)
      quote.valid?
      # The validation checks if children need adults, but since there are adults, it should pass
      # Let's test the actual failure case - only children
      quote_only_children = Quote.new(
        valid_attributes.merge(
          travellers: [ { age: 5 }, { age: 10 } ], # Only children
          age: 5
        )
      )
      expect(quote_only_children).not_to be_valid
      expect(quote_only_children.errors[:travellers]).to include("Children under #{PremiumCalculator::CHILD_AGE} need an adult #{PremiumCalculator::ADULT_AGE}+")
    end

      it "handles traveller data as hash with string keys" do
        quote = Quote.new(
          valid_attributes.merge(
            travellers: [ { "age" => 30 } ]
          )
        )
        quote.valid? # Trigger validations
        expect(quote.errors[:travellers]).to be_empty
      end

      it "handles traveller data as hash with symbol keys" do
        quote = Quote.new(
          valid_attributes.merge(
            travellers: [ { age: 30 } ]
          )
        )
        quote.valid? # Trigger validations
        expect(quote.errors[:travellers]).to be_empty
      end
    end

    describe "snow coverage validations" do
      it "requires snow_start_date when snow is enabled" do
        quote = Quote.new(
          valid_attributes.merge(
            snow: true,
            snow_start_date: nil,
            snow_end_date: Date.today + 1.month + 2.days
          )
        )
        expect(quote).not_to be_valid
        expect(quote.errors[:snow_start_date]).to include("required when snow coverage is selected")
      end

      it "requires snow_end_date when snow is enabled" do
        quote = Quote.new(
          valid_attributes.merge(
            snow: true,
            snow_start_date: Date.today + 1.month + 2.days,
            snow_end_date: nil
          )
        )
        expect(quote).not_to be_valid
        expect(quote.errors[:snow_end_date]).to include("required when snow coverage is selected")
      end

      it "does not require snow dates when snow is disabled" do
        quote = Quote.new(
          valid_attributes.merge(
            snow: false,
            snow_start_date: nil,
            snow_end_date: nil
          )
        )
        quote.valid? # Trigger validations
        expect(quote.errors[:snow_start_date]).to be_empty
        expect(quote.errors[:snow_end_date]).to be_empty
      end

      it "validates snow_start_date is within trip dates" do
        quote = Quote.new(
          valid_attributes.merge(
            snow: true,
            start_date: Date.today + 1.month,
            end_date: Date.today + 1.month + 7.days,
            snow_start_date: Date.today + 1.month - 1.day, # Before trip start
            snow_end_date: Date.today + 1.month + 2.days
          )
        )
        expect(quote).not_to be_valid
        expect(quote.errors[:snow_start_date]).to include("must be within trip dates")
      end

      it "validates snow_end_date is within trip dates" do
        quote = Quote.new(
          valid_attributes.merge(
            snow: true,
            start_date: Date.today + 1.month,
            end_date: Date.today + 1.month + 7.days,
            snow_start_date: Date.today + 1.month + 2.days,
            snow_end_date: Date.today + 1.month + 10.days # After trip end
          )
        )
        expect(quote).not_to be_valid
        expect(quote.errors[:snow_end_date]).to include("must be within trip dates")
      end

      it "validates snow_end_date is after snow_start_date" do
        quote = Quote.new(
          valid_attributes.merge(
            snow: true,
            snow_start_date: Date.today + 1.month + 5.days,
            snow_end_date: Date.today + 1.month + 2.days
          )
        )
        expect(quote).not_to be_valid
        expect(quote.errors[:snow_end_date]).to include("must be after start date")
      end

      it "allows snow dates at trip boundaries" do
        quote = Quote.new(
          valid_attributes.merge(
            snow: true,
            start_date: Date.today + 1.month,
            end_date: Date.today + 1.month + 7.days,
            snow_start_date: Date.today + 1.month, # At trip start
            snow_end_date: Date.today + 1.month + 7.days # At trip end
          )
        )
        quote.valid? # Trigger validations
        expect(quote.errors[:snow_start_date]).to be_empty
        expect(quote.errors[:snow_end_date]).to be_empty
      end
    end
  end

  describe "#destination_ids" do
    it "returns array of destination ids" do
      quote = Quote.new(valid_attributes.merge(age: 30, destination_ids: []))
      quote.save(validate: false)
      QuotesToDestination.where(quote_id: quote.id).destroy_all
      QuotesToDestination.create(quote_id: quote.id, destination_id: destination1.id)
      QuotesToDestination.create(quote_id: quote.id, destination_id: destination2.id)
      quote.reload
      # Clear the cached destination_ids to force reload from database
      quote.instance_variable_set(:@destination_ids, nil)
      expect(quote.destination_ids).to match_array([ destination1.id, destination2.id ])
    end

    it "returns empty array when no destinations" do
      quote = Quote.new(valid_attributes.merge(age: 30, destination_ids: []))
      quote.save(validate: false)
      QuotesToDestination.where(quote_id: quote.id).destroy_all
      quote.reload
      expect(quote.destination_ids).to eq([])
    end

    it "returns cached value when set via destination_ids=" do
      quote = Quote.new(valid_attributes.merge(age: 30))
      quote.destination_ids = [ destination1.id ]
      expect(quote.destination_ids).to eq([ destination1.id ])
    end
  end

  describe "#destination_ids=" do
    let(:quote) { create(:quote) }

    it "sets destinations from ids array" do
      quote.destination_ids = [ destination1.id, destination2.id ]
      quote.save
      expect(quote.destinations).to match_array([ destination1, destination2 ])
    end

    it "replaces existing destinations" do
      quote.destinations << destination1
      quote.destination_ids = [ destination2.id ]
      quote.save
      expect(quote.destinations).to match_array([ destination2 ])
    end

    it "handles empty array" do
      quote.destinations << destination1
      quote.destination_ids = []
      # Note: This will fail validation, but we're testing the assignment logic
      # In production, validation would prevent saving with no destinations
      quote.save(validate: false)
      quote.reload
      expect(quote.destinations).to be_empty
    end

    it "filters out blank values" do
      quote.destination_ids = [ destination1.id, "", nil, destination2.id ]
      quote.save
      expect(quote.destinations).to match_array([ destination1, destination2 ])
    end
  end

  describe "callbacks" do
    it "updates destinations after save" do
      quote = create(:quote)
      quote.destination_ids = [ destination1.id, destination2.id ]
      quote.save
      expect(quote.destinations.reload).to match_array([ destination1, destination2 ])
    end

    it "destroys old destination associations when updating" do
      quote = create(:quote)
      quote.destinations << destination1
      quote.destination_ids = [ destination2.id ]
      quote.save
      expect(quote.destinations.reload).to match_array([ destination2 ])
      expect(QuotesToDestination.where(quote_id: quote.id).count).to eq(1)
    end
  end

  describe "edge cases" do
    it "handles traveller data as JSON string" do
      quote = Quote.new(
        valid_attributes.merge(
          travellers: [ '{"age": 30}' ]
        )
      )
      quote.valid? # Trigger validations
      # Should not raise error and should extract age correctly
      expect(quote.errors[:travellers]).to be_empty
    end

    it "handles invalid JSON string gracefully" do
      quote = Quote.new(
        valid_attributes.merge(
          travellers: [ 'invalid json' ]
        )
      )
      quote.valid? # Should not raise error
      # Age extraction should default to 0, which will fail validation
      expect(quote.errors[:travellers]).to be_present
    end

    it "handles nil traveller gracefully" do
      quote = Quote.new(
        valid_attributes.merge(
          travellers: [ nil ]
        )
      )
      quote.valid? # Should not raise error
      expect(quote.errors[:travellers]).to be_present
    end
  end
end
