# Déploiement containerisé de Wazuh — TP Sécurité

**Auteur :** Péniel LAWSON-Body  
**Date :** 20 mars 2026  
**Rendu :** 21 mars 2026 — 12h00

---

## Présentation

Ce dépôt contient l'ensemble des fichiers nécessaires au déploiement d'un environnement **Wazuh entièrement containerisé** composé de :

- Un **Wazuh Manager** (image officielle `wazuh/wazuh-manager:4.7.3`)
- Un **agent Wazuh sur Debian 12** (image construite localement)
- Un **agent Wazuh sur Ubuntu 22.04** (image construite localement)

> ⚠️ Pas d'indexeur (Elasticsearch/OpenSearch) ni de tableau de bord déployés.  
> La validation se fait uniquement via les fichiers de logs et d'alertes du manager.

---

## Architecture

```
RÉSEAU DOCKER : wazuh-net (172.20.0.0/24)
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  [agent-debian]     [agent-ubuntu]    [wazuh-manager]   │
│   debian:12          ubuntu:22.04      wazuh 4.7.3      │
│   172.20.0.3         172.20.0.4        172.20.0.2       │
│       │                   │                 │           │
│       └───────────────────┘─────────────────┘           │
│                    Wazuh Protocol                       │
│              1514/UDP  •  1515/TCP                      │
└─────────────────────────────────────────────────────────┘
```

---

## Structure du projet

```
wazuh-docker-tp/
├── README.md
├── docker-compose.yml
└── agents/
    ├── debian/
    │   ├── Dockerfile        # Image basée sur debian:12
    │   └── entrypoint.sh     # Enrôlement + démarrage automatique
    └── ubuntu/
        ├── Dockerfile        # Image basée sur ubuntu:22.04
        └── entrypoint.sh     # Enrôlement + démarrage automatique
```

---

## Prérequis

- Docker Engine >= 24.x
- Docker Compose v2 (`docker compose` — pas `docker-compose`)
- Accès internet pour télécharger les images et packages Wazuh

---

## Déploiement rapide

### 1. Cloner le dépôt

```bash
git clone https://github.com/TON_USERNAME/wazuh-docker-tp.git
cd wazuh-docker-tp
```

### 2. Construire les images agents

```bash
docker build -t wazuh-agent-debian:4.7.3 ./agents/debian/
docker build -t wazuh-agent-ubuntu:4.7.3 ./agents/ubuntu/
```

### 3. Lancer l'environnement

```bash
docker compose up -d
```

> Le manager démarre en premier. Les agents attendent automatiquement que le healthcheck du manager passe avant de s'enrôler.

### 4. Vérifier le démarrage

```bash
# État des conteneurs
docker ps

# Logs du manager
docker compose logs -f wazuh-manager

# Logs d'un agent
docker compose logs -f agent-debian
```

---

## Validation — Vérifier les agents

```bash
# Lister les agents enregistrés sur le manager
docker exec -it wazuh-manager /var/ossec/bin/agent_control -l

# Suivre les alertes en temps réel
docker exec -it wazuh-manager tail -F /var/ossec/logs/alerts/alerts.json
```

---

## Tests de génération d'événements

### Test FIM (agent-debian)
```bash
docker exec -it agent-debian bash -c "touch /tmp/test_wazuh.txt && sleep 2 && rm /tmp/test_wazuh.txt"
```

### Test brute-force SSH simulé (agent-ubuntu)
```bash
docker exec -it agent-ubuntu bash -c "
for i in 1 2 3 4 5 6; do
  echo 'Mar 20 09:28:07 agent-ubuntu sshd[1234]: Failed password for invalid user admin from 192.168.1.100 port 54321 ssh2' >> /var/log/auth.log
  sleep 1
done"
```

### Test modification /etc/passwd (agent-debian)
```bash
docker exec -it agent-debian bash -c "
cp /etc/passwd /etc/passwd.bak
echo 'testuser:x:0:0::/root:/bin/bash' >> /etc/passwd
mv /etc/passwd.bak /etc/passwd"
```

---

## Arrêt de l'environnement

```bash
# Arrêter les conteneurs (données conservées dans le volume)
docker compose down

# Arrêter ET supprimer les volumes (reset complet)
docker compose down -v
```

---

## Commandes utiles

| Commande | Description |
|---|---|
| `docker compose up -d` | Démarrer tous les services |
| `docker compose down` | Arrêter tous les services |
| `docker compose logs -f` | Suivre les logs en temps réel |
| `docker exec -it wazuh-manager bash` | Shell dans le manager |
| `docker exec -it agent-debian bash` | Shell dans l'agent Debian |
| `docker exec -it agent-ubuntu bash` | Shell dans l'agent Ubuntu |
| `docker exec -it wazuh-manager /var/ossec/bin/agent_control -l` | Lister les agents |
| `docker exec -it wazuh-manager tail -F /var/ossec/logs/alerts/alerts.json` | Alertes en temps réel |

---

## Contraintes respectées

- ✅ Aucune modification sur l'hôte physique ou la VM
- ✅ Toutes les configurations sont dans les conteneurs
- ✅ Deux distributions Linux différentes (Debian 12 + Ubuntu 22.04)
- ✅ Pas d'indexeur ni de dashboard déployé
- ✅ Validation via fichiers logs/alertes du manager uniquement

---

## Version du rendu

Tag Git : `v1.0` — commit utilisé dans le PDF de rendu.
