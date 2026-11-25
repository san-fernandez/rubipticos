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

`db:setup` carga el catálogo de crípticos por HTTP desde la API de la cátedra, así que necesita conexión a internet.

## Catálogo de crípticos

El catálogo se sincroniza desde una API JSON. La URL se configura desde el backend; por defecto es la de la cátedra:
`https://ecorrons.github.io/cryptics-api/v1/cryptics.json`.

Otras fuentes posibles (cambiando la URL en la configuración):

- **Catálogo con errores**, para ver cómo se informan los rechazados: `https://ecorrons.github.io/cryptics-api/v1/cryptics_with_errors.json`.
- **Servidor local**, para trabajar sin conexión, desde una copia de [cryptics-api](https://github.com/ecorrons/cryptics-api):

  ```bash
  gem install webrick
  cd cryptics-api && ruby -run -e httpd . -p 8000
  # URL: http://localhost:8000/v1/cryptics.json
  ```

El juego siempre lee los crípticos de la base; la API solo se consulta al sincronizar (botón «Sincronizar ahora» en `/admin/syncs`, o `db:seed`).

## Usuarios de prueba

Los crea `db/seeds.rb`. No hay registro público de usuarios del backend.

| Rol | Email | Contraseña |
| --- | --- | --- |
| Administrador | `admin@rubipticos.test` | `rubipticos2026` |
| Editor de puntajes | `editor@rubipticos.test` | `editor2026` |

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

### Jugadores

- El jugador no tiene cuenta: el navegador solo guarda su token, en una cookie firmada, permanente y `httponly`. Si alguien la edita, la firma no coincide y se descarta. Si se borran las cookies, se empieza de cero.
- «Empezar como otro jugador» borra la cookie, no el registro: el jugador anterior sigue en la base y en la tabla de posiciones.
- **Términos bloqueados por «contiene»:** un nombre se rechaza si contiene un término bloqueado, sin distinguir mayúsculas. Bloquear `tonto` también rechaza `ElTonto99`. Elegimos «contiene» en lugar de «es igual» porque con la igualdad alcanza con agregar un número o una letra para esquivar el bloqueo.
- **Jugador bloqueado:** no aparece en la tabla de posiciones y, para seguir jugando, tiene que cambiar el nombre. Se desbloquea solo si elige un nombre distinto (sin contar mayúsculas ni espacios en los bordes) que pase las validaciones, incluidos los términos bloqueados. Sus partidas, racha y puntos se conservan.

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
