# frozen_string_literal: true

require "test_helper"

class Admin::DifficultySettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    DifficultySetting::DEFAULTS.each do |difficulty, values|
      DifficultySetting.create!(difficulty: difficulty, multiplier: values[:multiplier],
                                reference_seconds: values[:reference_seconds])
    end
    @medio = DifficultySetting.for_difficulty("medio")
  end

  test "sin login redirige al login" do
    get admin_difficulty_settings_path

    assert_redirected_to new_session_path
  end

  test "el editor de puntajes ve los multiplicadores de fácil a avanzado" do
    sign_in_as users(:editor)
    get admin_difficulty_settings_path

    assert_response :success
    assert_select "tbody tr", 3
    assert_select "tbody tr:first-child td:first-child", "Fácil"
  end

  test "el editor de puntajes puede cambiar un multiplicador" do
    sign_in_as users(:editor)
    patch admin_difficulty_setting_path(@medio), params: { difficulty_setting: { multiplier: "2.5" } }

    assert_redirected_to admin_difficulty_settings_path
    assert_equal BigDecimal("2.5"), @medio.reload.multiplier
  end

  test "no guarda un multiplicador mayor que 5 y muestra el error" do
    sign_in_as users(:admin)
    patch admin_difficulty_setting_path(@medio), params: { difficulty_setting: { multiplier: "6" } }

    assert_response :unprocessable_entity
    assert_select ".alert-danger", /Medio/
    assert_equal BigDecimal("2"), @medio.reload.multiplier
  end

  test "el tiempo de referencia no se puede cambiar desde el admin" do
    sign_in_as users(:admin)
    patch admin_difficulty_setting_path(@medio),
          params: { difficulty_setting: { multiplier: "2", reference_seconds: 10 } }

    assert_equal 180, @medio.reload.reference_seconds
  end
end
