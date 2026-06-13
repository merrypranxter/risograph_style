// SHADER 05 — DARK_MATTER
// Black (#000000) + Teal (#00838A)
// Regime: DARK_MATTER
//   - Heavy black layer at high coverage (large dots, dense screen)
//   - Teal at lower density — peek-through effect
//   - 60 lpi — coarser screen accentuates the black presence
//   - Screen angles: 45° (Black), 75° (Teal)
//   - Black dot gain: 1.12 — heavy ink, bleeds
//   - Teal at 35% coverage area — emerges from the dark
//   - Near-black paper (#1A1814) — paper is dark, ink is darker
//   - Misregistration: 3px — black shadow edges
//
// Pipeline notes:
//   - Black layer uses threshold-based hard dots (no softness)
//   - Teal layer uses soft dots to allow bleed-through at edges
//   - Multiply between black and teal → near-black with teal tint
//   - The reward is at coverage boundaries: teal halos around black forms
//
// Animated: teal density pulses with slow sine — color breathes in the dark.

precision highp float;

uniform float u_time;
uniform vec2  u_resolution;

// ─── DARK_MATTER defaults ────────────────────────────────────────────────────
// u_ink_1      = vec3(0.04, 0.04, 0.04)      // Near-black (Black #000000 with slight paper)
// u_ink_2      = vec3(0.0, 0.514, 0.541)     // Teal #00838A
// u_paper_color= vec3(0.102, 0.094, 0.078)   // Near-black paper #1A180E
// u_halftone_lpi        = 60.0
// u_misreg_2            = vec2(3.0, -2.0)
// u_dot_gain_black      = 1.12
// u_dot_gain_teal       = 0.88   (smaller dots = lower coverage)
// u_ink_transparency    = 0.90   (black is dense)

uniform vec3  u_ink_1;
uniform vec3  u_ink_2;
uniform vec3  u_paper_color;
uniform float u_halftone_lpi;
uniform vec2  u_misreg_2;
uniform float u_dot_gain;
uniform float u_ink_transparency;

// ─── Utility ─────────────────────────────────────────────────────────────────

float hash2(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 17.5);
    return fract(p.x * p.y);
}

// Hard-edged halftone (black layer)
float halftone_hard(vec2 uv, float lpi, float angle, float gain) {
    float c = cos(angle), s = sin(angle);
    vec2 rot = vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
    vec2 cell = fract(rot * lpi) - 0.5;
    float r = 0.40 / gain;
    return 1.0 - step(r, length(cell));
}

// Soft halftone (teal peek-through layer)
float halftone_soft(vec2 uv, float lpi, float angle, float gain) {
    float c = cos(angle), s = sin(angle);
    vec2 rot = vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
    vec2 cell = fract(rot * lpi) - 0.5;
    float r = 0.30 / gain;   // smaller radius = lower coverage = peek-through
    return 1.0 - smoothstep(r - 0.06, r + 0.06, length(cell));
}

float dropout(vec2 uv, float rate) {
    return step(rate, hash2(floor(uv * u_resolution * 0.44)));
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float lpi = u_halftone_lpi / u_resolution.y;

    // Black: heavy, hard-edged, dense
    float h1 = halftone_hard(uv, lpi, radians(45.0), u_dot_gain * 1.12);
    h1 *= dropout(uv, 0.02);

    // Teal: soft, lower coverage, animated density
    float teal_pulse = 0.80 + 0.20 * sin(u_time * 0.5);
    vec2 uv2 = uv + u_misreg_2 / u_resolution;
    float h2 = halftone_soft(uv2, lpi, radians(75.0), u_dot_gain * 0.88 * teal_pulse);
    h2 *= dropout(uv2, 0.03);

    // Colour
    vec3 col = u_paper_color;

    vec3 i1 = u_ink_1 * u_ink_transparency;
    vec3 i2 = u_ink_2 * (u_ink_transparency * 0.85);  // teal slightly translucent
    vec3 multiply_zone = i1 * i2;

    // Layer black first (print order matters)
    col = mix(col, i1, h1 * (1.0 - h2));
    // Teal peeks through black at edges
    col = mix(col, i2, h2 * (1.0 - h1) * 0.7);       // teal on paper (dimmed)
    col = mix(col, multiply_zone, h1 * h2);             // teal bleeding through black

    gl_FragColor = vec4(col, 1.0);
}
