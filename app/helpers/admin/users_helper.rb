# frozen_string_literal: true

module Admin::UsersHelper
  # Opciones del select de rol, con el nombre traducido: [["Administrador", "admin"], ...]
  def role_options
    User.roles.keys.map { |role| [ role_name(role), role ] }
  end

  def role_name(role)
    t("enums.user.role.#{role}")
  end
end
