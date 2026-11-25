# frozen_string_literal: true

require "test_helper"

# Los permisos del backend se controlan en el servidor (Admin::BaseController):
# ocultar los links del menú no alcanza, porque la URL se puede escribir a mano.
class AdminPermissionsTest < ActionDispatch::IntegrationTest
  ADMIN_ONLY_PAGES = %i[
    admin_users_path new_admin_user_path admin_players_path admin_blocked_names_path
    edit_admin_setting_path admin_cryptics_path admin_syncs_path
  ].freeze

  test "un editor de puntajes que escribe la URL de una sección de admin es redirigido" do
    sign_in_as users(:editor)

    ADMIN_ONLY_PAGES.each do |page|
      get public_send(page)

      assert_redirected_to admin_root_path, "#{page} debería rechazar al editor"
      assert_equal "No tenés permiso para entrar a esa sección.", flash[:alert]
    end
  end

  test "un editor de puntajes no puede cambiar nada aunque mande el formulario a mano" do
    sign_in_as users(:editor)

    assert_no_difference "User.count" do
      post admin_users_path, params: { user: { email_address: "colado@rubipticos.test", password: "secreto123",
                                               password_confirmation: "secreto123", role: "admin" } }
    end
    patch admin_user_path(users(:editor)), params: { user: { role: "admin" } }
    patch admin_player_path(players(:pedrito)), params: { player: { blocked: true } }
    patch admin_setting_path, params: { setting: { source_url: "http://malicioso.test/cryptics.json" } }
    post reset_leaderboard_admin_players_path

    assert users(:editor).reload.score_editor?
    assert_not players(:pedrito).reload.blocked?
    assert_equal Setting::DEFAULT_SOURCE_URL, Setting.current.source_url
    assert_nil Setting.current.leaderboard_reset_at
  end

  test "un admin entra a todas las secciones" do
    sign_in_as users(:admin)

    ADMIN_ONLY_PAGES.each do |page|
      get public_send(page)

      assert_response :success, "#{page} debería dejar entrar al admin"
    end
  end

  test "sin login, todas las secciones piden iniciar sesión" do
    ADMIN_ONLY_PAGES.each do |page|
      get public_send(page)

      assert_redirected_to new_session_path
    end
  end
end
