// SHADER 07 — RISO_PUNK
// Black (#000000) + Fluorescent Pink (#FF6BB5)
// Regime: RISO_PUNK
//   - 80 lpi — tight, high-energy screen
//   - White paper (#FAFAFA) — pure contrast, no warmth
//   - Screen angles: 45° (Black), 75° (Pink)
//   - Misregistration: 4px — deliberate, readable, gig poster energy
//   - Dot gain: 1.05 — black is crisp, Pink bleeds slightly more
//   - Ink transparency: 0.88 — dense inks, this is a gig poster
//
// The classic RISO_PUNK combination: photocopied noise, concert energy.
// Black at high coverage dominates; Fluorescent Pink burns through.
// Where they overlap: near-black with a pink cast (Pink × Black → dark magenta).
//
// Pattern: large-scale concentric ring structure (simulating a photographic
// portrait printed halftone — common punk/zine subject matter).
// Rings modulate dot density — high coverage center, dots expand outward.

precision highp float;

uniform float u_time;
uniform vec2  u_resolution;

// ─── RISO_PUNK defaults ──────────────────────────────────────────────────────
// u_ink_1      = vec3(0.04, 0.04, 0.04)      // Black #000000 (slight paper tint)
// u_ink_2      = vec3(1.0, 0.420, 0.710)     // Fluorescent Pink #FF6BB5
// u_paper_color= vec3(0.980, 0.980, 0.980)   // White paper
// u_halftone_lpi        = 80.0
// u_misreg_2            = vec2(4.0, 2.0)
// u_dot_gain            = 1.05
// u_ink_transparency    = 0.88

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

float halftone(vec2 uv, float lpi, float angle, float gain) {
    float c = cos(angle), s = sin(angle);
    vec2 rot = vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
    vec2 cell = fract(rot * lpi) - 0.5;
    float r = 0.38 / gain;
    return 1.0 - smoothstep(r - 0.03, r + 0.03, length(cell));
}

float dropout(vec2 uv, float rate) {
    return step(rate, hash2(floor(uv * u_resolution * 0.54)));
}

// Concentric ring density modulator — portrait halftone energy
float portrait_density(vec2 uv) {
    vec2 center = uv - 0.5;
    float dist  = length(center * vec2(1.0, 1.3));  // slightly taller oval
    // Rings: high in center, decreasing outward, with interference bands
    float rings = sin(dist * 18.0 - u_time * 0.3) * 0.5 + 0.5;
    float vignette = 1.0 - smoothstep(0.2, 0.75, dist);
    return mix(0.3, 1.0, rings * vignette + (1.0 - vignette) * 0.2);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float lpi = u_halftone_lpi / u_resolution.y;
    float density = portrait_density(uv);

    // Black: density-modulated gain — larger dots in dense areas
    float black_gain = u_dot_gain * (0.7 + 0.6 * density);
    float h1 = halftone(uv, lpi, radians(45.0), black_gain);
    h1 *= dropout(uv, 0.02);

    // Pink: inverse of black density + misreg — burns through where black thins
    float pink_gain = u_dot_gain * (0.5 + 0.8 * (1.0 - density * 0.6));
    vec2 uv2 = uv + u_misreg_2 / u_resolution;
    float h2 = halftone(uv2, lpi, radians(75.0), pink_gain);
    h2 *= dropout(uv2, 0.025);

    vec3 col = u_paper_color;

    vec3 i1 = u_ink_1 * u_ink_transparency;
    vec3 i2 = u_ink_2 * u_ink_transparency;
    vec3 multiply_zone = i1 * i2;

    col = mix(col, i1, h1 * (1.0 - h2));
    col = mix(col, i2, h2 * (1.0 - h1));
    col = mix(col, multiply_zone, h1 * h2);

    gl_FragColor = vec4(col, 1.0);
}
