# frozen_string_literal: true

require "test_helper"

class ChatbotsControllerTest < ActionDispatch::IntegrationTest
  test "es público y arranca por la bienvenida" do
    get chatbot_path

    assert_response :success
    assert_select "turbo-frame#chatbot p", /Soy el ayudante/
  end

  test "cada opción es un link a otro nodo dentro del frame" do
    get chatbot_path

    assert_select "turbo-frame#chatbot a[href=?]", chatbot_path(node: "types")
  end

  test "guarda el nodo en la sesión y lo retoma al volver a abrir" do
    get chatbot_path(node: "type_anagrama")
    assert_select "p", /Anagrama/
    assert_equal "type_anagrama", session[:chatbot_node]

    get chatbot_path
    assert_select "p", /Anagrama/
  end

  test "no usa la cookie del jugador" do
    get chatbot_path(node: "types")

    assert_nil cookies[CurrentPlayer::COOKIE]
  end

  test "un nodo inexistente muestra la bienvenida" do
    get chatbot_path(node: "no-existe")

    assert_select "p", /Soy el ayudante/
    assert_equal "welcome", session[:chatbot_node]
  end

  test "fuera de la bienvenida hay un link para volver al menú" do
    get chatbot_path(node: "hints")

    assert_select "a[href=?]", chatbot_path(node: "welcome"), text: "Volver al menú"
  end

  test "como página completa no repite el frame del panel" do
    get chatbot_path

    assert_select "turbo-frame#chatbot", 1
  end
end
