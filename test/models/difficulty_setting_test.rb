# frozen_string_literal: true

require "test_helper"

class DifficultySettingTest < ActiveSupport::TestCase
  def build(multiplier: 2, reference_seconds: 180)
    DifficultySetting.new(difficulty: "medio", multiplier: multiplier, reference_seconds: reference_seconds)
  end

  test "es válido con los valores iniciales del enunciado" do
    assert build.valid?
  end

  test "el multiplicador tiene que ser mayor que 0" do
    assert_not build(multiplier: 0).valid?
    assert_not build(multiplier: -1).valid?
    assert build(multiplier: 0.5).valid?
  end

  test "el multiplicador puede ser como máximo 5" do
    assert build(multiplier: 5).valid?
    assert_not build(multiplier: 5.01).valid?
  end

  test "el tiempo de referencia tiene que ser un entero positivo" do
    assert_not build(reference_seconds: 0).valid?
    assert_not build(reference_seconds: 30.5).valid?
  end

  test "la dificultad tiene que ser una de las definidas" do
    setting = build
    setting.difficulty = "imposible"

    assert_not setting.valid?
  end

  test "no puede haber dos filas para la misma dificultad" do
    build.save!

    assert_not build(multiplier: 3).valid?
  end

  test "la base también rechaza un multiplicador mayor que 5" do
    setting = build
    setting.save!

    # update_column saltea las validaciones del modelo: así se prueba el check de la base.
    assert_raises(ActiveRecord::StatementInvalid) do
      setting.update_column(:multiplier, 6)
    end
  end

  test "for_difficulty devuelve la configuración de esa dificultad" do
    setting = build
    setting.save!

    assert_equal setting, DifficultySetting.for_difficulty("medio")
  end

  test "for_difficulty falla si la dificultad no está configurada" do
    assert_raises(ActiveRecord::RecordNotFound) do
      DifficultySetting.for_difficulty("medio")
    end
  end

  test "los valores iniciales cubren todas las dificultades" do
    assert_equal Cryptic::DIFFICULTIES.sort, DifficultySetting::DEFAULTS.keys.sort
  end
end