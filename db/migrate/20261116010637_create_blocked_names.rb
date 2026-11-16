# frozen_string_literal: true

# Términos ofensivos que un jugador no puede usar en su nombre.
class CreateBlockedNames < ActiveRecord::Migration[8.1]
  def change
    create_table :blocked_names do |t|
      t.string :term, null: false

      t.timestamps
    end

    add_index :blocked_names, :term, unique: true
  end
end
