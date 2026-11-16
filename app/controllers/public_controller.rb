# frozen_string_literal: true

# Base de todos los controladores del sitio público (juego, racha, tabla, etc.).
# Los jugadores no tienen cuenta, así que no se exige el login del backend.
# Acá se va a incluir el concern CurrentPlayer (current_player, require_player).
class PublicController < ApplicationController
  allow_unauthenticated_access
end
