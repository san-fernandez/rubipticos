# frozen_string_literal: true

# Jugadores en el backend (solo admin): listado con búsqueda, bloquear y
# desbloquear, bloquear prohibiendo el nombre en un solo paso y reiniciar
# la tabla de posiciones.
class Admin::PlayersController < Admin::BaseController
  PER_PAGE = 25

  def index
    @query = params[:q]
    @players = Player.name_like(@query).order(:name).page(params[:page]).per(PER_PAGE)
    @leaderboard_reset_at = Setting.current.leaderboard_reset_at
  end

  def reset_leaderboard
    Setting.current.reset_leaderboard!
    redirect_to admin_players_path, notice: "Se reinició la tabla de posiciones. Las partidas no se borraron."
  end

  def update
    player = Player.find(params[:id])
    attributes = params.expect(player: %i[blocked add_term])
    player.update_block!(blocked: boolean(attributes[:blocked]), add_term: boolean(attributes[:add_term]))

    redirect_back_or_to admin_players_path, notice: block_notice(player)
  end

  private

  # Los formularios mandan "true"/"false" como texto; esto los pasa a booleano.
  def boolean(value)
    ActiveModel::Type::Boolean.new.cast(value) || false
  end

  def block_notice(player)
    player.blocked? ? "#{player.name} quedó bloqueado." : "#{player.name} quedó desbloqueado."
  end
end
