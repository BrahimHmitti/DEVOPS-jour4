# 🚀 TP DevOps Jour 4 - Infrastructure Résiliente & GitOps

> **Objectif** : Déployer une infrastructure Kubernetes complète avec résilience, monitoring, chaos engineering, CI/CD et GitOps.

## 📊 Vue d'ensemble

Ce repository contient l'implémentation complète d'un TP DevOps couvrant **13 parties** :

| Partie | Thème | Status |
|--------|-------|--------|
| 0 | Cluster Minikube multi-nodes | ✅ |
| 1 | Topology Spread Constraints | ✅ |
| 2 | Prometheus & Grafana | ✅ |
| 3 | Ingress NGINX + Load Testing | ✅ |
| 4 | Dashboard Grafana personnalisé | ✅ |
| 5 | Chaos Engineering (Chaos Mesh) | ✅ |
| 6 | GitHub Runner self-hosted | ✅ |
| 7 | Pipeline CI/CD GitHub Actions | ✅ |
| 8 | Renovate Bot | ✅ |
| 9 | ArgoCD GitOps | ✅ |
| 10 | Burrito IaC | ✅ |
| 11 | Signature images Cosign | ✅ |
| 12 | Vérification signatures Kyverno | ✅ |
| 13 | Documentation | ✅ |

## 🚀 Démarrage Rapide

### Prérequis
- Docker installé
- minikube v1.34+
- kubectl v1.28+
- Helm v3.19+
- 4 Go RAM minimum (8 Go recommandé)

### Installation en 3 commandes

```bash
# 1. Démarrer le cluster
minikube start --nodes 2 --driver=docker --cpus=2 --memory=3500

# 2. Tester toutes les parties
./test-all-tp.sh

# 3. Déployer tout automatiquement (optionnel)
./deploy-full-tp.sh
```

## 📁 Structure du Repository

```
.
├── .github/workflows/         # Pipeline CI/CD
│   └── docker-build.yaml
├── *.yaml                     # Manifests Kubernetes (Parties 1-10)
├── test-all-tp.sh            # ⭐ Script de test complet
├── deploy-full-tp.sh          # Déploiement automatique
├── quick-commands.sh          # Menu interactif
├── apprentissage.md           # 📚 Documentation complète
└── STATUS.md                  # État détaillé + commandes
```

## 🧪 Tester le TP

**Script de test automatique (recommandé) :**
```bash
./test-all-tp.sh
```

Ce script vérifie automatiquement les 13 parties et affiche un rapport détaillé.

## 📚 Documentation

- **[apprentissage.md](apprentissage.md)** - Guide complet avec retour d'expérience (PRINCIPAL)
- **[STATUS.md](STATUS.md)** - État de chaque partie avec commandes de déploiement
- **[RECAP.md](RECAP.md)** - Récapitulatif technique
- **[FICHIERS-A-SUPPRIMER.md](FICHIERS-A-SUPPRIMER.md)** - Liste des fichiers redondants

## 🎯 Parties Principales

### Partie 1 : Topology Spread Constraints
```bash
kubectl apply -f resilient-app-deployment.yaml
kubectl apply -f resilient-app-service.yaml
```
**Validation :** 4 pods distribués 2+2 sur les nœuds

### Partie 2 : Monitoring Stack
```bash
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```
**Accès :** http://localhost:3000 (admin / prom-operator)

### Partie 5 : Chaos Engineering
```bash
helm install chaos-mesh chaos-mesh/chaos-mesh -n chaos-mesh --create-namespace
kubectl apply -f chaos-pod-kill-experiment.yaml
```

### Partie 9 : ArgoCD GitOps
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f argocd-application.yaml
```

## 🌐 Accès aux Services

```bash
# Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Chaos Mesh Dashboard
kubectl port-forward -n chaos-mesh svc/chaos-dashboard 2333:2333

# ArgoCD UI
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Métriques custom
kubectl port-forward svc/guestbook-metrics-service 8082:80
```

## 🔧 Scripts Utilitaires

| Script | Description |
|--------|-------------|
| `test-all-tp.sh` | ⭐ Valide les 13 parties automatiquement |
| `deploy-full-tp.sh` | Déploie l'infrastructure complète |
| `quick-commands.sh` | Menu interactif pour déployer/tester |
| `validate-all-parts.sh` | Vérification rapide de l'état |

## 🛠️ Commandes Utiles

```bash
# État global
kubectl get all --all-namespaces

# Logs d'un pod
kubectl logs -f <pod-name>

# État des nœuds
kubectl get nodes -o wide
kubectl top nodes

# Événements récents
kubectl get events --sort-by='.lastTimestamp'

# Cleanup complet
minikube delete --all
```

## 📊 Statistiques du Projet

- **Namespaces** : 6 (default, monitoring, chaos-mesh, argocd, renovate, burrito)
- **Deployments** : 12+
- **Services** : 15+
- **CRDs** : 50+
- **Fichiers YAML** : 18
- **Scripts** : 4
- **Documentation** : 2000+ lignes

## 🎓 Compétences Démontrées

- ✅ Kubernetes multi-nodes
- ✅ Haute disponibilité (Topology Spread Constraints)
- ✅ Observabilité (Prometheus/Grafana/AlertManager)
- ✅ Ingress & Load Balancing
- ✅ Chaos Engineering
- ✅ CI/CD (GitHub Actions)
- ✅ GitOps (ArgoCD)
- ✅ Automatisation (Renovate)
- ✅ Infrastructure as Code (Burrito/Terraform)
- ✅ Sécurité (Cosign/Kyverno)

## 🔗 Ressources

- [Kubernetes Docs](https://kubernetes.io/docs/)
- [Prometheus Operator](https://prometheus-operator.dev/)
- [Chaos Mesh](https://chaos-mesh.org/)
- [ArgoCD](https://argo-cd.readthedocs.io/)
- [GitHub Actions](https://docs.github.com/actions)

## 👤 Auteur

**Brahim Hmitti**  
Repository: [BrahimHmitti/DEVOPS-jour4](https://github.com/BrahimHmitti/DEVOPS-jour4)

---

**🎉 Projet complet - Prêt pour la production !**