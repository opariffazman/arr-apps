# arr-apps

suite of ***arr** application running via dockerized container from standardised images by folks at [lscr.io](https://www.linuxserver.io/)

currently tested for windows but docker is running via [WSL2 engine](https://learn.microsoft.com/en-us/windows/wsl/install), so the `docker-compose.yml` probably would work the same in linux environment.

## apps included

- [plex](https://www.plex.tv/) - self hosted media server
- [overseerr](https://overseerr.dev/) - request management and media discovery tool for plex
- [jellyfin](https://jellyfin.org/) - open source alternative to plex
- [jellyseerr](https://github.com/Fallenbagel/jellyseerr) - fork of overseer for jellyfin
- [radarr](https://radarr.video/) - movie collection manager
- [sonarr](https://sonarr.tv/) - tv collection manager
- [bazarr](https://www.bazarr.media/) - subtitles manager
- [prowlarr](https://wiki.servarr.com/en/prowlarr) - indexer
- *[nginxproxymanager](https://nginxproxymanager.com/) - reverse proxy for exposing services securely
- *[duckdns](https://www.duckdns.org/) - free dynamic dns provider

`*` is optional & not needed for the *arr suite to work

## pre-req

[docker](https://www.docker.com) & [git](https://git-scm.com/download) installed

## usage

clone this repo or download as zip and extract it
```powershell
git clone https://github.com/opariffazman/arr-apps.git
```

run `main.ps1` script inside the `arr-apps` folder to generate `docker-compose.yml` accordingly
```powershell
cd arr-apps
.\main.ps1
```

answer the prompts accordingly & run after `docker-compose.yml` generated
```powershell
docker compose up -d
```