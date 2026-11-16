# frozen_string_literal: true

# Jugadores del sitio público. No tienen cuenta: los identifica el token
# guardado en una cookie firmada. Las columnas de racha las usa la Persona 3.
class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.string :name, null: false
      t.string :token, null: false
      t.boolean :blocked, null: false, default: false
      t.integer :current_streak, null: false, default: 0
      t.integer :best_streak, null: false, default: 0
      t.date :last_solved_on

      t.timestamps
    end

    add_index :players, :token, unique: true
    # Nombre único sin distinguir mayúsculas: "Pedro" y "pedro" chocan en la base.
    add_index :players, "lower(name)", unique: true, name: "index_players_on_lower_name"
  end
end
