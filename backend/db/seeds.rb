# frozen_string_literal: true

# Seed appointment slots for the next 2 weeks (Mon-Fri, 9am-5pm, 30-min intervals)
service_types = %w[orientation hr_review it_setup]

(Date.tomorrow..Date.tomorrow + 14).each do |date|
  next if date.saturday? || date.sunday?

  service_types.each do |service_type|
    (9..16).each do |hour|
      [0, 30].each do |minute|
        start_time = format("%02d:%02d", hour, minute)
        end_time = minute == 30 ? format("%02d:%02d", hour + 1, 0) : format("%02d:%02d", hour, 30)

        AppointmentSlot.find_or_create_by!(
          date: date,
          start_time: start_time,
          end_time: end_time,
          service_type: service_type
        ) do |slot|
          slot.capacity = service_type == "orientation" ? 10 : 3
          slot.duration_minutes = 30
        end
      end
    end
  end
end

puts "Seeded #{AppointmentSlot.count} appointment slots"
