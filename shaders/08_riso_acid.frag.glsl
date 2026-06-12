// SHADER 08 — RISO_ACID
// Fluorescent Red (#FF4C00) + Green (#00A95C)
// Regime: RISO_ACID
//   - The discordant combination: simultaneous red-green opponent contrast
//   - 65 lpi halftone
//   - Cream paper (#F0EADA)
//   - Screen angles: 45° / 75°
//   - Misregistration: 5px — slightly more chaos, the combo demands it
//   - Dot gain: 1.08
//   - Ink transparency: 0.75
//
// Fluorescent Red × Green = horrible + correct.
// The two colors sit at maximum perceptual distance on the red-green axis.
// Their overlap is a muddy near-black: Fluo Red × Green ≈ #006900 region.
// The fringe at misregistration edges is where the acid really hits:
// a sliver of pure red next to a sliver of pure green — optical vibration.
//
// Pattern: Voronoi-cell-like structure modulates density between inks —
// hard-edge territories with acid fringe at borders (simulates a screen-print
// look where film registration determines color territory).
//
// Warning: high visual intensity. Do not operate heavy machinery.

precision highp float;

uniform float u_time;
uniform vec2  u_resolution;

// ─── RISO_ACID defaults ──────────────────────────────────────────────────────
// u_ink_1      = vec3(1.0, 0.298, 0.0)      // Fluorescent Red #FF4C00
// u_ink_2      = vec3(0.0, 0.663, 0.361)    // Green #00A95C
// u_paper_color= vec3(0.941, 0.918, 0.855)  // Cream #F0EADA
// u_halftone_lpi        = 65.0
// u_misreg_2            = vec2(5.0, 2.5)
// u_dot_gain            = 1.08
// u_ink_transparency    = 0.75

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

vec2 hash2v(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

float halftone(vec2 uv, float lpi, float angle, float gain) {
    float c = cos(angle), s = sin(angle);
    vec2 rot = vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
    vec2 cell = fract(rot * lpi) - 0.5;
    float r = 0.38 / gain;
    return 1.0 - smoothstep(r - 0.04, r + 0.04, length(cell));
}

float dropout(vec2 uv, float rate) {
    return step(rate, hash2(floor(uv * u_resolution * 0.49)));
}

// Slow-moving Voronoi territory map — which ink "owns" this region
// Returns 0.0 (Red territory) to 1.0 (Green territory) with sharp edge
float territory(vec2 uv) {
    // Two drifting Voronoi seed points
    vec2 seed_r = vec2(0.35 + 0.12 * sin(u_time * 0.11), 0.45 + 0.08 * cos(u_time * 0.09));
    vec2 seed_g = vec2(0.65 + 0.10 * cos(u_time * 0.13), 0.55 + 0.12 * sin(u_time * 0.07));

    float dr = length(uv - seed_r);
    float dg = length(uv - seed_g);

    // Sharp territory boundary — acid demands hard edges
    return smoothstep(-0.01, 0.01, dr - dg);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float lpi = u_halftone_lpi / u_resolution.y;
    float terr = territory(uv);

    // Red: strong in its territory, present but weaker in green territory
    float red_gain  = u_dot_gain * mix(1.15, 0.75, terr);
    float h1 = halftone(uv, lpi, radians(45.0), red_gain);
    h1 *= dropout(uv, 0.03);

    // Green: strong in its territory, weaker in red territory
    float green_gain = u_dot_gain * mix(0.72, 1.18, terr);
    vec2 uv2 = uv + u_misreg_2 / u_resolution;
    float h2 = halftone(uv2, lpi, radians(75.0), green_gain);
    h2 *= dropout(uv2, 0.03);

    vec3 col = u_paper_color;

    vec3 i1 = u_ink_1 * u_ink_transparency;
    vec3 i2 = u_ink_2 * u_ink_transparency;
    // The acid money shot: red × green overlap → dark mud with tinge
    vec3 multiply_zone = i1 * i2;

    col = mix(col, i1, h1 * (1.0 - h2));
    col = mix(col, i2, h2 * (1.0 - h1));
    col = mix(col, multiply_zone, h1 * h2);

    gl_FragColor = vec4(col, 1.0);
}
