/**
 * In-browser LLM via WebLLM (WebGPU).
 * Replaces the Express /chat backend — no server needed.
 */

import * as webllm from 'https://esm.run/@mlc-ai/web-llm';

const MODEL = 'Qwen3-0.6B-q4f16_1-MLC';

const SYSTEM_PROMPT =
  'You are a telegraph operator. ' +
  'The user communicates with you exclusively via Morse code, and your responses will be ' +
  'converted back to Morse code and transmitted to them.\n\n' +
  'Rules:\n' +
  '- Keep responses SHORT — ideally under 10 words.\n' +
  '- Long words and punctuation are costly to tap, so be concise.\n' +
  '- No markdown, no bullet points, no special characters except . , ? ! -\n' +
  '- You may occasionally use radio/telegraph lingo (COPY THAT, ROGER, OVER) for flavour.\n' +
  '- Be knowledgeable, friendly, and slightly old-fashioned in vocabulary.';

/** @type {webllm.MLCEngine|null} */
let engine = null;

/**
 * Download and initialise the model.
 * @param {(report: {progress: number, text: string}) => void} onProgress
 */
export async function initLLM(onProgress) {
  engine = await webllm.CreateMLCEngine(MODEL, {
    initProgressCallback: onProgress,
  });
}

/**
 * Strip <think>…</think> blocks that Qwen3 emits in thinking mode.
 * Also handles an unclosed <think> tag (model cut off mid-thought).
 * @param {string} text
 * @returns {string}
 */
function stripThinkTags(text) {
  return text
    .replace(/<think>[\s\S]*?<\/think>/g, '')  // complete blocks
    .replace(/<think>[\s\S]*/g, '')             // unclosed block
    .trim();
}

/**
 * Run a chat completion against the loaded model.
 * Appends /no_think to the last user message so Qwen3 skips its reasoning
 * chain — the history passed in is never mutated.
 * @param {{ role: string, content: string }[]} messages  conversation history
 * @returns {Promise<string>} uppercased reply text
 */
export async function chat(messages) {
  if (!engine) throw new Error('LLM not initialised');

  // Append /no_think to the last user turn without mutating the caller's array.
  const patched = messages.map((m, i) =>
    i === messages.length - 1 && m.role === 'user'
      ? { ...m, content: m.content + ' /no_think' }
      : m
  );

  const response = await engine.chat.completions.create({
    messages: [
      { role: 'system', content: SYSTEM_PROMPT },
      ...patched,
    ],
    max_tokens: 64,
  });

  const raw = response.choices[0].message.content;
  return stripThinkTags(raw).toUpperCase();
}
