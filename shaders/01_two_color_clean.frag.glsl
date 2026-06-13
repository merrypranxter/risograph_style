// SHADER 01 — TWO_COLOR_CLEAN / RISO_CHERRY
// Fluorescent Red (#FF4C00) + Yellow (#FFE800)
// Regime: TWO_COLOR_CLEAN
//   - 65 lpi halftone
//   - Deliberate misregistration 3px
//   - Cream paper (#F5F0E8) as third color
//   - Screen angles: 45° (ink 1), 75° (ink 2)
//   - Multiply blend in overlap zone
//   - 3% ink dropout for mechanical texture
//
// Overlap zone: warm orange (#FF4C00 × #FFE800 ≈ #FF9E00)
// Paper zones read as warm cream between halftone dots.

precision highp float;

uniform float u_time;
uniform vec2  u_resolution;

// ─── RISO_CHERRY defaults ────────────────────────────────────────────────────
// Override via uniform if driving from JS:
//   u_ink_1      = vec3(1.0, 0.298, 0.0)       // Fluorescent Red #FF4C00
//   u_ink_2      = vec3(1.0, 0.910, 0.0)        // Yellow #FFE800
//   u_paper_color= vec3(0.961, 0.941, 0.910)    // Cream #F5F0E8
//   u_halftone_lpi        = 65.0
//   u_misreg_2            = vec2(3.0, 1.5)
//   u_dot_gain            = 1.08
//   u_ink_transparency    = 0.78

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

// Circular AM halftone dot, returns ink coverage [0,1]
float halftone(vec2 uv, float lpi, float angle, float gain) {
    float c = cos(angle), s = sin(angle);
    vec2 rot = vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
    vec2 cell = fract(rot * lpi) - 0.5;
    float r = 0.38 / gain;
    return 1.0 - smoothstep(r - 0.04, r + 0.04, length(cell));
}

// Stochastic ink dropout — mechanical imperfection
float dropout(vec2 uv, float rate) {
    return step(rate, hash2(floor(uv * u_resolution * 0.48)));
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float lpi    = u_halftone_lpi / u_resolution.y;
    float angle1 = radians(45.0);
    float angle2 = radians(75.0);

    // Ink 1 — no misregistration (first color down)
    float h1 = halftone(uv, lpi, angle1, u_dot_gain);
    h1 *= dropout(uv, 0.03);

    // Ink 2 — slight misregistration
    vec2 uv2 = uv + u_misreg_2 / u_resolution;
    float h2 = halftone(uv2, lpi, angle2, u_dot_gain);
    h2 *= dropout(uv2, 0.025);

    // Paper base
    vec3 col = u_paper_color;

    // Ink 1 layer
    vec3 ink1_rgb = u_ink_1 * u_ink_transparency;
    col = mix(col, ink1_rgb, h1);

    // Ink 2 layer — multiply over ink 1 in overlap, straight over paper otherwise
    vec3 ink2_rgb = u_ink_2 * u_ink_transparency;
    vec3 multiply_zone = ink1_rgb * ink2_rgb;

    col = mix(col, ink2_rgb, h2 * (1.0 - h1));        // ink 2 on paper
    col = mix(col, multiply_zone, h1 * h2);             // multiply in overlap

    gl_FragColor = vec4(col, 1.0);
}
