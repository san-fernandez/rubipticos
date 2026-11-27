# frozen_string_literal: true

# Multiplicador de cada dificultad. Lo usan el admin y el editor de puntajes.
# Solo se listan y se editan: hay exactamente una fila por dificultad (las crea el seed).
class Admin::DifficultySettingsController < Admin::BaseController
  # Excepción de permisos: el editor de puntajes también puede entrar acá.
  # Admin::BaseController igual exige que haya iniciado sesión y esté activo.
  skip_before_action :require_admin!

  def index
    @difficulty_settings = load_difficulty_settings
  end

  def update
    difficulty_setting = DifficultySetting.find(params[:id])
    label = Cryptic::DIFFICULTY_LABELS[difficulty_setting.difficulty]

    if difficulty_setting.update(difficulty_setting_params)
      redirect_to admin_difficulty_settings_path, notice: "Se guardó el multiplicador de #{label}."
    else
      flash.now[:alert] = "No se pudo guardar el multiplicador de #{label}: " \
                          "#{difficulty_setting.errors.full_messages.to_sentence}."
      @difficulty_settings = load_difficulty_settings
      render :index, status: :unprocessable_entity
    end
  end

  private

  # Ordenadas de fácil a avanzado, y no alfabéticamente.
  def load_difficulty_settings
    DifficultySetting.in_order_of(:difficulty, Cryptic::DIFFICULTIES)
  end

  # Solo se puede cambiar el multiplicador. El tiempo de referencia es fijo
  # (lo define el enunciado) y no se edita desde el admin.
  def difficulty_setting_params
    params.expect(difficulty_setting: [ :multiplier ])
  end
end
