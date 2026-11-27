# frozen_string_literal: true

# Puntos de cada tipo de críptico (una fila por tipo). Los edita el admin o el
# editor de puntajes y son la primera parte de la base del puntaje.
class CreateTypeScores < ActiveRecord::Migration[8.1]
  # Copia de Cryptic::TYPES: una migración no debe depender del modelo,
  # que puede cambiar después.
  TYPES = %w[anagrama oculta charada contenedor inversion supresion homofono
             doble_definicion iniciales finales sustitucion simbolos combinada].freeze

  def change
    create_table :type_scores do |t|
      t.string :cryptic_type, null: false
      t.integer :points, null: false, default: 100

      t.timestamps
    end

    add_index :type_scores, :cryptic_type, unique: true
    add_check_constraint :type_scores, "cryptic_type IN (#{quoted_list(TYPES)})", name: "type_scores_type_check"
    add_check_constraint :type_scores, "points BETWEEN 10 AND 1000", name: "type_scores_points_check"
  end

  private

  # Arma "'anagrama', 'oculta', ..." para usar dentro del IN de SQL.
  def quoted_list(values)
    values.map { |value| "'#{value}'" }.join(", ")
  end
end