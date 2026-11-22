# frozen_string_literal: true

# Marca local (no viene en el JSON de la API) con la que el admin reserva un
# críptico para el Críptico del día. El sincronizador no la toca.
class AddDailyCandidateToCryptics < ActiveRecord::Migration[8.1]
  def change
    add_column :cryptics, :daily_candidate, :boolean, null: false, default: false
  end
end
