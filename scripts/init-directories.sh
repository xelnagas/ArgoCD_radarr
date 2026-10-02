#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script d'initialisation des répertoires pour la Media Stack sur linux2
# Host cible : 192.168.1.160
# ==============================================================================

echo "=== Initialisation des répertoires pour la stack Servarr ==="

BASE_CONFIG="/stockage/k8s-servarr-config"
BASE_MEDIA="/stockage"

# Création des dossiers de configurations persistantes
mkdir -p "${BASE_CONFIG}/qbittorrent"
mkdir -p "${BASE_CONFIG}/prowlarr"
mkdir -p "${BASE_CONFIG}/radarr"
mkdir -p "${BASE_CONFIG}/sonarr"
mkdir -p "${BASE_CONFIG}/jellyseerr"

# Création des dossiers de téléchargement et médiathèques
mkdir -p "${BASE_MEDIA}/download/torrents"
mkdir -p "${BASE_MEDIA}/series"
mkdir -p "${BASE_MEDIA}/films"

# Initialisation de la configuration qBittorrent si absente
QBIT_CONF_DIR="${BASE_CONFIG}/qbittorrent/qBittorrent"
if [ ! -f "${QBIT_CONF_DIR}/qBittorrent.conf" ]; then
  mkdir -p "${QBIT_CONF_DIR}"
  cat << 'EOF' > "${QBIT_CONF_DIR}/qBittorrent.conf"
[AutoRun]
enabled=false
program=

[BitTorrent]
Session\AddTorrentStopped=false
Session\DefaultSavePath=/data/download/torrents/
Session\Port=6882
Session\QueueingSystemEnabled=true
Session\SSL\Port=56580
Session\ShareLimitAction=Stop
Session\TempPath=/data/download/temp/

[LegalNotice]
Accepted=true

[Meta]
MigrationVersion=8

[Network]
PortForwardingEnabled=false
Proxy\HostnameLookupEnabled=false
Proxy\Profiles\BitTorrent=true
Proxy\Profiles\Misc=true
Proxy\Profiles\RSS=true

[Preferences]
Connection\PortRangeMin=6881
Connection\UPnP=false
Downloads\SavePath=/data/download/torrents/
Downloads\TempPath=/data/download/temp/
WebUI\Address=*
WebUI\ServerDomains=*
WebUI\CSRFProtection=false
WebUI\HostHeaderValidation=false
WebUI\AuthSubnetWhitelist=10.42.0.0/16,192.168.0.0/16,127.0.0.1/32
WebUI\AuthSubnetWhitelistEnabled=true
WebUI\LocalHostAuth=false
EOF
fi

# Attribution des droits au user 1000:1000 (julien)
chown -R 1000:1000 "${BASE_CONFIG}"
chmod -R 775 "${BASE_CONFIG}"

echo "=== Répertoires créés et sécurisés avec succès ==="
ls -ld "${BASE_CONFIG}"/*
