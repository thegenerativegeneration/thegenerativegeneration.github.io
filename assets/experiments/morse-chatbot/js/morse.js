/**
 * Morse code encode / decode utilities.
 */

export const MORSE_MAP = {
  '.-':    'A', '-...':  'B', '-.-.': 'C', '-..':  'D', '.':    'E',
  '..-.':  'F', '--.':   'G', '....': 'H', '..':   'I', '.---': 'J',
  '-.-':   'K', '.-..':  'L', '--':   'M', '-.':   'N', '---':  'O',
  '.--.':  'P', '--.-':  'Q', '.-.':  'R', '...':  'S', '-':    'T',
  '..-':   'U', '...-':  'V', '.--':  'W', '-..-': 'X', '-.--': 'Y',
  '--..':  'Z',
  '-----': '0', '.----': '1', '..---': '2', '...--': '3', '....-': '4',
  '.....': '5', '-....': '6', '--...': '7', '---..': '8', '----.': '9',
  '.-.-.-': '.', '--..--': ',', '..--..': '?', '-..-.': '/',
  '.--.-.': '@', '---...': ':', '-....-': '-', '.-.-..': '!',
};

const TEXT_MAP = Object.fromEntries(
  Object.entries(MORSE_MAP).map(([code, char]) => [char, code])
);

/** Decode a morse string ("-- --- .-. ... .") to plain text. */
export function morseToText(morse) {
  return morse.trim().split(' / ').map(word =>
    word.split(' ').map(code => MORSE_MAP[code] ?? '?').join('')
  ).join(' ');
}

/** Encode plain text to a morse string. */
export function textToMorse(text) {
  return text.toUpperCase().split(' ').map(word =>
    word.split('').map(c => TEXT_MAP[c] ?? '?').join(' ')
  ).join(' / ');
}
