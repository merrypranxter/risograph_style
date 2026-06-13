// SHADER 04 — FLUORESCENT_GLOW
// Fluorescent Red (#FF4C00) + Fluorescent Pink (#FF6BB5)
// Regime: FLUORESCENT_GLOW
//   - 75 lpi — slightly tighter screen for delicacy
//   - Cream paper (#F5EFE0) — warm substrate amplifies warmth
//   - Screen angles: 45° / 75°
//   - Misregistration: 2px — barely off, glows rather than fights
//   - Dot gain: 1.10 — ink bleeds slightly into paper fibers
//   - Ink transparency: 0.72 — translucent enough for paper to glow through
//   - FM noise variation: stochastic dot jitter simulates risograph's
//     inconsistent ink transfer at high fluorescent pigment loads
//
// The two fluorescents are so close in value that their multiply zone
// reads almost the same hue — shifted toward Fluorescent Red.
// Where dots don't land, cream paper blazes through. Electric and delicate.
//
// Animated: dot density pulses slowly with u_time — simulates drum speed variation.

precision highp float;

uniform float u_time;
uniform vec2  u_resolution;

// ─── FLUORESCENT_GLOW defaults ───────────────────────────────────────────────
// u_ink_1      = vec3(1.0, 0.298, 0.0)      // Fluorescent Red #FF4C00
// u_ink_2      = vec3(1.0, 0.420, 0.710)    // Fluorescent Pink #FF6BB5
// u_paper_color= vec3(0.961, 0.937, 0.878)  // Warm cream #F5EFE0
// u_halftone_lpi        = 75.0
// u_misreg_2            = vec2(2.0, 1.0)
// u_dot_gain            = 1.10
// u_ink_transparency    = 0.72

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

// Hash for FM-style jitter
vec2 hash2v(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

// AM halftone with optional FM jitter
float halftone(vec2 uv, float lpi, float angle, float gain, float jitter) {
    float c = cos(angle), s = sin(angle);
    vec2 rot = vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
    vec2 grid = rot * lpi;
    vec2 cell_id = floor(grid);
    vec2 cell_uv = fract(grid) - 0.5;
    // FM jitter: shift dot center within cell
    vec2 offset = (hash2v(cell_id) - 0.5) * jitter;
    float r = 0.38 / gain;
    return 1.0 - smoothstep(r - 0.04, r + 0.04, length(cell_uv - offset));
}

float dropout(vec2 uv, float rate) {
    return step(rate, hash2(floor(uv * u_resolution * 0.46)));
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float lpi = u_halftone_lpi / u_resolution.y;

    // Animate dot gain slightly — drum speed variation
    float anim_gain = u_dot_gain + 0.04 * sin(u_time * 0.7);

    // FM jitter: 0.18 = modest stochastic displacement
    float jitter = 0.18;

    float h1 = halftone(uv, lpi, radians(45.0), anim_gain, jitter);
    h1 *= dropout(uv, 0.04);

    vec2 uv2 = uv + u_misreg_2 / u_resolution;
    float h2 = halftone(uv2, lpi, radians(75.0), anim_gain, jitter);
    h2 *= dropout(uv2, 0.035);

    // Fluorescent inks have a slight glow halo — add soft bleed radius
    // Simulated by a secondary soft dot at lower radius
    float halo1 = halftone(uv, lpi * 0.97, radians(45.0), anim_gain * 1.22, jitter * 0.5) * 0.25;
    float halo2 = halftone(uv2, lpi * 0.97, radians(75.0), anim_gain * 1.22, jitter * 0.5) * 0.20;

    h1 = clamp(h1 + halo1, 0.0, 1.0);
    h2 = clamp(h2 + halo2, 0.0, 1.0);

    // Color compositing
    vec3 col = u_paper_color;

    vec3 i1 = u_ink_1 * u_ink_transparency;
    vec3 i2 = u_ink_2 * u_ink_transparency;
    vec3 multiply_zone = i1 * i2;

    col = mix(col, i1, h1 * (1.0 - h2));
    col = mix(col, i2, h2 * (1.0 - h1));
    col = mix(col, multiply_zone, h1 * h2);

    gl_FragColor = vec4(col, 1.0);
}
