# frozen_string_literal: true

# Base de todos los controladores del sitio público (juego, racha, tabla, etc.).
# Los jugadores no tienen cuenta, así que no se exige el login del backend.
# CurrentPlayer agrega current_player (puede ser nil) y require_player.
class PublicController < ApplicationController
  allow_unauthenticated_access
  include CurrentPlayer
end
