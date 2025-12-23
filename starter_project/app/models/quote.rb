# typed: false
# frozen_string_literal: true

class Quote < ApplicationRecord
	belongs_to :trip_type, class_name: 'TripType', optional: false

	has_many :quotes_to_destinations, class_name: 'QuotesToDestination', dependent: :destroy
	has_many :destinations, through: :quotes_to_destinations, source: :destination, join_table: :quotes_to_destinations, class_name: 'Destination'

	belongs_to :excess, class_name: 'Excess', optional: false
	belongs_to :cover, class_name: 'Cover', optional: true

	# Virtual attribute for handling destination_ids in forms
	after_save :update_destinations

	def destination_ids
		return @destination_ids if defined?(@destination_ids) && @destination_ids
		destinations.pluck(:id)
	end

	def destination_ids=(ids)
		@destination_ids = ids.is_a?(Array) ? ids.reject(&:blank?) : ids
	end

	private

	def update_destinations
		return unless @destination_ids

		quotes_to_destinations.destroy_all
		@destination_ids.each do |destination_id|
			quotes_to_destinations.create(destination_id: destination_id)
		end
	end
end
