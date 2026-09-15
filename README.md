# Nexus IPTV GitHub Pages Portal v2

This version implements the intended portal flow:

1. `index.html` is the device login page.
2. Successful MAC + device-key login stores the session locally and redirects to `/NexusIPTV/playlists/`.
3. `playlists/index.html` loads the device's saved playlists.
4. The playlists page contains the Xtream Codes form: Playlist Name, Server URL, Username, Password, Hide Playlist, and Lock Playlist.
5. Save uses `POST /api/playlists`.
6. List uses `GET /api/playlists?mac=...&deviceKey=...`.
7. Delete uses `POST /api/playlists/delete`.

The API is preconfigured as:

`https://api.neonarwhal.qzz.io`

Upload all files/folders to the GitHub Pages repository, preserving the `playlists/` folder.
