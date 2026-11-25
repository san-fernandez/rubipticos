# frozen_string_literal: true

# Jugador del sitio público. No tiene cuenta: se identifica con un token
# aleatorio que se guarda en una cookie firmada (ver concern CurrentPlayer).
# El nombre se puede cambiar; partidas, racha y puntos pertenecen al jugador.
class Player < ApplicationRecord
  NAME_LENGTH = (3..20)

  has_secure_token :token

  normalizes :name, with: ->(name) { name.strip }

  # La unicidad sin mayúsculas también está en la base:
  # índice único sobre lower(name) (index_players_on_lower_name).
  validates :name, presence: true, length: { in: NAME_LENGTH },
                   uniqueness: { case_sensitive: false }
  validate :name_not_blocked

  # Los bloqueados no aparecen en la tabla de posiciones (lo usa P3).
  scope :visible, -> { where(blocked: false) }

  # Búsqueda del admin por parte del nombre, sin distinguir mayúsculas.
  scope :name_like, lambda { |text|
    text.present? ? where("lower(name) LIKE ?", "%#{sanitize_sql_like(text.downcase)}%") : all
  }

  # Primera variante libre del nombre: "Pedrito" → "Pedrito_2", "Pedrito_3"...
  # Recorre un rango infinito con un enumerador lazy: genera candidatos
  # de a uno y se detiene en el primero que no está tomado.
  def self.suggest_name(base)
    base = base.to_s.strip
    (2..).lazy
         .map { |n| "#{base.first(NAME_LENGTH.max - n.to_s.size - 1)}_#{n}" }
         .find { |candidate| !name_taken?(candidate) }
  end

  def self.name_taken?(name)
    where("lower(name) = ?", name.to_s.downcase).exists?
  end

  # Cambio de nombre hecho por el propio jugador. El bloqueo es por el nombre:
  # solo se desbloquea si elige uno DISTINTO (que además pasa las validaciones,
  # incluidos los términos bloqueados). Mandar el mismo nombre, aunque sea con
  # otras mayúsculas, no lo libera.
  def rename(new_name)
    if blocked? && same_name?(new_name)
      errors.add(:name, :still_blocked)
      return false
    end

    update(name: new_name, blocked: false)
  end

  # Bloqueo o desbloqueo hecho por el admin. Con add_term, además agrega el
  # nombre como término bloqueado, así nadie más puede usarlo: las dos cosas
  # en una transacción (o se hacen ambas o ninguna).
  # update_attribute saltea las validaciones a propósito: se bloquea justamente
  # porque el nombre no es aceptable, y eso no debe impedir guardar el bloqueo.
  def update_block!(blocked:, add_term: false)
    transaction do
      update_attribute(:blocked, blocked)
      BlockedName.find_or_create_by!(term: name) if blocked? && add_term
    end
  end

  # true si el único problema del nombre es que otro jugador ya lo usa:
  # en ese caso tiene sentido sugerir una variante.
  def name_taken?
    errors.of_kind?(:name, :taken)
  end

  private

  # Compara con el nombre guardado, como lo hace la unicidad:
  # sin espacios en los bordes y sin distinguir mayúsculas.
  def same_name?(other)
    other.to_s.strip.casecmp?(name_in_database.to_s)
  end

  def name_not_blocked
    errors.add(:name, :blocked) if BlockedName.matches?(name)
  end
end
