# frozen_string_literal: true

# Crea un administrador sin pasar por la interfaz (no hay registro público).
#   bin/rails admin:create EMAIL=yo@ejemplo.com PASSWORD=secreto123
namespace :admin do
  desc "Crea un administrador: bin/rails admin:create EMAIL=x PASSWORD=y"
  task create: :environment do
    user = User.create!(email_address: ENV.fetch("EMAIL"), password: ENV.fetch("PASSWORD"), role: "admin")
    puts "Admin creado: #{user.email_address}"
  rescue KeyError
    abort "Faltan datos. Uso: bin/rails admin:create EMAIL=x PASSWORD=y"
  rescue ActiveRecord::RecordInvalid => e
    abort "No se pudo crear el admin: #{e.record.errors.full_messages.to_sentence}"
  end
end
