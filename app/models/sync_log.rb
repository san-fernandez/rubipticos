# frozen_string_literal: true

# Resultado de una sincronización del catálogo (lo crea CrypticSynchronizer).
class SyncLog < ApplicationRecord
  STATUSES = %w[ok unchanged failed].freeze

  belongs_to :user, optional: true

  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }

  def ok? = status == "ok"
  def unchanged? = status == "unchanged"
  def failed? = status == "failed"

  # Resumen en una línea, para el aviso que ve el admin y para el seed.
  def summary
    case status
    when "unchanged" then "Sin cambios: la fuente sigue en la versión #{version}."
    when "failed" then "La sincronización falló: #{error_message}"
    else "Versión #{version}: #{created_count} creados, #{updated_count} actualizados, " \
         "#{deactivated_count} desactivados y #{rejected_count} rechazados."
    end
  end
end
