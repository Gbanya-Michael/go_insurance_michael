# typed: false
# frozen_string_literal: true

class QuotesToDestination < ApplicationRecord
  # Associations with presence validation (optional: false validates foreign key presence)
  belongs_to :quote, class_name: "Quote", optional: false
  belongs_to :destination, class_name: "Destination", optional: false

  # Note: quote_id and destination_id are validated by belongs_to associations
  validates :destination_id, uniqueness: { scope: :quote_id, message: "has already been added to this quote" }
end
