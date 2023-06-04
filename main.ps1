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
    "Prowlarr"  = "9696"
    "Sonarr"    = "8989"
    "Radarr"    = "7878"
    "Bazarr"    = "6767"
    "Overseerr" = "5055"
  }

  $Port = $Ports[$name]

  $template = @"
  ${name}:
    image: lscr.io/linuxserver/${name}:latest
    container_name: ${name}
    environment:
      - TZ=`${TIMEZONE}
    volumes:
      - ./config/${name}-config:/config
      - ./data:/data
    ports:
      - ${Port}:${Port}
    restart: unless-stopped

"@
  
  $template | Out-File .\docker-compose.yml -Append
}
function Add-Plex {
  $template = @"
  plex:
    image: lscr.io/linuxserver/plex:latest
    container_name: plex
    environment:
      - TZ=`${TIMEZONE}
      - VERSION=docker
    volumes:
      - ./config/plex-config:/config
      - ./data/media/:/media
    ports:
      - 32400:32400
    restart: unless-stopped

"@

  $template | Out-File .\docker-compose.yml -Append
}

function Add-Qbittorrent {
  $template = @"
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - TZ=`${TIMEZONE}
      - WEBUI_PORT=8080
    volumes:
      - ./config/qbittorrent-config:/config
      - ./data/torrents:/data/torrents
      - ./data/torrents/tv:/data/torrents/tv
      - ./data/torrents/movies:/data/torrents/movies
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
    image: jc21/nginx-proxy-manager:latest
    container_name: nginxproxymanager
    environment:
      - TZ=`${TIMEZONE}
    ports:
      - 80:80
      - 81:81
      - 443:443
    volumes:
      - ./config/nginxproxymanager-config/data:/data
      - ./config/nginxproxymanager-config/letsencrypt:/etc/letsencrypt
    networks:
      - wsl
    restart: unless-stopped

"@

  $template | Out-File .\docker-compose.yml -Append
}

function Add-DuckDns {
  $template = @"
  app:
    container_name: duckdns
    image: lscr.io/linuxserver/duckdns:latest
    environment:
      - TZ=`${TIMEZONE}
      - SUBDOMAINS=`${DUCK_DNS_SUBDOMAINS}
      - TOKEN=`${DUCK_DNS_TOKEN}
    networks:
      - wsl
    restart: unless-stopped

"@
  
  $template | Out-File .\docker-compose.yml -Append

  $subdomains = Set-Prompt -prompt "enter duckdns subdomain(s) eg:mydomain.duckdns.org,mydomain2.duckdns.org..." -color magenta
  "DUCK_DNS_SUBDOMAINS=${subdomains}" | Out-File .\.env -Encoding utf8 -Append
  $token = Set-Prompt -prompt "enter duckdns token available via duckdns dashboard" -color magenta
  "DUCK_DNS_TOKEN=${token}" | Out-File .\.env -Encoding utf8 -Append
}

function Initial {
  $initial = @"
---
services:
"@

  $initial | Out-File .\docker-compose.yml -Force
}

function Final {
  $final = @"
networks:
  wsl:
    external: true
    driver: bridge
"@

  $final | Out-File .\docker-compose.yml -Append
}

try {
  $dockerVersion = docker --version
}
catch {
  $dockerVersion = $_.Exception.Message
}

if ($dockerVersion) {
  Set-Prompt -prompt "docker is installed. version: $dockerVersion, ensure Docker Desktop is running in the background & then press enter to proceed" -color green
}
else {
  Write-Host "docker desktop not installed, attempting to download & install" -ForegroundColor Yellow
  if (-not(Test-Path "DockerDesktopInstaller.exe")) {
    Invoke-WebRequest -Uri "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe" -OutFile DockerDesktopInstaller.exe
  }
  Start-Process "DockerDesktopInstaller.exe" -Wait install -Verbose
  Set-Prompt -prompt "docker installation complete. press enter to exit & re-run the script after running docker desktop application manually" -color blue
}

$timeZone = Set-Prompt -prompt "timezone? [Default: Asia/Singapore]" -color magenta
if ($timeZone -eq '') {
  $timeZone = "Asia/Singapore"
}
"TIMEZONE=${timeZone}" | Out-File .\.env -Encoding utf8

Initial

$servarr = 'sonarr', 'radarr', 'bazarr', 'prowlarr', 'overseerr'
$servarr | ForEach-Object {
  $choice = Set-Prompt -prompt "install $($_)? [y/n]" -color magenta
  if ($choice -eq 'y' -or $choice -eq 'Y' -or $choice -eq '') {
    Add-Containarr -Name $_
  }
}

$otherr = 'Plex', 'Qbittorrent', 'NginxProxyManager'
$otherr | ForEach-Object {
  $containerName = $($_).ToLower()
  $choice = Set-Prompt -prompt "install $($containerName)? [y/n]" -color magenta
  if ($choice -eq 'y' -or $choice -eq 'Y' -or $choice -eq '') {
    Invoke-Expression -Command "Add-$($_)"
  }
}

# Final

Write-Host "a docker-compose.yml has been generated, you may check it first" -ForegroundColor Green
$choice = Set-Prompt -prompt "Or straight away run `"docker compose up -d`"? [y/n]" -color magenta

if ($choice -eq 'y' -or $choice -eq 'Y' -or $choice -eq '') { 
  docker compose up -d 
}

$folder = '.\data\media\tv', '.\data\media\movie'
$folder | ForEach-Object { 
  Write-Host "creating additional folder [${$_}]" -ForegroundColor blue
  New-Item -ItemType Directory -Path $_ -ErrorAction SilentlyContinue | Out-Null
}

Set-Prompt -prompt "press enter to exit, you may proceed to configure the *arr services manually" -color cyan