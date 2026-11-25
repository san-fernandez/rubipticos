# frozen_string_literal: true

# Chatbot guiado de "Cómo se juega" (sin IA: nodos fijos en config/chatbot.yml).
# Cada opción es un link a este mismo show con ?node=<destino>; como la vista
# va dentro de un Turbo Frame, la conversación avanza sin recargar la página.
#
# El nodo actual se guarda en la sesión de Rails (session[:chatbot_node]),
# nunca en la cookie del jugador: así, al reabrir el panel, sigue donde estaba.
class ChatbotsController < PublicController
  def show
    @node = ChatbotTree.node(params[:node].presence || session[:chatbot_node])
    session[:chatbot_node] = @node.id
  end
end
