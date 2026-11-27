# frozen_string_literal: true

require "test_helper"

class StreakUpdaterTest < ActiveSupport::TestCase
  setup do
    @player = Player.create!(name: "Rachero")
    @day = Date.new(2026, 11, 20)
  end

  test "la primera vez que resuelve, la racha es de 1 día" do
    days = StreakUpdater.call(player: @player, date: @day)

    assert_equal 1, days
    assert_equal 1, @player.reload.current_streak
    assert_equal 1, @player.best_streak
    assert_equal @day, @player.last_solved_on
  end

  test "si resuelve otro críptico el mismo día, la racha no cambia" do
    StreakUpdater.call(player: @player, date: @day)
    days = StreakUpdater.call(player: @player, date: @day)

    assert_equal 1, days
  end

  test "si resuelve al día siguiente, la racha suma un día" do
    StreakUpdater.call(player: @player, date: @day)
    days = StreakUpdater.call(player: @player, date: @day + 1)

    assert_equal 2, days
    assert_equal 2, @player.reload.best_streak
  end

  test "si saltea un día, la racha vuelve a 1 pero se guarda la mejor" do
    StreakUpdater.call(player: @player, date: @day)
    StreakUpdater.call(player: @player, date: @day + 1)
    days = StreakUpdater.call(player: @player, date: @day + 3)

    assert_equal 1, days
    assert_equal 1, @player.reload.current_streak
    assert_equal 2, @player.best_streak
  end
end
