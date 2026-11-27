# frozen_string_literal: true

# Actualiza la racha de un jugador cuando RESUELVE un críptico y devuelve los
# días de racha contando hoy (ScoreCalculator los usa para el factor de racha).
# Lo llama Game#solve! (Persona 2), dentro de la misma transacción que guarda
# los puntos: si algo falla, la racha tampoco se guarda.
#
# Decisión del grupo: un día cuenta si el jugador resolvió al menos un críptico.
# Rendirse no pasa por acá, así que no suma.
class StreakUpdater
  def self.call(player:, date:)
    player.current_streak = new_streak(player, date)
    player.best_streak = [ player.best_streak, player.current_streak ].max
    player.last_solved_on = date
    player.save!

    player.current_streak
  end

  def self.new_streak(player, date)
    last_day = player.last_solved_on

    if last_day == date
      player.current_streak # ya resolvió hoy: la racha no cambia
    elsif last_day == date.yesterday
      player.current_streak + 1 # resolvió ayer: suma un día
    else
      1 # primera vez o se cortó la racha: empieza de nuevo
    end
  end
  private_class_method :new_streak
end
