# frozen_string_literal: true

require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "lista los usuarios" do
    get admin_users_path

    assert_response :success
    assert_select "tbody tr", User.count
  end

  test "crea un usuario con rol" do
    assert_difference "User.count", 1 do
      post admin_users_path, params: { user: { email_address: "nuevo@rubipticos.test", password: "secreto123",
                                               password_confirmation: "secreto123", role: "score_editor" } }
    end

    assert_redirected_to admin_users_path
    assert User.find_by(email_address: "nuevo@rubipticos.test").score_editor?
  end

  test "con datos inválidos vuelve a mostrar el formulario con errores" do
    assert_no_difference "User.count" do
      post admin_users_path, params: { user: { email_address: "no-es-email", password: "a",
                                               password_confirmation: "b", role: "admin" } }
    end

    assert_response :unprocessable_entity
    assert_select ".alert-danger li", minimum: 1
  end

  test "editar con la contraseña vacía no la cambia" do
    editor = users(:editor)
    patch admin_user_path(editor), params: { user: { email_address: "editor2@example.com", role: "score_editor",
                                                     password: "", password_confirmation: "" } }

    assert_redirected_to admin_users_path
    assert_equal "editor2@example.com", editor.reload.email_address
    assert editor.authenticate("password")
  end

  test "desactiva un usuario y le cierra las sesiones" do
    editor = users(:editor)
    editor.sessions.create!

    patch admin_user_path(editor), params: { user: { active: false } }

    assert_redirected_to admin_users_path
    assert_not editor.reload.active?
    assert_empty editor.sessions
  end

  test "un admin no puede desactivarse a sí mismo" do
    users(:inactive).update!(active: true) # que no sea el último admin
    patch admin_user_path(users(:admin)), params: { user: { active: false } }

    assert_response :unprocessable_entity
    assert users(:admin).reload.active?
  end

  test "no hay ruta para borrar usuarios" do
    assert_not_includes Rails.application.routes.routes.map { |r| [ r.verb, r.path.spec.to_s ] },
                        [ "DELETE", "/admin/users/:id(.:format)" ]
  end
end
