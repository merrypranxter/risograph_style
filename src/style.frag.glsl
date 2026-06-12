// risograph_style — Base Fragment Shader
// Full GPU pipeline: threshold → halftone → ink layers → multiply blend → paper → dropout
//
// This is the canonical shader stub. Each regime shader (shaders/0N_*.frag.glsl)
// wires up specific ink colors, lpi, angles, misregistration, and regime logic.
//
// RISO ink catalog (sRGB, divide by 255):
//   Fluorescent Red #FF4C00   Yellow         #FFE800   Green  #00A95C
//   Blue            #0078BF   Fluorescent Pink#FF6BB5  Navy   #012169
//   Orange          #DC4E28   Purple         #3D1F6D   Teal   #00838A
//   Brown           #8B4C2A   Black          #000000

precision highp float;

uniform float u_time;
uniform vec2  u_resolution;

// Ink system
uniform int   u_n_inks;
uniform vec3  u_ink_1;
uniform vec3  u_ink_2;
uniform vec3  u_ink_3;

// Halftone
uniform float u_halftone_lpi;
uniform float u_halftone_angle_1;
uniform float u_halftone_angle_2;

// Registration & gain
uniform vec2  u_misreg_1;
uniform vec2  u_misreg_2;
uniform float u_dot_gain;

// Substrate
uniform vec3  u_paper_color;
uniform float u_ink_transparency;

// ─── Utility ─────────────────────────────────────────────────────────────────

float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

// Low-quality hash for stochastic dropout
float hash2(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 17.5);
    return fract(p.x * p.y);
}

// Rotate UV by angle, then tile at lpi, return circular dot coverage [0,1]
float halftone_dot(vec2 uv, float lpi, float angle, float dot_gain_mul) {
    float c = cos(angle), s = sin(angle);
    vec2 rot = vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
    vec2 cell = fract(rot * lpi) - 0.5;
    // dot_gain expands dots: lower threshold → bigger dot
    float radius = 0.38 / dot_gain_mul;
    return 1.0 - smoothstep(radius - 0.04, radius + 0.04, length(cell));
}

// Subtractive (multiply) ink blend — physical RISO overlap
vec3 ink_multiply(vec3 a, vec3 b) {
    return a * b;
}

// Paper show-through: mix substrate with ink result proportional to ink coverage
vec3 over_paper(vec3 paper, vec3 ink_rgb, float coverage, float transparency) {
    return mix(paper, ink_rgb * transparency, coverage);
}

// ─── Ink dropout ─────────────────────────────────────────────────────────────
// Simulate 2–5% random ink starvation from mechanical imperfection
float dropout(vec2 uv, float rate) {
    return step(rate, hash2(floor(uv * u_resolution * 0.5)));
}

// ─── Main ─────────────────────────────────────────────────────────────────────

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // --- Ink 1 ---
    vec2 uv1 = uv + u_misreg_1 / u_resolution;
    float h1  = halftone_dot(uv1, u_halftone_lpi / u_resolution.y, u_halftone_angle_1, u_dot_gain);
    h1 *= dropout(uv1, 0.03);

    // --- Ink 2 ---
    vec2 uv2 = uv + u_misreg_2 / u_resolution;
    float h2  = halftone_dot(uv2, u_halftone_lpi / u_resolution.y, u_halftone_angle_2, u_dot_gain);
    h2 *= dropout(uv2, 0.025);

    // Start from paper
    vec3 col = u_paper_color;

    // Layer ink 1
    vec3 layer1 = mix(u_paper_color, u_ink_1 * u_ink_transparency, h1);

    // Layer ink 2 — multiply over ink 1 where they overlap
    vec3 overlap = ink_multiply(u_ink_1, u_ink_2) * u_ink_transparency;
    vec3 layer2  = mix(layer1, u_ink_2 * u_ink_transparency, h2 * (1.0 - h1));
    layer2       = mix(layer2, overlap, h1 * h2);

    col = layer2;

    // Optional third ink
    if (u_n_inks >= 3) {
        float angle3 = u_halftone_angle_1 + radians(30.0);
        float h3 = halftone_dot(uv, u_halftone_lpi / u_resolution.y, angle3, u_dot_gain);
        h3 *= dropout(uv, 0.02);
        vec3 multi = ink_multiply(col, u_ink_3 * u_ink_transparency);
        col = mix(col, multi, h3);
    }

    gl_FragColor = vec4(col, 1.0);
}
