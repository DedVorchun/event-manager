class Event < ApplicationRecord
  include DateValidators
  include ActiveModel::Validations

  belongs_to :room
  belongs_to :user
  belongs_to :organizer
  belongs_to :lector

  # проверка на присутствие
  validates :title,  :date, :begin_time, :end_time, :user_id, :organizer_id, :lector_id, :room_id, presence: true
  # проверка на integer и not_null
  validates :user_id, :organizer_id, :lector_id, :room_id, numericality: { only_integer: true }

  validates_with EventValidator

end
