# typed: false
# frozen_string_literal: true

class Cover < ApplicationRecord
	has_many :quotes, class_name: 'Quote', dependent: :destroy, foreign_key: :id
end
