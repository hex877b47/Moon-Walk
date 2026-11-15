class_name FlareData
extends RefCounted

var id: String
var link: String
var class_label: String
var class_letter: String
var class_number: float
var real_date: String
var begin_unix: float
var end_unix: float
var has_sep := false
var has_cme := false
var sep_delay_minutes := 0.0

const MONTHS := ["enero", "febrero", "marzo", "abril", "mayo", "junio",
	"julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"]

func pretty_date() -> String:
	var p := real_date.split("-")          # ["2024", "05", "14"]
	if p.size() < 3:
		return real_date
	return "%d de %s de %s" % [int(p[2]), MONTHS[int(p[1]) - 1], p[0]]

func to_message() -> InfoMessage:
	var m := InfoMessage.new()
	m.title = "Llamarada solar %s" % class_label
	if has_sep:
		m.body = "Pasó de verdad el %s. Mandó partículas peligrosas hacia el espacio: por eso conviene estar en la base." % pretty_date()
	else:
		m.body = "Pasó de verdad el %s. Fue muy brillante, pero casi no mandó partículas. Lo que daña a los astronautas son las partículas, no solo la luz." % pretty_date()
	m.source = "Datos reales: NASA DONKI (histórico)"
	m.accent = Color(1.0, 0.5, 0.15)
	m.duration = 9.0
	m.priority = 2
	return m

static func from_donki(d: Dictionary) -> FlareData:
	var f := FlareData.new()
	f.id = d.get("flrID", "")
	f.link = d.get("link", "")
	f.class_label = d.get("classType", "C1.0")
	f.class_letter = f.class_label.substr(0, 1)
	f.class_number = f.class_label.substr(1).to_float()
	f.real_date = str(d.get("beginTime", "")).substr(0, 10)
	f.begin_unix = _to_unix(str(d.get("beginTime", "")))
	f.end_unix = _to_unix(str(d.get("endTime", "")))

	var linked = d.get("linkedEvents")      # puede venir null
	if linked != null:
		for e in linked:
			var aid: String = e.get("activityID", "")
			if "-CME-" in aid:
				f.has_cme = true
			if "-SEP-" in aid:
				var sep_unix := Time.get_unix_time_from_datetime_string(aid.substr(0, 19))
				var delay := (sep_unix - f.begin_unix) / 60.0
				if delay > 0.0 and (not f.has_sep or delay < f.sep_delay_minutes):
					f.has_sep = true
					f.sep_delay_minutes = delay    # nos quedamos con el SEP más temprano
	return f

static func _to_unix(s: String) -> float:
	# DONKI manda "2025-05-13T15:25Z" (sin segundos)
	return Time.get_unix_time_from_datetime_string(s.replace("Z", ":00"))

func severity() -> float:
	var base: float = {"C": 1.0, "M": 2.0, "X": 3.0}.get(class_letter, 1.0)
	return base + class_number * 0.1

# --- conversiones a valores de juego (minutos de juego) ---
func game_warning_minutes() -> float:
	return clampf(sep_delay_minutes, 30.0, 240.0) if has_sep else 60.0

func game_duration_minutes() -> float:
	return clampf((end_unix - begin_unix) / 60.0, 30.0, 120.0)

func damage_multiplier() -> float:
	return severity() / 2.5 * (1.0 if has_sep else 0.6)
