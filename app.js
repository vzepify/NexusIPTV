(() => {
  "use strict";
  const API = String(window.NEXUS_PORTAL_API || "").replace(/\/+$/, "");
  const form = document.getElementById("loginForm");
  const status = document.getElementById("status");
  const button = document.getElementById("loginButton");

  function setStatus(message, error = false) {
    status.textContent = message || "";
    status.classList.toggle("error", error);
  }

  function normalizeDeviceId(value) {
    return String(value || "").trim();
  }

  function normalizeDeviceKey(value) {
    // Preserve the complete key exactly; only surrounding whitespace is removed.
    return String(value || "").trim();
  }

  async function login(deviceId, deviceKey) {
    if (!API) throw new Error("Portal API is not configured.");
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 10000);
    let response;
    try {
      response = await fetch(API + "/api/device/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ deviceId, deviceKey }),
        signal: controller.signal
      });
    } catch (e) {
      if (e.name === "AbortError") throw new Error("The API did not respond within 10 seconds.");
      throw new Error("Could not connect to the Nexus API: " + e.message);
    } finally {
      clearTimeout(timer);
    }
    let data = {};
    try { data = await response.json(); } catch (_) {}
    if (!response.ok) throw new Error(data.error || `Login failed (${response.status})`);
    return data;
  }

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    const deviceId = normalizeDeviceId(document.getElementById("deviceId").value);
    const deviceKey = normalizeDeviceKey(document.getElementById("deviceKey").value);

    if (!deviceId) { setStatus("Enter the Device ID shown on your Roku.", true); return; }
    if (deviceKey.length < 8) { setStatus("Enter the complete Device Key shown on your Roku, including the final character.", true); return; }

    button.disabled = true;
    button.textContent = "CHECKING...";
    setStatus("Checking device...");

    try {
      const result = await login(deviceId, deviceKey);
      localStorage.setItem("nexusDevice", JSON.stringify({ deviceId, deviceKey }));
      setStatus(
        result.migrated
          ? "Roku connected. Your old shortened key was upgraded to the complete key."
          : "Roku connected. Opening playlists...",
        false
      );
      setTimeout(() => { window.location.href = "playlists/"; }, 250);
    } catch (err) {
      setStatus(err.message, true);
      button.disabled = false;
      button.innerHTML = "LOGIN <span>→</span>";
    }
  });
})();
