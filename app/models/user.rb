# frozen_string_literal: true

# Usuario del backend. Lo creó el generador de autenticación de Rails 8;
# se le agregan el rol y si está activo. No se borra: se desactiva, porque
# los SyncLog guardan qué admin sincronizó.
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  # admin: hace todo. score_editor: solo edita puntos por tipo y multiplicadores.
  # Genera admin?, score_editor?, User.admin, etc.
  enum :role, { admin: "admin", score_editor: "score_editor" }, validate: true

  scope :active, -> { where(active: true) }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # Unicidad también en la base (índice único en email_address).
  validates :email_address, presence: true, uniqueness: true,
                            format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :cannot_lose_admin_self, on: :update
  validate :keeps_one_active_admin, on: :update

  # Un usuario desactivado pierde las sesiones abiertas en el momento.
  after_update_commit :close_sessions, if: -> { saved_change_to_active?(to: false) }

  private

  # true si con este cambio el usuario deja de ser un admin activo.
  def losing_active_admin?
    was_active_admin = role_in_database == "admin" && active_in_database
    was_active_admin && !(admin? && active?)
  end

  # Current.user es el usuario logueado en este request (ver modelo Current).
  def cannot_lose_admin_self
    return unless Current.user == self && losing_active_admin?

    errors.add(:base, :cannot_lose_admin_self)
  end

  def keeps_one_active_admin
    return unless losing_active_admin?
    return if User.admin.active.where.not(id: id).exists?

    errors.add(:base, :last_active_admin)
  end

  def close_sessions
    sessions.destroy_all
  end
end
