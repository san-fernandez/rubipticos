# frozen_string_literal: true

# Puntos de un tipo de críptico. Hay una fila por cada tipo (las carga el seed).
# Es la primera parte de la base del puntaje: puntos del tipo × multiplicador
# de la dificultad. Un cambio solo afecta a las partidas que se resuelvan
# después, porque cada partida guarda sus puntos al resolverse.
class TypeScore < ApplicationRecord
  MIN_POINTS = 10
  MAX_POINTS = 1000
  DEFAULT_POINTS = 100

  validates :cryptic_type, inclusion: { in: Cryptic::TYPES }, uniqueness: true
  validates :points, numericality: { only_integer: true,
                                     greater_than_or_equal_to: MIN_POINTS,
                                     less_than_or_equal_to: MAX_POINTS }

  # Devuelve los puntos configurados para un tipo. Usa find_by! para que, si
  # falta la configuración, falle con un error claro en vez de devolver nil.
  def self.points_for(cryptic_type)
    find_by!(cryptic_type: cryptic_type).points
  end
end