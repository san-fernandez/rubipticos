# frozen_string_literal: true

# Puntos de cada tipo de críptico. Lo usan el admin y el editor de puntajes.
# Solo se listan y se editan: hay exactamente una fila por tipo (las crea el seed).
class Admin::TypeScoresController < Admin::BaseController
  # Excepción de permisos: el editor de puntajes también puede entrar acá.
  # Admin::BaseController igual exige que haya iniciado sesión y esté activo.
  skip_before_action :require_admin!

  def index
    @type_scores = load_type_scores
  end

  def update
    type_score = TypeScore.find(params[:id])
    label = Cryptic::TYPE_LABELS[type_score.cryptic_type]

    if type_score.update(type_score_params)
      redirect_to admin_type_scores_path, notice: "Se guardaron los puntos de #{label}."
    else
      flash.now[:alert] = "No se pudieron guardar los puntos de #{label}: #{type_score.errors.full_messages.to_sentence}."
      @type_scores = load_type_scores
      render :index, status: :unprocessable_entity
    end
  end

  private

  # Ordenados como en el enunciado (anagrama, oculta, charada...) y no alfabéticamente.
  def load_type_scores
    TypeScore.in_order_of(:cryptic_type, Cryptic::TYPES)
  end

  # Solo se pueden cambiar los puntos, nunca el tipo.
  def type_score_params
    params.expect(type_score: [ :points ])
  end
end
