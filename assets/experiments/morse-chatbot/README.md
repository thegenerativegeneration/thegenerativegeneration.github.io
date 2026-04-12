# Morse Chatbot

A browser Morse-code chat experience: you tap dots and dashes, the app decodes them to text, runs an in-browser LLM, then plays and displays the reply back in Morse.

## How it works

```
[space bar / TAP button]
          ↓
 tap.js classifies press duration as dot or dash
          ↓
 morse.js decodes symbols to plain text
          ↓
 llm.js sends chat history to WebLLM (in browser, WebGPU)
          ↓
 reply text is encoded back to Morse and played as tone
```

## Tapping guide

| Action | Timing |
| --- | --- |
| Dot | tap < 200 ms |
| Dash | tap >= 200 ms |
| Next letter | pause 700 ms |
| Word space | pause 1.6 s |
| Send message | press **Enter** or click **SEND** |

You can tap with the on-screen **TAP** button or the **Space bar**.

## Requirements

- A WebGPU-capable browser (latest Chrome/Edge recommended)

No API key is required in the current implementation.

## Run

Open `index.html` from `public/morse-chatbot` in a modern browser.

If your browser blocks direct file access for module imports, serve this folder with any simple static file server and open the served page.

## Development

All app logic is client-side and lives in this experiment folder:

- `index.html`
- `style.css`
- `js/*.js`

## Experiment structure

```
.
├── index.html
├── meta.json
├── README.md
├── style.css
└── js/
    ├── app.js
    ├── audio.js
    ├── chat.js
    ├── llm.js
    ├── morse.js
    ├── tap.js
    └── waveform.js
```

## Notes

- No backend chat API is required for this experiment.
- The model is configured in `js/llm.js`.
