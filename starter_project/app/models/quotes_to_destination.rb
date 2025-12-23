# typed: false
# frozen_string_literal: true

class QuotesToDestination < ApplicationRecord
	belongs_to :quote, class_name: 'Quote', optional: false
	belongs_to :destination, class_name: 'Destination', optional: false
end
