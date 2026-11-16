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

# --- Catálogo de crípticos ---
# Se carga con el mismo sincronizador que usa el admin, por HTTP (necesita internet,
# o que la URL de la configuración apunte a un servidor local).
log = CrypticSynchronizer.call(user: admin, url: Setting.current.source_url)
puts "Catálogo: #{log.summary}"
abort("No se pudo cargar el catálogo de crípticos.") if log.failed?
