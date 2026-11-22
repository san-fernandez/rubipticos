# frozen_string_literal: true

# Identidad del jugador: elegir nombre, cambiarlo y "empezar como otro".
# Es un recurso singular (resource :player): siempre se trata del jugador
# de la cookie, nunca de otro, así que no hay id en la URL.
class PlayersController < PublicController
  before_action :redirect_if_player, only: %i[new create]
  before_action :redirect_unless_player, only: %i[edit update destroy]

  def new
    @player = Player.new
  end

  def create
    @player = Player.new(player_params)

    if @player.save
      remember_player(@player)
      redirect_to after_player_url, notice: "¡Hola, #{@player.name}! Ya podés jugar."
    else
      @suggestion = Player.suggest_name(@player.name) if @player.name_taken?
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @player = current_player
  end

  def update
    # Otra instancia: si el nombre nuevo es inválido, el menú sigue
    # mostrando el nombre guardado y no el que se intentó.
    @player = Player.find(current_player.id)

    if @player.rename(player_params[:name])
      redirect_to after_player_url, notice: "Listo, ahora te llamás #{@player.name}."
    else
      @suggestion = Player.suggest_name(@player.name) if @player.name_taken?
      render :edit, status: :unprocessable_entity
    end
  end

  # "Empezar como otro jugador": borra la cookie, NO el registro.
  # El jugador anterior queda en la base y sigue contando en el ranking,
  # pero desde este navegador ya no se puede recuperar.
  def destroy
    forget_player
    redirect_to new_player_path, notice: "Empezaste como un jugador nuevo. Elegí tu nombre."
  end

  private

  def player_params
    params.expect(player: [ :name ])
  end

  def redirect_if_player
    redirect_to edit_player_path if current_player
  end

  def redirect_unless_player
    redirect_to new_player_path unless current_player
  end
end
