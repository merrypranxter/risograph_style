// SHADER 02 — TWO_COLOR_CLEAN / RISO_OCEAN
// Blue (#0078BF) + Teal (#00838A)
// Regime: TWO_COLOR_CLEAN
//   - 68 lpi halftone
//   - 2.5px misregistration (gentle horizontal drift)
//   - White paper (#FAFAFA) — ocean on white
//   - Screen angles: 45° (Blue), 105° (Teal) — max separation to avoid moiré
//   - Multiply overlap produces deep cyan-teal (#005C8A region)
//
// The two blues fight gently. White paper reads as sky between dots.
// Misregistration direction: Teal shifts right/up, creating a blue shadow left-edge.

precision highp float;

uniform float u_time;
uniform vec2  u_resolution;

// ─── RISO_OCEAN defaults ─────────────────────────────────────────────────────
// u_ink_1      = vec3(0.0, 0.471, 0.749)    // Blue #0078BF
// u_ink_2      = vec3(0.0, 0.514, 0.541)    // Teal #00838A
// u_paper_color= vec3(0.980, 0.980, 0.980)  // Near-white
// u_halftone_lpi        = 68.0
// u_misreg_2            = vec2(2.5, -1.0)
// u_dot_gain            = 1.06
// u_ink_transparency    = 0.82

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
    return 1.0 - smoothstep(r - 0.04, r + 0.04, length(cell));
}

float dropout(vec2 uv, float rate) {
    return step(rate, hash2(floor(uv * u_resolution * 0.52)));
}

// Gentle sine-wave density modulation — ocean surface movement
float wave_density(vec2 uv) {
    return 0.55 + 0.45 * sin(uv.y * 8.0 + u_time * 0.4)
                * sin(uv.x * 5.0 - u_time * 0.25);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    float lpi    = u_halftone_lpi / u_resolution.y;
    float angle1 = radians(45.0);
    float angle2 = radians(105.0);

    // Modulate dot size with wave motion
    float density = wave_density(uv);
    float gain1 = u_dot_gain * (0.8 + 0.4 * density);
    float gain2 = u_dot_gain * (0.7 + 0.5 * (1.0 - density));

    float h1 = halftone(uv, lpi, angle1, gain1);
    h1 *= dropout(uv, 0.028);

    vec2 uv2 = uv + u_misreg_2 / u_resolution;
    float h2 = halftone(uv2, lpi, angle2, gain2);
    h2 *= dropout(uv2, 0.022);

    vec3 col = u_paper_color;

    vec3 ink1_rgb = u_ink_1 * u_ink_transparency;
    vec3 ink2_rgb = u_ink_2 * u_ink_transparency;
    vec3 multiply_zone = ink1_rgb * ink2_rgb;

    col = mix(col, ink1_rgb, h1);
    col = mix(col, ink2_rgb, h2 * (1.0 - h1));
    col = mix(col, multiply_zone, h1 * h2);

    gl_FragColor = vec4(col, 1.0);
}
