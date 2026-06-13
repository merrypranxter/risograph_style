# risograph_style

two inks. one machine. a hundred ways for it to go slightly wrong.

Risograph printing visual grammar — the RISO GR/EZ series digital duplicator that became the indie publishing machine of the 2010s. Limited spot color palettes, halftone dot screens, ink-on-ink multiply blending, and the beautiful accidents of mechanical misregistration.

## What This Is

Technical visual grammar for risograph-style rendering — the physical ink behavior, the color system, the halftone mathematics, and the specific palette of RISO standard inks.

Eight self-contained GLSL fragment shaders, each embodying a different aesthetic regime of the risograph process. Stack: Three.js + WebGL2 + Vite.

## Visual DNA

**RISO ink colors (standard catalogue):**
- `#FF4C00` Fluorescent Red (SO46)
- `#FFE800` Yellow (S006)
- `#00A95C` Green (S009)
- `#0078BF` Blue (S027)
- `#FF6BB5` Fluorescent Pink (SO47)
- `#012169` Navy Blue (S019)
- `#DC4E28` Orange (S150)
- `#3D1F6D` Purple (S017)
- `#00838A` Teal (S175)
- `#8B4C2A` Brown (S053)
- `#000000` Black (S040)

**Physical ink behavior:**
- Ink is translucent: where two inks overlap they multiply, not add
- Dot gain: halftone dots are larger in ink than in artwork (5–15%)
- Ink order matters: first ink down = bottom layer; topographic color mixing
- Paper shows through: ink sits ON paper, doesn't penetrate fully — paper color is a palette element
- Ink slur: fast drum rotation causes slight directional smear at high coverage

**Halftone screens:**
- Standard: 65–85 lpi halftone
- Angle: each color at different angle to avoid moiré (45°, 75°, 105°)
- Dot: circular dot (standard), elliptical, line, cross
- AM halftone: regular grid (standard riso)
- FM halftone: random dot position, less moiré

**Color palettes (2-color combinations):**
- `RISO_CHERRY`: Fluorescent Red + Yellow = warm orange shadows
- `RISO_OCEAN`: Blue + Teal = cyan-adjacent water
- `RISO_FOREST`: Green + Brown = earthy natural
- `RISO_NIGHT`: Navy + Fluorescent Pink = party purple
- `RISO_ACID`: Fluorescent Red + Green = horrible + correct
- `RISO_PUNK`: Black + Fluorescent Pink = gig poster energy

## Aesthetic Regimes

### `TWO_COLOR_CLEAN` — Intentional 2-ink risograph
Two chosen inks. Deliberate misregistration (2–4px). Halftone at 65 lpi. Paper color (cream/white) as third color. Multiply blend in overlap zone.

### `THREE_COLOR_PUSH` — Maximum before it breaks
Three inks. Risk of moiré. Overlap creates up to 7 color zones. Registration tighter but still imperfect. Dense and rich.

### `FLUORESCENT_GLOW` — Neon risograph
Fluorescent Red + Fluorescent Pink dominant. Against cream paper. Halftone at 75 lpi. Electric and delicate simultaneously.

### `DARK_MATTER` — Black + one color
Heavy black layer. Single second ink at low density — peek-through effect. Ink-dark ground with color emerging.

### `MISREG_CHAOS` — Registration deliberately broken
Large misregistration (8–15px). Colors fight. Shadow becomes color edge. The accident is the aesthetic.

## Shader Uniforms

```glsl
uniform int   u_n_inks;             // 1–3, number of RISO ink colors
uniform vec3  u_ink_1;              // first ink color (linear RGB)
uniform vec3  u_ink_2;              // second ink color
uniform vec3  u_ink_3;              // third ink color (if n_inks=3)
uniform float u_halftone_lpi;       // 45.0–85.0 lines per inch
uniform float u_halftone_angle_1;   // radians, screen angle for ink 1
uniform float u_halftone_angle_2;   // radians, screen angle for ink 2
uniform vec2  u_misreg_1;           // pixel offset for ink 1
uniform vec2  u_misreg_2;           // pixel offset for ink 2
uniform float u_dot_gain;           // 1.0–1.15, dot size multiplier
uniform vec3  u_paper_color;        // paper/substrate base color
uniform float u_ink_transparency;   // 0.6–0.85, ink translucency
uniform float u_time;               // seconds, for animated variants
uniform vec2  u_resolution;         // viewport resolution in pixels
```

## Shader Gallery

| File | Regime | Palette |
|------|--------|---------|
| `shaders/01_two_color_clean.frag.glsl` | TWO_COLOR_CLEAN | RISO_CHERRY (Fluo Red + Yellow) |
| `shaders/02_riso_ocean.frag.glsl` | TWO_COLOR_CLEAN | RISO_OCEAN (Blue + Teal) |
| `shaders/03_three_color_push.frag.glsl` | THREE_COLOR_PUSH | Night (Navy + Fluo Pink + Yellow) |
| `shaders/04_fluorescent_glow.frag.glsl` | FLUORESCENT_GLOW | Fluo Red + Fluo Pink |
| `shaders/05_dark_matter.frag.glsl` | DARK_MATTER | Black + Teal |
| `shaders/06_misreg_chaos.frag.glsl` | MISREG_CHAOS | Orange + Purple |
| `shaders/07_riso_punk.frag.glsl` | RISO_PUNK | Black + Fluorescent Pink |
| `shaders/08_riso_acid.frag.glsl` | RISO_ACID | Fluorescent Red + Green |

## GPU Pipeline

```
threshold → halftone → color layer 1 → color layer 2 (misregistered)
  → multiply blend → paper layer → dropout pass → output
```

Each layer:
1. **Threshold pass**: convert input luminance to binary ink/no-ink decision
2. **Halftone pass**: AM screen — `length(fract(rot(uv, angle) * lpi) - 0.5) < threshold / dot_gain`
3. **Color layer 1**: apply ink 1 RGB with transparency, at screen angle 45°
4. **Color layer 2**: apply ink 2 RGB with misregistration offset, at screen angle 75°
5. **Multiply blend**: `result = ink1 * ink2` (subtractive, in ink density space)
6. **Paper layer**: `mix(paper_color, ink_result, max_coverage)`
7. **Dropout pass**: stochastic ink dropout at 2–5% to simulate mechanical imperfection

## Running

```bash
npm install
npm run dev
```

Press `←` / `→` to cycle between the 8 shaders in the browser preview.

## Ecosystem

Part of the [merrypranxter](https://github.com/merrypranxter) generative art pipeline.
RepoScripter2 context source. ShaderForge style module.

Use with: `zine_aesthetic`, `dither`, `damage_aesthetics`, `duotone_halftone_press`
