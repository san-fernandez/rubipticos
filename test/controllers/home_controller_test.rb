# frozen_string_literal: true

require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "la home es pública y muestra el texto de bienvenida" do
    get root_path

    assert_response :success
    assert_select "p.lead", Setting::DEFAULT_WELCOME_TEXT
  end

  test "el menú tiene las cuatro secciones" do
    get root_path

    assert_select "nav a", "Jugar"
    assert_select "nav a", "Mi racha"
    assert_select "nav a", "Tabla de posiciones"
    assert_select "nav a", "Cómo se juega"
  end

  test "sin jugador invita a elegir un nombre" do
    get root_path

    assert_select "main a[href=?]", new_player_path
    assert_select "nav a", "Elegir nombre"
  end

  test "con jugador muestra su nombre y el botón para jugar" do
    sign_in_player players(:pedrito)
    get root_path

    assert_select "main", /Hola, Pedrito/
    assert_select "main a[href=?]", new_game_path
    assert_select "nav", /Pedrito/
  end

  test "el panel del chatbot está en la página y carga en lazy" do
    get root_path

    assert_select "#chatbot-panel turbo-frame#chatbot[src=?][loading=lazy]", chatbot_path
    assert_select "nav a[data-bs-target='#chatbot-panel']", "Cómo se juega"
  end

  test "el menú tiene el botón de tema claro u oscuro" do
    get root_path

    assert_select "nav button[data-controller=theme][data-action='theme#toggle']"
  end
end
