# frozen_string_literal: true

# Simula un navegador que ya eligió nombre: pone el token del jugador en la
# cookie firmada, igual que CurrentPlayer#remember_player.
module PlayerTestHelper
  def sign_in_player(player)
    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[CurrentPlayer::COOKIE] = player.token
      cookies[CurrentPlayer::COOKIE.to_s] = cookie_jar[CurrentPlayer::COOKIE]
    end
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include PlayerTestHelper
end
