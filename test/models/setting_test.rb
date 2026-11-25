# frozen_string_literal: true

require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "current crea la única fila con la URL de la cátedra" do
    assert_difference -> { Setting.count }, 1 do
      assert_equal Setting::DEFAULT_SOURCE_URL, Setting.current.source_url
    end
    assert_no_difference -> { Setting.count } do
      Setting.current
    end
  end

  test "la URL de la fuente tiene que ser http o https" do
    setting = Setting.current
    setting.source_url = "archivo.json"

    assert_not setting.valid?
  end

  test "reiniciar la tabla de posiciones guarda el momento actual" do
    freeze_time do
      Setting.current.reset_leaderboard!

      assert_equal Time.current, Setting.current.leaderboard_reset_at
    end
  end
end
