# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "el email es obligatorio, válido y único sin importar mayúsculas" do
    assert_not User.new(password: "secreto123").valid?
    assert_not User.new(email_address: "no-es-un-email", password: "secreto123").valid?

    duplicate = User.new(email_address: " ADMIN@example.com ", password: "secreto123")
    assert_not duplicate.valid?
    assert duplicate.errors[:email_address].any?
  end

  test "por defecto es editor de puntajes" do
    assert User.new.score_editor?
  end

  test "rechaza un rol desconocido en el modelo y en la base" do
    user = users(:admin)
    user.role = "superadmin"

    assert_not user.valid?
    assert_raises(ActiveRecord::StatementInvalid) { user.update_column(:role, "superadmin") }
  end

  test "no se puede desactivar ni degradar al último admin activo" do
    admin = users(:admin) # en los fixtures es el único admin activo

    assert_not admin.update(active: false)
    assert_includes admin.errors[:base], "Tiene que quedar al menos un administrador activo."
    assert_not admin.reload.update(role: "score_editor")
  end

  test "con otro admin activo, sí se puede desactivar" do
    users(:inactive).update!(active: true)

    assert users(:admin).update(active: false)
  end

  test "un admin no puede desactivarse ni quitarse el rol a sí mismo" do
    admin = users(:admin)
    users(:inactive).update!(active: true) # que no sea el último admin
    Current.session = admin.sessions.create!

    assert_not admin.update(active: false)
    assert_includes admin.errors[:base], "No podés desactivarte ni quitarte el rol de administrador a vos mismo."
    assert_not admin.reload.update(role: "score_editor")
  ensure
    Current.reset
  end

  test "al desactivarlo se cierran sus sesiones" do
    editor = users(:editor)
    editor.sessions.create!

    assert_difference -> { editor.sessions.count }, -1 do
      editor.update!(active: false)
    end
  end
end
