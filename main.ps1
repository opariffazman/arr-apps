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

try {
  $dockerVersion = docker --version 2>&1
}
catch {
  $dockerVersion = $_.Exception.Message
}

if ($dockerVersion) {
  Write-Host "docker is installed. version: $dockerVersion"
}
else {
  Write-Host "docker desktop not installed, attempting to download & install"
  if (-not(Test-Path "DockerDesktopInstaller.exe")) {
    Invoke-WebRequest -Uri "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe" -OutFile DockerDesktopInstaller.exe
  }
  Start-Process "DockerDesktopInstaller.exe" -Wait install
  Read-Host -Prompt "docker installation complete. press enter to exit & re-run the script after running docker desktop application manually"
}

if ($null -ne (docker network ls -f "name=wsl" -q)) {
  Write-Host "docker network name wsl already exists, skipping creation"
}
else {
  docker network create wsl
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

Write-Host "a docker-compose.yml has been generated, you may check it first" -ForegroundColor Yellow
$choice = Read-Host -Prompt "Or straight away run `"docker compose up -d`"? [y/n]"

if ($choice -eq 'y' -or $choice -eq 'Y' -or $choice -eq '') { 
  docker compose up -d 
}

Write-Host "creating additional folder for tv & movie"
$folder = '.\data\media\tv', '.\data\media\movie'
$folder | ForEach-Object { New-Item -ItemType Directory -Path $_ -ErrorAction SilentlyContinue }

Read-Host -Prompt "press enter to exit, you may proceed to configure the *arr services manually"