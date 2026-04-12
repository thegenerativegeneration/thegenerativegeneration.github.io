/**
 * Chat UI: appending user and bot message bubbles to the chat pane.
 */

const chatEl = document.getElementById('chat');

function scrollToBottom() {
  chatEl.scrollTop = chatEl.scrollHeight;
}

function buildBubble(role, morse, text) {
  const wrap = document.createElement('div');
  wrap.className = `msg ${role}`;

  const label = document.createElement('div');
  label.className = 'msg-label';
  label.textContent = role === 'user' ? 'YOU' : 'BOT';

  const bubble = document.createElement('div');
  bubble.className = 'msg-bubble';

  const morseDiv = document.createElement('div');
  morseDiv.className = 'msg-morse';
  morseDiv.textContent = morse;

  const textDiv = document.createElement('div');
  textDiv.className = 'msg-text';
  textDiv.textContent = text;

  bubble.append(morseDiv, textDiv);
  wrap.append(label, bubble);
  return { wrap, morseDiv, textDiv };
}

export function appendMessage(role, morse, text) {
  const { wrap } = buildBubble(role, morse, text);
  chatEl.appendChild(wrap);
  scrollToBottom();
}

export function appendThinking() {
  const { wrap, morseDiv, textDiv } = buildBubble('bot', '', 'transmitting\u2026');
  morseDiv.classList.add('thinking-dots');
  chatEl.appendChild(wrap);
  scrollToBottom();
  return {
    resolve(morse, text) {
      morseDiv.classList.remove('thinking-dots');
      morseDiv.textContent = morse;
      textDiv.textContent  = text;
      scrollToBottom();
    },
    remove() { wrap.remove(); },
  };
}
