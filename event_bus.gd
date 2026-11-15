extends Node
## Autoload "EventBus": señales globales para no acoplar escenas.

signal message(text: String)              # texto corto para el HUD
signal flare_warning(seconds: float)      # aviso previo a una llamarada
