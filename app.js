(() => {
  "use strict";

  const API = String(window.NEXUS_PORTAL_API || "").replace(/\/+$/, "");
  const state = { mac: "", deviceKey: "", playlists: [] };

  const $ = (id) => document.getElementById(id);
  const loginCard = $("loginCard");
  const portalCard = $("portalCard");
  const loginForm = $("loginForm");
  const playlistForm = $("playlistForm");
  const loginStatus = $("loginStatus");
  const playlistStatus = $("playlistStatus");
  const playlistList = $("playlistList");

  function setStatus(el, message, error = false) {
    el.textContent = message || "";
    el.classList.toggle("error", error);
  }

  function apiUrl(path) {
    return API + path;
  }

  async function request(path, options = {}) {
    if (!API || API.includes("YOUR-API-DOMAIN")) {
      throw new Error("Set your API URL in config.js first.");
    }
    const response = await fetch(apiUrl(path), {
      ...options,
      headers: { "Content-Type": "application/json", ...(options.headers || {}) }
    });
    let data = {};
    try { data = await response.json(); } catch (_) {}
    if (!response.ok) throw new Error(data.error || `Request failed (${response.status})`);
    return data;
  }

  function credentials() {
    return { mac: state.mac, deviceKey: state.deviceKey };
  }

  function renderPlaylists() {
    playlistList.innerHTML = "";
    if (!state.playlists.length) {
      playlistList.innerHTML = '<div class="empty">No playlists saved for this device yet.</div>';
      return;
    }
    for (const playlist of state.playlists) {
      const row = document.createElement("div");
      row.className = "playlist";

      const info = document.createElement("div");
      const name = document.createElement("div");
      name.className = "playlistName";
      name.textContent = playlist.name || "Unnamed playlist";
      const meta = document.createElement("div");
      meta.className = "playlistMeta";
      meta.textContent = `${playlist.server || ""}${playlist.hidden ? " • Hidden" : ""}${playlist.locked ? " • Locked" : ""}`;
      info.append(name, meta);

      const actions = document.createElement("div");
      actions.className = "playlistActions";

      const remove = document.createElement("button");
      remove.className = "danger";
      remove.textContent = "DELETE";
      remove.addEventListener("click", async () => {
        if (!confirm(`Delete "${playlist.name}"?`)) return;
        try {
          await request("/api/playlists/delete", {
            method: "POST",
            body: JSON.stringify({ ...credentials(), id: playlist.id })
          });
          await loadPlaylists();
          setStatus(playlistStatus, "Playlist deleted.");
        } catch (err) {
          setStatus(playlistStatus, err.message, true);
        }
      });

      actions.append(remove);
      row.append(info, actions);
      playlistList.append(row);
    }
  }

  async function loadPlaylists() {
    const data = await request("/api/playlists", {
      method: "POST",
      body: JSON.stringify(credentials())
    });
    state.playlists = Array.isArray(data.playlists) ? data.playlists : [];
    renderPlaylists();
  }

  loginForm.addEventListener("submit", async (event) => {
    event.preventDefault();
    state.mac = $("mac").value.trim();
    state.deviceKey = $("deviceKey").value.trim();

    if (!state.mac || !state.deviceKey) return;
    const button = loginForm.querySelector("button");
    button.disabled = true;
    setStatus(loginStatus, "Checking device...");
    try {
      await request("/api/device/login", {
        method: "POST",
        body: JSON.stringify(credentials())
      });
      $("deviceLabel").textContent = state.mac;
      await loadPlaylists();
      loginCard.classList.add("hidden");
      portalCard.classList.remove("hidden");
      setStatus(loginStatus, "");
    } catch (err) {
      setStatus(loginStatus, err.message, true);
    } finally {
      button.disabled = false;
    }
  });

  playlistForm.addEventListener("submit", async (event) => {
    event.preventDefault();
    const button = playlistForm.querySelector("button");
    button.disabled = true;
    setStatus(playlistStatus, "Saving playlist...");
    const payload = {
      ...credentials(),
      name: $("playlistName").value.trim(),
      server: $("server").value.trim().replace(/\/+$/, ""),
      username: $("username").value.trim(),
      password: $("password").value,
      hidden: $("hiddenPlaylist").checked,
      locked: $("lockedPlaylist").checked
    };
    try {
      await request("/api/playlists", { method: "POST", body: JSON.stringify(payload) });
      playlistForm.reset();
      await loadPlaylists();
      setStatus(playlistStatus, "Playlist saved successfully.");
    } catch (err) {
      setStatus(playlistStatus, err.message, true);
    } finally {
      button.disabled = false;
    }
  });

  $("logoutButton").addEventListener("click", () => {
    state.mac = "";
    state.deviceKey = "";
    state.playlists = [];
    loginForm.reset();
    playlistForm.reset();
    portalCard.classList.add("hidden");
    loginCard.classList.remove("hidden");
    setStatus(playlistStatus, "");
    setStatus(loginStatus, "");
  });

  renderPlaylists();
})();
