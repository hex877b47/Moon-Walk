# Moon Walk – paquete "lo que falta" (sin pixel art)

Descomprime EN LA RAIZ del proyecto (junto a project.godot). Sobrescribe:
time_manager.gd, stats.gd, hud.gd. El resto son archivos nuevos.

## Pasos en Godot (2 min)
1. Project > Project Settings > Autoload. Deja este orden:
   EventBus, TimeManager, Stats, EventDirector
   (Quita GameClock: duplicaba a TimeManager.)
2. Borra solar_flare.gd y solar_wave.tscn: tenían un error (`gameclock`) y la llamarada ahora vive en EventDirector.
3. Project Settings > Application > Run > Main Scene = main.tscn
4. F5. Los cuadros de colores son las estaciones; muévelas en main.tscn a donde estén las salas.

## Teclas
WASD mover · E interactuar (mantener para reparar) · R reiniciar al morir/ganar
Debug: F1 llamarada · F2 EVA · F3 refugio · F4 tiempo x1/x5/x10 · F5 romper un módulo

## Balance (por día de juego; 1 día = 10 min reales)
Convertí los valores del plan (por minuto real) x10. Los que había en stats.gd estaban pensados para otra escala:
con ellos el O2 nunca bajaba (generador +14 contra -10 de consumo).
- Luz 06:00–23:00 (≈ 7 min reales) y noche ≈ 3 min.
- Dificultad 1 + 0.15 x día afecta a eventos (radiación de llamarada, nº de fallas), NO al consumo.
  Si multiplicara el consumo, el generador (+60) ya no alcanzaría desde el día 4 (40 x 1.6 = 64).
- Invernadero: cosecha manual cada ≈ 3 min. Puse +12 de comida en vez de +25 (con 25 la comida
  sube 4 veces más rápido de lo que baja). Constante: Stats.HARVEST_FOOD.
- Victoria: sobrevivir hasta el día 7 (≈ 58 min). Constante: Stats.GOAL_DAY.

## Eventos (EventDirector)
Día 1 gracia · día 2 llamarada con tutorial · día 4 falla doble · día 6 tormenta de polvo + falla
Otros días: 1–2 fallas + llamarada con 50 %.

## Lo que sigue faltando
1. Colisiones: el TileSet no tiene Physics Layer, el astronauta atraviesa paredes. Añade una capa de
   física al TileSet y pinta colisión en los tiles de pared (o StaticBody2D alrededor de las salas).
2. EVA caminable (escena exterior) – por ahora la esclusa solo activa/desactiva el estado EVA.
3. Minijuegos de reparación (ahora es mantener E).
4. Pixel art: astronauta 3 direcciones y estaciones, cuando toque.
5. Limpieza: Inventario.tscn / inventario.gd / Rock.tscn están vacíos o sin usar; .gitignore tiene
   `*.traanslation` (typo, es `*.translation`); esenario1 = "escenario1".
