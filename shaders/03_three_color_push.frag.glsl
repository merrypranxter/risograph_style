// SHADER 03 — THREE_COLOR_PUSH / RISO_NIGHT + Yellow
// Navy (#012169) + Fluorescent Pink (#FF6BB5) + Yellow (#FFE800)
// Regime: THREE_COLOR_PUSH
//   - 70 lpi halftone — higher density, risk of moiré
//   - Three screen angles: 45° / 75° / 105° — maximum angle separation
//   - Registration: ±1.5px on ink 2 and 3 (tighter than chaos, imperfect)
//   - Up to 7 color zones from three-way overlap
//   - Cream paper (#F2EDE4)
//
// Color zones:
//   paper alone        → cream
//   Navy alone         → deep blue
//   Fluo Pink alone    → electric pink
//   Yellow alone       → bright yellow
//   Navy × Pink        → deep purple-violet
//   Navy × Yellow      → muted olive-green (surprising)
//   Pink × Yellow      → warm peach-salmon
//   Navy × Pink × Yell → near-black purple-brown
//
// The three-way multiply creates a rich topographic map of accidental color.

precision highp float;

uniform float u_time;
uniform vec2  u_resolution;

// ─── THREE_COLOR_PUSH / RISO_NIGHT+Yellow defaults ───────────────────────────
// u_ink_1      = vec3(0.004, 0.129, 0.412)   // Navy #012169
// u_ink_2      = vec3(1.0, 0.420, 0.710)     // Fluorescent Pink #FF6BB5
// u_ink_3      = vec3(1.0, 0.910, 0.0)       // Yellow #FFE800
// u_paper_color= vec3(0.949, 0.929, 0.894)   // Cream #F2EDE4
// u_halftone_lpi        = 70.0
// u_misreg_2            = vec2(1.5, -1.0)
// u_misreg_3            = vec2(-1.0, 1.5)
// u_dot_gain            = 1.09
// u_ink_transparency    = 0.80

uniform vec3  u_ink_1;
uniform vec3  u_ink_2;
uniform vec3  u_ink_3;
uniform vec3  u_paper_color;
uniform float u_halftone_lpi;
uniform vec2  u_misreg_2;
uniform vec2  u_misreg_3;
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
    return step(rate, hash2(floor(uv * u_resolution * 0.50)));
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float lpi    = u_halftone_lpi / u_resolution.y;
    float angle1 = radians(45.0);
    float angle2 = radians(75.0);
    float angle3 = radians(105.0);

    // --- Ink coverages ---
    float h1 = halftone(uv, lpi, angle1, u_dot_gain);
    h1 *= dropout(uv, 0.03);

    vec2 uv2 = uv + u_misreg_2 / u_resolution;
    float h2 = halftone(uv2, lpi, angle2, u_dot_gain);
    h2 *= dropout(uv2, 0.025);

    vec2 uv3 = uv + u_misreg_3 / u_resolution;
    float h3 = halftone(uv3, lpi, angle3, u_dot_gain);
    h3 *= dropout(uv3, 0.022);

    // --- Ink RGB values (with transparency) ---
    vec3 i1 = u_ink_1 * u_ink_transparency;
    vec3 i2 = u_ink_2 * u_ink_transparency;
    vec3 i3 = u_ink_3 * u_ink_transparency;

    // Start from paper
    vec3 col = u_paper_color;

    // 7-zone compositing via coverage weights
    // Single inks
    col = mix(col, i1, h1 * (1.0 - h2) * (1.0 - h3));
    col = mix(col, i2, h2 * (1.0 - h1) * (1.0 - h3));
    col = mix(col, i3, h3 * (1.0 - h1) * (1.0 - h2));

    // Two-ink overlaps — multiply blend
    col = mix(col, i1 * i2, h1 * h2 * (1.0 - h3));
    col = mix(col, i1 * i3, h1 * h3 * (1.0 - h2));
    col = mix(col, i2 * i3, h2 * h3 * (1.0 - h1));

    // Three-ink overlap
    col = mix(col, i1 * i2 * i3, h1 * h2 * h3);

    gl_FragColor = vec4(col, 1.0);
}
