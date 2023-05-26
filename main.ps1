function Containarr {
  param (
    $Servarr,
    $TimeZone
  )

  $Ports = @{
    "Prowlarr"  = "9696"
    "Sonarr"    = "8989"
    "Radarr"    = "7878"
    "Bazarr"    = "6767"
    "Overseerr" = "5055"
  }

  $Port = $Ports[$Servarr]

  $Template = @"
  ${Servarr}:
    image: lscr.io/linuxserver/${Servarr}:latest
    container_name: ${Servarr}
    environment:
      - TZ=${TimeZone}
    volumes:
      - ./config/${Servarr}-config:/config
      - ./data:/data
    ports:
      - "${Port}:${Port}"
    networks:
      - wsl
    restart: unless-stopped

"@
  
  $Template | Out-File .\docker-compose.yml -Append
}

function plex {
  param (
    $TimeZone
  )

  $Template = @"
  plex:
    image: lscr.io/linuxserver/plex:latest
    container_name: plex
    environment:
      - TZ=${TimeZone}
      - VERSION=docker
    volumes:
      - ./config/plex-config:/config
      - ./data/media/:/media
    ports:
      - "32400:32400"
    networks:
      - wsl
    restart: unless-stopped

"@

  $Template | Out-File .\docker-compose.yml -Append
}

function qbittorrent {
  param (
    $TimeZone
  )

  $Template = @"
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - TZ=${TimeZone}
      - WEBUI_PORT=8080
    volumes:
      - ./config/qbittorrent-config:/config
      - ./data/torrents:/data/torrents
      - ./data/torrents/tv:/data/torrents/tv
      - ./data/torrents/movies:/data/torrents/movies
    ports:
      - "8080:8080"
      - "6881:6881"
      - "6881:6881/udp"
    networks:
      - wsl
    restart: unless-stopped
    
"@

  $Template | Out-File .\docker-compose.yml -Append
}

function Initial {
  $Initial = @"
---
services:
"@

  $Initial | Out-File .\docker-compose.yml -Force
}

function Final {
  $Final = @"
networks:
  wsl:
    external: true
    driver: bridge
"@

  $Final | Out-File .\docker-compose.yml -Append
}

if (!(docker --version)) {
  Write-Host "Docker Desktop not installed, attempting to install"

  Start-Process "Docker Desktop Installer.exe" -Wait install
}

$dockerVersion = docker --version
if ($LASTEXITCODE -eq 0) {
  if ($null -ne (docker network ls -f "name=wsl" -q)) {
    Write-Host "docker network name wsl already exists, skipping creation"
  }
  else {
    docker network create wsl
  }
}

$TimeZone = Read-Host -Prompt "timezone? [Default: Asia/Singapore]"
[void](($TimeZone = $TimeZone) -or ($TimeZone = "Asia/Singapore"))

Initial

$servarr = 'sonarr', 'radarr', 'bazarr', 'prowlarr', 'overseerr'
$servarr | ForEach-Object {
  $choice = Read-Host -Prompt "install $($_)? [y/n]"
  if ($choice -eq 'y' -or $choice -eq 'Y' -or $choice -eq '') {
    Containarr -Servarr $_ -TimeZone $TimeZone
  }
}

$otherr = 'plex', 'qbittorrent'

$otherr | ForEach-Object {
  $choice = Read-Host -Prompt "install $($_)? [y/n]"
  if ($choice -eq 'y' -or $choice -eq 'Y' -or $choice -eq '') {
    Invoke-Expression -Command "$($_) $TimeZone"
  }
}

Final

Write-Host "a docker-compose.yml has been generated, you may check it first"
Write-Host "or straight away run `"docker compose up -d`""