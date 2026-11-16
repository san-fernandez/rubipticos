# frozen_string_literal: true

# Página de inicio del backend. La ven los dos roles (por eso saltea
# require_admin!): es adonde se redirige a un editor de puntajes que
# intenta entrar a una sección que no le corresponde.
class Admin::DashboardController < Admin::BaseController
  skip_before_action :require_admin!

  def show
  end
end
