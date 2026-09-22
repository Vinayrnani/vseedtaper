const pool = require('./playwright_pool');

(async () => {
  const { browser, page } = await pool.newPage({ width: 1600, height: 1000 });

  const errors = [];
  page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
  page.on('pageerror', err => errors.push(err.message));

  await page.goto('http://localhost:9099/index.html', { waitUntil: 'networkidle' });
  await page.waitForFunction(() => window._pivots && window._setRotations, { timeout: 15000 });
  await page.waitForTimeout(2000);

  // Pivot positions
  const pivots = await page.evaluate(() => {
    const p = window._pivots;
    return {
      drum: { x: p.drum.position.x, y: p.drum.position.y, z: p.drum.position.z },
      crankMount: { x: p.crankMount.position.x, y: p.crankMount.position.y, z: p.crankMount.position.z }
    };
  });

  console.log('=== PIVOTS ===');
  console.log('drumPivot:', JSON.stringify(pivots.drum));
  console.log('crankMount:', JSON.stringify(pivots.crankMount));

  const tol = 0.15;
  const drumOk = Math.abs(pivots.drum.x - 100) < tol && Math.abs(pivots.drum.y - 60) < tol && Math.abs(pivots.drum.z - (-30)) < tol;
  const crankOk = Math.abs(pivots.crankMount.x - 160) < tol && Math.abs(pivots.crankMount.y - 60) < tol && Math.abs(pivots.crankMount.z - (-68)) < tol;
  console.log('drumPivot match:', drumOk ? 'PASS' : 'FAIL');
  console.log('crankMount match:', crankOk ? 'PASS' : 'FAIL');

  // Ratios
  const ratios = await page.evaluate(() => {
    const setRot = window._setRotations;
    setRot(Math.PI / 2);
    const d = window._pivots.drum.rotation.z;
    const t = window._pivots.twister.rotation.x;
    const tk = window._pivots.takeup.rotation.z;
    setRot(0);
    return {
      drum: d - window._pivots.drum.rotation.z,
      twister: t - window._pivots.twister.rotation.x,
      takeup: tk - window._pivots.takeup.rotation.z
    };
  });

  console.log('=== RATIOS (per PI/2 crank) ===');
  const dr = ratios.drum / (Math.PI / 2);
  const tr = ratios.twister / (Math.PI / 2);
  const trk = ratios.takeup / (Math.PI / 2);
  console.log(`drum: ${dr.toFixed(4)} (expect -0.5 ±3%)`);
  console.log(`twister: ${tr.toFixed(4)} (expect -3 ±3%)`);
  console.log(`takeup: ${trk.toFixed(4)} (expect -2 ±3%)`);
  console.log('drum:', Math.abs(dr - (-0.5)) < 0.015 ? 'PASS' : 'FAIL');
  console.log('twister:', Math.abs(tr - (-3)) < 0.09 ? 'PASS' : 'FAIL');
  console.log('takeup:', Math.abs(trk - (-2)) < 0.06 ? 'PASS' : 'FAIL');

  // 3 screenshots while animating
  await page.evaluate(() => window._setRotations(0.3));
  await page.waitForTimeout(500);
  await page.screenshot({ path: 'screenshots/cartridge_front_gears.png', scale: 'css' });

  await page.evaluate(() => window._setRotations(0.6));
  await page.waitForTimeout(500);
  await page.screenshot({ path: 'screenshots/cartridge_full_assembly.png', scale: 'css' });

  await page.evaluate(() => window._setRotations(1.0));
  await page.waitForTimeout(500);
  await page.screenshot({ path: 'screenshots/cartridge_angle2.png', scale: 'css' });

  console.log('=== SCREENSHOTS ===');
  console.log('screenshots/cartridge_front_gears.png');
  console.log('screenshots/cartridge_full_assembly.png');
  console.log('screenshots/cartridge_angle2.png');

  console.log('=== CONSOLE ERRORS ===');
  console.log(errors.length === 0 ? '0 errors (PASS)' : `${errors.length} errors: ${errors.join('; ')}`);

  await page.close();
  await pool.releaseBrowser(browser);
})();
