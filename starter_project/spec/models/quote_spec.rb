# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Quote, type: :model do
  describe 'associations' do
    it { should belong_to(:trip_type) }
    it { should belong_to(:excess) }
    it { should belong_to(:cover).optional }
    it { should have_many(:quotes_to_destinations).dependent(:destroy) }
    it { should have_many(:destinations) }
  end

  describe '#destination_ids' do
    let(:quote) { create(:quote) }
    let(:destination1) { create(:destination) }
    let(:destination2) { create(:destination) }

    it 'returns array of destination ids' do
      quote.destinations << [destination1, destination2]
      expect(quote.destination_ids).to match_array([destination1.id, destination2.id])
    end
  end

  describe '#destination_ids=' do
    let(:quote) { create(:quote) }
    let(:destination1) { create(:destination) }
    let(:destination2) { create(:destination) }

    it 'sets destinations from ids array' do
      quote.destination_ids = [destination1.id, destination2.id]
      quote.save
      expect(quote.destinations).to match_array([destination1, destination2])
    end
  end
end



