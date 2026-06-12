// risograph_style — Shader Gallery Viewer
// Three.js + WebGL2 fullscreen quad, cycling through 8 regime shaders.
// Press ← → or use the on-screen buttons to switch shaders.

import * as THREE from 'three';

// ─── Shader imports (Vite raw string via ?raw) ────────────────────────────────
import shader01 from '../shaders/01_two_color_clean.frag.glsl?raw';
import shader02 from '../shaders/02_riso_ocean.frag.glsl?raw';
import shader03 from '../shaders/03_three_color_push.frag.glsl?raw';
import shader04 from '../shaders/04_fluorescent_glow.frag.glsl?raw';
import shader05 from '../shaders/05_dark_matter.frag.glsl?raw';
import shader06 from '../shaders/06_misreg_chaos.frag.glsl?raw';
import shader07 from '../shaders/07_riso_punk.frag.glsl?raw';
import shader08 from '../shaders/08_riso_acid.frag.glsl?raw';

// ─── RISO ink palette (linear sRGB) ──────────────────────────────────────────
const INK = {
  FLUO_RED:   new THREE.Color('#FF4C00'),
  YELLOW:     new THREE.Color('#FFE800'),
  GREEN:      new THREE.Color('#00A95C'),
  BLUE:       new THREE.Color('#0078BF'),
  FLUO_PINK:  new THREE.Color('#FF6BB5'),
  NAVY:       new THREE.Color('#012169'),
  ORANGE:     new THREE.Color('#DC4E28'),
  PURPLE:     new THREE.Color('#3D1F6D'),
  TEAL:       new THREE.Color('#00838A'),
  BROWN:      new THREE.Color('#8B4C2A'),
  BLACK:      new THREE.Color('#0A0A0A'),
};

const PAPER = {
  CREAM:      new THREE.Color('#F5F0E8'),
  WARM_CREAM: new THREE.Color('#F5EFE0'),
  CREAM2:     new THREE.Color('#F2EDE4'),
  CREAM3:     new THREE.Color('#F0EADA'),
  CREAM4:     new THREE.Color('#F0EAD8'),
  WHITE:      new THREE.Color('#FAFAFA'),
  DARK:       new THREE.Color('#1A180E'),
};

// ─── Shader gallery definitions ───────────────────────────────────────────────
// Each entry: { frag, name, meta, uniforms }
// uniforms: object of { key: value } — overrides for this regime
const SHADERS = [
  {
    frag: shader01,
    name: 'TWO_COLOR_CLEAN — RISO_CHERRY',
    meta: 'Fluorescent Red + Yellow  ·  65 lpi  ·  3px misreg  ·  cream paper',
    uniforms: {
      u_ink_1:            { value: INK.FLUO_RED },
      u_ink_2:            { value: INK.YELLOW },
      u_paper_color:      { value: PAPER.CREAM },
      u_halftone_lpi:     { value: 65.0 },
      u_misreg_2:         { value: new THREE.Vector2(3.0, 1.5) },
      u_dot_gain:         { value: 1.08 },
      u_ink_transparency: { value: 0.78 },
    },
  },
  {
    frag: shader02,
    name: 'TWO_COLOR_CLEAN — RISO_OCEAN',
    meta: 'Blue + Teal  ·  68 lpi  ·  2.5px misreg  ·  white paper  ·  animated waves',
    uniforms: {
      u_ink_1:            { value: INK.BLUE },
      u_ink_2:            { value: INK.TEAL },
      u_paper_color:      { value: PAPER.WHITE },
      u_halftone_lpi:     { value: 68.0 },
      u_misreg_2:         { value: new THREE.Vector2(2.5, -1.0) },
      u_dot_gain:         { value: 1.06 },
      u_ink_transparency: { value: 0.82 },
    },
  },
  {
    frag: shader03,
    name: 'THREE_COLOR_PUSH — RISO_NIGHT + Yellow',
    meta: 'Navy + Fluorescent Pink + Yellow  ·  70 lpi  ·  7 color zones  ·  cream paper',
    uniforms: {
      u_ink_1:            { value: INK.NAVY },
      u_ink_2:            { value: INK.FLUO_PINK },
      u_ink_3:            { value: INK.YELLOW },
      u_paper_color:      { value: PAPER.CREAM2 },
      u_halftone_lpi:     { value: 70.0 },
      u_misreg_2:         { value: new THREE.Vector2(1.5, -1.0) },
      u_misreg_3:         { value: new THREE.Vector2(-1.0, 1.5) },
      u_dot_gain:         { value: 1.09 },
      u_ink_transparency: { value: 0.80 },
    },
  },
  {
    frag: shader04,
    name: 'FLUORESCENT_GLOW',
    meta: 'Fluorescent Red + Fluorescent Pink  ·  75 lpi  ·  FM jitter  ·  warm cream  ·  animated',
    uniforms: {
      u_ink_1:            { value: INK.FLUO_RED },
      u_ink_2:            { value: INK.FLUO_PINK },
      u_paper_color:      { value: PAPER.WARM_CREAM },
      u_halftone_lpi:     { value: 75.0 },
      u_misreg_2:         { value: new THREE.Vector2(2.0, 1.0) },
      u_dot_gain:         { value: 1.10 },
      u_ink_transparency: { value: 0.72 },
    },
  },
  {
    frag: shader05,
    name: 'DARK_MATTER',
    meta: 'Black + Teal  ·  60 lpi  ·  peek-through  ·  dark paper  ·  breathing teal',
    uniforms: {
      u_ink_1:            { value: INK.BLACK },
      u_ink_2:            { value: INK.TEAL },
      u_paper_color:      { value: PAPER.DARK },
      u_halftone_lpi:     { value: 60.0 },
      u_misreg_2:         { value: new THREE.Vector2(3.0, -2.0) },
      u_dot_gain:         { value: 1.08 },
      u_ink_transparency: { value: 0.90 },
    },
  },
  {
    frag: shader06,
    name: 'MISREG_CHAOS',
    meta: 'Orange + Purple  ·  72 lpi  ·  8–15px animated drift  ·  colors fight',
    uniforms: {
      u_ink_1:            { value: INK.ORANGE },
      u_ink_2:            { value: INK.PURPLE },
      u_paper_color:      { value: PAPER.CREAM4 },
      u_halftone_lpi:     { value: 72.0 },
      u_dot_gain:         { value: 1.07 },
      u_ink_transparency: { value: 0.80 },
    },
  },
  {
    frag: shader07,
    name: 'RISO_PUNK',
    meta: 'Black + Fluorescent Pink  ·  80 lpi  ·  4px misreg  ·  white paper  ·  portrait rings',
    uniforms: {
      u_ink_1:            { value: INK.BLACK },
      u_ink_2:            { value: INK.FLUO_PINK },
      u_paper_color:      { value: PAPER.WHITE },
      u_halftone_lpi:     { value: 80.0 },
      u_misreg_2:         { value: new THREE.Vector2(4.0, 2.0) },
      u_dot_gain:         { value: 1.05 },
      u_ink_transparency: { value: 0.88 },
    },
  },
  {
    frag: shader08,
    name: 'RISO_ACID',
    meta: 'Fluorescent Red + Green  ·  65 lpi  ·  5px misreg  ·  Voronoi territory  ·  horrible + correct',
    uniforms: {
      u_ink_1:            { value: INK.FLUO_RED },
      u_ink_2:            { value: INK.GREEN },
      u_paper_color:      { value: PAPER.CREAM3 },
      u_halftone_lpi:     { value: 65.0 },
      u_misreg_2:         { value: new THREE.Vector2(5.0, 2.5) },
      u_dot_gain:         { value: 1.08 },
      u_ink_transparency: { value: 0.75 },
    },
  },
];

// ─── Shared vertex shader ─────────────────────────────────────────────────────
const VERTEX_SHADER = `
  void main() {
    gl_Position = vec4(position, 1.0);
  }
`;

// ─── Base uniforms always present ─────────────────────────────────────────────
function baseUniforms() {
  return {
    u_time:         { value: 0 },
    u_resolution:   { value: new THREE.Vector2(window.innerWidth, window.innerHeight) },
    u_n_inks:       { value: 2 },
    u_ink_1:        { value: new THREE.Color('#FF4C00') },
    u_ink_2:        { value: new THREE.Color('#FFE800') },
    u_ink_3:        { value: new THREE.Color('#000000') },
    u_halftone_lpi:        { value: 65.0 },
    u_halftone_angle_1:    { value: Math.PI / 4 },
    u_halftone_angle_2:    { value: Math.PI * 75 / 180 },
    u_misreg_1:            { value: new THREE.Vector2(0, 0) },
    u_misreg_2:            { value: new THREE.Vector2(3.0, 1.5) },
    u_misreg_3:            { value: new THREE.Vector2(0, 0) },
    u_dot_gain:            { value: 1.08 },
    u_paper_color:         { value: new THREE.Color('#F5F0E8') },
    u_ink_transparency:    { value: 0.78 },
  };
}

// ─── Setup Three.js ───────────────────────────────────────────────────────────
const renderer = new THREE.WebGLRenderer({ antialias: false });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
document.body.appendChild(renderer.domElement);

const scene  = new THREE.Scene();
const camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
const geo    = new THREE.PlaneGeometry(2, 2);

let currentIndex = 0;
let mesh = null;

// ─── Build/replace shader mesh ────────────────────────────────────────────────
function loadShader(index) {
  const def = SHADERS[index];
  const uniforms = { ...baseUniforms(), ...def.uniforms };

  // Deep-clone uniform values so Three.js doesn't share references
  const clonedUniforms = {};
  for (const [k, v] of Object.entries(uniforms)) {
    if (v.value && typeof v.value.clone === 'function') {
      clonedUniforms[k] = { value: v.value.clone() };
    } else {
      clonedUniforms[k] = { value: v.value };
    }
  }

  const mat = new THREE.ShaderMaterial({
    vertexShader: VERTEX_SHADER,
    fragmentShader: def.frag,
    uniforms: clonedUniforms,
    glslVersion: THREE.GLSL1,
  });

  if (mesh) {
    mesh.material.dispose();
    scene.remove(mesh);
  }
  mesh = new THREE.Mesh(geo, mat);
  scene.add(mesh);

  // Update UI
  document.getElementById('shader-name').textContent = def.name;
  document.getElementById('shader-meta').textContent = def.meta;
  document.getElementById('counter').textContent = `${index + 1} / ${SHADERS.length}`;
}

// ─── Navigation ───────────────────────────────────────────────────────────────
function go(delta) {
  currentIndex = ((currentIndex + delta) + SHADERS.length) % SHADERS.length;
  loadShader(currentIndex);
}

document.getElementById('btn-prev').addEventListener('click', () => go(-1));
document.getElementById('btn-next').addEventListener('click', () => go(+1));

window.addEventListener('keydown', (e) => {
  if (e.key === 'ArrowLeft')  go(-1);
  if (e.key === 'ArrowRight') go(+1);
});

// ─── Render loop ──────────────────────────────────────────────────────────────
function animate(time) {
  requestAnimationFrame(animate);
  if (mesh) {
    mesh.material.uniforms.u_time.value = time * 0.001;
  }
  renderer.render(scene, camera);
}

// ─── Resize ───────────────────────────────────────────────────────────────────
window.addEventListener('resize', () => {
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  if (mesh) {
    mesh.material.uniforms.u_resolution.value.set(window.innerWidth, window.innerHeight);
  }
});

// ─── Boot ─────────────────────────────────────────────────────────────────────
loadShader(0);
requestAnimationFrame(animate);
