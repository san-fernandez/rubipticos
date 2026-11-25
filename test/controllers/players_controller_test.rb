# frozen_string_literal: true

require "test_helper"

class PlayersControllerTest < ActionDispatch::IntegrationTest
  test "elegir un nombre crea el jugador y guarda solo el token en una cookie firmada" do
    assert_difference "Player.count", 1 do
      post player_path, params: { player: { name: "  Lucía " } }
    end

    player = Player.last
    assert_equal "Lucía", player.name
    assert_redirected_to root_path
    assert_equal player.token, signed_cookies[CurrentPlayer::COOKIE]
  end

  test "la cookie es httponly" do
    post player_path, params: { player: { name: "Lucía" } }

    assert_match(/httponly/i, response.headers["Set-Cookie"].to_s)
  end

  test "un nombre tomado muestra el error y sugiere una variante" do
    assert_no_difference "Player.count" do
      post player_path, params: { player: { name: "pedrito" } }
    end

    assert_response :unprocessable_entity
    assert_select ".invalid-feedback", /ya lo está usando otro jugador/
    assert_select "button[value=?]", "pedrito_2"
  end

  test "el botón de la sugerencia gana sobre lo escrito en el campo" do
    # Así llega el form cuando se toca "Usar pedrito_2": el campo y el botón
    # mandan player[name], y Rails se queda con el último (el del botón).
    post player_path, params: "player[name]=pedrito&player[name]=pedrito_2",
                      headers: { "CONTENT_TYPE" => "application/x-www-form-urlencoded" }

    assert_equal "pedrito_2", Player.last.name
  end

  test "un nombre bloqueado no se sugiere" do
    post player_path, params: { player: { name: "ElTonto" } }

    assert_response :unprocessable_entity
    assert_select ".invalid-feedback", /no está permitido/
    assert_select "button[name='player[name]']", count: 0
  end

  test "con jugador, elegir nombre lleva a cambiarlo" do
    sign_in_player players(:pedrito)
    get new_player_path

    assert_redirected_to edit_player_path
  end

  test "cambiar el nombre conserva el jugador" do
    player = players(:pedrito)
    sign_in_player player

    assert_no_difference "Player.count" do
      patch player_path, params: { player: { name: "Pedro" } }
    end

    assert_equal "Pedro", player.reload.name
    assert_equal player.token, signed_cookies[CurrentPlayer::COOKIE]
  end

  test "un cambio de nombre inválido no cambia el nombre del menú" do
    sign_in_player players(:pedrito)
    patch player_path, params: { player: { name: "X" } }

    assert_response :unprocessable_entity
    assert_select "nav", /Pedrito/
  end

  test "un jugador bloqueado no se libera mandando el mismo nombre" do
    player = players(:bloqueado)
    sign_in_player player
    patch player_path, params: { player: { name: player.name } }

    assert_response :unprocessable_entity
    assert_select ".invalid-feedback", /elegí uno distinto/
    assert player.reload.blocked?
  end

  test "un jugador bloqueado se libera eligiendo otro nombre" do
    player = players(:bloqueado)
    sign_in_player player
    patch player_path, params: { player: { name: "Nuevito" } }

    assert_redirected_to root_path
    assert_not player.reload.blocked?
  end

  test "empezar como otro borra la cookie pero no el jugador" do
    sign_in_player players(:pedrito)

    assert_no_difference "Player.count" do
      delete player_path
    end

    assert_redirected_to new_player_path
    assert_empty cookies[CurrentPlayer::COOKIE].to_s
  end

  test "una cookie editada a mano se descarta" do
    cookies[CurrentPlayer::COOKIE] = players(:pedrito).token # sin firmar
    get edit_player_path

    assert_redirected_to new_player_path
  end

  private

  def signed_cookies
    ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash).signed
  end
end
