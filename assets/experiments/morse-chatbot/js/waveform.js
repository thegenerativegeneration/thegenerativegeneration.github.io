/**
 * Animating waveform bar visualizer tied to key-press state.
 */

const NUM_BARS = 32;

export function createWaveform(container) {
  for (let i = 0; i < NUM_BARS; i++) {
    const bar = document.createElement('div');
    bar.className = 'wv-bar';
    bar.style.height = '4px';
    container.appendChild(bar);
  }

  const bars = [...container.querySelectorAll('.wv-bar')];
  let rafId   = null;
  let active  = false;

  function frame() {
    bars.forEach(bar => {
      if (active) {
        bar.style.height     = (4 + Math.random() * 18) + 'px';
        bar.style.background = 'var(--green)';
        bar.style.boxShadow  = '0 0 4px var(--green)';
      } else {
        bar.style.height     = '4px';
        bar.style.background = 'var(--green-dim)';
        bar.style.boxShadow  = 'none';
      }
    });
    if (active) rafId = requestAnimationFrame(frame);
  }

  return {
    setActive(on) {
      active = on;
      if (rafId) cancelAnimationFrame(rafId);
      frame();
    },
  };
}
