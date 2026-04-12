/**
 * Telegraph-key tap detector.
 *
 * Fires onDot / onDash callbacks as the user taps, and onLetterCommit /
 * onWordSpace when silence thresholds are crossed.
 *
 * Timing (all in ms):
 *   DOT_THRESHOLD  – press shorter than this → dot, else dash
 *   LETTER_GAP     – silence after which the current symbol is committed as a letter
 *   WORD_GAP       – silence after which a word separator is inserted
 */

const DOT_THRESHOLD = 200;
const LETTER_GAP    = 700;
const WORD_GAP      = 1600;

/**
 * @param {{
 *   onSymbol:       (symbol: '.'|'-') => void,
 *   onLetterCommit: (letter: string)  => void,
 *   onWordSpace:    ()                => void,
 *   onPressStart:   ()                => void,
 *   onPressEnd:     ()                => void,
 * }} callbacks
 */
export function createTapDetector(callbacks) {
  const { onSymbol, onLetterCommit, onWordSpace, onPressStart, onPressEnd } = callbacks;

  let pressStart   = 0;
  let isPressed    = false;
  let currentCode  = '';   // dots/dashes for the letter in progress
  let letterTimer  = null;
  let wordTimer    = null;

  function commitLetter() {
    if (!currentCode) return;
    onLetterCommit(currentCode);
    currentCode = '';
    clearTimeout(wordTimer);
    wordTimer = setTimeout(onWordSpace, WORD_GAP);
  }

  function pressDown() {
    if (isPressed) return;
    isPressed = true;
    pressStart = Date.now();
    clearTimeout(letterTimer);
    clearTimeout(wordTimer);
    onPressStart();
  }

  function pressUp() {
    if (!isPressed) return;
    isPressed = false;
    onPressEnd();

    const sym = (Date.now() - pressStart) < DOT_THRESHOLD ? '.' : '-';
    currentCode += sym;
    onSymbol(sym);

    clearTimeout(letterTimer);
    letterTimer = setTimeout(commitLetter, LETTER_GAP);
  }

  /** Force-commit whatever is buffered right now (used before sending). */
  function flush() {
    clearTimeout(letterTimer);
    clearTimeout(wordTimer);
    if (currentCode) commitLetter();
    // commitLetter() sets a new wordTimer; clear it so it doesn't fire
    // unexpectedly while the message is being sent/received.
    clearTimeout(wordTimer);
  }

  /** Bind keyboard events to the document. */
  function bindKeyboard() {
    document.addEventListener('keydown', e => {
      if (e.code === 'Space' && !e.repeat) { e.preventDefault(); pressDown(); }
    });
    document.addEventListener('keyup', e => {
      if (e.code === 'Space') { e.preventDefault(); pressUp(); }
    });
  }

  /** Bind mouse + touch events to a DOM element. */
  function bindButton(el) {
    el.addEventListener('mousedown',  e => { e.preventDefault(); pressDown(); });
    el.addEventListener('touchstart', e => { e.preventDefault(); pressDown(); }, { passive: false });
    window.addEventListener('mouseup',  () => { if (isPressed) pressUp(); });
    window.addEventListener('touchend', () => { if (isPressed) pressUp(); });
  }

  return { bindKeyboard, bindButton, flush };
}
