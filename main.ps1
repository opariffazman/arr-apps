function Set-Prompt {
  param(
    $prompt,
    $color
  )
  return $(Write-Host "${prompt}: " -ForegroundColor $color -NoNewline; Read-Host)
}

function Add-Containarr {
  param (
    $name
  )

  $Ports = @{
    "Prowlarr"   = "9696"
    "Sonarr"     = "8989"
    "Radarr"     = "7878"
    "Bazarr"     = "6767"
    "Overseerr"  = "5055"
    "Jellyseerr" = "5055"
  }

  $Port = $Ports[$name]

  if ($name -eq 'Jellyseerr') {
    $provider = 'fallenbagel'
  } else {
    $provider = 'lscr.io/linuxserver'
  }

  $template = @"
  ${name}:
    container_name: ${name}
    image: ${provider}/${name}:latest
    environment:
      - TZ=`${TIMEZONE}
    volumes:
      - ./config/${name}-config:/config
    ports:
      - ${Port}:${Port}
    restart: unless-stopped

"@
  
  $template | Out-File .\docker-compose.yml -Append
}

function Add-Plex {
  $template = @"
  plex:
    container_name: plex
    image: lscr.io/linuxserver/plex:latest
    environment:
      - TZ=`${TIMEZONE}
      - VERSION=docker
    volumes:
      - ./config/plex-config:/config
      - `${DATAPATH}/media/:/media
    ports:
      - 32400:32400
    restart: unless-stopped

"@

  $template | Out-File .\docker-compose.yml -Append
}

function Add-Jellyfin {
  $template = @"
  plex:
    container_name: jellyfin
    image: lscr.io/linuxserver/jellyfin:latest
    environment:
      - TZ=`${TIMEZONE}
      - VERSION=docker
    volumes:
      - ./config/jellyfin-config:/config
      - `${DATAPATH}/media/:/media
    ports:
      - 8096:8096
      - 8920:8920 #optional
      - 7359:7359/udp #optional
      - 1900:1900/udp #optional
    restart: unless-stopped

"@

  $template | Out-File .\docker-compose.yml -Append
}

function Add-Qbittorrent {
  $template = @"
  qbittorrent:
    container_name: qbittorrent
    image: lscr.io/linuxserver/qbittorrent:latest
    environment:
      - TZ=`${TIMEZONE}
      - WEBUI_PORT=8080
    volumes:
      - ./config/qbittorrent-config:/config
      - `${DATAPATH}/torrents:/data/torrents
      - `${DATAPATH}/torrents/tv:/data/torrents/tv
      - `${DATAPATH}/torrents/movies:/data/torrents/movies
    ports:
      - 8080:8080
      - 6881:6881
      - 6881:6881/udp
    restart: unless-stopped
    
"@

  $template | Out-File .\docker-compose.yml -Append
}

function Add-NginxProxyManager {
  $template = @"
  nginxproxymanager:
    container_name: nginxproxymanager
    image: jc21/nginx-proxy-manager:latest
    environment:
      - TZ=`${TIMEZONE}
    ports:
      - 80:80
      - 81:81
      - 443:443
    volumes:
      - ./config/nginxproxymanager-config/data:/data
      - ./config/nginxproxymanager-config/letsencrypt:/etc/letsencrypt
    restart: unless-stopped

"@

  $template | Out-File .\docker-compose.yml -Append
}

function Add-DuckDns {
  $template = @"
  duckdns:
    container_name: duckdns
    image: lscr.io/linuxserver/duckdns:latest
    environment:
      - TZ=`${TIMEZONE}
      - SUBDOMAINS=`${DUCK_DNS_SUBDOMAINS}
      - TOKEN=`${DUCK_DNS_TOKEN}
    restart: unless-stopped

"@
  
  $template | Out-File .\docker-compose.yml -Append

  $subdomains = Set-Prompt -prompt "enter duckdns subdomain(s) eg:mydomain.duckdns.org,mydomain2.duckdns.org..." -color magenta
  "DUCK_DNS_SUBDOMAINS=${subdomains}" | Out-File .\.env -Encoding utf8 -Append
  $token = Set-Prompt -prompt "enter duckdns token available via duckdns dashboard" -color magenta
  "DUCK_DNS_TOKEN=${token}" | Out-File .\.env -Encoding utf8 -Append
}

function Start-Yaml {
  $initial = @"
---
services:
"@

  $initial | Out-File .\docker-compose.yml -Force
}

try {
  $dockerVersion = docker --version
  Set-Prompt -prompt "docker is installed. version: $dockerVersion, ensure docker daemon is running in the background & then press enter to proceed" -color green
}
catch {
  Write-Host "docker is not installed, please download docker first" -ForegroundColor Yellow
}

$timeZone = Set-Prompt -prompt "timezone? [Default: Asia/Singapore]" -color magenta
if ($timeZone -eq '') {
  $timeZone = "Asia/Singapore"
}
"TIMEZONE=${timeZone}" | Out-File .\.env -Encoding utf8

$dataPath = Set-Prompt -prompt "data path? [Default: ./data]" -color magenta
if ($dataPath -eq '') {
  $dataPath = "./data"
}
"DATAPATH=${dataPath}" | Out-File .\.env -Encoding utf8 -Append

Start-Yaml

$mediaServer = Set-Prompt -prompt "plex (overseerr) or jellyfin (jellyseerr)? [Default: plex]" -color magenta
if ($mediaServer -eq '') {
  $mediaServer = "plex"
  $mediaTool = "overseerr"
} else {
  $mediaServer = "jellyfin"
  $mediaTool = "jellyseerr"
}

$otherr = $mediaServer, 'Qbittorrent', 'NginxProxyManager', 'DuckDns'
$otherr | ForEach-Object {
  $containerName = $($_).ToLower()
  $choice = Set-Prompt -prompt "install $($containerName)? [y/n]" -color magenta
  if ($choice -eq 'y' -or $choice -eq 'Y' -or $choice -eq '') {
    Invoke-Expression -Command "Add-$($_)"
  }
}

$servarr = $mediaTool, 'sonarr', 'radarr', 'bazarr', 'prowlarr'
$servarr | ForEach-Object {
  $choice = Set-Prompt -prompt "install $($_)? [y/n]" -color magenta
  if ($choice -eq 'y' -or $choice -eq 'Y' -or $choice -eq '') {
    Add-Containarr -Name $_
  }
}

Write-Host "a docker-compose.yml has been generated, you may check it first" -ForegroundColor Green
$choice = Set-Prompt -prompt "Or straight away run `"docker compose up -d`"? [y/n]" -color magenta

if ($choice -eq 'y' -or $choice -eq 'Y' -or $choice -eq '') { 
  docker compose up -d 
}

$folder = "${DATAPATH}\media\tv", "${DATAPATH}\media\movie"
$folder | ForEach-Object { 
  Write-Host "creating media folder [$_]" -ForegroundColor blue
  New-Item -ItemType Directory -Path $_ -ErrorAction SilentlyContinue | Out-Null
}

Set-Prompt -prompt "press enter to exit, you may proceed to configure the *arr services manually" -color cyan