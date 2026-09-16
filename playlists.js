const API = String(window.NEXUS_CONFIG?.API_BASE || '').replace(/\/+$/, '');
const deviceId = localStorage.getItem('nexus_device_id') || '';
const deviceKey = localStorage.getItem('nexus_device_key') || '';
const $ = (id) => document.getElementById(id);

function setStatus(id, message, kind = '') {
  const el = $(id);
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
    if (!response.ok || data.ok === false) throw new Error(data.error || `HTTP ${response.status}`);
    return data;
  } finally {
    clearTimeout(timer);
  }
}

function authQuery() {
  return `deviceId=${encodeURIComponent(deviceId)}&deviceKey=${encodeURIComponent(deviceKey)}&mac=${encodeURIComponent(deviceId)}`;
}

function escapeHtml(value) {
  return String(value ?? '').replace(/[&<>'"]/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[ch]));
}

async function loadPlaylists() {
  const list = $('playlistList');
  list.innerHTML = '<div class="empty">Refreshing playlists...</div>';
  try {
    const data = await fetchJson(`/api/playlists?${authQuery()}`);
    const rows = Array.isArray(data.playlists) ? data.playlists : [];
    $('count').textContent = String(rows.length);
    if (!rows.length) {
      list.innerHTML = '<div class="empty">No playlists saved yet.</div>';
      return;
    }
    list.innerHTML = rows.map(p => `
      <article class="playlist-card">
        <div>
          <h3>${escapeHtml(p.name)}</h3>
          <p>${escapeHtml(p.server)}</p>
          <small>${escapeHtml(p.username)}</small>
        </div>
        <button class="button danger" data-delete="${Number(p.id)}">Delete</button>
      </article>`).join('');
    list.querySelectorAll('[data-delete]').forEach(btn => {
      btn.addEventListener('click', () => deletePlaylist(Number(btn.dataset.delete)));
    });
  } catch (error) {
    list.innerHTML = `<div class="empty error">${escapeHtml(error.name === 'AbortError' ? 'API request timed out.' : error.message)}</div>`;
  }
}

async function deletePlaylist(id) {
  if (!confirm('Delete this playlist?')) return;
  try {
    await fetchJson('/api/playlists/delete', {
      method: 'POST',
      body: JSON.stringify({ id, deviceId, deviceKey, mac: deviceId })
    });
    await loadPlaylists();
  } catch (error) {
    setStatus('globalStatus', error.message || 'Could not delete playlist.', 'error');
  }
}

$('playlistForm')?.addEventListener('submit', async (event) => {
  event.preventDefault();
  const button = $('saveButton');
  button.disabled = true;
  button.textContent = 'Saving...';
  setStatus('formStatus', 'Saving playlist...');
  const body = {
    deviceId,
    deviceKey,
    mac: deviceId,
    name: $('name').value.trim(),
    server: $('server').value.trim().replace(/\/+$/, ''),
    username: $('username').value.trim(),
    password: $('password').value
  };
  try {
    await fetchJson('/api/playlists', { method: 'POST', body: JSON.stringify(body) });
    event.target.reset();
    setStatus('formStatus', 'Playlist saved.', 'success');
    await loadPlaylists();
  } catch (error) {
    setStatus('formStatus', error.message || 'Could not save playlist.', 'error');
  } finally {
    button.disabled = false;
    button.textContent = 'Save playlist';
  }
});

$('refresh')?.addEventListener('click', loadPlaylists);
$('logout')?.addEventListener('click', () => {
  localStorage.removeItem('nexus_device_id');
  localStorage.removeItem('nexus_device_key');
  window.location.href = '../';
});

if (!deviceId || !deviceKey) {
  window.location.href = '../';
} else {
  $('deviceId').textContent = deviceId;
  $('deviceKey').textContent = deviceKey;
  loadPlaylists();
  setInterval(loadPlaylists, 30000);
}
