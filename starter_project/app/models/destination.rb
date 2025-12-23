# typed: false
# frozen_string_literal: true

class Destination < ApplicationRecord
	has_many :quotes_to_destinations, class_name: 'QuotesToDestination'
	has_many :quotes, through: :quotes_to_destinations, source: :quote, join_table: :quotes_to_destinations, class_name: 'Quote'
end
