/**
 * Main application entry point.
 * Wires together: tap detector, morse codec, audio, waveform, chat UI, and API calls.
 */

import { morseToText, textToMorse, MORSE_MAP } from './morse.js';
import { initLLM, chat } from './llm.js';
import { startTone, stopTone, playMorse } from './audio.js';
import { createWaveform }           from './waveform.js';
import { createTapDetector }        from './tap.js';
import { appendMessage, appendThinking } from './chat.js';

// ── DOM refs ──────────────────────────────────────────────────────────────────
const morseDisplay   = document.getElementById('morse-display');
const decodedDisplay = document.getElementById('decoded-display');
const sendBtn        = document.getElementById('send-btn');
const clearBtn       = document.getElementById('clear-btn');
const statusEl       = document.getElementById('status');
const tapKey         = document.getElementById('tap-key');
const refBody        = document.getElementById('morse-ref-body');

// ── State ─────────────────────────────────────────────────────────────────────
let currentSymbol = '';  // dots/dashes not yet committed as a letter
let currentMorse  = '';  // full morse string for the current message
let isBusy        = false; // true while waiting for a reply or playing audio
const history     = []; // {role, content} pairs sent to the API

// ── Waveform ──────────────────────────────────────────────────────────────────
const waveform = createWaveform(document.getElementById('waveform'));

// ── Display helpers ───────────────────────────────────────────────────────────
function updateDisplay() {
  const preview = currentMorse + (currentSymbol ? ' ' + currentSymbol : '');
  morseDisplay.textContent   = preview || '\u00a0';
  decodedDisplay.textContent = preview.trim()
    ? morseToText(preview.trim())
    : 'decoded text appears here\u2026';
  sendBtn.disabled = !currentMorse.trim() && !currentSymbol;
}

let statusTimer = null;
function setStatus(text, ttlMs = 1000) {
  statusEl.textContent = text;
  clearTimeout(statusTimer);
  if (ttlMs > 0) statusTimer = setTimeout(() => { statusEl.textContent = 'READY'; }, ttlMs);
}

// ── Tap detector ──────────────────────────────────────────────────────────────
const tap = createTapDetector({
  onPressStart() {
    waveform.setActive(true);
    tapKey.classList.add('active');
    startTone();
  },
  onPressEnd() {
    stopTone();
    waveform.setActive(false);
    tapKey.classList.remove('active');
  },
  onSymbol(sym) {
    currentSymbol += sym;
    setStatus(sym === '.' ? 'DOT' : 'DASH');
    updateDisplay();
  },
  onLetterCommit(code) {
    currentMorse  += (currentMorse && !currentMorse.endsWith('/ ') ? ' ' : '') + code;
    currentSymbol  = '';
    updateDisplay();
  },
  onWordSpace() {
    if (currentMorse && !currentMorse.endsWith('/ ')) {
      currentMorse += ' / ';
      updateDisplay();
    }
  },
});

tap.bindKeyboard();
tap.bindButton(tapKey);

// ── Keyboard shortcuts ────────────────────────────────────────────────────────
document.addEventListener('keydown', e => {
  if (e.code === 'Enter') { e.preventDefault(); sendMessage(); }
});

// ── Clear ─────────────────────────────────────────────────────────────────────
clearBtn.addEventListener('click', () => {
  currentSymbol = '';
  currentMorse  = '';
  updateDisplay();
  setStatus('CLEARED');
});

// ── Send ──────────────────────────────────────────────────────────────────────
sendBtn.addEventListener('click', sendMessage);

async function sendMessage() {
  if (isBusy) return;
  tap.flush();
  const morse = currentMorse.trim();
  if (!morse) return;

  const userText = morseToText(morse);
  appendMessage('user', morse, userText);
  history.push({ role: 'user', content: userText });

  currentSymbol = '';
  currentMorse  = '';
  updateDisplay();
  isBusy = true;
  sendBtn.disabled = true;
  setStatus('SENDING\u2026', 0);

  const thinking = appendThinking();

  try {
    const reply = await chat(history);
    history.push({ role: 'assistant', content: reply });

    const botMorse = textToMorse(reply);
    thinking.resolve(botMorse, reply);

    setStatus('PLAYING\u2026', 0);
    await playMorse(botMorse);
    setStatus('READY', 0);
    statusEl.textContent = 'READY';

  } catch (err) {
    thinking.remove();
    history.pop(); // remove the user message that never got a reply
    appendMessage('bot', '... --- ...', 'Error: ' + err.message);
    setStatus('ERROR');
  } finally {
    isBusy = false;
  }
}

// ── Morse reference sidebar ───────────────────────────────────────────────────
(function buildRef() {
  const order = [
    ...'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''),
    ...'0123456789'.split(''),
    ...Object.values(MORSE_MAP).filter(c => !/[A-Z0-9]/.test(c)),
  ];
  for (const char of order) {
    const code = Object.keys(MORSE_MAP).find(k => MORSE_MAP[k] === char);
    if (!code) continue;
    const row = document.createElement('div');
    row.className = 'mt-row';
    row.innerHTML = `<span class="mt-char">${char}</span><span class="mt-code">${code}</span>`;
    refBody.appendChild(row);
  }
})();

// ── Init ──────────────────────────────────────────────────────────────────────
updateDisplay();

// ── LLM bootstrap ─────────────────────────────────────────────────────────────
const loadingOverlay = document.getElementById('loading-overlay');
const loadingBar     = document.getElementById('loading-bar');
const loadingText    = document.getElementById('loading-text');

// Keep UI locked until the model is ready
tapKey.disabled  = true;
clearBtn.disabled = true;

initLLM((report) => {
  loadingBar.style.width = (report.progress * 100).toFixed(1) + '%';
  loadingText.textContent = report.text;
}).then(() => {
  loadingOverlay.classList.add('hidden');
  tapKey.disabled   = false;
  clearBtn.disabled = false;
  setStatus('READY', 0);
}).catch((err) => {
  loadingText.textContent = 'ERROR: ' + err.message;
  loadingText.style.color = 'var(--red)';
});
