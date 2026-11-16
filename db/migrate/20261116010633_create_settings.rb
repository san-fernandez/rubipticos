# frozen_string_literal: true

# Configuración general del sitio. Tiene una sola fila (Setting.current).
class CreateSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :settings do |t|
      t.string :source_url, null: false
      t.text :welcome_text
      t.string :last_synced_version
      t.datetime :leaderboard_reset_at

      t.timestamps
    end
  end
end
