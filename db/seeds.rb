# frozen_string_literal: true

# Carga inicial: bin/rails db:setup (o db:seed) deja el sistema listo.
# Es idempotente: se puede correr varias veces sin duplicar nada.
# Orden: usuarios y configuración → puntajes → sincronización del catálogo.

# --- Usuarios del backend y configuración general ---
# Credenciales de prueba (documentadas en el README). No hay registro público.
admin = User.find_or_create_by!(email_address: "admin@rubipticos.com") do |user|
  user.password = "admin1234"
  user.role = "admin"
end

User.find_or_create_by!(email_address: "editor@rubipticos.com") do |user|
  user.password = "editor1234"
  user.role = "score_editor"
end

Setting.current

puts "Admin de prueba: #{admin.email_address} / admin1234"
