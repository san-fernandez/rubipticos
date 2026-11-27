# frozen_string_literal: true

# Calcula los puntos de una partida resuelta con la fórmula del enunciado:
#
#   puntos = base × factor de tiempo × factor de pistas × factor de racha
#
# redondeado al entero más cercano y con un mínimo de 10 puntos.
# Lo llama Game#solve! (Persona 2) al resolver, después de StreakUpdater.
# Rendirse no pasa por acá: esa partida guarda 0 puntos directamente.
#
# Las cuentas se hacen con BigDecimal (decimales exactos) y no con Float,
# porque Float no puede guardar 0,2 exacto: 1 - 0.2 * 3 da 0.3999999999999999.
class ScoreCalculator
  MIN_POINTS = 10
  DAILY_MULTIPLIER = 2
  HINT_PENALTY = BigDecimal("0.20")
  STREAK_BONUS = BigDecimal("0.05")
  MAX_STREAK_FACTOR = BigDecimal("1.5")
  MIN_TIME_FACTOR = BigDecimal("0.25")

  def self.call(game:, streak_days:)
    new(game: game, streak_days: streak_days).points
  end

  def initialize(game:, streak_days:)
    @game = game
    @streak_days = streak_days
    @difficulty_setting = DifficultySetting.for_difficulty(game.cryptic.difficulty)
  end

  def points
    total = base * time_factor * hint_factor * streak_factor
    [ total.round, MIN_POINTS ].max
  end

  private

  # Puntos del tipo × multiplicador de la dificultad (×2 si es el Críptico del día).
  def base
    type_points = TypeScore.points_for(@game.cryptic.cryptic_type)
    result = type_points * @difficulty_setting.multiplier

    if @game.daily?
      result * DAILY_MULTIPLIER
    else
      result
    end
  end

  # 1 si tardó lo mismo o menos que la referencia; si no, referencia ÷ tiempo,
  # pero nunca menos de 0,25.
  def time_factor
    reference = @difficulty_setting.reference_seconds
    seconds = @game.elapsed_seconds
    return 1 if seconds <= reference

    [ BigDecimal(reference) / seconds, MIN_TIME_FACTOR ].max
  end

  # Cada pista resta 0,20: 0 pistas = 1, 1 pista = 0,8 ... 4 pistas = 0,2.
  def hint_factor
    1 - (HINT_PENALTY * @game.hints_used)
  end

  # Cada día de racha (contando hoy) suma 0,05, hasta un máximo de 1,5.
  def streak_factor
    [ 1 + (STREAK_BONUS * @streak_days), MAX_STREAK_FACTOR ].min
  end
end
