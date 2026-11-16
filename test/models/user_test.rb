# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
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
