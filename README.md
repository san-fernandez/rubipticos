# Rubípticos

Sitio web para jugar crípticos: acertijos de palabras en español en los que una frase esconde una palabra detrás de un juego de palabras. Trabajo Final Integrador de TTPS Opción Ruby (UNLP, 2026).

Por ejemplo, en «Pato rosado esconde un animal de las corridas (4)» la definición es «un animal de las corridas», el indicador «esconde» dice que la respuesta está oculta y el material es «Pato rosado»: pa**TO RO**sado → **TORO**.

## Integrantes

| Integrante | Área |
| --- | --- |
| Persona 1 — _(nombre)_ ([@san-fernandez](https://github.com/san-fernandez)) | Catálogo y sincronización con la API |
| Persona 2 — _(nombre)_ | Partida y Críptico del día |
| Persona 3 — _(nombre)_ | Puntaje, rachas, tabla de posiciones, estadísticas y Compartir |
| Persona 4 — _(nombre)_ ([@ignagallardo](https://github.com/ignagallardo)) | Proyecto base, autenticación y permisos, backend de usuarios y jugadores, identidad del jugador, layouts, chatbot y README |

## Qué tiene

**Sitio público** (sin cuenta: el jugador entra solo con un nombre)

- **Jugar**: un críptico al azar de la dificultad elegida, con cronómetro, hasta 5 intentos y hasta 4 pistas.
- **Críptico del día**: el mismo para todos, vale el doble.
- **Mi racha**: días seguidos con al menos un críptico resuelto.
- **Tabla de posiciones**.
- **Cómo se juega**: un chatbot guiado que explica las reglas, disponible desde cualquier página, y una página con las mismas reglas.
- Tema claro u oscuro.

**Backend** (`/admin`, con email y contraseña)

- **Administrador**: catálogo de crípticos, sincronización, usuarios del backend, jugadores y términos bloqueados, reinicio de la tabla de posiciones, configuración general y puntajes.
- **Editor de puntajes**: solo los puntos por tipo y los multiplicadores por dificultad.

## Requisitos

| Herramienta | Versión |
| --- | --- |
| Ruby | 3.3.14 (ver `.ruby-version`) |
| Rails | 8.1 |
| Node.js | 22.12 o más (ver `.node-version`) |
| Yarn | 1.22 |
| SQLite | 3 |

Node y Yarn hacen falta porque Bootstrap se compila con `cssbundling-rails`.

## Cómo levantarlo

### Linux y macOS

Con Ruby instalado con un gestor de versiones (rbenv, asdf o mise), que lee `.ruby-version` solo:

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

`db:setup` carga el catálogo de crípticos por HTTP desde la API de la cátedra, así que necesita conexión a internet. Deja el sistema listo para jugar: usuarios de prueba, configuración y catálogo sincronizado.

Para volver a empezar con la base limpia: `bin/rails db:reset`.

### Windows

Recomendamos **WSL2** con Ubuntu: Rails, SQLite y `bin/dev` funcionan igual que en Linux.

1. En PowerShell como administrador: `wsl --install -d Ubuntu` y reiniciar.
2. Dentro de Ubuntu, instalar las dependencias del sistema:

   ```bash
   sudo apt update
   sudo apt install -y build-essential git curl libssl-dev libyaml-dev zlib1g-dev libsqlite3-dev sqlite3
   ```

3. Instalar Ruby 3.3.14 y Node 22 con un gestor de versiones. Por ejemplo, con [mise](https://mise.jdx.dev):

   ```bash
   curl https://mise.run | sh
   echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc && source ~/.bashrc
   mise use -g ruby@3.3.14 node@22
   corepack enable    # deja disponible yarn
   ```

4. Clonar el repositorio **dentro de WSL** (por ejemplo en `~/rubipticos`, no en `/mnt/c/...`, que es mucho más lento) y seguir los pasos de Linux.

La aplicación se abre desde el navegador de Windows en http://localhost:3000.

## Usuarios de prueba

Los crea `db/seeds.rb`. No hay registro público de usuarios del backend.

| Rol | Email | Contraseña |
| --- | --- | --- |
| Administrador | `admin@rubipticos.test` | `rubipticos2026` |
| Editor de puntajes | `editor@rubipticos.test` | `editor2026` |

Para crear otro administrador sin entrar a la interfaz:

```bash
bin/rails admin:create EMAIL=yo@ejemplo.com PASSWORD=secreto123
```

## Catálogo de crípticos

El catálogo se sincroniza desde una API JSON. La URL se configura desde el backend (`/admin/setting/edit`); por defecto es la de la cátedra:
`https://ecorrons.github.io/cryptics-api/v1/cryptics.json`.

Otras fuentes posibles (cambiando la URL en la configuración):

- **Catálogo con errores**, para ver cómo se informan los rechazados: `https://ecorrons.github.io/cryptics-api/v1/cryptics_with_errors.json`.
- **Un fork propio** de [cryptics-api](https://github.com/ecorrons/cryptics-api) publicado en GitHub Pages: `https://<usuario>.github.io/cryptics-api/v1/cryptics.json`.
- **Servidor local**, para trabajar sin conexión, desde una copia de [cryptics-api](https://github.com/ecorrons/cryptics-api):

  ```bash
  gem install webrick
  cd cryptics-api && ruby -run -e httpd . -p 8000
  # URL: http://localhost:8000/v1/cryptics.json
  ```

El juego siempre lee los crípticos de la base; la API solo se consulta al sincronizar (botón «Sincronizar ahora» en `/admin/syncs`, o `db:seed`).

## Tests

```bash
bin/rails test
bin/rubocop
```

Si la versión de Node instalada es más vieja que la de `.node-version`, los tests se pueden correr sin compilar el CSS: `SKIP_CSS_BUILD=1 bin/rails test`.

## Organización del código

| Dónde | Qué hay |
| --- | --- |
| `app/models` | Reglas y validaciones (`Cryptic`, `Player`, `User`, `Setting`, `BlockedName`, …) y `ChatbotTree`, que lee los nodos del chatbot |
| `app/services` | Lógica entre modelos, con un método de clase `call` (`TextNormalizer`, `CrypticSynchronizer`, …) |
| `app/controllers/public_controller.rb` | Base de todo el sitio público: permite entrar sin login e incluye `CurrentPlayer` |
| `app/controllers/admin/base_controller.rb` | Base del backend: layout propio, usuario activo y permisos de admin |
| `app/controllers/concerns/current_player.rb` | `current_player` y `require_player`, a partir de la cookie firmada |
| `app/javascript/controllers` | Controladores Stimulus (solo comportamiento visual, como el tema) |
| `config/chatbot.yml` | Los nodos del chatbot |
| `db/seeds.rb` | Carga inicial: usuarios y configuración, puntajes y catálogo, en ese orden |

## Decisiones de diseño

- El código (clases, tablas, columnas) está en inglés para evitar problemas con los plurales de Rails; la interfaz, en español.
- Zona horaria `America/Argentina/Buenos_Aires`: "hoy" se calcula siempre con `Date.current` y `Time.current`.
- Las reglas se validan en el modelo **y** en la base (`null: false`, valores por defecto, índices únicos, claves foráneas y restricciones `CHECK`), así un dato inválido no entra ni por la consola.
- Nada se borra si tiene historia: los crípticos que salen de la fuente y los usuarios del backend se **desactivan**; los jugadores bloqueados conservan sus partidas.
- La configuración general (`Setting`) tiene una sola fila, a la que se accede con `Setting.current`.
- Sin frameworks de frontend: Turbo Frames y Streams para actualizar partes de la página y Stimulus solo para lo visual.

### Backend y permisos

- Los permisos del backend se controlan en el servidor, en `Admin::BaseController`: un usuario desactivado pierde la sesión, y uno que no es admin no entra a las secciones de admin aunque escriba la URL a mano (vuelve al panel con un aviso). Ocultar los links del menú no alcanza. Los controladores de puntajes son los únicos que dejan pasar al editor (`skip_before_action :require_admin!`). Elegimos `before_action` en lugar de cancancan porque con dos roles y una sola excepción alcanza, y se lee en un solo archivo.
- Los roles se validan en el modelo (`enum`) y en la base (restricción `CHECK`).
- Los usuarios del backend no se borran ni tienen página de detalle (`resources :users, except: %i[show destroy]`): se desactivan desde la edición. Al desactivar a un usuario se cierran sus sesiones abiertas y ya no puede volver a entrar.
- No se puede desactivar ni pasar a editor al último admin activo, ni a uno mismo, para que el sistema nunca quede sin nadie que lo administre.
- **Recuperar contraseña:** se conservó el flujo que genera Rails («¿Olvidaste tu contraseña?»), pero no hay un servidor de mails configurado: en desarrollo el mail no se envía y queda en `log/development.log`. En la práctica, un admin le asigna una contraseña nueva a otro usuario desde la edición de usuarios.
- **Reiniciar la tabla de posiciones** no borra partidas: guarda la fecha en `Setting#leaderboard_reset_at` y la tabla solo cuenta las partidas resueltas después. Así no se pierden la historia de los jugadores, sus rachas ni las estadísticas de cada críptico.

### Jugadores

- El jugador no tiene cuenta: el navegador solo guarda su token, en una cookie firmada, permanente y `httponly`. Si alguien la edita, la firma no coincide y se descarta. Si se borran las cookies, se empieza de cero.
- El nombre tiene de 3 a 20 caracteres y es único sin distinguir mayúsculas, en el modelo y en la base (índice único sobre `lower(name)`). Si está ocupado, se sugiere una variante libre. Cambiar el nombre conserva las partidas, la racha y los puntos.
- «Empezar como otro jugador» borra la cookie, no el registro: el jugador anterior sigue en la base y en la tabla de posiciones.
- **Términos bloqueados por «contiene»:** un nombre se rechaza si contiene un término bloqueado, sin distinguir mayúsculas. Bloquear `tonto` también rechaza `ElTonto99`. Elegimos «contiene» en lugar de «es igual» porque con la igualdad alcanza con agregar un número o una letra para esquivar el bloqueo.
- **Jugador bloqueado:** no aparece en la tabla de posiciones y, para seguir jugando, tiene que cambiar el nombre. Se desbloquea solo si elige un nombre distinto (sin contar mayúsculas ni espacios en los bordes) que pase las validaciones, incluidos los términos bloqueados. Sus partidas, racha y puntos se conservan. Desde el admin se puede bloquear al jugador y agregar su nombre a los términos bloqueados en un solo paso.

### Chatbot «Cómo se juega»

- Es un chatbot **guiado**, sin IA: cada nodo tiene un mensaje y botones que llevan a otros nodos. Recorre qué es un críptico, las partes de un enunciado, un nodo por cada uno de los 13 tipos (con un ejemplo), el puntaje, las pistas, los intentos y las rachas.
- Los nodos están en `config/chatbot.yml` y no en la base: son contenido fijo que cambia junto con las reglas del juego, así que va versionado con el código y no hace falta un ABM. `ChatbotTree` lo carga una vez, lo congela y agrega «Volver al menú» a todos los nodos salvo la bienvenida.
- Se abre desde «Cómo se juega» en el menú o desde un botón flotante, en un panel lateral (offcanvas de Bootstrap) que está en todas las páginas públicas. La conversación avanza dentro de un Turbo Frame, sin recargar la página.
- El nodo actual se guarda en la sesión de Rails (`session[:chatbot_node]`), nunca en la cookie del jugador: es estado de navegación, no identidad. Si se cierra el panel o se cambia de página, al volver a abrirlo sigue donde estaba.
- Los ejemplos son inventados: un test verifica que ninguna respuesta de ejemplo coincida con la de un críptico activo del catálogo. Las soluciones están escondidas hasta que el jugador las pide. Otros tests verifican que todos los destinos existen y que hay un nodo por cada tipo de `Cryptic::TYPES`.
- La página `/como-se-juega` arma las reglas con el mismo YAML, así el chatbot y la página nunca se contradicen.

### Tema oscuro

- Es una preferencia visual, así que se guarda en `localStorage` con un controlador Stimulus (`theme_controller.js`) y el atributo `data-bs-theme` de Bootstrap. Si no hay preferencia guardada, se usa la del sistema. Es lo único que guarda el navegador además del token del jugador.

### Partida

- _(A completar por Persona 2: qué pasa al agotar los 5 intentos, cómo se elige el críptico al azar y el Críptico del día, y cómo se mide el tiempo.)_
- La respuesta correcta nunca viaja al navegador antes de resolver o rendirse. El tiempo y los puntos se calculan en el servidor; el cronómetro en pantalla es solo visual.

### Puntaje, rachas y tabla de posiciones

- _(A completar por Persona 3.)_
- Cada partida guarda sus puntos al resolverse: cambiar los puntajes o los multiplicadores desde el admin no recalcula las partidas anteriores.
- Un día cuenta para la racha si se resolvió al menos un críptico; rendirse no suma. La racha se corta si el último día resuelto es anterior a ayer.

### Catálogo y sincronización

- La sincronización es un servicio (`CrypticSynchronizer`), no lógica del controlador. La usan el admin y el seed.
- Si falla la red, la fuente responde con error o el JSON no sirve, no se toca la base y se registra la sincronización como fallida con el motivo.
- Es idempotente: si la versión del catálogo es la misma que la de la última sincronización exitosa, informa «Sin cambios». Cada críptico se busca por su id de la fuente, que es único en la base, así que nunca se duplica.
- Un críptico inválido se saltea y se informa con su id y el motivo; los demás se procesan igual. Si un id aparece dos veces en la fuente, se rechaza la segunda aparición.
- Si un críptico que ya estaba en la base viene inválido, conserva su versión anterior y sigue activo, porque vino en la fuente.
- Los crípticos que ya no vienen en la fuente se desactivan, nunca se borran (pueden tener partidas). Los que vienen en la fuente quedan activos: si uno había desaparecido y vuelve, se reactiva. Por eso, si el admin desactiva a mano un críptico que sigue en la fuente, la próxima sincronización con una versión nueva lo vuelve a activar.
- El Críptico del día sigue la recomendación de la cátedra: el admin reserva crípticos con la marca local `daily_candidate` (botón «Reservar para el día» en `/admin/cryptics`). Esa marca no viene en el JSON de la API y el sincronizador solo escribe los campos de la API, así que nunca la pisa. Los reservados no salen en las partidas comunes (`Cryptic.regular`) y el del día se elige entre ellos (`Cryptic.daily_candidates`), así nadie lo juega antes de tiempo.
- El origen de cada críptico es el host de la URL desde la que se sincronizó (por ejemplo `ecorrons.github.io` o `localhost:8000`). Sirve para distinguir el catálogo de la cátedra de un fork o de un servidor local. Si el mismo id llega después desde otra URL, se actualiza el mismo críptico y su origen pasa a ser el nuevo.
- Para no sincronizar dos veces lo mismo, se compara la versión **y** la URL con las de la última sincronización exitosa (`Setting#last_synced_version` y `Setting#last_synced_url`). Si cambia cualquiera de las dos (por ejemplo, el admin apunta a un fork con la misma versión), se vuelve a sincronizar.
- Un críptico que el admin desactivó a mano y sigue viniendo en la fuente se reactiva en la próxima sincronización con cambios: la fuente manda.
- Validaciones de un críptico, en el modelo y en la base: campos obligatorios, tipo y dificultad dentro de los valores definidos, enumeración igual al largo de la respuesta (sin contar tildes ni espacios) y cada definición, indicador y material escrito tal cual en el enunciado. Además, según el tipo: la doble definición tiene 2 definiciones; en la oculta, la respuesta está dentro del material; en el anagrama, el material tiene las mismas letras; en iniciales y finales, las primeras o últimas letras de las palabras del material forman la respuesta, sin contar palabras de unión como «y».
- Las respuestas se comparan normalizadas con `TextNormalizer`: sin tildes, mayúsculas, espacios ni signos. La Ñ se distingue de la N.
