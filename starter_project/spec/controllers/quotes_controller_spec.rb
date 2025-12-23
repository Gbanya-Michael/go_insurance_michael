# frozen_string_literal: true

require 'rails_helper'

RSpec.describe QuotesController, type: :controller do
  describe 'GET #new' do
    it 'returns http success' do
      get :new
      expect(response).to have_http_status(:success)
    end

    it 'assigns @quote' do
      get :new
      expect(assigns(:quote)).to be_a_new(Quote)
    end

    it 'assigns @trip_types' do
      get :new
      expect(assigns(:trip_types)).to eq(TripType.all)
    end

    it 'assigns @excesses' do
      get :new
      expect(assigns(:excesses)).to eq(Excess.all)
    end

    it 'assigns @destinations' do
      get :new
      expect(assigns(:destinations)).to eq(Destination.all.order(:label))
    end
  end

  describe 'POST #create' do
    let(:trip_type) { TripType.first || create(:trip_type) }
    let(:excess) { Excess.first || create(:excess) }
    let(:destination) { Destination.first || create(:destination) }
    let(:cover) { Cover.first || create(:cover) }
    
    before do
      # Ensure a cover exists for the controller's default cover logic
      cover
    end

    context 'with valid parameters' do
      let(:valid_attributes) do
        {
          quote: {
            travellers: [{ age: 30 }],
            start_date: (Date.today + 1.month).to_s,
            end_date: (Date.today + 1.month + 7.days).to_s,
            destination_ids: [destination.id],
            trip_type_id: trip_type.id,
            excess_id: excess.id
          }
        }
      end

      it 'creates a new quote' do
        expect {
          post :create, params: valid_attributes
        }.to change(Quote, :count).by(1)
      end

      it 'redirects to the quote show page' do
        post :create, params: valid_attributes
        expect(response).to redirect_to(quote_path(Quote.last))
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) do
        {
          quote: {
            travellers: [],
            start_date: nil,
            end_date: nil,
            destination_ids: [],
            trip_type_id: nil,
            excess_id: nil
          }
        }
      end

      it 'does not create a new quote' do
        expect {
          post :create, params: invalid_attributes
        }.not_to change(Quote, :count)
      end

      it 'renders the new template' do
        post :create, params: invalid_attributes
        expect(response).to render_template(:new)
      end
    end

    context 'with child traveller without adult' do
      let(:invalid_attributes) do
        {
          quote: {
            travellers: [{ age: 10 }],
            start_date: (Date.today + 1.month).to_s,
            end_date: (Date.today + 1.month + 7.days).to_s,
            destination_ids: [destination.id],
            trip_type_id: trip_type.id,
            excess_id: excess.id
          }
        }
      end

      it 'does not create a quote' do
        expect {
          post :create, params: invalid_attributes
        }.not_to change(Quote, :count)
      end
    end
  end

  describe 'GET #show' do
    let(:quote) { create(:quote) }

    it 'returns http success' do
      get :show, params: { id: quote.id }
      expect(response).to have_http_status(:success)
    end

    it 'assigns @quote' do
      get :show, params: { id: quote.id }
      expect(assigns(:quote)).to eq(quote)
    end

    it 'assigns @premiums' do
      get :show, params: { id: quote.id }
      expect(assigns(:premiums)).to be_a(Hash)
    end
  end
end



