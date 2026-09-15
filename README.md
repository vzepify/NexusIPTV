# Nexus IPTV — Roku + IPTV Extreme-style portal

This build changes the playlist workflow to mirror IPTV Extreme's portal model: the Roku has a device code, and a web portal uses that code to add Xtream Codes playlists to the device. The portal frontend can be hosted on GitHub Pages. The API must be hosted on a server/runtime (for example Railway), because GitHub Pages is static and cannot receive/store POST requests by itself.

## API

Deploy `server/` on a Node host such as Railway. Run `npm install && npm start`. Use a persistent disk/volume for `nexus.sqlite` or set `DB_FILE` to a persistent location.

## GitHub Pages portal

Edit `portal/config.js` so `NEXUS_PORTAL_API` is the public API URL, then publish `portal/` as the GitHub Pages site.

## Roku

Sideload the ZIP. The login screen displays a persistent **DEVICE CODE**. Enter that code on the portal, fill in the Xtream server/username/password, and save. Put the API URL in the Roku's **Portal API** field and press **SYNC PORTAL**. The app loads the first playlist returned for that device.
