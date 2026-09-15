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

  function normalizeMac(value) {
    return String(value || "").trim().toUpperCase();
  }

  function validMac(value) {
    return /^(?:[0-9A-F]{2}:){5}[0-9A-F]{2}$/.test(value) || /^[0-9A-F]{12}$/.test(value);
  }

  async function login(mac, deviceKey) {
    if (!API) throw new Error("Portal API is not configured.");
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 10000);
    let response;
    try {
      response = await fetch(API + "/api/device/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ mac, deviceKey }),
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
    const mac = normalizeMac(document.getElementById("mac").value);
    const deviceKey = document.getElementById("deviceKey").value.trim();
    if (!validMac(mac)) { setStatus("Enter a valid MAC address, for example 00:11:22:33:44:55.", true); return; }
    if (!deviceKey) { setStatus("Enter your device key.", true); return; }
    button.disabled = true;
    button.textContent = "CHECKING...";
    setStatus("Checking device...");
    try {
      await login(mac, deviceKey);
      localStorage.setItem("nexusDevice", JSON.stringify({ mac, deviceKey }));
      window.location.href = "playlists/";
    } catch (err) {
      setStatus(err.message, true);
      button.disabled = false;
      button.innerHTML = "LOGIN <span>→</span>";
    }
  });
})();
