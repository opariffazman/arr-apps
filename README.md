# arr-apps

suite of *arr application running via dockerized container from standardised images by folks at [lscr.io](https://www.linuxserver.io/).

currently tested and compatible for windows but docker is running via [WSL2 engine](https://learn.microsoft.com/en-us/windows/wsl/install)

## apps included

- [plex](https://www.plex.tv/) - self hosted media server
- [radarr](https://radarr.video/) - movie collection manager
- [sonarr](https://sonarr.tv/) - tv collection manager
- [bazarr](https://www.bazarr.media/) - subtitles manager
- [prowlarr](https://wiki.servarr.com/en/prowlarr) - indexer
- *[nginxproxymanager](https://nginxproxymanager.com/) - reverse proxy for exposing services securely
- *[duckdns](https://www.duckdns.org/) - free dynamic dns provider

`*` is optional & not needed for the *arr suite to work

## usage

clone this repo using [git](https://git-scm.com/download/win) or download as zip and extract it
```powershell
git clone https://github.com/opariffazman/arr-apps.git
```

run `main.ps1` script inside the `arr-apps` folder to generate `docker-compose.yml` accordingly
```powershell
cd arr-apps
.\main.ps1
```

answer the prompts accordingly