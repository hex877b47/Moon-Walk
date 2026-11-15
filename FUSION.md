# Fusión: tu proyecto + lo de tu compañero (llamaradas NASA, mensajes, minerales)

## 1. Antes de copiar
- BORRA los 3 archivos basura de la carpeta del proyecto de tu compañero (salieron de un comando mal escrito en la terminal; no los copies ni los subas a git):
    olar_wave.tscn project.godot
    sBar#Uf022 type=#Uf022ProgressBar#Uf022 parent=#Uf022WarningPanel#Uf022 unique_id=1658330198]
    elf, #Uf022position#Uf022, start_pos, 0.15)
- NO borres solar_flare.gd ni solar_wave.tscn (antes se recomendó borrarlos; ya no): son el sistema de llamaradas del compañero.

## 2. Copiar
Extrae este zip en la raíz del proyecto (junto a project.godot) y acepta sobrescribir:
  stats.gd, event_director.gd, hud.gd, time_manager.gd  -> fusionados (tu stats "realista" + su sistema de llamaradas)
  todo lo demás                                          -> archivos nuevos del compañero

## 3. En Godot (Project > Project Settings > Autoload)
  + Messages   -> res://messages.gd
  + Inventario -> res://inventario.gd      (Rock lo necesita; sin esto rock_m.gd da error)
Orden sugerido: TimeManager, Messages, Stats, EventBus, EventDirector, Inventario

## 4. Probar
F1 llamarada con aviso (barra + impacto) · F6 llamarada instantánea · F7 mensaje de llamarada ·
Bloq Mayús mensaje de mineral · F2 EVA · F3 refugio · F4 tiempo x1/x5/x10 · F5 romper un módulo

## Qué se unió y cómo
- esenario1.tscn: idéntico en las dos versiones (mismos tiles y colisiones); no se toca.
- time_manager.gd: + get_total_minutes() y real_second_to_game_minutes() (las usa solar_flare.gd).
- stats.gd: + spawn_flare_event(), _load_flares(), flare_pool; trigger_flare(mult) ahora fija la
  intensidad de la llamarada (flare_intensity) dentro de tu modelo de dosis en mSv.
- event_director.gd: las llamaradas (día 2 y aleatorias) pasan por spawn_flare_event().
- hud.gd: F1 = con aviso (como en su versión); F6 = instantánea; F7 y Bloq Mayús de su versión.
