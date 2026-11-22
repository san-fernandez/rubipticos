# frozen_string_literal: true

require "test_helper"

class Admin::SyncsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
    Cryptic.delete_all
  end

  test "muestra la fuente y el botón para sincronizar" do
    get admin_syncs_path

    assert_response :success
    assert_select "code", Setting::DEFAULT_SOURCE_URL
    assert_select "button", "Sincronizar ahora"
  end

  test "sincronizar ahora trae el catálogo y muestra el informe con los rechazados" do
    stub_request(:get, Setting::DEFAULT_SOURCE_URL).to_return(body: file_fixture("cryptics_with_errors.json").read)

    post admin_syncs_path

    assert_redirected_to admin_syncs_path
    assert_match "1 creados", flash[:notice]
    follow_redirect!
    assert_select "td", "cr-107"
    assert_select "td", /no contiene «una planta»/
    assert_equal users(:admin), SyncLog.last.user
  end

  test "si la sincronización falla lo muestra como alerta" do
    stub_request(:get, Setting::DEFAULT_SOURCE_URL).to_timeout

    post admin_syncs_path

    assert_match "falló", flash[:alert]
  end

  test "un editor de puntajes no puede sincronizar" do
    sign_in_as users(:editor)

    post admin_syncs_path

    assert_redirected_to admin_root_path
    assert_equal 0, SyncLog.count
  end
end
