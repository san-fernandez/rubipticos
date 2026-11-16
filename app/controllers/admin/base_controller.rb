# frozen_string_literal: true

# Base de todos los controladores del backend (/admin).
# El login lo exige ApplicationController (concern Authentication).
# Acá se controla, en el servidor, que el usuario esté activo y sea admin:
# ocultar links del menú no alcanza, porque la URL se puede escribir a mano.
# Los controladores que puede usar el editor de puntajes hacen
# skip_before_action :require_admin!
class Admin::BaseController < ApplicationController
  layout "admin"

  before_action :require_active_user
  before_action :require_admin!

  private

  def require_active_user
    return if Current.user.active?

    terminate_session
    redirect_to new_session_path, alert: "Tu usuario está desactivado."
  end

  def require_admin!
    return if Current.user.admin?

    redirect_to admin_root_path, alert: "No tenés permiso para entrar a esa sección."
  end
end
