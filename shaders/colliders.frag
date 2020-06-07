#pragma language glsl3

uniform float scale = 1;
uniform float thickness = 0.125;
uniform float smoothness = 1;

uniform int type;
uniform vec2 pos;
uniform vec2 delta;
uniform mat2 rotation;
uniform vec2 hdims;
uniform float radius;

vec4 effect(vec4 color, Image image, vec2 uv, vec2 xy) {
	float dist, depth, metric;

	if (type == 1) {
		dist = length(pos - xy);
		metric = (scale - dist) / smoothness + 0.5; // center to fill, scaled world units

		if (metric >= 0) color.w = mix(0.4 * color.w, color.w, clamp(metric, 0, 1));
		else {
			depth = radius - dist;
			metric = (depth - thickness) / smoothness - 0.5; // fill to border, screen units

			if (metric >= 0) color.w = mix(color.w, 0.4 * color.w, clamp(metric, 0, 1));
			else {
				metric = (depth + thickness) / smoothness + 0.5; // border to outside, screen units

				if (metric >= 0) color.w = mix(0, color.w, clamp(metric, 0, 1));
				else discard;
			}
		}
	}
	else if (type == 2) {
		vec2 offset = inverse(rotation) * (pos - xy);

		dist = length(offset);
		metric = (scale - dist) / smoothness + 0.5; // center to fill, scaled world units

		if (metric >= 0) color.w = mix(0.4 * color.w, color.w, clamp(metric, 0, 1));
		else {
			vec2 delta = abs(offset) - hdims;
			vec2 clip = max(delta, 0);
			float dist = length(clip) + min(max(delta.x, delta.y), 0);

			depth = radius - dist;
			metric = (depth - thickness) / smoothness - 0.5; // fill to border, screen units

			if (metric >= 0) color.w = mix(color.w, 0.4 * color.w, clamp(metric, 0, 1));
			else {
				metric = (depth + thickness) / smoothness + 0.5; // border to outside, screen units

				if (metric >= 0) color.w = mix(0, color.w, clamp(metric, 0, 1));
				else discard;
			}
		}
	}
	else if (type == 3) {
		vec2 offset = pos - xy;

		dist = length(offset);
		metric = (scale - dist) / smoothness + 0.5; // p1 center to fill, scaled world units

		if (metric >= 0) color.w = mix(0.4 * color.w, color.w, clamp(metric, 0, 1));
		else {
			dist = length(offset + delta);
			metric = (scale - dist) / smoothness + 0.5; // p2 center to fill, scaled world units

			if (metric >= 0) color.w = mix(0.4 * color.w, color.w, clamp(metric, 0, 1));
			else {
				float scalar = dot(delta, -offset) / dot(delta, delta);
				vec2 clamped = pos + delta * clamp(scalar, 0, 1);
				dist = length(clamped - xy);

				depth = radius - dist;
				metric = (depth - thickness) / smoothness - 0.5; // fill to border, screen units

				if (metric >= 0) color.w = mix(color.w, 0.4 * color.w, clamp(metric, 0, 1));
				else {
					metric = (depth + thickness) / smoothness + 0.5; // border to outside, screen units

					if (metric >= 0) color.w = mix(0, color.w, clamp(metric, 0, 1));
					else discard;
				}
			}
		}
	}

	return color;
}
