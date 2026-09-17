'use strict';
// playwright_pool.js — shared Chromium pool for verify_*.js runs.
//
// Reuses ONE browser server process across verify runs (no kill/start
// every run). First caller spawns a detached holder (`__holder`) that
// owns `chromium.launchServer()`; later callers `chromium.connect()` it.
// Idle kill: holder exits + pkill after IDLE_MS with no use (default 10min).
// Parallel: N connections share one server; ref-counted per pid so the
// holder never kills a browser with live clients.
//
// Usage in verify scripts:
//   const pool = require('./playwright_pool');
//   const { browser, page } = await pool.newPage({ width: 1600, height: 1000 });
//   ... await page.close();            // keep: close pages per script
//   ... await pool.releaseBrowser(browser); // NEVER browser.close() here
//
// Full teardown + pkill: `node playwright_pool.js stop`
// Inspect: `node playwright_pool.js status`
// Test-only idle override: VSEEDTAPER_POOL_IDLE_MS=<ms>

const fs = require('fs');
const { spawn, execSync } = require('child_process');
const { chromium } = require('playwright');

const ENDPOINT_FILE = '/tmp/vseedtaper-browser.json';
const LOCK_DIR = '/tmp/vseedtaper-browser.lock';
const IDLE_MS = Number(process.env.VSEEDTAPER_POOL_IDLE_MS) || 10 * 60 * 1000;
const LOCK_TIMEOUT_MS = 15000;
const HOLDER_WAIT_MS = 30000;
const HOLDER_POLL_MS = 15000;
const LAUNCH_ARGS = ['--no-sandbox'];
const DEFAULT_VIEWPORT = { width: 1280, height: 800 };

function isValidState(s) {
  return !!s && typeof s.wsEndpoint === 'string' && s.wsEndpoint.startsWith('ws://')
    && typeof s.holderPid === 'number' && typeof s.lastUsed === 'number'
    && !!s.active && typeof s.active === 'object';
}

function readState() {
  let raw;
  try {
    raw = fs.readFileSync(ENDPOINT_FILE, 'utf8');
  } catch (e) {
    if (e.code === 'ENOENT') return null;
    throw new Error(`playwright_pool: cannot read ${ENDPOINT_FILE}: ${e.message}`);
  }
  try {
    const parsed = JSON.parse(raw);
    if (!isValidState(parsed)) return null;
    return parsed;
  } catch {
    return null; // corrupt file = dead pool, caller recreates under lock
  }
}

function writeStateSync(state) {
  if (!isValidState(state)) throw new Error('playwright_pool: refusing to write invalid state');
  const tmp = `${ENDPOINT_FILE}.${process.pid}.tmp`;
  fs.writeFileSync(tmp, JSON.stringify(state));
  fs.renameSync(tmp, ENDPOINT_FILE);
}

function isPidAlive(pid) {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

function pruneDeadPids(state) {
  for (const pid of Object.keys(state.active)) {
    if (!isPidAlive(Number(pid))) delete state.active[pid];
  }
  return state;
}

async function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function acquireLock() {
  const deadline = Date.now() + LOCK_TIMEOUT_MS;
  for (;;) {
    try {
      fs.mkdirSync(LOCK_DIR);
      return;
    } catch (e) {
      if (e.code !== 'EEXIST') throw new Error(`playwright_pool: lock failed: ${e.message}`);
    }
    try {
      const age = Date.now() - fs.statSync(LOCK_DIR).mtimeMs;
      if (age > LOCK_TIMEOUT_MS) fs.rmdirSync(LOCK_DIR); // stale lock, previous holder died
    } catch { /* raced, retry */ }
    if (Date.now() > deadline) throw new Error('playwright_pool: timed out acquiring lock');
    await sleep(50);
  }
}

function releaseLock() {
  try {
    fs.rmdirSync(LOCK_DIR);
  } catch { /* already gone, ignore */ }
}

async function withLock(fn) {
  await acquireLock();
  try {
    return await fn();
  } finally {
    releaseLock();
  }
}

// mutateStateSync assumes the caller already holds the lock.
function mutateStateSync(fn) {
  const state = readState() || { wsEndpoint: '', holderPid: 0, lastUsed: 0, active: {} };
  fn(state);
  pruneDeadPids(state);
  poolLog(`mutate by=${process.pid} active=${JSON.stringify(state.active)} lastUsed=${state.lastUsed}`);
  if (isValidState(state)) writeStateSync(state);
  return state;
}

async function mutateState(fn) {
  return withLock(async () => mutateStateSync(fn));
}

function poolLog(msg) {
  try {
    fs.appendFileSync('/tmp/vseedtaper-holder.log', `${new Date().toISOString()} pid=${process.pid} ${msg}\n`);
  } catch { /* ignore */ }
}

function pkillChromium() {
  // Bracket patterns so pkill never matches our own command line.
  try {
    execSync("pkill -f '[c]hromium'; pkill -f '[c]hrome-headless-shell'; true", { stdio: 'ignore' });
  } catch { /* best effort */ }
}

async function tryConnect(wsEndpoint, timeoutMs) {
  if (!wsEndpoint) return null;
  try {
    return await chromium.connect(wsEndpoint, { timeout: timeoutMs || 5000 });
  } catch {
    return null;
  }
}

async function tryConnectFromFile() {
  const state = readState();
  if (!state) return null;
  return tryConnect(state.wsEndpoint);
}

function spawnHolderChild() {
  const child = spawn(process.execPath, [__filename, '__holder'], {
    detached: true,
    stdio: 'ignore',
    env: process.env,
  });
  child.unref();
}

async function waitForServer() {
  const deadline = Date.now() + HOLDER_WAIT_MS;
  for (;;) {
    const state = readState();
    if (state) {
      const browser = await tryConnect(state.wsEndpoint);
      if (browser) return browser;
    }
    if (Date.now() > deadline) {
      throw new Error('playwright_pool: holder did not publish a live endpoint in time');
    }
    await sleep(200);
  }
}

async function getBrowser() {
  const fast = await tryConnectFromFile();
  if (fast) {
    await mutateState(s => {
      s.active[process.pid] = (s.active[process.pid] || 0) + 1;
      s.lastUsed = Date.now();
    });
    console.log('playwright_pool: reused browser');
    return fast;
  }
  let lockedBrowser = null;
  await withLock(async () => {
    lockedBrowser = await tryConnectFromFile();
    if (lockedBrowser) {
      mutateStateSync(s => {
        s.active[process.pid] = (s.active[process.pid] || 0) + 1;
        s.lastUsed = Date.now();
      });
      return;
    }
    // A parallel client may have just spawned a holder: wait briefly for
    // its endpoint before spawning our own (avoids double browsers).
    const waited = Date.now() + 3000;
    while (Date.now() < waited) {
      await sleep(200);
      lockedBrowser = await tryConnectFromFile();
      if (lockedBrowser) {
        mutateStateSync(s => {
          s.active[process.pid] = (s.active[process.pid] || 0) + 1;
          s.lastUsed = Date.now();
        });
        return;
      }
    }
    const stale = readState();
    if (stale && stale.holderPid && stale.holderPid !== process.pid && isPidAlive(stale.holderPid)) {
      try {
        process.kill(stale.holderPid, 'SIGTERM'); // reap orphaned holder, it exits quietly
        poolLog(`reaped stale holder ${stale.holderPid}`);
      } catch { /* already gone */ }
    }
    try { fs.unlinkSync(ENDPOINT_FILE); } catch { /* stale/missing, ignore */ }
    spawnHolderChild();
    console.log('playwright_pool: spawned new holder');
  });
  if (lockedBrowser) {
    console.log('playwright_pool: reused browser');
    return lockedBrowser;
  }
  const browser = await waitForServer();
  await mutateState(s => {
    s.active[process.pid] = (s.active[process.pid] || 0) + 1;
    s.lastUsed = Date.now();
  });
  console.log('playwright_pool: connected to new browser');
  return browser;
}

async function newPage(viewport) {
  const browser = await getBrowser();
  const page = await browser.newPage({ viewport: viewport || DEFAULT_VIEWPORT });
  return { browser, page };
}

async function newContext(options) {
  const browser = await getBrowser();
  const context = await browser.newContext(options || { viewport: DEFAULT_VIEWPORT });
  return { browser, context };
}

async function releaseBrowser(browser) {
  // NOTE: on a CONNECTED browser, close() only drops our connection
  // (server stays alive for reuse). Never kills the shared browser.
  try {
    if (browser) await browser.close();
  } catch { /* already gone, ignore */ }
  try {
    await mutateState(s => {
      if (s.active[process.pid] !== undefined) {
        s.active[process.pid] -= 1;
        if (s.active[process.pid] <= 0) delete s.active[process.pid];
      }
      s.lastUsed = Date.now();
    });
  } catch { /* pool already torn down, ignore */ }
  console.log('playwright_pool: released (browser stays alive for reuse)');
}

async function shutdownPool() {
  const state = readState();
  if (state) {
    const browser = await tryConnect(state.wsEndpoint);
    if (browser) {
      try {
        await browser.close();
        console.log('playwright_pool: browser closed');
      } catch (e) {
        console.log(`playwright_pool: browser close failed: ${e.message}`);
      }
    }
    try { fs.unlinkSync(ENDPOINT_FILE); } catch { /* ignore */ }
    if (state.holderPid && isPidAlive(state.holderPid) && state.holderPid !== process.pid) {
      try {
        process.kill(state.holderPid, 'SIGTERM');
        console.log(`playwright_pool: holder ${state.holderPid} stopped`);
      } catch { /* ignore */ }
    }
  } else {
    console.log('playwright_pool: no endpoint file, nothing to close');
  }
  pkillChromium();
  console.log('playwright_pool: pkill done');
}

async function runHolder() {
  poolLog(`holder start IDLE_MS=${IDLE_MS}`);
  process.on('uncaughtException', e => poolLog(`uncaughtException: ${e.message}`));
  process.on('unhandledRejection', e => poolLog(`unhandledRejection: ${e && e.message}`));
  const server = await chromium.launchServer({ headless: true, args: LAUNCH_ARGS });
  writeStateSync({
    wsEndpoint: server.wsEndpoint(),
    holderPid: process.pid,
    lastUsed: Date.now(),
    active: {},
  });
  poolLog(`holder listening ws=${server.wsEndpoint()}`);
  console.log(`playwright_pool holder: listening (pid ${process.pid})`);

  let stopping = false;
  async function teardown(reason, exitCode) {
    if (stopping) return;
    stopping = true;
    poolLog(`teardown reason=${reason}`);
    if (reason === 'superseded') {
      // Lost a spawn race: close ONLY our own just-launched server,
      // never touch the shared file or pkill (winner owns those).
      try { await server.close(); } catch { /* ignore */ }
      process.exit(0);
    }
    releaseLock(); // never exit while holding the lock (stale lock dir)
    try { await server.close(); } catch { /* ignore */ }
    try { fs.unlinkSync(ENDPOINT_FILE); } catch { /* ignore */ }
    pkillChromium();
    process.exit(exitCode);
  }
  process.on('SIGTERM', () => teardown('SIGTERM', 0));
  process.on('SIGINT', () => teardown('SIGINT', 0));

  setInterval(() => {
    if (stopping) return;
    // Decide inside the lock, act outside: teardown() exits the process
    // and must never run while we hold the lock (else stale lock dir).
    withLock(async () => {
      const current = readState();
      if (!current) return 'missing-file';
      if (current.holderPid !== process.pid) return 'superseded'; // stale holder, exit quietly
      const fresh = mutateStateSync(() => { /* prune dead pids only, never touch lastUsed */ });
      const live = Object.values(fresh.active).reduce((a, b) => a + b, 0);
      const idleFor = Date.now() - fresh.lastUsed;
      poolLog(`tick live=${live} idleFor=${idleFor} lastUsed=${fresh.lastUsed}`);
      if (live === 0 && idleFor > IDLE_MS) {
        console.log('playwright_pool holder: idle 10min, shutting down');
        return 'idle-timeout';
      }
      return false;
    }).then(shouldStop => {
      if (shouldStop === 'superseded') teardown('superseded', 0);
      else if (shouldStop) teardown(shouldStop, 0);
    }).catch(() => { /* lock race, retry next tick */ });
  }, HOLDER_POLL_MS);
}

if (require.main === module) {
  (async () => {
    const cmd = process.argv[2];
    if (cmd === '__holder') {
      await runHolder();
    } else if (cmd === 'stop') {
      await shutdownPool();
    } else if (cmd === 'status') {
      const state = readState();
      if (!state) {
        console.log('playwright_pool: no pool running');
        return;
      }
      console.log(JSON.stringify({ ...state, idleMs: IDLE_MS }, null, 2));
      const probe = await tryConnect(state.wsEndpoint, 3000);
      if (probe) {
        console.log('playwright_pool: endpoint ALIVE');
        await probe.close().catch(() => {});
      } else {
        console.log('playwright_pool: endpoint DEAD');
      }
    } else {
      console.log('usage: node playwright_pool.js [status|stop]');
      process.exit(1);
    }
  })().catch(e => { console.error(`playwright_pool failed: ${e.message}`); process.exit(1); });
}

module.exports = {
  getBrowser,
  newPage,
  newContext,
  releaseBrowser,
  shutdownPool,
  ENDPOINT_FILE,
  IDLE_MS,
  LAUNCH_ARGS,
  DEFAULT_VIEWPORT,
};
