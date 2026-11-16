# Rubípticos

Sitio web para jugar crípticos: acertijos de palabras en español en los que una frase esconde una palabra detrás de un juego de palabras. Trabajo Final Integrador de TTPS Opción Ruby (UNLP, 2026).

## Requisitos

| Herramienta | Versión |
| --- | --- |
| Ruby | 3.3.5 (ver `.ruby-version`) |
| Rails | 8.1 |
| Node.js | 22.12 o más (ver `.node-version`) |
| Yarn | 1.22 |
| SQLite | 3 |

Node y Yarn hacen falta porque Bootstrap se compila con `cssbundling-rails`.

## Cómo levantarlo

```bash
git clone git@github.com:san-fernandez/rubipticos.git
cd rubipticos
bin/setup        # instala gemas y paquetes, prepara la base, carga los seeds y levanta el servidor
```

O paso a paso:

```bash
bundle install
yarn install
bin/rails db:setup   # crea la base, carga el esquema y los seeds
bin/dev              # levanta Rails y el watcher de CSS
```

Después, abrir http://localhost:3000. El backend está en http://localhost:3000/admin.

## Usuarios de prueba

Los crea `db/seeds.rb`. No hay registro público de usuarios del backend.

| Rol | Email | Contraseña |
| --- | --- | --- |
| Administrador | `admin@rubipticos.com` | `admin1234` |
| Editor de puntajes | `editor@rubipticos.com` | `editor1234` |

## Tests

```bash
bin/rails test
bin/rubocop
```

## Decisiones de diseño

- El código (clases, tablas, columnas) está en inglés para evitar problemas con los plurales de Rails; la interfaz, en español.
- Zona horaria `America/Argentina/Buenos_Aires`: "hoy" se calcula siempre con `Date.current` y `Time.current`.
- Los permisos del backend se controlan en el servidor, en `Admin::BaseController`: un usuario desactivado pierde la sesión, y uno que no es admin no entra a las secciones de admin aunque escriba la URL a mano.
- Los roles se validan en el modelo (`enum`) y en la base (restricción `CHECK`). El nombre del jugador es único sin distinguir mayúsculas gracias a un índice único sobre `lower(name)`.
- La configuración general (`Setting`) tiene una sola fila, a la que se accede con `Setting.current`.
