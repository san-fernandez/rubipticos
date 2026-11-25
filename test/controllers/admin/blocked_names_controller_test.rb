# frozen_string_literal: true

require "test_helper"

class Admin::BlockedNamesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "lista los términos" do
    get admin_blocked_names_path

    assert_response :success
    assert_select "li", /tonto/
  end

  test "agrega un término normalizado" do
    assert_difference "BlockedName.count", 1 do
      post admin_blocked_names_path, params: { blocked_name: { term: "  FEO " } }
    end

    assert_redirected_to admin_blocked_names_path
    assert BlockedName.exists?(term: "feo")
  end

  test "un término repetido muestra el error" do
    assert_no_difference "BlockedName.count" do
      post admin_blocked_names_path, params: { blocked_name: { term: "Tonto" } }
    end

    assert_response :unprocessable_entity
    assert_select ".alert-danger"
  end

  test "quita un término" do
    assert_difference "BlockedName.count", -1 do
      delete admin_blocked_name_path(blocked_names(:tonto))
    end

    assert_redirected_to admin_blocked_names_path
  end
end
