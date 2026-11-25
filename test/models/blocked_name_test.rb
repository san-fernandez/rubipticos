# frozen_string_literal: true

require "test_helper"

class BlockedNameTest < ActiveSupport::TestCase
  test "guarda el término sin espacios y en minúsculas" do
    assert_equal "feo", BlockedName.new(term: "  FEO ").term
  end

  test "el término es obligatorio y único" do
    assert_not BlockedName.new(term: " ").valid?
    assert_not BlockedName.new(term: "TONTO").valid?
  end

  test "un nombre coincide si contiene un término, sin importar mayúsculas" do
    assert BlockedName.matches?("ElTONTO99")
    assert_not BlockedName.matches?("Pedrito")
    assert_not BlockedName.matches?(nil)
  end
end
