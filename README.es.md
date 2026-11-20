# instaprompt

Un gestor de prompts para bash, pequeño y sin dependencias. Clona el repo,
añade una línea a `~/.bashrc` y cambia de prompt al instante.

[English](README.md) | [Español](README.es.md)

## Por qué

- **Una línea para instalarlo.** Clonar, cargar, listo.
- **Cambio instantáneo.** El nombre del prompt activo se relee de un fichero
  de estado antes de *cada* prompt, así que `prompt-use compact` surte efecto
  en el siguiente comando — no hace falta reiniciar la terminal.
- **Los prompts son ficheros.** Un prompt es un `.sh` con unas cuantas
  variables. Escribe el tuyo en cinco líneas.
- **Sin subprocesos.** El camino de render usa solo builtins de bash, así que
  no cuesta nada por prompt.

## Instalación

```sh
git clone https://github.com/aognio/instaprompt.git ~/.instaprompt
```

Y añade esto al final de `~/.bashrc`:

```sh
[ -f "$HOME/.instaprompt/instaprompt.sh" ] && . "$HOME/.instaprompt/instaprompt.sh"
```

Abre una terminal nueva (o `source ~/.bashrc`) y ya está.

El instalador hace los dos pasos por ti:

```sh
git clone https://github.com/aognio/instaprompt.git && cd instaprompt && ./install.sh
```

## Uso

```sh
prompt-list          # qué hay disponible y cuál está activo
prompt-use compact   # cambiar
prompt-current       # imprime el activo
```

El cambio es instantáneo: el siguiente prompt que veas ya es el nuevo.

## Los prompts incluidos

| Prompt | Aspecto |
|---|---|
| `default` | El de reserva: `user@host` en verde, ruta en azul atenuado |
| `regular` | El clásico de Ubuntu |
| `minimal` | Solo la ruta |
| `compact` | Una línea densa |
| `two-line` | Identidad arriba, `❯` abajo |
| `clock` | El clásico con la hora delante |
| `nix` | Ruta, `❯` y la rama de git |
| `status` | El marcador se pone rojo si el último comando falló |
| `powerline` | Segmentos de color con separadores powerline |

## Escribe tu propio prompt

Deja un fichero en `~/.bash_prompts/`:

```sh
# @desc: mi prompt
PS1_COLOR='\[\033[01;36m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
PS1_PLAIN='\u@\h:\w\$ '
PROMPT_TITLE='\u@\h: \w'
```

| Variable | Significado |
|---|---|
| `PS1_COLOR` | el prompt, con color |
| `PS1_PLAIN` | el prompt, para terminales sin color |
| `PS1` | un prompt completo; tiene prioridad sobre los dos anteriores |
| `PROMPT_TITLE` | el título de la ventana/pestaña de la terminal |

Usa **comillas simples**: `\u`, `\w` y `\$` deben expandirse al dibujar el
prompt, no al leer el fichero.

El comentario `@desc:` es lo que muestra `prompt-list`.

Los ficheros de prompt se cargan justo antes de dibujar el prompt, así que
pueden mirar el estado de la shell. `__instaprompt_status` guarda el código
de salida del último comando:

```sh
if [ "${__instaprompt_status:-0}" -ne 0 ]; then
    # el comando anterior falló
fi
```

Ojo: un prompt que lance procesos (`git`, `docker`, ...) cuesta un fork por
prompt. El motor nunca lo hace.

## Cómo funciona

El valor del fichero de estado decide el prompt:

```
~/.current_bash_prompt          ->  ~/.bash_prompts/<valor>.sh
                                ->  ~/.instaprompt/prompts/<valor>.sh
                                ->  ~/.instaprompt/prompts/default.sh
                                ->  un prompt verde integrado
```

Un prompt en `~/.bash_prompts/` gana sobre uno del repo, así que puedes
sustituir cualquier ejemplo sin tocar el repositorio.

El motor se registra en `PROMPT_COMMAND`, que bash ejecuta antes de cada
prompt. Eso es lo que hace el cambio instantáneo. El hook:

- no pisa un `PROMPT_COMMAND` que ya exista — el tuyo corre primero;
- no se registra dos veces, aunque el fichero se cargue otra vez;
- admite las dos formas de `PROMPT_COMMAND`: cadena y array.

## Configuración

Todo se puede cambiar desde el entorno antes de cargar el fichero.

| Variable | Por defecto | Significado |
|---|---|---|
| `INSTAPROMPT_USER_DIR` | `~/.bash_prompts` | tus prompts; ganan |
| `INSTAPROMPT_DIR` | `<repo>/prompts` | los prompts del repo |
| `INSTAPROMPT_STATE` | `~/.current_bash_prompt` | el nombre del prompt activo |
| `INSTAPROMPT_COLOR` | `auto` | `auto`, `always` o `never` |

Con `auto` se usa color en cualquier terminal con un `TERM` de verdad, y se
descarta en las que tienen `TERM` vacío o `dumb`.

## Migrar desde un bloque de prompt en `~/.bashrc`

Si tu `~/.bashrc` ya tiene su propio bloque de prompt, quítalo y deja solo
la línea de instaprompt. Si no, dos motores escriben `PS1` en cada prompt y
se pelean por él: gana el que se registró el último, así que el síntoma es un
prompt que parpadea entre los dos.

La línea puede ir al final del `~/.bashrc`; no hace nada si el repo no está
instalado, así que es seguro versionarla.

## Tests

```sh
bash tests/run.sh
```

La batería ejecuta cada caso en una bash interactiva nueva contra un
directorio de estado en un sandbox, así que nunca toca tu `~/.bashrc` real.

## Licencia

Licencia MIT - Copyright (c) 2026 Antonio Ognio — ver [LICENSE](LICENSE).

Made with ❤️ from 🇵🇪. El Perú es clave 🔑.
