# Fusión Moon-Walk (Eugenio + compañero)

Base: el proyecto de Eugenio (sin tocar: mapa "hielo", player, estaciones, menús, EventDirector, balance realista).
Aportes del compañero: llamaradas reales NASA (DONKI), sistema de mensajes y minerales/rocas.

## Cambios respecto a tu proyecto
- project.godot: autoloads nuevos `Messages` e `Inventario`. Orden: TimeManager, EventBus, Messages, Stats, EventDirector.
  (Inventario va después de Messages y antes de Stats solo por orden; no depende de nadie.)
- stats.gd: + flare_pool, _load_flares(), spawn_flare_event() (llamarada con aviso, usa solar_wave.tscn),
  trigger_flare(mult) ahora recibe la intensidad (clase C/M/X) y la aplica dentro de tu modelo de dosis (mSv).
  reset() limpia la llamarada activa.
- event_director.gd: las llamaradas (día 2 y aleatorias) usan spawn_flare_event(); si no se puede, cae al aviso simple de antes.
- time_manager.gd: + get_total_minutes() y real_second_to_game_minutes() (los usa solar_flare.gd).
- hud.gd: F1 = llamarada con aviso · F6 = instantánea · F7 = mensaje de llamarada · Bloq Mayús = mensaje de mineral.
- Rock.tscn: reemplazado por la roca real del compañero (la tuya estaba vacía).

## Alertas (UI)
- Tus alertas (UI/Message en main.tscn) ahora tienen fondo oscuro con borde, igual que los mensajes del compañero; se ocultan cuando no hay texto.
- El aviso de llamarada (solar_wave.tscn) pasó abajo al centro, justo encima de tus alertas, con barra redondeada que cambia de verde a rojo.
- Los mensajes educativos (messages.gd) suben más arriba para no encimarse con ninguno de los dos.

## Archivos del compañero que ya estaban en tu carpeta y se conservan
flare_data.gd, info_message.gd, messages.gd, mineral_data.gd, rock_m.gd, solar_flare.gd, solar_wave.tscn,
Ilmenita.tres, armalcolita.tres, plagiocasa.tres, data/flares.json, moon base/Rock.M.png

## NO copiado (basura del compañero)
Los 3 archivos de nombres raros (olar_wave.tscn project.godot, sBar#Uf022..., elf, #Uf022position...).
Su esenario1.tscn tampoco: es el mapa viejo; el tuyo ya tiene "mapa hielo".
Su stats.gd/hud.gd/time_manager.gd tampoco: eran la versión simple que tu balance reemplaza.

## Pendiente (no hecho)
- Las rocas todavía no están colocadas en main.tscn ni el jugador las puede minar (rock.hit()). Solo existe la tecla de depuración.
- Probar en Godot 4.7: no pude ejecutar el juego aquí.
