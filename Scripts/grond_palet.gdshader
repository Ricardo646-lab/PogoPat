shader_type canvas_item;

// Kleurt de grondtegels van de Kenney-tilesheet om naar een palet (Scripts/palettes.gd).
// De bruine korst bovenop wordt "rand", de blauwgrijze golfjes worden "grond".
// De lichte/donkere tinten van de tegel blijven een beetje zichtbaar (schaduw).
// Alleen de grondtegels (bovenste 2 rijen van de tilesheet) veranderen; spikes enz. niet.

uniform vec4 grond : source_color;
uniform vec4 rand : source_color;
uniform float schaduw = 0.35;   // 0 = helemaal vlak, 1 = alle tinten van de tegel

void fragment() {
	vec4 t = texture(TEXTURE, UV);
	COLOR = t;
	// Tilesheet 1960 x 1120 px, tiles 70 px: grondtegels zitten in rij 0-1, kolom 0-17
	if (UV.y < 140.0 / 1120.0 && UV.x < 1260.0 / 1960.0) {
		float l = dot(t.rgb, vec3(0.299, 0.587, 0.114));
		bool korst = t.r > t.b + 0.05;
		vec3 basis = korst ? rand.rgb : grond.rgb;
		float ref = korst ? 0.62 : 0.74;   // gemiddelde helderheid van korst / golfjes
		COLOR = vec4(basis * mix(1.0, l / ref, schaduw), t.a);
	}
}
