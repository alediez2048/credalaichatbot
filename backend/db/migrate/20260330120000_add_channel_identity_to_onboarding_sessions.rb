# frozen_string_literal: true

class AddChannelIdentityToOnboardingSessions < ActiveRecord::Migration[7.2]
  def change
    add_column :onboarding_sessions, :channel_type, :string
    add_column :onboarding_sessions, :channel_user_id, :string

    add_index :onboarding_sessions, %i[channel_type channel_user_id],
      unique: true,
      name: "index_onboarding_sessions_on_channel_identity",
      where: "channel_type IS NOT NULL AND channel_user_id IS NOT NULL"
  end
end
