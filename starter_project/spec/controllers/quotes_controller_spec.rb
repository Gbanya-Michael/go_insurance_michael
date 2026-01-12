# frozen_string_literal: true

require "rails_helper"

# Comprehensive tests for QuotesController
# Tests cover all actions, edge cases, error handling, and business logic
RSpec.describe QuotesController, type: :controller do
  # Test data setup
  let(:trip_type) { create(:trip_type) }
  let(:excess) { create(:excess) }
  let(:cover) { create(:cover) }
  let(:destination) { create(:destination) }

  describe "GET #new" do
    it "returns http success" do
      get :new
      expect(response).to have_http_status(:success)
    end

    it "renders the new template" do
      get :new
      expect(response).to render_template(:new)
    end

    it "assigns a new quote" do
      get :new
      expect(assigns(:quote)).to be_a_new(Quote)
    end

    it "assigns all trip types" do
      # Clear existing data to avoid conflicts
      TripType.destroy_all
      trip_type1 = create(:trip_type)
      trip_type2 = create(:trip_type)
      get :new
      expect(assigns(:trip_types).to_a).to match_array([ trip_type1, trip_type2 ])
    end

    it "assigns all excesses" do
      # Clear existing data to avoid conflicts
      Excess.destroy_all
      excess1 = create(:excess)
      excess2 = create(:excess)
      get :new
      expect(assigns(:excesses).to_a).to match_array([ excess1, excess2 ])
    end

    it "assigns destinations ordered by label" do
      # Clear existing data to avoid conflicts
      Destination.destroy_all
      destination1 = create(:destination, label: "Zebra")
      destination2 = create(:destination, label: "Alpha")
      get :new
      expect(assigns(:destinations).to_a).to eq([ destination2, destination1 ])
    end
  end

  describe "POST #create" do
    let(:valid_attributes) do
      {
        quote: {
          travellers: [ { age: 30 } ],
          start_date: (Date.today + 1.month).to_s,
          end_date: (Date.today + 1.month + 7.days).to_s,
          destination_ids: [ destination.id ],
          trip_type_id: trip_type.id,
          excess_id: excess.id
        }
      }
    end

    before do
      # Ensure a cover exists for the controller's default cover logic
      cover
    end

    context "with valid parameters" do
      it "creates a new quote" do
        expect {
          post :create, params: valid_attributes
        }.to change(Quote, :count).by(1)
      end

      it "redirects to the quote show page" do
        post :create, params: valid_attributes
        expect(response).to redirect_to(quote_path(Quote.last))
      end

      it "assigns the correct attributes" do
        post :create, params: valid_attributes
        quote = Quote.last
        expect(quote.travellers).to eq([ { "age" => 30 } ])
        expect(quote.start_date).to eq(Date.today + 1.month)
        expect(quote.end_date).to eq(Date.today + 1.month + 7.days)
        expect(quote.trip_type).to eq(trip_type)
        expect(quote.excess).to eq(excess)
      end

      it "associates destinations correctly" do
        destination2 = create(:destination)
        attributes = valid_attributes.deep_merge(
          quote: { destination_ids: [ destination.id, destination2.id ] }
        )
        post :create, params: attributes
        quote = Quote.last
        expect(quote.destinations).to match_array([ destination, destination2 ])
      end

      it "handles multiple travellers" do
        attributes = valid_attributes.deep_merge(
          quote: {
            travellers: [
              { age: 30 },
              { age: 25 },
              { age: 50 }
            ]
          }
        )
        post :create, params: attributes
        quote = Quote.last
        expect(quote.travellers.length).to eq(3)
      end

      it "sets default cover when not provided" do
        post :create, params: valid_attributes
        quote = Quote.last
        expect(quote.cover).to eq(cover)
      end
    end

    context "with invalid parameters" do
      it "does not create a new quote with missing travellers" do
        attributes = valid_attributes.deep_merge(quote: { travellers: [] })
        expect {
          post :create, params: attributes
        }.not_to change(Quote, :count)
      end

      it "does not create a new quote with missing dates" do
        attributes = valid_attributes.deep_merge(
          quote: { start_date: nil, end_date: nil }
        )
        expect {
          post :create, params: attributes
        }.not_to change(Quote, :count)
      end

      it "does not create a new quote with missing destinations" do
        attributes = valid_attributes.deep_merge(quote: { destination_ids: [] })
        expect {
          post :create, params: attributes
        }.not_to change(Quote, :count)
      end

      it "does not create a new quote with missing trip_type_id" do
        attributes = valid_attributes.deep_merge(quote: { trip_type_id: nil })
        expect {
          post :create, params: attributes
        }.not_to change(Quote, :count)
      end

      it "does not create a new quote with missing excess_id" do
        attributes = valid_attributes.deep_merge(quote: { excess_id: nil })
        expect {
          post :create, params: attributes
        }.not_to change(Quote, :count)
      end

      it "renders the new template on validation failure" do
        attributes = valid_attributes.deep_merge(quote: { travellers: [] })
        post :create, params: attributes
        expect(response).to render_template(:new)
      end

      it "assigns errors to @quote on validation failure" do
        attributes = valid_attributes.deep_merge(quote: { travellers: [] })
        post :create, params: attributes
        expect(assigns(:quote).errors).not_to be_empty
      end

      it "preserves form data on validation failure" do
        attributes = valid_attributes.deep_merge(quote: { travellers: [] })
        post :create, params: attributes
        quote = assigns(:quote)
        # The controller sets start_date from params, check it's preserved
        expect(quote.start_date.to_s).to eq((Date.today + 1.month).to_s)
        # Check that trip_type_id and excess_id are preserved
        expect(quote.trip_type_id).to eq(trip_type.id)
        expect(quote.excess_id).to eq(excess.id)
      end
    end

    context "with business rule violations" do
      it "does not create a quote with child traveller without adult" do
        attributes = valid_attributes.deep_merge(
          quote: { travellers: [ { age: 10 } ] }
        )
        expect {
          post :create, params: attributes
        }.not_to change(Quote, :count)
      end

      it "does not create a quote with past start date" do
        attributes = valid_attributes.deep_merge(
          quote: { start_date: Date.yesterday.to_s }
        )
        expect {
          post :create, params: attributes
        }.not_to change(Quote, :count)
      end

      it "does not create a quote with end_date before start_date" do
        attributes = valid_attributes.deep_merge(
          quote: {
            start_date: (Date.today + 1.month + 7.days).to_s,
            end_date: (Date.today + 1.month).to_s
          }
        )
        expect {
          post :create, params: attributes
        }.not_to change(Quote, :count)
      end

      it "does not create a quote exceeding advance booking limit" do
        max_date = Date.current + PremiumCalculator::MAX_ADVANCE_BOOKING_MONTHS.months + 1.day
        attributes = valid_attributes.deep_merge(
          quote: { start_date: max_date.to_s }
        )
        expect {
          post :create, params: attributes
        }.not_to change(Quote, :count)
      end

      it "does not create a quote exceeding trip duration limit" do
        max_duration = PremiumCalculator::MAX_TRIP_DURATION_YEARS * 365 + 1
        attributes = valid_attributes.deep_merge(
          quote: {
            end_date: (Date.today + 1.month + max_duration.days).to_s
          }
        )
        expect {
          post :create, params: attributes
        }.not_to change(Quote, :count)
      end

      it "does not create a quote with traveller age exceeding maximum" do
        attributes = valid_attributes.deep_merge(
          quote: { travellers: [ { age: PremiumCalculator::MAX_AGE + 1 } ] }
        )
        expect {
          post :create, params: attributes
        }.not_to change(Quote, :count)
      end
    end

    context "with snow coverage" do
      it "creates quote with valid snow dates" do
        attributes = valid_attributes.deep_merge(
          quote: {
            snow: true,
            snow_start_date: (Date.today + 1.month + 2.days).to_s,
            snow_end_date: (Date.today + 1.month + 5.days).to_s
          }
        )
        expect {
          post :create, params: attributes
        }.to change(Quote, :count).by(1)
        quote = Quote.last
        expect(quote.snow).to be true
      end

      it "does not create quote with snow enabled but missing dates" do
        attributes = valid_attributes.deep_merge(
          quote: {
            snow: true,
            snow_start_date: nil,
            snow_end_date: nil
          }
        )
        expect {
          post :create, params: attributes
        }.not_to change(Quote, :count)
      end

      it "does not create quote with snow dates outside trip range" do
        attributes = valid_attributes.deep_merge(
          quote: {
            snow: true,
            snow_start_date: (Date.today + 1.month - 1.day).to_s,
            snow_end_date: (Date.today + 1.month + 5.days).to_s
          }
        )
        expect {
          post :create, params: attributes
        }.not_to change(Quote, :count)
      end
    end
  end

  describe "GET #show" do
    let(:quote) do
      create(:quote,
             travellers: [ { age: 30 } ],
             start_date: Date.today + 1.month,
             end_date: Date.today + 1.month + 7.days,
             trip_type: trip_type,
             excess: excess,
             cover: cover)
    end

    before do
      quote.destinations << destination
    end

    it "returns http success" do
      get :show, params: { id: quote.id }
      expect(response).to have_http_status(:success)
    end

    it "returns 404 when quote does not exist" do
      allow(Rails.logger).to receive(:warn)
      get :show, params: { id: 99999 }
      expect(response).to have_http_status(:not_found)
      expect(response).to render_template("errors/not_found")
    end

    it "logs the error when quote does not exist" do
      allow(Rails.logger).to receive(:warn)
      get :show, params: { id: 99999 }
      expect(Rails.logger).to have_received(:warn).with(
        /Quote not found: ID 99999/
      )
    end

    it "renders the show template" do
      get :show, params: { id: quote.id }
      expect(response).to render_template(:show)
    end

    it "assigns the requested quote" do
      get :show, params: { id: quote.id }
      expect(assigns(:quote)).to eq(quote)
    end

    it "assigns premiums hash" do
      get :show, params: { id: quote.id }
      expect(assigns(:premiums)).to be_a(Hash)
    end

    it "calculates premiums for all covers" do
      # Ensure we have the required data for premium calculation
      Premium.find_or_create_by!(premium_type: "base") do |p|
        p.label = "Base Premium"
        p.multiplier = 1.92
      end
      Age.find_or_create_by!(age_minimum: 18, age_maximum: 30) do |a|
        a.multiplier = 1.0
      end
      Duration.find_or_create_by!(minimum_days: 1, maximum_days: 7) do |d|
        d.multiplier = 1.0
      end

      cover1 = create(:cover, cover_type: "basic")
      cover2 = create(:cover, cover_type: "plus")
      get :show, params: { id: quote.id }
      premiums = assigns(:premiums)
      expect(premiums.keys).to include(cover1.id, cover2.id)
    end

    it "assigns covers" do
      get :show, params: { id: quote.id }
      expect(assigns(:covers)).to be_a(ActiveRecord::Relation)
    end

    it "assigns highest zone destination" do
      destination_zone_3 = create(:destination, zone: 3)
      quote.destinations << destination_zone_3
      get :show, params: { id: quote.id }
      expect(assigns(:highest_zone_destination).zone).to eq(3)
    end

    it "handles quote with no destinations gracefully" do
      quote_without_dest = create(:quote, trip_type: trip_type, excess: excess, cover: cover)
      get :show, params: { id: quote_without_dest.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH #update" do
    let(:quote) do
      create(:quote,
             travellers: [ { age: 30 } ],
             start_date: Date.today + 1.month,
             end_date: Date.today + 1.month + 7.days,
             trip_type: trip_type,
             excess: excess,
             cover: cover,
             cruise: false,
             snow: false)
    end

    before do
      quote.destinations << destination
    end

    it "returns 404 when quote does not exist" do
      allow(Rails.logger).to receive(:warn)
      patch :update, params: { id: 99999, quote: { cruise: true } }
      expect(response).to have_http_status(:not_found)
      expect(response).to render_template("errors/not_found")
    end

    context "with valid parameters" do
      it "updates quote attributes" do
        patch :update, params: {
          id: quote.id,
          quote: {
            cruise: true,
            snow: true,
            snow_start_date: (Date.today + 1.month + 2.days).to_s,
            snow_end_date: (Date.today + 1.month + 5.days).to_s,
            cover_id: cover.id
          }
        }
        quote.reload
        expect(quote.cruise).to be true
        expect(quote.snow).to be true
      end

      it "updates cover selection" do
        new_cover = create(:cover, cover_type: "plus")
        patch :update, params: {
          id: quote.id,
          quote: { cover_id: new_cover.id }
        }
        quote.reload
        expect(quote.cover).to eq(new_cover)
      end

      it "redirects to the quote show page" do
        patch :update, params: {
          id: quote.id,
          quote: { cruise: true }
        }
        expect(response).to redirect_to(quote_path(quote))
      end
    end

    context "with invalid parameters" do
      it "does not update with invalid snow dates" do
        patch :update, params: {
          id: quote.id,
          quote: {
            snow: true,
            snow_start_date: nil,
            snow_end_date: nil
          }
        }
        quote.reload
        expect(quote.snow).to be false
      end

      it "renders show template on validation failure" do
        patch :update, params: {
          id: quote.id,
          quote: {
            snow: true,
            snow_start_date: nil
          }
        }
        expect(response).to render_template(:show)
      end
    end
  end
end
