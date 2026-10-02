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

# Attribution des droits au user 1000:1000 (julien)
chown -R 1000:1000 "${BASE_CONFIG}"
chmod -R 775 "${BASE_CONFIG}"

echo "=== Répertoires créés et sécurisés avec succès ==="
ls -ld "${BASE_CONFIG}"/*
