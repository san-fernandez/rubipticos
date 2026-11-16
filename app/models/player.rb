# frozen_string_literal: true

# Jugador del sitio público. Se identifica con un token aleatorio que se
# guarda en una cookie firmada. Las reglas del nombre (largo, unicidad sin
# mayúsculas, nombres bloqueados) se agregan con la identidad del jugador.
class Player < ApplicationRecord
  has_secure_token :token
end
