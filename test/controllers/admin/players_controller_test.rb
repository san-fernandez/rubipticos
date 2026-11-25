# frozen_string_literal: true

require "test_helper"

class Admin::PlayersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "lista los jugadores" do
    get admin_players_path

    assert_response :success
    assert_select "tbody tr", Player.count
  end

  test "busca por parte del nombre sin distinguir mayúsculas" do
    get admin_players_path, params: { q: "PEDRI" }

    assert_select "tbody tr", 1
    assert_select "tbody", /Pedrito/
  end

  test "bloquea y desbloquea un jugador" do
    player = players(:pedrito)

    patch admin_player_path(player), params: { player: { blocked: true } }
    assert player.reload.blocked?
    assert_not BlockedName.exists?(term: "pedrito")

    patch admin_player_path(player), params: { player: { blocked: false } }
    assert_not player.reload.blocked?
  end

  test "bloquea y prohíbe el nombre en un solo paso" do
    player = players(:pedrito)

    assert_difference "BlockedName.count", 1 do
      patch admin_player_path(player), params: { player: { blocked: true, add_term: true } }
    end

    assert player.reload.blocked?
    assert_not Player.new(name: "Pedrito99").valid?
  end

  test "bloquea aunque el nombre ya contenga un término prohibido" do
    player = players(:pedrito)
    player.update_column(:name, "ElTonto") # nombre que hoy ya no pasaría la validación

    patch admin_player_path(player), params: { player: { blocked: true } }

    assert player.reload.blocked?
  end

  test "reiniciar la tabla guarda la fecha y no borra jugadores" do
    freeze_time do
      assert_no_difference "Player.count" do
        post reset_leaderboard_admin_players_path
      end

      assert_redirected_to admin_players_path
      assert_equal Time.current, Setting.current.leaderboard_reset_at
    end
  end
end
