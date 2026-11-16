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
end
