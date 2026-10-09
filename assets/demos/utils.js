// Microphone input with a device picker.
//
// Permission is requested on click rather than on load: browsers block
// AudioContexts started without a user gesture, and device ids and labels
// stay empty until permission is granted (Firefox rejects an `exact`
// constraint on such an empty id).

const ERROR_MESSAGES = {
    NotAllowedError: 'Microphone access was blocked. Allow it in the site settings and try again.',
    NotFoundError: 'No microphone found.',
    NotReadableError: 'The microphone is in use by another application.',
    OverconstrainedError: 'That microphone is no longer available.',
};

const el = (tag, props = {}) => Object.assign(document.createElement(tag), props);

const createAudioInput = (container, { fftSize }) => {
    const ui = el('div', { className: 'audio-input' });
    const start = el('button', { type: 'button', className: 'audio-input__start', textContent: 'Start microphone' });
    const picker = el('label', { className: 'audio-input__picker', textContent: 'Input ', hidden: true });
    const select = el('select', { className: 'audio-input__select' });
    const status = el('span', { className: 'audio-input__status', role: 'status' });
    picker.append(select);
    ui.append(start, picker, status);
    container.append(ui);

    let audioCtx, analyser, source, stream;

    const showError = (err) => {
        status.textContent = ERROR_MESSAGES[err.name] || `Microphone error: ${err.message}`;
    };

    const stopStream = () => {
        stream?.getTracks().forEach((track) => track.stop());
        source?.disconnect();
        stream = source = null;
    };

    const refreshDevices = async () => {
        const devices = (await navigator.mediaDevices.enumerateDevices())
            .filter((device) => device.kind === 'audioinput');
        const current = stream?.getAudioTracks()[0]?.getSettings().deviceId;
        select.replaceChildren(...devices.map((device, i) =>
            el('option', { value: device.deviceId, textContent: device.label || `Microphone ${i + 1}` })));
        if (current) select.value = current;
    };

    const useDevice = async (deviceId) => {
        stopStream();
        stream = await navigator.mediaDevices.getUserMedia({
            audio: deviceId ? { deviceId: { exact: deviceId } } : true,
        });
        source = audioCtx.createMediaStreamSource(stream);
        source.connect(analyser);
        // Fall back to the default input when the device is unplugged.
        stream.getAudioTracks()[0].addEventListener('ended', () => {
            useDevice().then(refreshDevices).catch(showError);
        });
        status.textContent = '';
    };

    start.addEventListener('click', async () => {
        if (!navigator.mediaDevices?.getUserMedia) {
            status.textContent = 'This browser does not allow microphone access here.';
            return;
        }
        // Created and resumed synchronously inside the click so autoplay rules allow it.
        audioCtx ??= new AudioContext();
        audioCtx.resume();
        if (!analyser) {
            analyser = audioCtx.createAnalyser();
            analyser.fftSize = fftSize;
        }
        start.disabled = true;
        status.textContent = 'Waiting for permission…';
        try {
            await useDevice();
            await refreshDevices();
            navigator.mediaDevices.addEventListener('devicechange', () => refreshDevices().catch(showError));
            start.hidden = true;
            picker.hidden = false;
        } catch (err) {
            showError(err);
            start.disabled = false;
        }
    });

    select.addEventListener('change', () => {
        useDevice(select.value).then(refreshDevices).catch(showError);
    });

    // Null until a stream is connected. The analyser itself outlives device switches.
    return { get analyser() { return stream ? analyser : null; } };
};

export { createAudioInput };
