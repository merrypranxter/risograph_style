// SHADER 06 — MISREG_CHAOS
// Orange (#DC4E28) + Purple (#3D1F6D)
// Regime: MISREG_CHAOS
//   - Large misregistration: 8–15px, animated drift
//   - Colors fight — the accident is the aesthetic
//   - Shadow becomes color edge: Orange halo left, Purple halo right
//   - 72 lpi halftone
//   - Screen angles: 45° / 75°
//   - Cream paper (#F0EAD8) — warm neutral lets both fight equally
//   - Dot gain: 1.07
//
// The machine has slipped. Both rollers are off. Orange and Purple
// chase each other across the substrate. Where they overlap:
//   Orange × Purple → deep brownish-red (#540E00 region, beautiful mud)
// Where they miss each other: raw ink on cream, the halo effect.
//
// Animated: misregistration offset oscillates with u_time — the machine
// is drifting. Different speeds for x and y creates diagonal drift.
// At extremes, the two color fields barely touch, then slam together.

precision highp float;

uniform float u_time;
uniform vec2  u_resolution;

// ─── MISREG_CHAOS defaults ───────────────────────────────────────────────────
// u_ink_1      = vec3(0.863, 0.306, 0.157)   // Orange #DC4E28
// u_ink_2      = vec3(0.239, 0.122, 0.427)   // Purple #3D1F6D
// u_paper_color= vec3(0.941, 0.918, 0.847)   // Warm cream #F0EAD8
// u_halftone_lpi        = 72.0
// u_dot_gain            = 1.07
// u_ink_transparency    = 0.80
// misreg magnitude: animated 8–15px

uniform vec3  u_ink_1;
uniform vec3  u_ink_2;
uniform vec3  u_paper_color;
uniform float u_halftone_lpi;
uniform float u_dot_gain;
uniform float u_ink_transparency;

// ─── Utility ─────────────────────────────────────────────────────────────────

float hash2(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 17.5);
    return fract(p.x * p.y);
}

float halftone(vec2 uv, float lpi, float angle, float gain) {
    float c = cos(angle), s = sin(angle);
    vec2 rot = vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
    vec2 cell = fract(rot * lpi) - 0.5;
    float r = 0.38 / gain;
    return 1.0 - smoothstep(r - 0.04, r + 0.04, length(cell));
}

float dropout(vec2 uv, float rate) {
    return step(rate, hash2(floor(uv * u_resolution * 0.51)));
}

// Animated chaos drift — different frequency per axis, non-harmonic
vec2 chaos_misreg(float t) {
    float mag_x = 8.0 + 7.0 * abs(sin(t * 0.23));
    float mag_y = 6.0 + 5.0 * abs(sin(t * 0.17 + 1.3));
    return vec2(
        mag_x * sin(t * 0.31),
        mag_y * cos(t * 0.19 + 0.7)
    );
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float lpi = u_halftone_lpi / u_resolution.y;

    // Animated misregistration — the machine is slipping
    vec2 drift = chaos_misreg(u_time);

    // Ink 1 — Orange, no offset (it's "correct" — the error is in ink 2)
    float h1 = halftone(uv, lpi, radians(45.0), u_dot_gain);
    h1 *= dropout(uv, 0.035);

    // Ink 2 — Purple, drifting badly
    vec2 uv2 = uv + drift / u_resolution;
    float h2 = halftone(uv2, lpi, radians(75.0), u_dot_gain);
    h2 *= dropout(uv2, 0.030);

    // Color fight
    vec3 col = u_paper_color;

    vec3 i1 = u_ink_1 * u_ink_transparency;
    vec3 i2 = u_ink_2 * u_ink_transparency;

    // Shadow-as-color-edge: at the boundary of h1 and h2, neither fully covers
    // This creates the characteristic MISREG_CHAOS fringing
    vec3 multiply_zone = i1 * i2;

    col = mix(col, i1, h1 * (1.0 - h2));
    col = mix(col, i2, h2 * (1.0 - h1));
    col = mix(col, multiply_zone, h1 * h2);

    gl_FragColor = vec4(col, 1.0);
}
