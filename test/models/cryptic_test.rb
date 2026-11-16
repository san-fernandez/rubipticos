# frozen_string_literal: true

require "test_helper"

class CrypticTest < ActiveSupport::TestCase
  def build(**attrs)
    Cryptic.new(source_id: "cr-900", statement: "Amor loco da una fruta del bosque", enumeration: "(4)",
                answer: "MORA", definitions: [ "una fruta del bosque" ], indicators: [ "loco" ],
                material: [ "Amor" ], cryptic_type: "anagrama", difficulty: "facil", **attrs)
  end

  test "los fixtures son válidos" do
    assert cryptics(:camisa).valid?
    assert cryptics(:mate).valid?
    assert cryptics(:gato_inactivo).valid?
  end

  test "exige los campos obligatorios" do
    cryptic = Cryptic.new

    assert_not cryptic.valid?
    %i[source_id statement answer enumeration].each { |field| assert cryptic.errors[field].any?, field }
  end

  test "el tipo y la dificultad tienen que ser valores conocidos" do
    cryptic = build(cryptic_type: "palindromo", difficulty: "experto")

    assert_not cryptic.valid?
    assert cryptic.errors[:cryptic_type].any?
    assert cryptic.errors[:difficulty].any?
  end

  test "la base rechaza un tipo desconocido aunque se saltee la validación" do
    assert_raises(ActiveRecord::StatementInvalid) { cryptics(:mate).update_column(:cryptic_type, "palindromo") }
  end

  test "el source_id es único en el modelo y en la base" do
    assert_not build(source_id: "cr-013").valid?
    assert_raises(ActiveRecord::RecordNotUnique) { build(source_id: "cr-013").save(validate: false) }
  end

  test "la enumeración tiene que coincidir con el largo sin tildes" do
    assert build(answer: "Móra").valid?
    assert_not build(enumeration: "(5)").valid?
  end

  test "la enumeración con varias palabras suma las partes" do
    cryptic = build(cryptic_type: "charada", enumeration: "(2,2)")

    assert cryptic.valid?, cryptic.errors.full_messages.to_sentence
  end

  test "cada fragmento tiene que aparecer en el enunciado" do
    cryptic = build(definitions: [ "una planta" ])

    assert_not cryptic.valid?
    assert_includes cryptic.errors[:statement], "no contiene «una planta»"
  end

  test "anagrama: el material tiene las mismas letras que la respuesta" do
    assert build.valid?
    assert_not build(answer: "MOR", enumeration: "(3)").valid?
  end

  test "oculta: la respuesta está escrita de corrido en el material" do
    assert cryptics(:mate).valid?

    cryptic = cryptics(:mate)
    cryptic.answer = "TOMA"
    assert_not cryptic.valid?
  end

  test "doble definición: exactamente dos definiciones" do
    cryptic = cryptics(:gato_inactivo)
    cryptic.definitions = [ "Felino" ]

    assert_not cryptic.valid?
    assert cryptic.errors[:definitions].any?
  end

  test "iniciales: las primeras letras forman la respuesta" do
    cryptic = build(statement: "Al principio, ocho sapos observan un animal peludo", enumeration: "(3)", answer: "OSO",
                    definitions: [ "un animal peludo" ], indicators: [ "Al principio" ],
                    material: [ "ocho sapos observan" ], cryptic_type: "iniciales")
    assert cryptic.valid?, cryptic.errors.full_messages.to_sentence

    cryptic.material = [ "ocho sapos" ]
    assert_not cryptic.valid?
  end

  test "finales: las últimas letras forman la respuesta, sin contar palabras de unión" do
    cryptic = build(statement: "Colas de álbum, casa y amor dan agua salada", enumeration: "(3)", answer: "MAR",
                    definitions: [ "agua salada" ], indicators: [ "Colas de" ],
                    material: [ "álbum, casa y amor" ], cryptic_type: "finales")

    assert cryptic.valid?, cryptic.errors.full_messages.to_sentence
  end

  test "los filtros con valor vacío no filtran" do
    assert_equal Cryptic.count, Cryptic.by_difficulty("").by_type(nil).by_status("").by_origin(nil).count
  end

  test "filtra por estado, dificultad, tipo y origen" do
    assert_equal [ cryptics(:gato_inactivo) ], Cryptic.by_status("inactivos").to_a
    assert_equal [ cryptics(:camisa) ], Cryptic.by_difficulty("medio").to_a
    assert_equal [ cryptics(:mate) ], Cryptic.by_type("oculta").to_a
    assert_equal [ cryptics(:gato_inactivo) ], Cryptic.by_origin("localhost").to_a
  end
end
