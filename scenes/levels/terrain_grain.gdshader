shader_type canvas_item;
// Fine grain on the terrain (DESIGN.md §11) so nothing reads as a flat fill.
// Uses the node's own coordinates, so the grain scrolls with the ground instead of sitting on the screen.

uniform float strength : hint_range(0.0, 0.3) = 0.07;
uniform float grain_size : hint_range(1.0, 6.0) = 2.0;
// Matches the terrain's repeat height so the grain lines up at the wrap.
uniform float repeat_height = 960.0;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 cell = floor(local_pos / grain_size);
	cell.y = mod(cell.y, floor(repeat_height / grain_size));
	COLOR.rgb += (hash(cell) - 0.5) * strength;
}
