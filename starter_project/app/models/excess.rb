# typed: false
# frozen_string_literal: true

class Excess < ApplicationRecord
	has_many :quotes, class_name: 'Quote', dependent: :destroy, foreign_key: :id
end
