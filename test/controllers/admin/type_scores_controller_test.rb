# frozen_string_literal: true

require "test_helper"

class Admin::TypeScoresControllerTest < ActionDispatch::IntegrationTest
  setup do
    Cryptic::TYPES.each do |cryptic_type|
      TypeScore.create!(cryptic_type: cryptic_type, points: TypeScore::DEFAULT_POINTS)
    end
    @anagrama = TypeScore.find_by!(cryptic_type: "anagrama")
  end

  test "sin login redirige al login" do
    get admin_type_scores_path

    assert_redirected_to new_session_path
  end

  test "el admin ve los puntos de todos los tipos" do
    sign_in_as users(:admin)
    get admin_type_scores_path

    assert_response :success
    assert_select "tbody tr", Cryptic::TYPES.size
  end

  test "el editor de puntajes ve los puntos de todos los tipos" do
    sign_in_as users(:editor)
    get admin_type_scores_path

    assert_response :success
    assert_select "tbody tr", Cryptic::TYPES.size
  end

  test "el editor de puntajes puede cambiar los puntos de un tipo" do
    sign_in_as users(:editor)
    patch admin_type_score_path(@anagrama), params: { type_score: { points: 250 } }

    assert_redirected_to admin_type_scores_path
    assert_equal 250, @anagrama.reload.points
  end

  test "no guarda puntos fuera del rango y muestra el error" do
    sign_in_as users(:editor)
    patch admin_type_score_path(@anagrama), params: { type_score: { points: 5 } }

    assert_response :unprocessable_entity
    assert_select ".alert-danger", /Anagrama/
    assert_equal 100, @anagrama.reload.points
  end

  test "no deja cambiar el tipo, solo los puntos" do
    sign_in_as users(:admin)
    patch admin_type_score_path(@anagrama), params: { type_score: { points: 300, cryptic_type: "adivinanza" } }

    assert_equal "anagrama", @anagrama.reload.cryptic_type
    assert_equal 300, @anagrama.points
  end

  test "el editor de puntajes no puede entrar a otras secciones del backend" do
    sign_in_as users(:editor)

    get admin_cryptics_path
    assert_redirected_to admin_root_path

    get admin_syncs_path
    assert_redirected_to admin_root_path
  end
end
