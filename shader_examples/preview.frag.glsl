// Risograph Style — Fragment Shader Stub
// Halftone dots, misregistration, multiply blend, RISO ink colors
//
// This is the preview/reference shader — a minimal self-contained example.
// See shaders/0N_*.frag.glsl for the full regime implementations.

precision highp float;
uniform float u_time;
uniform vec2 u_resolution;
uniform int u_n_inks;
uniform vec3 u_ink_1;
uniform vec3 u_ink_2;
uniform vec3 u_ink_3;
uniform float u_halftone_lpi;
uniform float u_halftone_angle_1;
uniform float u_halftone_angle_2;
uniform vec2 u_misreg_1;
uniform vec2 u_misreg_2;
uniform float u_dot_gain;
uniform vec3 u_paper_color;
uniform float u_ink_transparency;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5); }

float halftone(vec2 uv, float lpi, float angle, float dot_gain) {
    float c = cos(angle), s = sin(angle);
    vec2 rot = vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
    vec2 dot_uv = fract(rot * lpi) - 0.5;
    return smoothstep(0.35 * dot_gain, 0.0, length(dot_uv));
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    
    // Paper
    vec3 col = u_paper_color;
    
    // Ink 1
    float h1 = halftone(uv, u_halftone_lpi, u_halftone_angle_1, u_dot_gain);
    vec3 ink1 = u_ink_1 * h1 * u_ink_transparency;
    
    // Ink 2 with misregistration
    float h2 = halftone(uv + u_misreg_2 / u_resolution, u_halftone_lpi, u_halftone_angle_2, u_dot_gain);
    vec3 ink2 = u_ink_2 * h2 * u_ink_transparency;
    
    // Multiply blend
    vec3 blended = 1.0 - (1.0 - ink1) * (1.0 - ink2);
    col = mix(col, blended, max(h1, h2));
    
    // Ink 3 if present
    if (u_n_inks >= 3) {
        float h3 = halftone(uv, u_halftone_lpi, u_halftone_angle_1 + 1.0, u_dot_gain);
        vec3 ink3 = u_ink_3 * h3 * u_ink_transparency;
        blended = 1.0 - (1.0 - blended) * (1.0 - ink3);
        col = mix(col, blended, max(max(h1, h2), h3));
    }
    
    gl_FragColor = vec4(col, 1.0);
}
