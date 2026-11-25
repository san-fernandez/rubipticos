# frozen_string_literal: true

require "test_helper"

class ChatbotTreeTest < ActiveSupport::TestCase
  test "todo destino del YAML existe como nodo" do
    ChatbotTree.nodes.each_value do |node|
      node.options.each do |option|
        assert_includes ChatbotTree.ids, option.target, "#{node.id} lleva a #{option.target}, que no existe"
      end
    end
  end

  test "hay un nodo por cada tipo de juego de palabras" do
    Cryptic::TYPES.each do |type|
      assert_includes ChatbotTree.ids, "type_#{type}"
    end
    assert_equal Cryptic::TYPES.size, ChatbotTree.type_nodes.size
  end

  test "tiene los nodos del recorrido mínimo" do
    %w[welcome what_is parts types scoring hints streaks].each do |id|
      assert_includes ChatbotTree.ids, id
    end
  end

  test "ningún ejemplo es un críptico activo de la base" do
    active_answers = Cryptic.active.pluck(:answer).map { |answer| TextNormalizer.call(answer) }

    example_answers.each do |node_id, answer|
      assert_not_includes active_answers, TextNormalizer.call(answer), "el ejemplo de #{node_id} es del catálogo"
    end
  end

  test "ningún ejemplo es un críptico del catálogo de la cátedra" do
    catalog = JSON.parse(file_fixture("cryptics.json").read).fetch("cripticos")
    catalog_answers = catalog.map { |cryptic| TextNormalizer.call(cryptic.fetch("respuesta")) }

    example_answers.each do |node_id, answer|
      assert_not_includes catalog_answers, TextNormalizer.call(answer), "el ejemplo de #{node_id} es del catálogo"
    end
  end

  test "la enumeración de cada ejemplo coincide con el largo de su respuesta" do
    ChatbotTree.nodes.each_value do |node|
      next unless node.example_answer && (enumeration = node.example[/\((\d+)\)\z/, 1])

      assert_equal enumeration.to_i, TextNormalizer.call(node.example_answer).length, "enumeración de #{node.id}"
    end
  end

  test "todos los nodos salvo la bienvenida tienen Volver al menú" do
    ChatbotTree.nodes.each_value do |node|
      back = node.options.any? { |option| option.target == ChatbotTree::ROOT && option.text == "Volver al menú" }

      assert_equal !node.root?, back, node.id
    end
  end

  test "un id desconocido devuelve la bienvenida" do
    assert_equal "welcome", ChatbotTree.node("no-existe").id
    assert_equal "welcome", ChatbotTree.node(nil).id
  end

  test "los nodos están congelados" do
    assert ChatbotTree.nodes.frozen?
    assert ChatbotTree.node("types").options.frozen?
  end

  private

  def example_answers
    ChatbotTree.nodes.values.filter_map { |node| [ node.id, node.example_answer ] if node.example_answer }
  end
end
