# frozen_string_literal: true

class HomeController < PublicController
  def show
    @setting = Setting.current
  end
end
