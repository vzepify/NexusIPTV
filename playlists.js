(() => {
  "use strict";
  const API = String(window.NEXUS_PORTAL_API || "").replace(/\/+$/, "");
  const saved = localStorage.getItem("nexusDevice");
  if (!saved) { window.location.href = "../"; return; }
  let state;
  try { state = JSON.parse(saved); } catch (_) { window.location.href = "../"; return; }
  if (!state.mac || !state.deviceKey) { window.location.href = "../"; return; }

  const $ = (id) => document.getElementById(id);
  $("deviceLabel").textContent = state.mac;
  const list = $("playlistList");
  const status = $("playlistStatus");
  const form = $("playlistForm");
  const saveButton = $("saveButton");

  function setStatus(text, error = false) { status.textContent = text || ""; status.classList.toggle("error", error); }

  async function request(path, options = {}) {
    const response = await fetch(API + path, {
      ...options,
      headers: { "Content-Type": "application/json", ...(options.headers || {}) }
    });
    let data = {};
    try { data = await response.json(); } catch (_) {}
    if (!response.ok) throw new Error(data.error || `Request failed (${response.status})`);
    return data;
  }

  async function loadPlaylists() {
    const query = new URLSearchParams({ mac: state.mac, deviceKey: state.deviceKey });
    const data = await request("/api/playlists?" + query.toString());
    const playlists = Array.isArray(data.playlists) ? data.playlists : [];
    list.innerHTML = "";
    if (!playlists.length) {
      list.innerHTML = '<div class="empty">No playlists saved for this device yet.</div>';
      return;
    }
    for (const playlist of playlists) {
      const row = document.createElement("div");
      row.className = "playlist";
      const info = document.createElement("div");
      const name = document.createElement("div"); name.className = "playlistName"; name.textContent = playlist.name || "Unnamed playlist";
      const meta = document.createElement("div"); meta.className = "playlistMeta";
      meta.textContent = `${playlist.server || ""}${playlist.hidden ? " • Hidden" : ""}${playlist.locked ? " • Locked" : ""}`;
      info.append(name, meta);
      const remove = document.createElement("button"); remove.className = "danger"; remove.textContent = "DELETE";
      remove.addEventListener("click", async () => {
        if (!confirm(`Delete "${playlist.name}"?`)) return;
        remove.disabled = true;
        try {
          await request("/api/playlists/delete", { method: "POST", body: JSON.stringify({ mac: state.mac, deviceKey: state.deviceKey, id: playlist.id }) });
          await loadPlaylists(); setStatus("Playlist deleted.");
        } catch (err) { setStatus(err.message, true); remove.disabled = false; }
      });
      const actions = document.createElement("div"); actions.className = "playlistActions"; actions.append(remove);
      row.append(info, actions); list.append(row);
    }
  }

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    const name = $("playlistName").value.trim();
    const server = $("server").value.trim().replace(/\/+$/, "");
    const username = $("username").value.trim();
    const password = $("password").value;
    if (!name || !server || !username || !password) { setStatus("Fill in Playlist Name, Server URL, Username, and Password.", true); return; }
    saveButton.disabled = true; setStatus("Saving playlist...");
    try {
      await request("/api/playlists", {
        method: "POST",
        body: JSON.stringify({ mac: state.mac, deviceKey: state.deviceKey, name, server, username, password, hidden: $("hiddenPlaylist").checked, locked: $("lockedPlaylist").checked })
      });
      form.reset(); await loadPlaylists(); setStatus("Playlist saved successfully.");
    } catch (err) { setStatus(err.message, true); }
    finally { saveButton.disabled = false; }
  });

  $("logoutButton").addEventListener("click", () => { localStorage.removeItem("nexusDevice"); window.location.href = "../"; });

  loadPlaylists().catch(err => setStatus(err.message, true));
})();
