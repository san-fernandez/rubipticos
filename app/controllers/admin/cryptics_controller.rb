# frozen_string_literal: true

# Catálogo de crípticos en el backend (solo admin): listar con filtros,
# ver el detalle y activar o desactivar. El contenido no se edita acá:
# viene de la fuente y se actualiza con la sincronización.
class Admin::CrypticsController < Admin::BaseController
  PER_PAGE = 20

  before_action :set_cryptic, only: %i[show update]

  def index
    @filters = filter_params
    @cryptics = Cryptic.by_difficulty(@filters[:difficulty]).by_type(@filters[:cryptic_type])
                       .by_status(@filters[:status]).by_origin(@filters[:origin])
                       .order(:source_id).page(params[:page]).per(PER_PAGE)
  end

  def show
  end

  def update
    if @cryptic.update(params.expect(cryptic: [ :active ]))
      redirect_back_or_to admin_cryptic_path(@cryptic),
                          notice: "El críptico #{@cryptic.source_id} quedó #{@cryptic.active? ? "activo" : "inactivo"}."
    else
      redirect_back_or_to admin_cryptic_path(@cryptic), alert: @cryptic.errors.full_messages.to_sentence
    end
  end

  private

  def set_cryptic
    @cryptic = Cryptic.find(params[:id])
  end

  def filter_params
    params.permit(:difficulty, :cryptic_type, :status, :origin)
  end
end
