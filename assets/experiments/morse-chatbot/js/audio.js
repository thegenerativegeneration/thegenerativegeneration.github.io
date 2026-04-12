/**
 * Web Audio engine: beep generation and morse playback.
 */

let audioCtx = null;

function getCtx() {
  if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  if (audioCtx.state === 'suspended') audioCtx.resume();
  return audioCtx;
}

// ── Sustained tone (held while key is pressed) ────────────────────────────────
let _toneOsc  = null;
let _toneGain = null;

/** Start a continuous tone. Call stopTone() when the key is released. */
export function startTone(freqHz = 700, vol = 0.35) {
  if (_toneOsc) stopTone();          // safety: don't stack tones
  const ctx  = getCtx();
  _toneOsc   = ctx.createOscillator();
  _toneGain  = ctx.createGain();
  _toneOsc.connect(_toneGain);
  _toneGain.connect(ctx.destination);
  _toneOsc.type = 'sine';
  _toneOsc.frequency.value = freqHz;
  const t = ctx.currentTime;
  _toneGain.gain.setValueAtTime(0, t);
  _toneGain.gain.linearRampToValueAtTime(vol, t + 0.005);
  _toneOsc.start(t);
}

/** Stop the sustained tone with a short fade to avoid a click. */
export function stopTone() {
  if (!_toneOsc) return;
  const ctx = getCtx();
  const t   = ctx.currentTime;
  _toneGain.gain.setValueAtTime(_toneGain.gain.value, t);
  _toneGain.gain.linearRampToValueAtTime(0, t + 0.008);
  _toneOsc.stop(t + 0.01);
  _toneOsc  = null;
  _toneGain = null;
}

/** Play a fixed-duration beep (used internally by playMorse). */
function beep(durationMs, freqHz = 700, vol = 0.35) {
  const ctx  = getCtx();
  const osc  = ctx.createOscillator();
  const gain = ctx.createGain();
  osc.connect(gain);
  gain.connect(ctx.destination);
  osc.type = 'sine';
  osc.frequency.value = freqHz;
  const t = ctx.currentTime;
  gain.gain.setValueAtTime(0, t);
  gain.gain.linearRampToValueAtTime(vol, t + 0.005);
  gain.gain.linearRampToValueAtTime(vol, t + durationMs / 1000 - 0.01);
  gain.gain.linearRampToValueAtTime(0,   t + durationMs / 1000);
  osc.start(t);
  osc.stop(t + durationMs / 1000 + 0.01);
}

const sleep = ms => new Promise(r => setTimeout(r, ms));

/** Play a full morse string as audio beeps (returns a promise). */
export async function playMorse(morse) {
  const DOT_MS   = 80;
  const DASH_MS  = 240;
  const GAP_MS   = 80;   // between symbols
  const LTR_MS   = 240;  // between letters
  const WORD_MS  = 560;  // between words

  for (const token of morse) {
    if (token === '.') {
      beep(DOT_MS, 700);
      await sleep(DOT_MS + GAP_MS);
    } else if (token === '-') {
      beep(DASH_MS, 700);
      await sleep(DASH_MS + GAP_MS);
    } else if (token === ' ') {
      await sleep(LTR_MS);
    } else if (token === '/') {
      await sleep(WORD_MS);
    }
  }
}
