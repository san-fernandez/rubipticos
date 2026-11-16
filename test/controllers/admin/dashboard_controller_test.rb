# frozen_string_literal: true

require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "sin login redirige al login" do
    get admin_root_path

    assert_redirected_to new_session_path
  end

  test "un admin ve el panel" do
    sign_in_as users(:admin)
    get admin_root_path

    assert_response :success
    assert_select "nav a", "Usuarios"
  end

  test "un editor de puntajes ve el panel sin las secciones de admin" do
    sign_in_as users(:editor)
    get admin_root_path

    assert_response :success
    assert_select "nav a", text: "Usuarios", count: 0
    assert_select "nav a", "Puntos por tipo"
  end

  test "un usuario desactivado es expulsado y pierde la sesión" do
    sign_in_as users(:inactive)
    get admin_root_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end
