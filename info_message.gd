class_name InfoMessage
extends RefCounted

var title := ""
var body := ""
var source := ""            # "Datos reales: NASA DONKI"
var accent := Color.WHITE   # color del borde y del título
var duration := 6.0         # segundos en pantalla
var priority := 0           # mayor = interrumpe al que esté mostrándose
var pause_game := false     # true = congela el reloj hasta presionar Espacio
var once_key := ""          # si no está vacío, solo se muestra una vez
