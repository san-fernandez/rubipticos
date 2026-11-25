# frozen_string_literal: true

# Página "Cómo se juega": las mismas reglas del chatbot, todas juntas.
# Sirve de respaldo sin JavaScript y para leer todo de corrido.
# Usa ChatbotTree, así el texto sale del mismo YAML que el chatbot.
class HelpController < PublicController
  SECTIONS = %w[what_is parts attempts hints scoring streaks daily].freeze

  def show
    @sections = SECTIONS.map { |id| ChatbotTree.node(id) }
    @type_nodes = ChatbotTree.type_nodes
  end
end
