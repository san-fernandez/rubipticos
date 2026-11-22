# frozen_string_literal: true

# Término que un jugador no puede usar en su nombre (lo carga el admin).
# Un nombre queda bloqueado si CONTIENE el término, sin distinguir mayúsculas:
# bloquear "tonto" también rechaza "ElTonto99".
class BlockedName < ApplicationRecord
  normalizes :term, with: ->(term) { term.strip.downcase }

  # Unicidad también en la base (índice único en term).
  validates :term, presence: true, uniqueness: true

  def self.matches?(name)
    return false if name.blank?

    downcased = name.downcase
    pluck(:term).any? { |term| downcased.include?(term) }
  end
end
