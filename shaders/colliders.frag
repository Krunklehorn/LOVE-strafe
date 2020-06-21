#pragma language glsl3

#define MATH_HUGE 100000

uniform float scale;
uniform float line_width = 1;

uniform int type;
uniform vec2 pos;
uniform vec2 delta;
uniform mat2 rotation;
uniform vec2 hdims;
uniform float radius;

vec4 effect(vec4 color, Image image, vec2 uv, vec2 xy) {
	float sdist = MATH_HUGE;
	float alpha;

	if (type == 1) {
		vec2 offset = pos - xy;
		sdist = length(offset) - radius;
	}
	else if (type == 2) {
		vec2 offset = inverse(rotation) * (pos - xy);

		// early exit from circumscribed circle
		//if (length(offset) - line_width - 0.5 > length(hdims) + radius)
			//discard;

		vec2 delta = abs(offset) - hdims;
		vec2 clip = max(delta, 0);

		sdist = length(clip) + min(max(delta.x, delta.y), 0) - radius;
	}
	else if (type == 3) {
		vec2 offset = pos - xy;

		// early exit from circumscribed circle
		//if (length(pos + (delta / 2) - xy) - line_width - 0.5 > length(delta) / 2 + radius)
			//discard;

		float scalar = dot(delta, -offset) / dot(delta, delta);
		vec2 clamped = pos + delta * clamp(scalar, 0, 1);

		sdist = length(clamped - xy) - radius;
	}

	if (sdist - line_width - 0.5 <= 0) {
		alpha = 1 + (line_width - 1 - abs(sdist)) / 1.5;
		if (sdist <= 0) alpha = clamp(alpha, 0.4, 1);

		color.a *= alpha;
		return color;
	}
	else discard;
}
