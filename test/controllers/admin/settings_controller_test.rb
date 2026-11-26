# frozen_string_literal: true

require "test_helper"

class Admin::SettingsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "muestra el formulario" do
    get edit_admin_setting_path

    assert_response :success
    assert_select "input[type=url][value=?]", Setting.current.source_url
  end

  test "guarda la URL y el texto de bienvenida, que se ve en la home" do
    patch admin_setting_path, params: { setting: { source_url: "http://localhost:8000/v1/cryptics.json",
                                                   welcome_text: "¡Hola, cripticómanos!" } }

    assert_redirected_to edit_admin_setting_path
    assert_equal "http://localhost:8000/v1/cryptics.json", Setting.current.source_url

    get root_path
    assert_select "p.lead", "¡Hola, cripticómanos!"
  end

  test "rechaza una URL que no es http o https" do
    patch admin_setting_path, params: { setting: { source_url: "ftp://algo/cryptics.json" } }

    assert_response :unprocessable_entity
    assert_equal Setting::DEFAULT_SOURCE_URL, Setting.current.source_url
  end

  test "no permite tocar los campos que escribe el sistema" do
    patch admin_setting_path, params: { setting: { welcome_text: "Hola", leaderboard_reset_at: 1.day.ago } }

    assert_nil Setting.current.leaderboard_reset_at
  end
end
