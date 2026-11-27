# frozen_string_literal: true

require "test_helper"

class TypeScoreTest < ActiveSupport::TestCase
  test "es válido con un tipo del catálogo y 100 puntos" do
    type_score = TypeScore.new(cryptic_type: "anagrama", points: 100)

    assert type_score.valid?
  end

  test "acepta los límites de 10 y 1000 puntos" do
    assert TypeScore.new(cryptic_type: "anagrama", points: 10).valid?
    assert TypeScore.new(cryptic_type: "anagrama", points: 1000).valid?
  end

  test "rechaza puntos fuera del rango de 10 a 1000" do
    assert_not TypeScore.new(cryptic_type: "anagrama", points: 9).valid?
    assert_not TypeScore.new(cryptic_type: "anagrama", points: 1001).valid?
  end

  test "los puntos tienen que ser un número entero" do
    type_score = TypeScore.new(cryptic_type: "anagrama", points: 15.5)

    assert_not type_score.valid?
    assert type_score.errors.of_kind?(:points, :not_an_integer)
  end

  test "el tipo tiene que ser uno de los definidos" do
    assert_not TypeScore.new(cryptic_type: "adivinanza", points: 100).valid?
  end

  test "no puede haber dos filas para el mismo tipo" do
    TypeScore.create!(cryptic_type: "oculta", points: 100)
    repeated = TypeScore.new(cryptic_type: "oculta", points: 200)

    assert_not repeated.valid?
  end

  test "la base también rechaza puntos fuera de rango" do
    type_score = TypeScore.create!(cryptic_type: "charada", points: 100)

    # update_column saltea las validaciones del modelo: así se prueba el check de la base.
    assert_raises(ActiveRecord::StatementInvalid) do
      type_score.update_column(:points, 5)
    end
  end

  test "points_for devuelve los puntos configurados para el tipo" do
    TypeScore.create!(cryptic_type: "anagrama", points: 150)

    assert_equal 150, TypeScore.points_for("anagrama")
  end

  test "points_for falla si el tipo no está configurado" do
    assert_raises(ActiveRecord::RecordNotFound) do
      TypeScore.points_for("anagrama")
    end
  end
end
