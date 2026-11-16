# frozen_string_literal: true

# Usuario del backend. Lo creó el generador de autenticación de Rails 8;
# se le agregan el rol y si está activo.
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  # admin: hace todo. score_editor: solo edita puntos por tipo y multiplicadores.
  # Genera admin?, score_editor?, User.admin, etc.
  enum :role, { admin: "admin", score_editor: "score_editor" }, validate: true

  scope :active, -> { where(active: true) }

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
