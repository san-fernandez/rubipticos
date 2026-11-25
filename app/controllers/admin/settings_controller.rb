# frozen_string_literal: true

# Configuración general (solo admin): URL de la fuente del catálogo y texto
# de bienvenida de la home. Es un recurso singular (resource :setting): hay
# una sola fila, Setting.current, así que no hay id en la URL.
# last_synced_version (P1) y leaderboard_reset_at (reinicio de la tabla) no
# se editan acá: los escribe el sistema.
class Admin::SettingsController < Admin::BaseController
  before_action :set_setting

  def edit
  end

  def update
    if @setting.update(params.expect(setting: %i[source_url welcome_text]))
      redirect_to edit_admin_setting_path, notice: "Configuración guardada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_setting
    @setting = Setting.current
  end
end
