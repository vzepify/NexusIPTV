const API = String(window.NEXUS_CONFIG?.API_BASE || '').replace(/\/+$/, '');
const $ = (id) => document.getElementById(id);

function setStatus(message, kind = '') {
  const el = $('status');
  if (!el) return;
  el.textContent = message;
  el.className = `status ${kind}`.trim();
}

async function fetchJson(path, options = {}, timeoutMs = 10000) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(`${API}${path}`, {
      ...options,
      signal: controller.signal,
      headers: { 'Content-Type': 'application/json', ...(options.headers || {}) }
    });
    let data = {};
    try { data = await response.json(); } catch (_) {}
    if (!response.ok || data.ok === false) {
      throw new Error(data.error || `HTTP ${response.status}`);
    }
    return data;
  } finally {
    clearTimeout(timer);
  }
}

function saveCredentials(deviceId, deviceKey) {
  localStorage.setItem('nexus_device_id', deviceId);
  localStorage.setItem('nexus_device_key', deviceKey);
}

$('loginForm')?.addEventListener('submit', async (event) => {
  event.preventDefault();
  const deviceId = $('deviceId').value.trim();
  const deviceKey = $('deviceKey').value.trim();
  const button = $('loginButton');

  if (!deviceId || !deviceKey) {
    setStatus('Enter both the Device ID and Device Key.', 'error');
    return;
  }

  button.disabled = true;
  button.textContent = 'Connecting...';
  setStatus('Connecting to Nexus IPTV API...');

  try {
    // New API accepts deviceId. mac is included only for compatibility with the older API.
    await fetchJson('/api/device/login', {
      method: 'POST',
      body: JSON.stringify({ deviceId, deviceKey, mac: deviceId })
    });
    saveCredentials(deviceId, deviceKey);
    setStatus('Roku connected. Opening playlists...', 'success');
    setTimeout(() => { window.location.href = 'playlists/'; }, 250);
  } catch (error) {
    setStatus(error.name === 'AbortError'
      ? 'The API took too long to respond.'
      : error.message || 'Could not connect to the API.', 'error');
    button.disabled = false;
    button.textContent = 'Connect Roku';
  }
});
