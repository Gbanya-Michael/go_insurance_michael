# typed: false
# frozen_string_literal: true

class Quote < ApplicationRecord
	belongs_to :trip_type, class_name: 'TripType', optional: false

	has_many :quotes_to_destinations, class_name: 'QuotesToDestination'
	has_many :destinations, through: :quotes_to_destinations, source: :destination, join_table: :quotes_to_destinations, class_name: 'Destination'

	belongs_to :excess, class_name: 'Excess', optional: false
	belongs_to :cover, class_name: 'Cover', optional: true
end
