# frozen_string_literal: true

# Configuración general del sitio. Hay una sola fila: siempre se usa Setting.current.
class Setting < ApplicationRecord
  DEFAULT_SOURCE_URL = "https://ecorrons.github.io/cryptics-api/v1/cryptics.json"
  DEFAULT_WELCOME_TEXT = "¡Bienvenido a Rubípticos! Elegí una dificultad y resolvé crípticos para sumar puntos."

  validates :source_url, presence: true,
                         format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
                                   message: "tiene que ser una URL http o https" }

  def self.current
    first_or_create!(source_url: DEFAULT_SOURCE_URL, welcome_text: DEFAULT_WELCOME_TEXT)
  end

  # Reiniciar la tabla de posiciones NO borra partidas: guarda desde cuándo
  # se cuenta. El ranking (P3) solo suma partidas resueltas después de esta
  # fecha; el historial de cada jugador queda intacto.
  def reset_leaderboard!
    update!(leaderboard_reset_at: Time.current)
  end
end
