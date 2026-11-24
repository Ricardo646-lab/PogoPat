extends RefCounted

# Kleurpaletten per level. Level 1 = palet 1, level 2 = palet 2, ..., level 9 = palet 9,
# level 10 = weer palet 1, enzovoort.
#
# Palet 1 is de originele look (luchtfoto, Kenney-grond, groene popup): daar verandert niets.
# Palet 2..9 zijn vlakke kleuren:
#   lucht     de lucht
#   gebouw    de gebouwen in de achtergrond
#   grond     de grond (de golfjes van de tegels)
#   rand      de bovenrand van de grond (de korst)
#   paneel    achtergrond van de popup
#   lijn      rand van de popup
#   schaduw   schaduw onder de popup
#   knop      HUD: levelnummer, tijd en tandwiel
#   accent    "GG!" in de popup en de kranen in de achtergrond
#   tekst     "LEVEL COMPLETE!" in de popup

const PALETTEN = [
	{},   # 1 origineel
	{   # 2 Golden hour: perzik lucht, paarse UI
		"lucht": Color("FFD3A3"), "gebouw": Color("F7B98B"), "grond": Color("A38BA8"), "rand": Color("E0795A"),
		"paneel": Color("3D1F4D"), "lijn": Color("FFB347"), "schaduw": Color("25112F"),
		"knop": Color("5A3470"), "accent": Color("FFB347"), "tekst": Color("FFEDE3"),
	},
	{   # 3 Forest and cream: donkergroene UI, oranje accent
		"lucht": Color("BFE8F5"), "gebouw": Color("E3F3F7"), "grond": Color("7FB89A"), "rand": Color("C98A66"),
		"paneel": Color("FFF8E8"), "lijn": Color("1F6B4F"), "schaduw": Color("134733"),
		"knop": Color("2F4F46"), "accent": Color("FF8A3D"), "tekst": Color("173D30"),
	},
	{   # 4 Pastel candy: zacht paars, roze accent
		"lucht": Color("CDE7FF"), "gebouw": Color("E8F1FF"), "grond": Color("B8A9E6"), "rand": Color("FF9EC4"),
		"paneel": Color("FFFFFF"), "lijn": Color("7C5CFF"), "schaduw": Color("5139C7"),
		"knop": Color("4A3E8F"), "accent": Color("FF5FA2"), "tekst": Color("2B2166"),
	},
	{   # 5 Sunny sand: zandkleurige bouwplaats, nacht-en-goud UI
		"lucht": Color("8EC9F5"), "gebouw": Color("CFE3F2"), "grond": Color("D9C7A3"), "rand": Color("C07A4A"),
		"paneel": Color("20243A"), "lijn": Color("FFC83D"), "schaduw": Color("12142A"),
		"knop": Color("343A5C"), "accent": Color("FFC83D"), "tekst": Color("FFF6DC"),
	},
	{   # 6 Dusk orange: blauwpaarse level, oranje UI
		"lucht": Color("9BB5F0"), "gebouw": Color("C2CDF5"), "grond": Color("6F7FB8"), "rand": Color("FF8A5B"),
		"paneel": Color("FFF3E0"), "lijn": Color("FF7A1A"), "schaduw": Color("C24E00"),
		"knop": Color("44495C"), "accent": Color("FF7A1A"), "tekst": Color("3A2410"),
	},
	{   # 7 Pine and peach: crème lucht, dennengroene UI
		"lucht": Color("FFE9C7"), "gebouw": Color("FAD9AE"), "grond": Color("6FA58A"), "rand": Color("C98A66"),
		"paneel": Color("1D3B34"), "lijn": Color("FFB38A"), "schaduw": Color("0F211D"),
		"knop": Color("2E5A4E"), "accent": Color("FFB38A"), "tekst": Color("FFF1E6"),
	},
	{   # 8 Olive and red: boterlucht, olijf, pogo-rood
		"lucht": Color("F6E7B4"), "gebouw": Color("E9D18A"), "grond": Color("A7B58A"), "rand": Color("7A5C3E"),
		"paneel": Color("FFF9E3"), "lijn": Color("2F3B2C"), "schaduw": Color("1B241A"),
		"knop": Color("4B5A3F"), "accent": Color("E8553D"), "tekst": Color("2F3B2C"),
	},
	{   # 9 Teal and coral: fris teal, koraal accent
		"lucht": Color("BFEFEA"), "gebouw": Color("DDF7F4"), "grond": Color("4FA3A5"), "rand": Color("FF8B6B"),
		"paneel": Color("E6FBF8"), "lijn": Color("0F7C80"), "schaduw": Color("0A5659"),
		"knop": Color("24565E"), "accent": Color("FF6B6B"), "tekst": Color("0B3B40"),
	},
]

const GROND_SHADER = preload("res://Scripts/grond_palet.gdshader")


# Het palet van dit level ({} = origineel)
static func voor_level(level: int) -> Dictionary:
	return PALETTEN[posmod(level - 1, PALETTEN.size())]


# Grondtegels omkleuren (tilemap-lagen met de Kenney-tilesheet)
static func kleur_grond(lagen: Array, pal: Dictionary) -> void:
	if pal.is_empty():
		return
	var mat := ShaderMaterial.new()
	mat.shader = GROND_SHADER
	mat.set_shader_parameter("grond", pal.grond)
	mat.set_shader_parameter("rand", pal.rand)
	for laag in lagen:
		laag.material = mat


# HUD in een level: levelnummer, tijd en tandwiel
static func kleur_hud(scene: Node, pal: Dictionary) -> void:
	if pal.is_empty():
		return
	for naam in ["LevelLabel", "TimerLabel"]:
		var label = scene.find_child(naam, true, false)
		if label:
			label.add_theme_color_override("font_color", pal.knop)
	var knop = scene.find_child("Button", true, false)
	if knop and "gear_color" in knop:
		knop.gear_color = pal.knop
		knop.queue_redraw()


# De "Level complete"-popup (Scenes/LevelComplete.tscn)
static func kleur_popup(popup: Node, pal: Dictionary) -> void:
	if pal.is_empty():
		return
	var paneel = popup.find_child("MainPanel", true, false)
	if paneel:
		var stijl: StyleBoxFlat = paneel.get_theme_stylebox("panel").duplicate()
		stijl.bg_color = pal.paneel
		stijl.border_color = pal.lijn
		stijl.shadow_color = Color(pal.schaduw, 0.6)
		paneel.add_theme_stylebox_override("panel", stijl)
	var schaduw = popup.find_child("PanelShadow", true, false)
	if schaduw:
		var stijl: StyleBoxFlat = schaduw.get_theme_stylebox("panel").duplicate()
		stijl.bg_color = pal.schaduw
		schaduw.add_theme_stylebox_override("panel", stijl)
	var titel = popup.find_child("LevelCompleteLabel", true, false)
	if titel:
		titel.add_theme_color_override("font_color", pal.tekst)
	var gg = popup.find_child("TextLabel", true, false)
	if gg:
		gg.add_theme_color_override("font_color", pal.accent)
