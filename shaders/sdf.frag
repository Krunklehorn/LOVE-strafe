#pragma language glsl3

#define MATH_HUGE 100000
#define ARRAY_MAX 64

uniform float scale = 1;
uniform float line_width = 1;

struct Circle {
	vec2 pos;
	float radius;
};

struct Box {
	vec2 pos;
	mat2 rotation;
	vec2 hdims;
	float radius;
};

struct Line {
	vec2 pos;
	vec2 delta;
	float radius;
};

uniform Circle circles[ARRAY_MAX];
uniform Box boxes[ARRAY_MAX];
uniform Line lines[ARRAY_MAX];

uniform int numCircles;
uniform int numBoxes;
uniform int numLines;

vec4 effect(vec4 color, Image image, vec2 uv, vec2 xy) {
	float sdist = MATH_HUGE;
	float alpha;

	for (int i = 0; i < numCircles; i++) {
		Circle circle = circles[i];
		vec2 offset = circle.pos - xy;

		sdist = min(sdist, length(offset) - circle.radius);
	}

	for (int i = 0; i < numBoxes; i++) {
		Box box = boxes[i];
		vec2 offset = inverse(box.rotation) * (box.pos - xy);
		vec2 delta = abs(offset) - box.hdims;
		vec2 clip = max(delta, 0);

		sdist = min(sdist, length(clip) + min(max(delta.x, delta.y), 0) - box.radius);
	}

	for (int i = 0; i < numLines; i++) {
		Line line = lines[i];
		vec2 offset = line.pos - xy;
		float scalar = dot(line.delta, -offset) / dot(line.delta, line.delta);
		vec2 clamped = line.pos + line.delta * clamp(scalar, 0, 1);

		sdist = min(sdist, length(clamped - xy) - line.radius);
	}

	if (sdist - line_width - 0.5 <= 0) {
		alpha = 1 + (line_width - 1 - abs(sdist)) / 1.5;
		if (sdist <= 0) alpha = clamp(alpha, 0.4, 1);

		color.a *= alpha;
		return color;
	}
	else discard;
}
