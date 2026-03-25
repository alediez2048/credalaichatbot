# frozen_string_literal: true

class AppointmentSlot < ApplicationRecord
  has_many :bookings, dependent: :nullify

  validates :date, :start_time, :end_time, :service_type, :capacity, presence: true
  validates :capacity, numericality: { greater_than: 0 }
  validate :start_before_end

  scope :available, -> { where(status: "available").where("booked_count < capacity") }
  scope :future, -> { where("date > ? OR (date = ? AND start_time > ?)", Date.current, Date.current, Time.current.strftime("%H:%M")) }
  scope :for_service, ->(type) { where(service_type: type) if type.present? }
  scope :in_date_range, ->(from, to) { where(date: from..to) if from && to }

  def full?
    booked_count >= capacity
  end

  private

  def start_before_end
    return unless start_time && end_time
    errors.add(:end_time, "must be after start time") if end_time <= start_time
  end
end
