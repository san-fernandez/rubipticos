# frozen_string_literal: true

require "test_helper"

class ScoreCalculatorTest < ActiveSupport::TestCase
  # Todavía no existe el modelo Game (es de la Persona 2). Mientras tanto se usa
  # una partida de prueba que responde a los mismos métodos que usa ScoreCalculator.
  FakeGame = Struct.new(:cryptic, :elapsed_seconds, :hints_used, :daily, keyword_init: true) do
    def daily?
      daily
    end
  end

  # Configuración inicial del enunciado: 100 puntos por tipo, multiplicadores 1, 2 y 3.
  setup do
    Cryptic::TYPES.each do |cryptic_type|
      TypeScore.create!(cryptic_type: cryptic_type, points: TypeScore::DEFAULT_POINTS)
    end

    DifficultySetting::DEFAULTS.each do |difficulty, values|
      DifficultySetting.create!(difficulty: difficulty, multiplier: values[:multiplier],
                                reference_seconds: values[:reference_seconds])
    end
  end

  # Por defecto: críptico medio (CAMISA), resuelto rápido, sin pistas y no diario.
  def build_game(cryptic: cryptics(:camisa), elapsed_seconds: 100, hints_used: 0, daily: false)
    FakeGame.new(cryptic: cryptic, elapsed_seconds: elapsed_seconds, hints_used: hints_used, daily: daily)
  end

  test "el ejemplo del enunciado da 144 puntos" do
    # Medio, 240 segundos, 1 pista, 4 días de racha: 200 × 0,75 × 0,8 × 1,2 = 144.
    game = build_game(elapsed_seconds: 240, hints_used: 1)

    assert_equal 144, ScoreCalculator.call(game: game, streak_days: 4)
  end

  test "el mismo ejemplo resuelto en 2 minutos y sin pistas da 240 puntos" do
    game = build_game(elapsed_seconds: 120, hints_used: 0)

    assert_equal 240, ScoreCalculator.call(game: game, streak_days: 4)
  end

  test "dentro del tiempo de referencia no pierde puntos por tiempo" do
    game = build_game(elapsed_seconds: 180)

    assert_equal 200, ScoreCalculator.call(game: game, streak_days: 0)
  end

  test "el factor de tiempo nunca baja de 0,25" do
    # Fácil (MATE) resuelto en 3 horas: 100 × 0,25 × 1 × 1,05 = 26,25 → 26.
    game = build_game(cryptic: cryptics(:mate), elapsed_seconds: 3 * 60 * 60)

    assert_equal 26, ScoreCalculator.call(game: game, streak_days: 1)
  end

  test "con 4 pistas el factor de pistas es 0,2" do
    game = build_game(cryptic: cryptics(:mate), elapsed_seconds: 30, hints_used: 4)

    assert_equal 20, ScoreCalculator.call(game: game, streak_days: 0)
  end

  test "el factor de racha llega como máximo a 1,5" do
    game = build_game

    assert_equal 300, ScoreCalculator.call(game: game, streak_days: 10)
    assert_equal 300, ScoreCalculator.call(game: game, streak_days: 30)
  end

  test "un críptico resuelto da como mínimo 10 puntos" do
    # Fácil en 3 horas con 4 pistas: 100 × 0,25 × 0,2 = 5, pero el mínimo es 10.
    game = build_game(cryptic: cryptics(:mate), elapsed_seconds: 3 * 60 * 60, hints_used: 4)

    assert_equal 10, ScoreCalculator.call(game: game, streak_days: 0)
  end

  test "el Críptico del día vale el doble" do
    game = build_game(elapsed_seconds: 240, hints_used: 1, daily: true)

    assert_equal 288, ScoreCalculator.call(game: game, streak_days: 4)
  end

  test "usa los puntos del tipo y el multiplicador configurados" do
    TypeScore.find_by!(cryptic_type: "contenedor").update!(points: 150)
    DifficultySetting.for_difficulty("medio").update!(multiplier: 3)
    game = build_game

    # 150 × 3 = 450.
    assert_equal 450, ScoreCalculator.call(game: game, streak_days: 0)
  end
end
