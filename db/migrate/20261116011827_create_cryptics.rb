# frozen_string_literal: true

# Catálogo de crípticos. Se carga y actualiza desde la API con CrypticSynchronizer.
# Las listas (definiciones, indicadores, material) se guardan como JSON.
class CreateCryptics < ActiveRecord::Migration[8.1]
  # Copia de Cryptic::TYPES y Cryptic::DIFFICULTIES: una migración no debe
  # depender del modelo, que puede cambiar después.
  TYPES = %w[anagrama oculta charada contenedor inversion supresion homofono
             doble_definicion iniciales finales sustitucion simbolos combinada].freeze
  DIFFICULTIES = %w[facil medio avanzado].freeze

  def change
    create_table :cryptics do |t|
      t.string :source_id, null: false
      t.text :statement, null: false
      t.string :enumeration, null: false
      t.string :answer, null: false
      t.json :definitions, null: false, default: []
      t.json :indicators, null: false, default: []
      t.json :material, null: false, default: []
      t.string :cryptic_type, null: false
      t.string :difficulty, null: false
      t.text :help
      t.text :explanation
      t.string :author
      t.string :origin
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :cryptics, :source_id, unique: true
    add_index :cryptics, %i[difficulty active]
    add_check_constraint :cryptics, "cryptic_type IN (#{quoted(TYPES)})", name: "cryptics_type_check"
    add_check_constraint :cryptics, "difficulty IN (#{quoted(DIFFICULTIES)})", name: "cryptics_difficulty_check"
  end

  private

  def quoted(values) = values.map { |value| "'#{value}'" }.join(", ")
end
