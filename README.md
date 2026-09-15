# Nexus IPTV GitHub Pages Portal

## Upload these files to GitHub Pages

Upload these four files to the root of the repository that GitHub Pages publishes:

- `index.html`
- `style.css`
- `app.js`
- `config.js`

## Configure the API

Open `config.js` and replace:

```js
window.NEXUS_PORTAL_API = "https://YOUR-API-DOMAIN.example.com";
```

with the public HTTPS URL of your Nexus IPTV API server.

The portal expects these API endpoints:

- `POST /api/device/login`
  - Body: `{ "mac": "...", "deviceKey": "..." }`
- `POST /api/playlists`
  - Login/list body: `{ "mac": "...", "deviceKey": "..." }`
  - Save body also includes `name`, `server`, `username`, `password`, `hidden`, and `locked`
- `POST /api/playlists/delete`
  - Body: `{ "mac": "...", "deviceKey": "...", "id": "..." }`

The API must return JSON. For playlist listing, return:

```json
{
  "playlists": [
    {
      "id": "1",
      "name": "My IPTV",
      "server": "http://example.com:8080",
      "hidden": false,
      "locked": false
    }
  ]
}
```

## GitHub Pages

1. Create or open your GitHub repository.
2. Upload the four website files to the published folder.
3. Go to **Settings → Pages**.
4. Select **Deploy from a branch**.
5. Select `main` and `/ (root)`.
6. Save and open the generated Pages URL.

This is the website only. Your Node.js API must be hosted separately, such as on your Windows PC through EZ PM2 GUI and exposed through a public HTTPS URL.
