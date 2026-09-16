const { chromium } = require('playwright');
const fs = require('fs');
const { execSync } = require('child_process');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  const errors = [];
  page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
  page.on('pageerror', err => errors.push(err.message));

  await page.goto('http://localhost:9099/');
  await page.waitForFunction(() => document.getElementById('status').textContent.includes('ready'), { timeout: 15000 });
  console.log('Page loaded, status=ready');

  const isPlaying = await page.$eval('#btnPlay', b => b.textContent.includes('Pause'));
  if (!isPlaying) {
    await page.click('#btnPlay');
    console.log('Clicked Play');
  } else {
    console.log('Already playing');
  }

  await page.waitForTimeout(3000);

  // Read readouts twice (2s apart)
  const readout1 = await page.evaluate(() => ({
    crank: parseFloat(document.getElementById('stCrank').textContent),
    tape: parseFloat(document.getElementById('stTape').textContent),
    drum: parseFloat(document.getElementById('stDrum').textContent)
  }));
  console.log('Readout 1:', JSON.stringify(readout1));

  await page.waitForTimeout(2000);

  const readout2 = await page.evaluate(() => ({
    crank: parseFloat(document.getElementById('stCrank').textContent),
    tape: parseFloat(document.getElementById('stTape').textContent),
    drum: parseFloat(document.getElementById('stDrum').textContent)
  }));
  console.log('Readout 2:', JSON.stringify(readout2));

  const crankDelta = readout2.crank - readout1.crank;
  const tapeDelta = readout2.tape - readout1.tape;
  const drumDelta = readout2.drum - readout1.drum;
  console.log('Deltas: crank=' + crankDelta.toFixed(4) + ', tape=' + tapeDelta.toFixed(4) + ', drum=' + drumDelta.toFixed(4));

  const tapePerRev = Math.PI * 20;
  const expectedTapeDelta = crankDelta * tapePerRev;
  const expectedDrumDelta = crankDelta * 0.5;
  console.log('Expected tape delta: ' + expectedTapeDelta.toFixed(4) + ' (actual: ' + tapeDelta.toFixed(4) + ')');
  console.log('Expected drum delta: ' + expectedDrumDelta.toFixed(4) + ' (actual: ' + drumDelta.toFixed(4) + ')');
  const tapeOk = Math.abs(tapeDelta - expectedTapeDelta) < 0.5;
  const drumOk = Math.abs(drumDelta - expectedDrumDelta) < 0.01;
  console.log('Tape ratio OK: ' + tapeOk + ', Drum ratio OK: ' + drumOk);

  // 4. Crank orbit check - find objects in scene graph
  // Use page.evaluate to find the scene by looking at the canvas's internal properties
  await page.evaluate(() => {
    window._getPivotRots = function() {
      const canvas = document.getElementById('view');
      
      // Try to find the renderer through the canvas's internal properties
      let renderer = null;
      
      // Method 1: Look at canvas properties for the renderer
      const keys = Object.getOwnPropertyNames(canvas);
      for (const key of keys) {
        try {
          const val = canvas[key];
          if (val && typeof val === 'object' && val.isWebGLRenderer) {
            renderer = val;
            break;
          }
        } catch(e) {}
      }
      
      // Method 2: Try to find through the WebGL context
      if (!renderer) {
        const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
        if (gl) {
          // Try to find the renderer through the WebGL context
          // In Three.js, the renderer might be stored on the context
        }
      }
      
      // Method 3: Try to find the renderer through the THREE global
      if (!renderer && window.THREE) {
        // The renderer might be accessible through the canvas
        // Let's try to find it by looking at the canvas's properties
        for (const key of Object.getOwnPropertyNames(canvas)) {
          try {
            const val = canvas[key];
            if (val && typeof val === 'object') {
              // Check if it has a _scene property
              if (val._scene && val._scene.isScene) {
                renderer = val;
                break;
              }
            }
          } catch(e) {}
        }
      }
      
      if (!renderer) return { error: 'renderer not found', crankY: null, drumY: null };
      
      const scene = renderer._scene || renderer.scene;
      if (!scene) return { error: 'scene not found', crankY: null, drumY: null };
      
      let crankSpinner = null, drumPivot = null;
      scene.traverse(obj => {
        if (obj.isGroup) {
          if (obj.position.x === 40 && Math.abs(obj.position.y + 8.47) < 0.01 && obj.position.z === 0) {
            crankSpinner = obj;
          }
          if (obj.position.x === 100 && obj.position.y === 60 && obj.position.z === -30) {
            drumPivot = obj;
          }
        }
      });
      return {
        crankY: crankSpinner ? crankSpinner.rotation.y : null,
        drumY: drumPivot ? drumPivot.rotation.y : null,
        crankFound: !!crankSpinner,
        drumFound: !!drumPivot
      };
    };
  });

  const r1 = await page.evaluate(() => window._getPivotRots());
  console.log('Rotation sample 1:', JSON.stringify(r1));

  await page.waitForTimeout(1000);

  const r2 = await page.evaluate(() => window._getPivotRots());
  console.log('Rotation sample 2:', JSON.stringify(r2));

  if (r1.crankFound && r2.crankFound) {
    const crankYDelta = r2.crankY - r1.crankY;
    const drumYDelta = r2.drumY - r1.drumY;
    console.log('Crank rotation.y delta: ' + crankYDelta.toFixed(6));
    console.log('Drum rotation.y delta: ' + drumYDelta.toFixed(6));
    console.log('Crank spins: ' + (Math.abs(crankYDelta) > 0.001));
    console.log('Drum spins same direction as crank: ' + (Math.sign(drumYDelta) === Math.sign(crankYDelta)));
    console.log('Drum at half rate: ' + (Math.abs(Math.abs(drumYDelta) - Math.abs(crankYDelta) * 0.5) < 0.01));
  } else {
    console.log('Could not find pivot objects in scene graph');
  }

  // 5. Screenshots
  await page.waitForTimeout(500);
  await page.screenshot({ path: '/tmp/v2_anim_a.png' });
  console.log('Screenshot A taken');
  
  await page.waitForTimeout(2000);
  await page.screenshot({ path: '/tmp/v2_anim_b.png' });
  console.log('Screenshot B taken');

  const bufA = fs.readFileSync('/tmp/v2_anim_a.png');
  const bufB = fs.readFileSync('/tmp/v2_anim_b.png');
  const diffResult = bufA.equals(bufB) ? 'IDENTICAL' : 'different';
  console.log('Screenshot comparison: ' + diffResult);

  // 6. Console errors
  console.log('Console errors: ' + errors.length);
  errors.forEach(e => console.log('  Error: ' + e));

  // 7. Terminate playwright
  await browser.close();
  console.log('Browser closed');

  try {
    const pgrep = execSync('pgrep -f playwright || echo "none"').toString().trim();
    console.log('Remaining playwright processes: ' + pgrep);
  } catch(e) {
    console.log('No playwright processes found');
  }
})();
