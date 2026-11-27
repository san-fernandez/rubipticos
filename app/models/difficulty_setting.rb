# frozen_string_literal: true

# Configuración de una dificultad. Hay una fila por dificultad (las carga el seed).
# - multiplier: multiplica los puntos del tipo para armar la base del puntaje.
# - reference_seconds: si el jugador tarda más que esto, pierde puntos por tiempo.
class DifficultySetting < ApplicationRecord
  MAX_MULTIPLIER = 5

  # Valores iniciales del enunciado: multiplicadores 1, 2 y 3, y tiempos de
  # referencia de 60, 180 y 300 segundos. Los usa db/seeds.rb.
  DEFAULTS = {
    "facil" => { multiplier: 1, reference_seconds: 60 },
    "medio" => { multiplier: 2, reference_seconds: 180 },
    "avanzado" => { multiplier: 3, reference_seconds: 300 }
  }.freeze

  validates :difficulty, inclusion: { in: Cryptic::DIFFICULTIES }, uniqueness: true
  validates :multiplier, numericality: { greater_than: 0, less_than_or_equal_to: MAX_MULTIPLIER }
  validates :reference_seconds, numericality: { only_integer: true, greater_than: 0 }

  # Devuelve la configuración de una dificultad. Usa find_by! para que, si
  # falta, falle con un error claro en vez de devolver nil.
  def self.for_difficulty(difficulty)
    find_by!(difficulty: difficulty)
  end
end