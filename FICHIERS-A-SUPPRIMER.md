# 🗑️ FICHIERS À SUPPRIMER

## Fichiers redondants ou inutiles

### ❌ Fichiers en double
```bash
rm resilient-app-soft-deployment.yaml
```
**Raison :** Doublon de `resilient-app-deployment.yaml`

### ❌ Fichiers temporaires
```bash
rm k6-v0.46.0-linux-amd64.tar.gz
rm -rf k6-v0.46.0-linux-amd64/
```
**Raison :** Archive et dossier d'installation k6, inutile après extraction

### ❌ Fichiers de documentation redondants (optionnel)
Si tu veux garder qu'un seul fichier de doc principal :
```bash
# Garde apprentissage.md (le plus complet)
# Supprime les autres si redondant :
rm how-to-start.md   # Redondant avec STATUS.md
rm condignes.md      # Consignes du prof, peut être gardé pour référence
```

**⚠️ NE PAS SUPPRIMER :**
- `STATUS.md` - État détaillé avec toutes les commandes
- `RECAP.md` - Récapitulatif technique
- `apprentissage.md` - Notes personnelles complètes
- `README.md` - Guide de démarrage (si présent)

## Fichiers YAML à garder (tous nécessaires pour le TP)

✅ **Partie 1 :**
- `resilient-app-deployment.yaml`
- `resilient-app-service.yaml`

✅ **Partie 3 :**
- `guestbook-deployment.yaml`
- `guestbook-ingress.yaml`

✅ **Partie 4 :**
- `guestbook-with-metrics.yaml`

✅ **Partie 5 :**
- `chaos-pod-kill-experiment.yaml`

✅ **Partie 6 :**
- `github-runner-deployment.yaml`

✅ **Partie 7 :**
- `.github/workflows/docker-build.yaml`
- `Dockerfile`
- `index.html`

✅ **Partie 8 :**
- `renovate-deployment.yaml`

✅ **Partie 9 :**
- `argocd-application.yaml`

✅ **Partie 10 :**
- `burrito-deployment.yaml`
- `burrito-terraformlayer.yaml`

✅ **Scripts utiles :**
- `test-all-tp.sh` - Script de test complet (NOUVEAU)
- `deploy-full-tp.sh` - Déploiement automatique
- `validate-all-parts.sh` - Validation rapide
- `check-tp-status.sh` - Vérification état
- `quick-commands.sh` - Menu interactif

✅ **Load testing :**
- `load-test.js`

## Commande de nettoyage recommandée

```bash
cd /mnt/c/Users/er-co/DEVOPS-jour4

# Supprimer les doublons
rm -f resilient-app-soft-deployment.yaml

# Supprimer les archives k6
rm -f k6-v0.46.0-linux-amd64.tar.gz
rm -rf k6-v0.46.0-linux-amd64/

# Supprimer doc redondante (optionnel - à toi de choisir)
# rm -f how-to-start.md

echo "✅ Nettoyage terminé !"
```

## Structure finale recommandée

```
DEVOPS-jour4/
├── 📁 .github/
│   └── workflows/
│       └── docker-build.yaml         # Partie 7 - Pipeline CI/CD
│
├── 📄 YAML Files (Parties 1-10)
│   ├── resilient-app-deployment.yaml
│   ├── resilient-app-service.yaml
│   ├── guestbook-deployment.yaml
│   ├── guestbook-ingress.yaml
│   ├── guestbook-with-metrics.yaml
│   ├── chaos-pod-kill-experiment.yaml
│   ├── github-runner-deployment.yaml
│   ├── renovate-deployment.yaml
│   ├── argocd-application.yaml
│   ├── burrito-deployment.yaml
│   └── burrito-terraformlayer.yaml
│
├── 📄 Application Files
│   ├── Dockerfile
│   ├── index.html
│   └── load-test.js
│
├── 📄 Scripts
│   ├── test-all-tp.sh              # ⭐ NOUVEAU - Test complet
│   ├── deploy-full-tp.sh
│   ├── validate-all-parts.sh
│   ├── check-tp-status.sh
│   └── quick-commands.sh
│
└── 📄 Documentation
    ├── apprentissage.md            # ⭐ Complet avec 13 parties
    ├── STATUS.md
    ├── RECAP.md
    ├── condignes.md               # Consignes (optionnel)
    └── README.md                  # Si présent
```

## Espace disque libéré

- `resilient-app-soft-deployment.yaml` : ~2 KB
- `k6-v0.46.0-linux-amd64.tar.gz` : ~15 MB
- `k6-v0.46.0-linux-amd64/` : ~50 MB
- `how-to-start.md` (optionnel) : ~8 KB

**Total : ~65 MB libérés**