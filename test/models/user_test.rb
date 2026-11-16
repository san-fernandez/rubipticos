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
end
