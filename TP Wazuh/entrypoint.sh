#!/bin/bash
# ================================================================
#  entrypoint.sh — Démarrage automatique de l'agent Wazuh
#  Auteur  : Péniel LAWSON-Body
#  Date    : 20 mars 2026
#
#  Ce script :
#    1. Configure l'adresse du manager dans ossec.conf
#    2. Attend que le manager soit joignable (port 1515/TCP)
#    3. Enrôle l'agent via agent-auth
#    4. Démarre l'agent Wazuh
#    5. Reste en foreground pour maintenir le conteneur actif
#
#  Variables d'environnement attendues (définies dans docker-compose) :
#    WAZUH_MANAGER              IP ou hostname du Wazuh Manager
#    WAZUH_AGENT_NAME           Nom de cet agent
#    WAZUH_REGISTRATION_SERVER  Serveur d'enrôlement (= manager)
#    WAZUH_REGISTRATION_PORT    Port d'enrôlement (défaut : 1515)
# ================================================================

set -e

MANAGER="${WAZUH_MANAGER:-172.20.0.2}"
AGENT_NAME="${WAZUH_AGENT_NAME:-$(hostname)}"
REG_SERVER="${WAZUH_REGISTRATION_SERVER:-${MANAGER}}"
REG_PORT="${WAZUH_REGISTRATION_PORT:-1515}"

echo "=============================================="
echo " Wazuh Agent — Démarrage"
echo " Nom de l'agent  : ${AGENT_NAME}"
echo " Manager         : ${MANAGER}"
echo " Serveur enrôl.  : ${REG_SERVER}:${REG_PORT}"
echo "=============================================="

# ── 1. Configurer l'adresse du manager dans ossec.conf ────────
echo "[*] Configuration du manager dans ossec.conf..."
sed -i "s|<address>MANAGER_IP</address>|<address>${MANAGER}</address>|g" \
    /var/ossec/etc/ossec.conf

# ── 2. Attendre que le manager accepte les connexions ─────────
echo "[*] Attente de disponibilité du manager sur ${REG_SERVER}:${REG_PORT}..."
RETRIES=0
MAX_RETRIES=30
until nc -z -w3 "${REG_SERVER}" "${REG_PORT}" 2>/dev/null; do
    RETRIES=$((RETRIES + 1))
    if [ "${RETRIES}" -ge "${MAX_RETRIES}" ]; then
        echo "[!] Timeout : le manager n'est pas disponible après ${MAX_RETRIES} tentatives."
        exit 1
    fi
    echo "    Manager non disponible, tentative ${RETRIES}/${MAX_RETRIES} dans 5s..."
    sleep 5
done
echo "[+] Manager disponible !"

# ── 3. Enrôlement de l'agent via agent-auth ───────────────────
echo "[*] Enrôlement de l'agent '${AGENT_NAME}'..."
/var/ossec/bin/agent-auth \
    -m "${REG_SERVER}" \
    -p "${REG_PORT}" \
    -A "${AGENT_NAME}"

echo "[+] Enrôlement terminé avec succès."

# ── 4. Démarrage du service Wazuh ─────────────────────────────
echo "[*] Démarrage du service Wazuh Agent..."
/var/ossec/bin/ossec-control start
echo "[+] Agent Wazuh démarré."

# ── 5. Maintenir le conteneur actif (logs en foreground) ──────
echo "[*] Suivi des logs en temps réel (tail -F)..."
exec tail -F /var/ossec/logs/ossec.log
