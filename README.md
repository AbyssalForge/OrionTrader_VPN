# OrionTrader VPN

Serveur VPN WireGuard avec déploiement automatique sur OVH VPS via GitHub Actions.

## Fonctionnalités

- VPN WireGuard avec interface web de gestion (wg-easy)
- Image Docker personnalisée sauvegardée sur Docker Hub
- Déploiement automatique sur push vers `main`
- Configuration simple via variables d'environnement
- Interface d'administration web

## Workflow de déploiement

À chaque push sur `main` ou déclenchement manuel :

1. **Build & Push** - Construction de l'image Docker personnalisée et envoi sur Docker Hub
2. **Deploy** - Connexion au VPS, pull de l'image depuis Docker Hub et redémarrage des services
3. **Verify** - Vérification du déploiement avec logs et status des containers

Cela permet d'avoir une image versionnée et sauvegardée sur Docker Hub, facilitant les rollbacks et les déploiements sur plusieurs serveurs.

## Prérequis

- VPS OVH avec Docker et Docker Compose installés
- Compte GitHub avec accès au repository
- Compte Docker Hub (pour sauvegarder vos images personnalisées)

## Configuration GitHub Secrets

Pour que le déploiement automatique fonctionne, configurez les secrets suivants dans votre repository GitHub (Settings > Secrets and variables > Actions) :

| Secret | Description | Exemple |
|--------|-------------|---------|
| `VPS_HOST` | Adresse IP ou domaine de votre VPS | `152.228.129.204` |
| `VPS_USERNAME` | Utilisateur SSH (généralement root) | `root` |
| `VPS_SSH_KEY` | Clé SSH privée pour se connecter au VPS | Contenu de `~/.ssh/id_rsa` |
| `VPS_PORT` | Port SSH (optionnel, défaut: 22) | `22` |
| `WG_PASSWORD` | Mot de passe pour l'interface web WireGuard | `VotreMotDePasseSecurise` |
| `DOCKERHUB_USERNAME` | Nom d'utilisateur Docker Hub | `votre-username` |
| `DOCKERHUB_TOKEN` | Token d'accès Docker Hub | Créé dans Docker Hub Settings |

### Générer une clé SSH pour le déploiement

```bash
# Sur votre machine locale
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/github_actions_key

# Copier la clé publique sur le VPS
ssh-copy-id -i ~/.ssh/github_actions_key.pub root@152.228.129.204

# Afficher la clé privée à copier dans GitHub Secrets
cat ~/.ssh/github_actions_key
```

### Créer un token Docker Hub

1. Connectez-vous sur [Docker Hub](https://hub.docker.com)
2. Allez dans **Account Settings > Security**
3. Cliquez sur **New Access Token**
4. Donnez un nom au token (ex: "github-actions")
5. Sélectionnez les permissions **Read, Write, Delete**
6. Cliquez sur **Generate** et copiez le token
7. Ajoutez le token dans les secrets GitHub (`DOCKERHUB_TOKEN`)

## Installation sur le VPS

### 1. Préparer le VPS

```bash
# Se connecter au VPS
ssh root@152.228.129.204

# Installer Docker et Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Installer Docker Compose
apt-get update
apt-get install -y docker-compose-plugin

# Configurer les permissions Docker (optionnel)
# Si vous n'utilisez pas root, ajoutez votre utilisateur au groupe docker
usermod -aG docker $USER
newgrp docker

# Configurer sudo sans mot de passe pour docker (pour GitHub Actions)
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/docker, /usr/bin/docker-compose" | sudo tee /etc/sudoers.d/docker

# Créer le répertoire de l'application
mkdir -p $HOME/wg-easy
```

### 2. Configuration locale

```bash
# Cloner le repository
git clone https://github.com/VOTRE-USERNAME/OrionTrader_VPN.git
cd OrionTrader_VPN

# Créer le fichier .env
cp .env.example .env
nano .env  # Modifier WG_PASSWORD
```

### 3. Déploiement

Le déploiement peut se faire de plusieurs façons :

#### a) Automatiquement (push sur main)

```bash
git add .
git commit -m "Configure deployment"
git push origin main
```

#### b) Manuellement via GitHub Actions

1. Allez sur votre repository GitHub
2. Cliquez sur l'onglet **Actions**
3. Sélectionnez **Deploy to OVH VPS** dans la liste des workflows
4. Cliquez sur **Run workflow** et confirmez

#### c) Manuellement sur le VPS

```bash
ssh root@152.228.129.204
cd $HOME/wg-easy
./deploy.sh
```

## Accès à l'interface Web

### Depuis le VPS (localhost)

L'interface web est accessible uniquement en local sur le VPS sur le port 51821.

### Tunnel SSH depuis votre machine locale

```bash
ssh -L 51821:localhost:51821 root@152.228.129.204
```

Puis ouvrez dans votre navigateur : [http://localhost:51821](http://localhost:51821)

## Configuration WireGuard

- **Host** : 152.228.129.204
- **Port UDP** : 51820
- **Réseau VPN** : 10.8.0.0/24
- **DNS** : 1.1.1.1 (Cloudflare)

## Gestion des clients

1. Accédez à l'interface web via le tunnel SSH
2. Connectez-vous avec le mot de passe défini dans `WG_PASSWORD`
3. Créez de nouveaux clients et téléchargez les configurations QR code

## Logs et monitoring

```bash
# Voir les logs en temps réel
docker-compose logs -f

# Status des containers
docker-compose ps

# Redémarrer le service
docker-compose restart

# Arrêter le service
docker-compose down

# Démarrer le service
docker-compose up -d
```

## Sécurité

- L'interface web est uniquement accessible en localhost (127.0.0.1:51821)
- Utilisez un mot de passe fort pour `WG_PASSWORD`
- Gardez vos clés SSH privées en sécurité
- Ne committez jamais le fichier `.env` dans Git

## Troubleshooting

### Le déploiement échoue

Vérifiez que :
- Tous les secrets GitHub sont correctement configurés
- La clé SSH est valide et a les bonnes permissions sur le VPS
- Docker est installé et fonctionne sur le VPS

### Permission denied sur Docker

Si vous obtenez une erreur `Permission denied` lors de l'accès au socket Docker :

```bash
# Option 1 : Ajouter l'utilisateur au groupe docker
sudo usermod -aG docker $USER
newgrp docker

# Option 2 : Configurer sudo sans mot de passe pour docker
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/docker, /usr/bin/docker-compose" | sudo tee /etc/sudoers.d/docker
sudo chmod 0440 /etc/sudoers.d/docker

# Vérifier que ça fonctionne
docker ps
```

### Erreur "Can't find docker-compose.yml"

Si docker-compose ne trouve pas le fichier de configuration, le repository n'a pas été cloné correctement :

```bash
ssh root@152.228.129.204

# Supprimer complètement le répertoire
rm -rf $HOME/wg-easy

# Relancer le workflow pour un clone propre
```

### Erreur "destination path already exists"

Si le git clone échoue avec cette erreur, nettoyez le répertoire :

```bash
ssh root@152.228.129.204
rm -rf $HOME/wg-easy
# Puis relancez le workflow
```

### Impossible d'accéder à l'interface web

```bash
# Vérifier que le container tourne
docker-compose ps

# Vérifier les logs
docker-compose logs wg-easy

# Redémarrer le container
docker-compose restart wg-easy
```

### Les clients ne peuvent pas se connecter

```bash
# Vérifier que le port UDP 51820 est ouvert
sudo ufw status
sudo ufw allow 51820/udp

# Vérifier les capabilities du container
docker inspect wg-easy | grep -A 10 CapAdd
```

## License

MIT