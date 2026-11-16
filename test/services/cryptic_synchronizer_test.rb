# frozen_string_literal: true

require "test_helper"

class CrypticSynchronizerTest < ActiveSupport::TestCase
  URL = "https://catalogo.test/v1/cryptics.json"

  setup do
    @admin = users(:admin)
    Cryptic.delete_all
  end

  def catalog_file(name) = file_fixture("#{name}.json").read

  def stub_catalog(body, status: 200)
    stub_request(:get, URL).to_return(status:, body:, headers: { "Content-Type" => "application/json" })
  end

  def item(id, **overrides)
    { "id" => id, "enunciado" => "Amor loco da una fruta del bosque", "enumeracion" => "(4)",
      "respuesta" => "MORA", "definiciones" => [ "una fruta del bosque" ], "indicadores" => [ "loco" ],
      "material" => [ "Amor" ], "tipo" => "anagrama", "dificultad" => "facil", "ayuda" => "Revolvé AMOR.",
      "explicacion" => "Anagrama de AMOR.", "autor" => "Cátedra" }.merge(overrides)
  end

  def sync = CrypticSynchronizer.call(user: @admin, url: URL)

  test "carga los 34 crípticos del catálogo real de la cátedra" do
    stub_catalog(catalog_file("cryptics"))

    log = sync

    assert log.ok?, log.summary
    assert_equal 34, log.created_count
    assert_equal 0, log.rejected_count
    assert_equal 34, Cryptic.active.count
    assert_equal @admin, log.user
    assert_equal "2026-10-26.1", Setting.current.last_synced_version
    assert_equal [ "catalogo.test" ], Cryptic.origins
  end

  test "con la misma versión informa sin cambios" do
    stub_catalog(catalog_file("cryptics"))
    sync

    log = sync

    assert log.unchanged?
    assert_equal 34, Cryptic.count
    assert_match "Sin cambios", log.summary
  end

  test "con una versión nueva actualiza solo los que cambiaron, sin duplicar" do
    stub_catalog({ version: "v1", cripticos: [ item("cr-1"), item("cr-2") ] }.to_json)
    sync
    stub_catalog({ version: "v2", cripticos: [ item("cr-1"), item("cr-2", "ayuda" => "Otra ayuda") ] }.to_json)

    log = sync

    assert_equal [ 0, 1 ], [ log.created_count, log.updated_count ]
    assert_equal 2, Cryptic.count
    assert_equal "Otra ayuda", Cryptic.find_by(source_id: "cr-2").help
  end

  test "desactiva los que ya no vienen en la fuente, sin borrarlos" do
    stub_catalog({ version: "v1", cripticos: [ item("cr-1"), item("cr-2") ] }.to_json)
    sync
    stub_catalog({ version: "v2", cripticos: [ item("cr-1") ] }.to_json)

    log = sync

    assert_equal 1, log.deactivated_count
    assert_not Cryptic.find_by(source_id: "cr-2").active?
  end

  test "reactiva un críptico que vuelve a aparecer en la fuente" do
    stub_catalog({ version: "v1", cripticos: [ item("cr-1") ] }.to_json)
    sync
    Cryptic.update_all(active: false)
    stub_catalog({ version: "v2", cripticos: [ item("cr-1") ] }.to_json)

    sync

    assert Cryptic.find_by(source_id: "cr-1").active?
  end

  test "el catálogo con errores informa cada rechazado con id y motivo, y procesa los demás" do
    stub_catalog(catalog_file("cryptics_with_errors"))

    log = sync

    assert log.ok?
    assert_equal 1, log.created_count
    assert_equal 6, log.rejected_count
    assert_equal %w[cr-102 cr-103 cr-104 cr-105 cr-101 cr-107], log.rejections.map { |rejection| rejection["id"] }
    assert_equal "el id está repetido en la fuente", log.rejections.find { |rejection| rejection["id"] == "cr-101" }["motivo"]
    assert_match "Enunciado no contiene «una planta»", log.rejections.last["motivo"]
  end

  test "un críptico existente que viene inválido conserva su versión anterior y sigue activo" do
    stub_catalog({ version: "v1", cripticos: [ item("cr-1") ] }.to_json)
    sync
    stub_catalog({ version: "v2", cripticos: [ item("cr-1", "respuesta" => "") ] }.to_json)

    log = sync

    assert_equal 1, log.rejected_count
    assert_equal 0, log.deactivated_count
    cryptic = Cryptic.find_by(source_id: "cr-1")
    assert_equal "MORA", cryptic.answer
    assert cryptic.active?
  end

  test "si se cae la red no toca la base e informa el error" do
    stub_request(:get, URL).to_timeout

    assert_no_difference -> { Cryptic.count } do
      log = sync
      assert log.failed?
      assert_match "No se pudo conectar", log.error_message
    end
    assert_nil Setting.current.last_synced_version
  end

  test "si la respuesta no es un JSON válido no toca la base" do
    stub_catalog("<html>no es json</html>")

    log = sync

    assert log.failed?
    assert_match "no es un JSON válido", log.error_message
    assert_equal 0, Cryptic.count
  end

  test "si la fuente responde con error HTTP lo informa" do
    stub_catalog("", status: 404)

    assert_match "404", sync.error_message
  end

  test "si al JSON le falta la versión o la lista lo informa" do
    stub_catalog({ cripticos: [] }.to_json)
    assert_match "versión", sync.error_message

    stub_catalog({ version: "v1" }.to_json)
    assert_match "lista de crípticos", sync.error_message
  end

  test "una URL inválida se informa sin hacer el pedido" do
    log = CrypticSynchronizer.call(user: @admin, url: "cryptics.json")

    assert log.failed?
    assert_match "URL de la fuente no es válida", log.error_message
  end

  test "usa un timeout de 10 segundos" do
    assert_equal 10, CrypticSynchronizer::TIMEOUT
  end
end
