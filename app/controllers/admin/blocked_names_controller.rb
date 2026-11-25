# frozen_string_literal: true

# Términos que un jugador no puede usar en su nombre (solo admin).
# Un nombre se rechaza si CONTIENE alguno (ver BlockedName.matches?).
# Agregar un término no cambia los nombres que ya existen: para eso se
# bloquea al jugador desde el listado de jugadores.
class Admin::BlockedNamesController < Admin::BaseController
  def index
    @blocked_name = BlockedName.new
    @blocked_names = BlockedName.order(:term)
  end

  def create
    @blocked_name = BlockedName.new(params.expect(blocked_name: [ :term ]))

    if @blocked_name.save
      redirect_to admin_blocked_names_path, notice: "Se bloqueó el término «#{@blocked_name.term}»."
    else
      @blocked_names = BlockedName.order(:term)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    blocked_name = BlockedName.find(params[:id])
    blocked_name.destroy!
    redirect_to admin_blocked_names_path, notice: "Se quitó el término «#{blocked_name.term}»."
  end
end
