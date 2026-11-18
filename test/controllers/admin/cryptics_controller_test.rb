# frozen_string_literal: true

require "test_helper"

class Admin::CrypticsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "lista todos los crípticos" do
    get admin_cryptics_path

    assert_response :success
    assert_select "tbody tr", Cryptic.count
  end

  test "filtra por dificultad, tipo, estado y origen" do
    get admin_cryptics_path, params: { difficulty: "medio" }
    assert_select "tbody tr", 1
    assert_select "tbody", /cr-013/

    get admin_cryptics_path, params: { cryptic_type: "oculta" }
    assert_select "tbody", /cr-001/

    get admin_cryptics_path, params: { status: "inactivos" }
    assert_select "tbody tr", 1
    assert_select "tbody", /cr-009/

    get admin_cryptics_path, params: { origin: "localhost" }
    assert_select "tbody tr", 1

    get admin_cryptics_path, params: { daily: "reservados" }
    assert_select "tbody tr", 1
    assert_select "tbody", /cr-001/
  end

  test "muestra el detalle" do
    get admin_cryptic_path(cryptics(:camisa))

    assert_response :success
    assert_select "dd", "CAMISA"
  end

  test "desactiva y activa un críptico" do
    cryptic = cryptics(:camisa)

    patch admin_cryptic_path(cryptic), params: { cryptic: { active: false } }
    assert_redirected_to admin_cryptic_path(cryptic)
    assert_not cryptic.reload.active?

    patch admin_cryptic_path(cryptic), params: { cryptic: { active: true } }
    assert cryptic.reload.active?
  end

  test "reserva un críptico para el Críptico del día y lo vuelve común" do
    cryptic = cryptics(:camisa)

    patch admin_cryptic_path(cryptic), params: { cryptic: { daily_candidate: true } }
    assert_redirected_to admin_cryptic_path(cryptic)
    assert_equal "El críptico cr-013 quedó reservado para el Críptico del día.", flash[:notice]
    assert cryptic.reload.daily_candidate?

    patch admin_cryptic_path(cryptic), params: { cryptic: { daily_candidate: false } }
    assert_not cryptic.reload.daily_candidate?
  end

  test "solo se puede cambiar el estado, no el contenido" do
    cryptic = cryptics(:camisa)

    patch admin_cryptic_path(cryptic), params: { cryptic: { active: true, answer: "OTRA" } }

    assert_equal "CAMISA", cryptic.reload.answer
  end

  test "un editor de puntajes no puede entrar aunque escriba la URL" do
    sign_in_as users(:editor)

    get admin_cryptics_path
    assert_redirected_to admin_root_path

    patch admin_cryptic_path(cryptics(:camisa)), params: { cryptic: { active: false, daily_candidate: true } }
    assert_redirected_to admin_root_path
    assert cryptics(:camisa).reload.active?
    assert_not cryptics(:camisa).daily_candidate?
  end
end
