import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';

// Setup Scene, Camera, Renderer
const canvas = document.querySelector('#bg-canvas');
const scene = new THREE.Scene();
scene.fog = new THREE.FogExp2(0x050510, 0.02);

const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
camera.position.set(0, 5, 15);

const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
renderer.setPixelRatio(window.devicePixelRatio);
renderer.setSize(window.innerWidth, window.innerHeight);

// Post-Processing (Bloom for Neon/Cyberpunk look)
const renderScene = new RenderPass(scene, camera);
const bloomPass = new UnrealBloomPass(
    new THREE.Vector2(window.innerWidth, window.innerHeight),
    1.5, // strength
    0.4, // radius
    0.85 // threshold
);
bloomPass.threshold = 0;
bloomPass.strength = 1.2; // Glowing strength
bloomPass.radius = 0.5;

const composer = new EffectComposer(renderer);
composer.addPass(renderScene);
composer.addPass(bloomPass);

// Controls
const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;
controls.dampingFactor = 0.05;
controls.autoRotate = true;
controls.autoRotateSpeed = 0.5;

// Cyberpunk Grid Helper
const gridHelper = new THREE.GridHelper(100, 50, 0x0fffff, 0xff0055);
gridHelper.position.y = -5;
// Make it fade into the dark background using opacity
gridHelper.material.transparent = true;
gridHelper.material.opacity = 0.2;
scene.add(gridHelper);

// Central Object: Wireframe TorusKnot
const geometry = new THREE.TorusKnotGeometry(3, 0.8, 100, 16);
const material = new THREE.MeshStandardMaterial({
    color: 0x00ffff,
    emissive: 0x0088ff,
    emissiveIntensity: 0.5,
    wireframe: true,
    transparent: true,
    opacity: 0.8
});
const torusKnot = new THREE.Mesh(geometry, material);
torusKnot.position.y = 2;
scene.add(torusKnot);

// Particle System (Data streams / stars)
const particlesGeometry = new THREE.BufferGeometry();
const particlesCount = 2000;
const posArray = new Float32Array(particlesCount * 3);

for (let i = 0; i < particlesCount * 3; i++) {
    // Spread particles around mostly in X and Z, and randomly in Y
    posArray[i] = (Math.random() - 0.5) * 60;
}
particlesGeometry.setAttribute('position', new THREE.BufferAttribute(posArray, 3));

// Create a glowing particle material
const particlesMaterial = new THREE.PointsMaterial({
    size: 0.05,
    color: 0xff0088,
    transparent: true,
    blending: THREE.AdditiveBlending
});

const particlesMesh = new THREE.Points(particlesGeometry, particlesMaterial);
scene.add(particlesMesh);

// Lighting
const ambientLight = new THREE.AmbientLight(0xffffff, 0.2);
scene.add(ambientLight);

const pointLight1 = new THREE.PointLight(0xff0088, 50, 100);
pointLight1.position.set(5, 5, 5);
scene.add(pointLight1);

const pointLight2 = new THREE.PointLight(0x00ffff, 50, 100);
pointLight2.position.set(-5, -5, -5);
scene.add(pointLight2);

// Mouse interaction for particles
let mouseX = 0;
let mouseY = 0;
document.addEventListener('mousemove', (event) => {
    mouseX = (event.clientX / window.innerWidth) - 0.5;
    mouseY = (event.clientY / window.innerHeight) - 0.5;
});

// Animation Loop
const clock = new THREE.Clock();

function animate() {
    requestAnimationFrame(animate);

    const elapsedTime = clock.getElapsedTime();

    // Rotate central object
    torusKnot.rotation.y = elapsedTime * 0.2;
    torusKnot.rotation.x = elapsedTime * 0.1;

    // Pulse effect on emissive intensity
    torusKnot.material.emissiveIntensity = 0.5 + Math.sin(elapsedTime * 2) * 0.3;

    // Move particles slowly and react to mouse
    particlesMesh.rotation.y = elapsedTime * 0.05 + mouseX * 0.5;
    particlesMesh.rotation.x = mouseY * 0.5;

    controls.update();

    // Use composer instead of renderer for bloom effect
    composer.render();
}

animate();

// Handle Window Resize
window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
    composer.setSize(window.innerWidth, window.innerHeight);
});
