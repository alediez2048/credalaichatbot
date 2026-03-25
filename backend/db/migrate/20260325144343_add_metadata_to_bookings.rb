class AddMetadataToBookings < ActiveRecord::Migration[7.2]
  def change
    add_column :bookings, :metadata, :jsonb
  end
end
