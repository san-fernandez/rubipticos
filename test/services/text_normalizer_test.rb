# frozen_string_literal: true

require "test_helper"

class TextNormalizerTest < ActiveSupport::TestCase
  test "saca tildes, mayúsculas y espacios" do
    [ "jamon", "Jamón", " JAMÓN " ].each do |text|
      assert_equal "JAMON", TextNormalizer.call(text)
    end
  end

  test "saca signos de puntuación y espacios intermedios" do
    assert_equal "GIRASOL", TextNormalizer.call("¡Gira sol!")
  end

  test "la diéresis cuenta como u" do
    assert_equal "PINGUINO", TextNormalizer.call("pingüino")
  end

  test "la Ñ se conserva y es distinta de la N" do
    assert_equal "AÑO", TextNormalizer.call("año")
    assert_not_equal TextNormalizer.call("año"), TextNormalizer.call("ano")
  end

  test "nil da un texto vacío" do
    assert_equal "", TextNormalizer.call(nil)
  end
end
