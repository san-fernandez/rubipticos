# frozen_string_literal: true

class SessionsController < ApplicationController
  layout "admin"
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Demasiados intentos. Probá de nuevo en unos minutos." }

  def new
  end

  def create
    # authenticate_by compara la contraseña aunque el email no exista (tarda lo
    # mismo), así no se puede averiguar qué emails están registrados.
    user = User.authenticate_by(params.permit(:email_address, :password))

    if user&.active?
      start_new_session_for user
      redirect_to after_authentication_url
    else
      # Mismo mensaje para contraseña incorrecta y usuario desactivado.
      redirect_to new_session_path, alert: "El email o la contraseña no son correctos, o el usuario está desactivado."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
