# frozen_string_literal: true

# Configuración de cada dificultad (una fila por dificultad): el multiplicador
# de la base del puntaje y el tiempo de referencia para el factor de tiempo.
class CreateDifficultySettings < ActiveRecord::Migration[8.1]
  # Copia de Cryptic::DIFFICULTIES: una migración no debe depender del modelo.
  DIFFICULTIES = %w[facil medio avanzado].freeze

  def change
    create_table :difficulty_settings do |t|
      t.string :difficulty, null: false
      t.decimal :multiplier, null: false, precision: 4, scale: 2
      t.integer :reference_seconds, null: false

      t.timestamps
    end

    add_index :difficulty_settings, :difficulty, unique: true
    add_check_constraint :difficulty_settings, "difficulty IN (#{quoted_list(DIFFICULTIES)})",
                         name: "difficulty_settings_difficulty_check"
    add_check_constraint :difficulty_settings, "multiplier > 0 AND multiplier <= 5",
                         name: "difficulty_settings_multiplier_check"
    add_check_constraint :difficulty_settings, "reference_seconds > 0",
                         name: "difficulty_settings_reference_seconds_check"
  end

  private

  # Arma "'facil', 'medio', 'avanzado'" para usar dentro del IN de SQL.
  def quoted_list(values)
    values.map { |value| "'#{value}'" }.join(", ")
  end
end