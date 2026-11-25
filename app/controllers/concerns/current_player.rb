# frozen_string_literal: true

# Identifica al jugador del sitio público por el token guardado en una
# cookie firmada. Lo incluye PublicController, así lo tienen todos los
# controladores públicos (juego, racha, tabla, etc.).
#
# cookies.signed: Rails firma el valor con secret_key_base. Si alguien edita
# la cookie a mano la firma no coincide, Rails la descarta y devuelve nil.
# La cookie guarda SOLO el token: puntos, partidas y rachas están en la base.
module CurrentPlayer
  extend ActiveSupport::Concern

  COOKIE = :player_token

  included do
    helper_method :current_player
  end

  private

  # nil si no eligió nombre todavía (o borró las cookies).
  def current_player
    return @current_player if defined?(@current_player)

    token = cookies.signed[COOKIE]
    @current_player = token && Player.find_by(token: token)
  end

  # before_action para las páginas que necesitan un jugador (por ejemplo, jugar).
  # Guarda adónde quería ir, para volver ahí después de elegir el nombre.
  # Un jugador bloqueado tiene que cambiar el nombre antes de seguir.
  def require_player
    if current_player.nil?
      session[:return_to_after_player] = request.fullpath if request.get?
      redirect_to new_player_path, alert: "Primero elegí un nombre para jugar."
    elsif current_player.blocked?
      redirect_to edit_player_path, alert: "Tu nombre fue bloqueado. Elegí otro para seguir jugando."
    end
  end

  def remember_player(player)
    @current_player = player
    cookies.signed.permanent[COOKIE] = { value: player.token, httponly: true, same_site: :lax }
  end

  def forget_player
    @current_player = nil
    cookies.delete(COOKIE)
  end

  def after_player_url
    session.delete(:return_to_after_player) || root_path
  end
end
