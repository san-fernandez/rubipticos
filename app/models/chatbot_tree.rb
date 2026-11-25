# frozen_string_literal: true

# Árbol de nodos del chatbot de "Cómo se juega". Es un PORO (objeto Ruby
# común, no ActiveRecord): lee config/chatbot.yml una sola vez, lo congela
# y responde qué dice cada nodo y adónde llevan sus opciones.
#
#   ChatbotTree.node("types").message
#   ChatbotTree.node("cualquier-cosa").id # => "welcome" (fallback)
class ChatbotTree
  PATH = Rails.root.join("config/chatbot.yml")
  ROOT = "welcome"
  BACK_TO_MENU = { text: "Volver al menú", target: ROOT }.freeze

  Option = Data.define(:text, :target)

  Node = Data.define(:id, :message, :example, :example_answer, :explanation, :options) do
    def root? = id == ChatbotTree::ROOT
  end

  class << self
    # Nodo pedido, o la bienvenida si el id no existe (por ejemplo, un id
    # viejo guardado en la sesión o uno escrito a mano en la URL).
    def node(id)
      nodes.fetch(id.to_s) { nodes.fetch(ROOT) }
    end

    def nodes
      @nodes ||= load_nodes
    end

    def ids
      nodes.keys
    end

    # Nodos de los tipos de juego de palabras, en el orden de Cryptic::TYPES.
    def type_nodes
      Cryptic::TYPES.filter_map { |type| nodes["type_#{type}"] }
    end

    # Para los tests y la consola: vuelve a leer el YAML.
    def reload!
      @nodes = nil
    end

    private

    def load_nodes
      YAML.load_file(PATH).to_h { |id, data| [ id, build_node(id, data) ] }.freeze
    end

    def build_node(id, data)
      options = Array(data["options"]).map { |option| Option.new(text: option["text"], target: option["target"]) }
      options << Option.new(**BACK_TO_MENU) unless id == ROOT

      Node.new(id:, message: data.fetch("message"), example: data["example"],
               example_answer: data["example_answer"], explanation: data["explanation"],
               options: options.freeze)
    end
  end
end
