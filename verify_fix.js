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
  console.log('Console errors:', errors.length);
  errors.forEach(e => console.log('  ', e));

  // Screenshots at t=0 and t=0.25
  await page.screenshot({ path: '/tmp/fix_t0.png' });
  console.log('Screenshot /tmp/fix_t0.png taken');
  await page.waitForTimeout(1000);
  await page.screenshot({ path: '/tmp/fix_t25.png' });
  console.log('Screenshot /tmp/fix_t25.png taken');

  // Sample crank grip positions at 4 animation frames
  const crankPositions = [];
  for (let i = 0; i < 4; i++) {
    const t = i * 0.25;
    const angle = t * Math.PI * 2;
    await page.evaluate((a) => window._setRotations(a), angle);
    await page.waitForTimeout(100);

    const result = await page.evaluate(() => window._getPivotData());
    if (result.crankGrips.length > 0) {
      crankPositions.push(result.crankGrips[0]);
      console.log(`Frame t=${t}: grip=(${result.crankGrips[0].x.toFixed(2)}, ${result.crankGrips[0].y.toFixed(2)}, ${result.crankGrips[0].z.toFixed(2)})`);
    } else {
      console.log(`Frame t=${t}: no crank grip found`);
      crankPositions.push(null);
    }
    await page.waitForTimeout(200);
  }

  // Check crank orbit radius
  // Shaft is at crankMount(160,60,-38) + crankSpinner(-5,0,-8.47) = (155,60,-46.47) in root-local
  console.log('\n--- Crank orbit check ---');
  const shaftX = 155, shaftZ = -46.47;
  const radii = [];
  for (const pos of crankPositions) {
    if (pos) {
      const dx = pos.x - shaftX;
      const dz = pos.z - shaftZ;
      const r = Math.sqrt(dx*dx + dz*dz);
      radii.push(r);
      console.log(`  radius=${r.toFixed(2)}`);
    }
  }
  const validRadii = radii.filter(r => !isNaN(r));
  const avgR = validRadii.reduce((a,b) => a+b, 0) / validRadii.length;
  console.log(`Average radius: ${avgR.toFixed(2)} (expected ~45, within ±5: ${Math.abs(avgR - 45) <= 5})`);

  // Check axle horizontal
  console.log('\n--- Axle horizontal check ---');
  const data = await page.evaluate(() => window._getPivotData());
  if (data.lowerAxle) {
    console.log(`  lowerAxle y=${data.lowerAxle.y.toFixed(6)}, horizontal=${Math.abs(data.lowerAxle.y) < 0.01}`);
  }
  if (data.upperAxle) {
    console.log(`  upperAxle y=${data.upperAxle.y.toFixed(6)}, horizontal=${Math.abs(data.upperAxle.y) < 0.01}`);
  }
  if (data.drumAxle) {
    console.log(`  drumAxle y=${data.drumAxle.y.toFixed(6)}, horizontal=${Math.abs(data.drumAxle.y) < 0.01}`);
  }

  // Also check the pivot positions
  console.log('\n--- Pivot positions ---');
  console.log('  crankSpinner:', JSON.stringify(data.crankSpinner.pos));
  console.log('  lowerPivot:', JSON.stringify(data.lowerPivot.pos));
  console.log('  upperPivot:', JSON.stringify(data.upperPivot.pos));
  console.log('  drumPivot:', JSON.stringify(data.drumPivot.pos));

  console.log('\nScreenshots: /tmp/fix_t0.png, /tmp/fix_t25.png');
  await browser.close();
  console.log('Browser closed');
})();
