# AI_TRACE

- Tarea: conectar los botones Play y X del menú y habilitar el acceso al mapa.
- Archivos: `scenes/menu.gd`, `project.godot`, `logica/personajes/jugador/jugador.gd`, `AI_TRACE.md`.
- Resumen: se configuró el menú como escena inicial, Play carga `res://logica/mapa_1.tscn` y X cierra el juego. Se corrigieron errores de sintaxis del script del jugador para permitir cargar el mapa.
- Limitaciones: EVENT_ID, TEAM_ID y PARTICIPANT_ID no fueron proporcionados. Las animaciones `walk`, `stay` y `punch` no están definidas en los recursos de sprites actuales; el movimiento usa `default` como alternativa y el ataque queda inactivo hasta que exista `punch`.
