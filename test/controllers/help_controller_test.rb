# frozen_string_literal: true

require "test_helper"

class HelpControllerTest < ActionDispatch::IntegrationTest
  test "es pública y muestra las reglas con los títulos de cada sección" do
    get help_path

    assert_response :success
    assert_select "h2", "¿Qué es un críptico?"
    assert_select "h2", "Pistas"
    assert_select "h2", "Puntaje"
    assert_select "h2", "Rachas"
  end

  test "muestra una tarjeta por cada tipo de juego de palabras" do
    get help_path

    assert_select ".card-body > p.mb-2", Cryptic::TYPES.size
  end

  test "las soluciones de los ejemplos quedan escondidas en un details" do
    get help_path

    assert_select "details summary", minimum: Cryptic::TYPES.size
  end
end
