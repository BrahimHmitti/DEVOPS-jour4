# 📚 Documentation d'Apprentissage - DevOps Jour 4

## 🎯 Objectif
Garder une trace des apprentissages, commandes utilisées, erreurs rencontrées et solutions apportées lors de la formation DevOps.

---

## 🔧 Commandes Utilisées

### Gestion des ressources Kubernetes
```bash
# Voir toutes les ressources
kubectl get all

# Voir les pods avec détails
kubectl get pods -o wide

# Voir tous les pods dans tous les namespaces
kubectl get pods -A -o wide

# Voir les nœuds du cluster
kubectl get nodes

# Voir la configuration kubectl
kubectl config view

# Supprimer des ressources par label
kubectl delete all -l app=guestbook

# Supprimer un deployment spécifique
kubectl delete deployment guestbook-deployment
```

### Gestion du cluster Minikube
```bash
# Voir la version de minikube
minikube version

# Créer un cluster multi-nœuds avec ressources spécifiques
minikube start --nodes 2 --cpus 3 --memory 4096

# Supprimer le cluster
minikube delete

# Voir le statut du cluster
minikube status

# Activer des addons
minikube addons enable dashboard
minikube addons enable metrics-server
minikube addons enable ingress
```

---

## 🎓 Apprentissages

### 1. Hiérarchie des ressources Kubernetes

**Problème rencontré :** Confusion entre les concepts de cluster, nœuds, namespaces, deployments, etc.

**Solution apportée :** Compréhension de la hiérarchie :
```
Cluster → Node → Namespace → Deployment → ReplicaSet → Pods
```

**Nouveau savoir :** 
- Un **cluster** contient plusieurs **nœuds** (machines)
- Les **namespaces** isolent logiquement les ressources
- Les **deployments** gèrent les **ReplicaSets** qui gèrent les **pods**
- **Pourquoi c'est utile :** Permet de mieux organiser et comprendre l'architecture Kubernetes

### 2. Erreur de suppression de ressources

**Problème rencontré :** 
```bash
kubectl delete guestbook-deployment
# error: the server doesn't have a resource type "guestbook-deployment"
```

**Pourquoi il est survenu :** Kubernetes a besoin du **type de ressource** explicite, pas seulement le nom.

**Solution apportée :** Spécifier le type de ressource :
```bash
kubectl delete deployment guestbook-deployment
# OU
kubectl delete all -l app=guestbook
```

**Nouveau savoir :** 
- La syntaxe correcte est `kubectl delete <type-ressource> <nom-ressource>`
- On peut utiliser les labels pour supprimer plusieurs ressources d'un coup
- **Pourquoi c'est utile :** Évite les erreurs et permet une gestion plus efficace des ressources

### 3. Service système Kubernetes

**Problème rencontré :** Inquiétude de voir le service `kubernetes` restant après suppression.

**Pourquoi il est survenu :** Méconnaissance des services système essentiels.

**Solution apportée :** Compréhension que le service `kubernetes` (ClusterIP: 10.96.0.1, Port: 443) est **système** et **obligatoire**.

**Nouveau savoir :** 
- Ce service est le point d'entrée API du cluster
- Il ne doit jamais être supprimé
- **Pourquoi c'est utile :** Évite de casser accidentellement la communication avec le cluster

### 4. Différence entre cluster et nœuds

**Problème rencontré :** Confusion - "Pourquoi un seul cluster alors qu'on a demandé 2 nœuds ?"

**Pourquoi il est survenu :** Confusion entre les concepts de cluster et nœuds.

**Solution apportée :** Clarification :
- **1 CLUSTER** = environnement Kubernetes complet
- **2 NŒUDS** = machines à l'intérieur de ce cluster

**Nouveau savoir :** 
```
🏢 CLUSTER "minikube" (= immeuble)
├── 🖥️ NODE "minikube" (control-plane) 
└── 🖥️ NODE "minikube-m02" (worker)
```
- **Pourquoi c'est utile :** Comprendre l'architecture permet de mieux gérer la répartition des charges

### 5. Drivers de virtualisation Minikube

**Problème rencontré :** Surprise que le système choisisse Docker au lieu de VirtualBox.

**Pourquoi il est survenu :** Minikube détecte automatiquement le meilleur driver disponible.

**Solution apportée :** Compréhension des différents drivers :

| Driver | Isolation | Performance | Use Case |
|--------|-----------|-------------|----------|
| Docker | Conteneurs | 🚀 Rapide | Développement local |
| VirtualBox | VMs complètes | 🐌 Plus lent | Tests avancés |
| Hyper-V | VMs Windows | ⚡ Moyen | Windows Pro/Enterprise |

**Nouveau savoir :** 
- Docker driver = conteneurs (partage kernel)
- VirtualBox driver = vraies VMs (OS séparé)
- Le choix automatique de Docker est optimal pour notre environnement WSL/Ubuntu
- **Pourquoi c'est utile :** Permet de choisir le bon driver selon le contexte et les besoins

### 6. Architecture réseau du cluster

**Problème rencontré :** Compréhension de l'organisation réseau du cluster multi-nœuds.

**Solution apportée :** Analyse de la sortie `kubectl get pods -A -o wide` :

**Nouveau savoir :** 
- **Cluster Network** : `10.244.x.x` (réseau des pods)
- **Node Network** : `192.168.49.x` (réseau des nœuds)
- **Control Plane** (minikube) : contient les composants maîtres (API, etcd, scheduler)
- **Worker Node** (minikube-m02) : contient les composants de travail (kubelet, kube-proxy)
- **Pourquoi c'est utile :** Comprendre le réseau aide au debugging et à la sécurité

---

## 📝 Notes Importantes

- Toujours spécifier le type de ressource dans les commandes kubectl
- Le service `kubernetes` est système et ne doit jamais être supprimé
- Un cluster peut contenir plusieurs nœuds, mais reste un seul environnement
- Docker driver est optimal pour le développement local sur WSL/Ubuntu
- La hiérarchie Kubernetes suit une logique : Cluster → Node → Namespace → Deployment → ReplicaSet → Pods

---

## 🚀 Prochaines Étapes

- [ ] Explorer les addons Minikube (dashboard, metrics-server, ingress)
- [ ] Déployer une application sur le cluster multi-nœuds
- [ ] Tester la répartition des pods sur les différents nœuds
- [ ] Apprendre les concepts de services et ingress