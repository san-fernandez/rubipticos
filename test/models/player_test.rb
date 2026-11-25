# frozen_string_literal: true

require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  test "genera un token al crearse" do
    player = Player.create!(name: "Nueva")

    assert player.token.present?
  end

  test "saca los espacios del principio y del final del nombre" do
    assert_equal "Ana Laura", Player.new(name: "  Ana Laura ").name
  end

  test "el nombre tiene entre 3 y 20 caracteres" do
    assert_not Player.new(name: "Al").valid?
    assert Player.new(name: "Ale").valid?
    assert Player.new(name: "a" * 20).valid?
    assert_not Player.new(name: "a" * 21).valid?
  end

  test "el nombre es único sin distinguir mayúsculas" do
    player = Player.new(name: "PEDRITO")

    assert_not player.valid?
    assert player.name_taken?
  end

  test "la base también rechaza un nombre repetido con otras mayúsculas" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      Player.new(name: "pedrito").save!(validate: false)
    end
  end

  test "no puede contener un término bloqueado" do
    player = Player.new(name: "ElTonto")

    assert_not player.valid?
    assert_not player.name_taken?
    assert_includes player.errors[:name], "no está permitido"
  end

  test "sugiere la primera variante libre del nombre" do
    assert_equal "pedrito_2", Player.suggest_name("pedrito")

    Player.create!(name: "Pedrito_2")
    assert_equal "Pedrito_3", Player.suggest_name("Pedrito")
  end

  test "la sugerencia no supera los 20 caracteres" do
    Player.create!(name: "a" * 20)

    assert_operator Player.suggest_name("a" * 20).length, :<=, Player::NAME_LENGTH.max
  end

  test "cambiar el nombre lo desbloquea, pero no si el nombre nuevo es inválido" do
    player = players(:bloqueado)

    assert_not player.rename("ElTonto")
    assert player.reload.blocked?

    assert player.rename("Bueno")
    assert_not player.reload.blocked?
  end

  test "un bloqueado que manda el mismo nombre sigue bloqueado" do
    player = players(:bloqueado)

    [ "Bloqueadito", " BLOQUEADITO " ].each do |same_name|
      assert_not player.rename(same_name)
      assert_includes player.errors[:name], "está bloqueado: elegí uno distinto"
      assert player.reload.blocked?
    end
  end

  test "un jugador no bloqueado puede mandar el mismo nombre" do
    player = players(:pedrito)

    assert player.rename("Pedrito")
    assert_not player.reload.blocked?
  end

  test "visible excluye a los jugadores bloqueados" do
    assert_includes Player.visible, players(:pedrito)
    assert_not_includes Player.visible, players(:bloqueado)
  end
end
