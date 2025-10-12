# 📚 Apprentissages DevOps - Jour 4

> 🎓 **TP Complet** : Infrastructure résiliente, Monitoring, Chaos Engineering, CI/CD et GitOps


---

# 🔷 CE QUE J'AI APPRIS ET RÉALISÉ

## PARTIE 0 : Architecture Multi-Nodes Kubernetes

J'ai créé un cluster minikube avec 2 nœuds pour simuler un environnement de production réel. J'ai compris que la multi-node architecture est essentielle pour tester la résilience des applications. C'est la base de tout ce que j'ai fait après.

**Commande utilisée :**
```bash
minikube start --nodes 2 --driver=docker --cpus=2 --memory=3500
```

**Ce que j'ai retenu :** Un seul nœud ne suffit jamais pour tester la haute disponibilité. J'ai appris à vérifier la santé des nœuds avec `kubectl get nodes` et à comprendre les rôles control-plane vs worker.

---

## PARTIE 1 : Topology Spread Constraints

J'ai découvert un mécanisme hyper puissant pour distribuer les pods intelligemment. Les Topology Spread Constraints permettent de s'assurer qu'une application ne se retrouve pas entièrement sur un seul nœud.

**Fichier créé :** `resilient-app-deployment.yaml`

**Configuration clé :**
```yaml
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: DoNotSchedule
```

**Test de résilience effectué :** J'ai drainé un nœud avec `kubectl drain` et j'ai vu les pods se redistribuer automatiquement. C'était impressionnant de voir Kubernetes respecter les contraintes même pendant une panne simulée.

**Leçon importante :** `whenUnsatisfiable: DoNotSchedule` crée des pods Pending si la contrainte ne peut pas être respectée. C'est voulu - mieux vaut attendre que de violer la règle de distribution.

---

## PARTIE 2 : Prometheus et Grafana

J'ai déployé toute une stack de monitoring via Helm. Ça m'a ouvert les yeux sur l'importance de l'observabilité. Sans métriques, on est aveugle.

**Installation via Helm :**
```bash
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring
```

**Ce que j'ai appris :**
- Prometheus scrape automatiquement les métriques des pods avec des annotations
- Grafana vient avec des dashboards pré-configurés pour Kubernetes
- AlertManager permet de configurer des alertes (Slack, email, etc.)

**Mot de passe Grafana :** Le secret s'appelle `kube-prometheus-stack-grafana` et contient le mot de passe en base64.

**Retour d'expérience :** Le déploiement prend 5-10 minutes avec beaucoup de CRDs (ServiceMonitor, PrometheusRule, etc.). Il faut être patient et ne pas paniquer devant les warnings Helm.

---

## PARTIE 3 : Ingress NGINX et Load Testing

J'ai configuré l'Ingress pour exposer mon application avec un nom de domaine. Ensuite j'ai fait des tests de charge pour voir comment elle réagit.

**Fichiers créés :**
- `guestbook-ingress.yaml` - Configuration Ingress avec host `guestbook.fbi.com`
- `load-test.js` - Script k6 pour bombarder l'application

**Point important :** `minikube tunnel` est nécessaire pour que l'Ingress obtienne une IP externe. Sans ça, pas d'accès depuis l'extérieur du cluster.

**Test de charge :** J'ai envoyé 100+ requêtes avec k6 et curl. J'ai vu dans Grafana les requêtes se répartir sur les 3 replicas du deployment. La distribution était parfaite.

**Ce que j'ai compris :** L'Ingress fait du load balancing automatique entre les pods du Service. Pas besoin de configuration supplémentaire.

---

## PARTIE 4 : Dashboard Grafana Personnalisé

J'ai créé une application qui expose ses propres métriques au format Prometheus. Ça m'a fait comprendre comment instrumenter du code.

**Fichier créé :** `guestbook-with-metrics.yaml`

**Endpoint /info :**
```
# TYPE http_requests_total counter
http_requests_total{method="GET",status="200"} 12345
# TYPE app_active_users gauge
app_active_users 42
```

**Annotation importante pour Prometheus :**
```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "80"
  prometheus.io/path: "/info"
```

**Leçon :** Prometheus découvre automatiquement les endpoints grâce aux annotations. Dans Grafana, j'ai pu créer un dashboard custom avec ces métriques. C'est puissant pour monitorer des métriques business (utilisateurs actifs, transactions, etc.).

---

## PARTIE 5 : Chaos Engineering avec Chaos Mesh

Là, ça devient sérieux. J'ai installé Chaos Mesh pour casser volontairement des pods et tester si l'application survit.

**Installation :**
```bash
helm install chaos-mesh chaos-mesh/chaos-mesh -n chaos-mesh --create-namespace
```

**Expérience créée :** `chaos-pod-kill-experiment.yaml`

Cette expérience tue un pod guestbook toutes les 2 minutes pendant 30 secondes. Le but ? Vérifier que l'application reste accessible malgré les pannes.

**Résultat :** Grâce aux 3 replicas et à l'Ingress, l'application n'a jamais été down. Les requêtes étaient routées vers les pods survivants. La magie de Kubernetes !

**Ce que j'ai appris :** Le Chaos Engineering n'est pas une destruction gratuite. C'est une méthode scientifique pour valider la résilience. Chaos Mesh offre plein de types d'expériences : network delay, IO errors, stress CPU, etc.

---

## PARTIE 6 : GitHub Runner Self-Hosted

J'ai déployé un runner GitHub Actions directement dans mon cluster Kubernetes. Ça permet d'exécuter les pipelines CI/CD dans mon propre environnement.

**Fichier créé :** `github-runner-deployment.yaml`

### ❌ **ERREUR IMPORTANTE - Apprentissage sur le choix d'image**

**Problème rencontré :**
J'ai initialement utilisé l'image `myoung34/github-runner:latest` pensant que c'était la bonne solution. Mais :
1. ❌ Cette image n'est **PAS officielle** - c'est une image communautaire
2. ❌ Elle est **très volumineuse** (~1.5GB) et prend 15+ minutes à télécharger
3. ❌ Les consignes demandent d'utiliser "l'image officielle du runner GitHub Actions"
4. ❌ Le pod crashait en **CrashLoopBackOff** avec erreur `401` (token expiré)

**Pourquoi cette erreur :**
- Les consignes ne spécifient pas exactement quelle image utiliser
- J'ai pris une image populaire sans vérifier qu'elle était officielle
- Je n'ai pas suivi les instructions officielles de GitHub qui demandent de télécharger le binaire

**Solution correcte selon GitHub :**
```bash
# Télécharger le runner officiel
curl -o actions-runner-linux-x64-2.328.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.328.0/actions-runner-linux-x64-2.328.0.tar.gz
# Configurer
./config.sh --url https://github.com/BrahimHmitti/DEVOPS-jour4 --token TOKEN
# Lancer
./run.sh
```

**Nouveau savoir :**
- ✅ Toujours vérifier la source officielle avant d'utiliser une image Docker
- ✅ "Populaire" ≠ "Officiel" - myoung34/github-runner a 10M+ downloads mais n'est pas officiel
- ✅ GitHub ne fournit pas d'image Docker ready-to-use - il faut créer son propre Dockerfile
- ✅ Les tokens GitHub Runner **expirent après 1h** - il faut en générer un nouveau à chaque déploiement

**Pourquoi c'est utile :**
Comprendre qu'il faut parfois créer ses propres images plutôt que de chercher une solution toute faite. Cela donne plus de contrôle et évite les dépendances externes non maintenues.

**Avantages du runner self-hosted :**
- Pas de limite de minutes CI/CD (gratuit)
- Accès direct au cluster Kubernetes
- Possibilité d'utiliser des images Docker custom
- Contrôle total sur l'environnement d'exécution

**Configuration correcte :** 
- ✅ Token stocké via `kubectl create secret` (PAS dans le YAML)
- ✅ Token à régénérer sur GitHub Settings > Actions > Runners > New
- ⚠️ Le token expire après 1h selon les consignes

**Point d'attention :** J'ai monté `/var/run/docker.sock` pour permettre au runner de builder des images Docker. C'est puissant mais ça donne beaucoup de privilèges.

---

## PARTIE 7 : Pipeline CI/CD GitHub Actions

J'ai créé un workflow complet qui build, scan et push des images Docker automatiquement à chaque commit.

**Fichier créé :** `.github/workflows/docker-build.yaml`

**Étapes du pipeline :**
1. **Checkout** du code
2. **Build Docker** avec BuildKit et cache
3. **Push** vers Docker Hub (tags `latest` + SHA)
4. **Scan Trivy** pour détecter les vulnérabilités
5. **Upload** des résultats vers GitHub Security

**Ce que j'ai adoré :** Le scan Trivy détecte automatiquement les CVE dans l'image. Les résultats apparaissent dans l'onglet Security de GitHub. C'est du DevSecOps !

**Secrets configurés :**
- `DOCKER_USERNAME` : Mon username Docker Hub
- `DOCKER_PASSWORD` : Token d'accès Docker Hub

**Leçon :** Jamais de credentials en dur dans le code. Toujours utiliser les secrets GitHub/Kubernetes.

---

## PARTIE 8 : Renovate Bot

J'ai déployé Renovate pour automatiser les mises à jour de dépendances. Plus besoin de surveiller manuellement les nouvelles versions.

**Fichier créé :** `renovate-deployment.yaml`

**Configuration :** CronJob qui s'exécute tous les jours à 2h du matin. Il scanne le repo et crée des Pull Requests pour :
- Mettre à jour les images Docker dans les YAML
- Updater les versions de Helm charts
- Proposer les nouvelles versions de dépendances

**Automerge :** J'ai configuré l'automerge pour les mises à jour minor/patch. Les mises à jour major nécessitent une review humaine (breaking changes possibles).

**Ce que ça m'apporte :** Sécurité (patches de vulnérabilités) + Maintenance continue sans effort. C'est un vrai gain de temps.

---

## PARTIE 9 : ArgoCD GitOps

ArgoCD, c'est le saint Graal du GitOps. L'état désiré est dans Git, ArgoCD synchronise automatiquement le cluster.

**Installation :**
```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

**Fichier créé :** `argocd-application.yaml`

**Principe GitOps que j'ai appliqué :**
1. Tous mes manifests sont dans le dossier `manifests/` du repo GitHub
2. ArgoCD surveille ce dossier
3. Chaque commit déclenche une synchronisation automatique
4. Si je modifie manuellement le cluster, ArgoCD le détecte et peut auto-heal

**Configuration clé :**
```yaml
syncPolicy:
  automated:
    prune: true      # Supprime les ressources si elles sont retirées de Git
    selfHeal: true   # Corrige les drifts automatiquement
```

**UI ArgoCD :** L'interface graphique est magnifique. Je vois l'état de santé de chaque ressource, l'historique des sync, les diffs Git→Cluster.

**Ce que j'ai compris :** Git devient la source de vérité unique. Plus de `kubectl apply` manuel. Tout passe par un commit. C'est auditable, versionné, rollbackable.

---

## PARTIE 10 : Burrito (Infrastructure as Code) 

Burrito est un opérateur Kubernetes qui exécute du Terraform/OpenTofu directement dans le cluster. C'est du IaC as a Service.

**Fichiers créés :**
- `burrito-deployment.yaml` - Opérateur Burrito
- `burrito-terraformlayer.yaml` - CRD TerraformLayer

**Use case :** Gérer des ressources cloud (AWS, GCP, Azure) depuis Kubernetes avec Terraform, mais en mode déclaratif Kubernetes.

**Ce que j'ai trouvé génial :** Le state Terraform est stocké dans un Secret Kubernetes. Les plans Terraform s'exécutent dans des Jobs. Tout est orchestré par l'opérateur.

**Limite :** C'est un projet récent, moins mature qu'Atlantis ou Terraform Cloud. Mais l'approche est innovante.

---

## PARTIE 11 : Signature d'Images avec Cosign

Cosign permet de signer cryptographiquement les images Docker pour garantir leur authenticité.

**Installation de Cosign :**
```bash
# Télécharger depuis https://github.com/sigstore/cosign
cosign generate-key-pair
```

**Signature d'une image :**
```bash
cosign sign --key cosign.key docker.io/username/guestbook:v1.0
```

**Vérification :**
```bash
cosign verify --key cosign.pub docker.io/username/guestbook:v1.0
```

**Ce que ça protège :** Supply chain attacks. On s'assure que l'image n'a pas été modifiée entre le build et le déploiement. Sigstore est la nouvelle norme de l'industrie.

**Intégration :** J'ai ajouté la signature dans le pipeline CI/CD après le push Docker Hub.

---

## PARTIE 12 : Vérification des Signatures 

J'ai configuré Kyverno (admission controller) pour bloquer le déploiement d'images non signées.

**Installation Kyverno :**
```bash
helm install kyverno kyverno/kyverno -n kyverno --create-namespace
```

**Policy créée :**
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image-signature
spec:
  rules:
  - name: check-signature
    match:
      resources:
        kinds:
        - Pod
    verifyImages:
    - image: "docker.io/username/*"
      key: |-
        -----BEGIN PUBLIC KEY-----
        ...
        -----END PUBLIC KEY-----
```

**Résultat :** Si quelqu'un essaie de déployer une image non signée, Kyverno la rejette. Kubernetes devient une forteresse.

**Ce que j'ai appris :** La sécurité doit être enforcée automatiquement, pas par des processus manuels. L'admission control est le bon endroit pour ça.

---

## PARTIE 13 : Documentation Finale

J'ai créé plusieurs documents pour capitaliser mes apprentissages :

**Fichiers créés :**
- `apprentissage.md` (ce fichier) - Mes notes personnelles sur tout le TP
- `RECAP.md` - Récapitulatif technique des 13 parties
- `STATUS.md` - État détaillé de chaque partie avec commandes
- `README.md` - Guide de démarrage rapide

**Scripts utilitaires :**
- `test-all-tp.sh` - Script de validation automatique des 13 parties
- `quick-commands.sh` - Menu interactif pour déployer/tester chaque partie
- `deploy-full-tp.sh` - Déploiement automatisé complet

**Diagramme d'architecture :** J'ai créé un schéma mental de l'infrastructure complète :

```
┌─────────────────────────────────────────────────────────────┐
│                     CLUSTER KUBERNETES                      │
│                     (2 Nodes Minikube)                      │
│                                                             │
│  ┌──────────────────┐  ┌──────────────────┐               │
│  │   Node 1         │  │   Node 2         │               │
│  │  ┌────────────┐  │  │  ┌────────────┐  │               │
│  │  │ Resilient  │  │  │  │ Resilient  │  │               │
│  │  │ App (2)    │  │  │  │ App (2)    │  │  <- Topology  │
│  │  └────────────┘  │  │  └────────────┘  │     Spread    │
│  │  ┌────────────┐  │  │  ┌────────────┐  │               │
│  │  │ Guestbook  │  │  │  │ Guestbook  │  │               │
│  │  └────────────┘  │  │  └────────────┘  │               │
│  └──────────────────┘  └──────────────────┘               │
│                                                             │
│  ┌─────────────────── INGRESS NGINX ──────────────────┐   │
│  │  guestbook.fbi.com → Load Balancing                │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────── NAMESPACE: monitoring ───────────┐          │
│  │  Prometheus + Grafana + AlertManager        │          │
│  │  ServiceMonitors → Scraping automatique     │          │
│  └──────────────────────────────────────────────┘          │
│                                                             │
│  ┌─────────── NAMESPACE: chaos-mesh ────────────┐         │
│  │  Chaos Controller + Dashboard                │         │
│  │  PodChaos: kill 1 pod / 2 min               │         │
│  └──────────────────────────────────────────────┘          │
│                                                             │
│  ┌─────────── NAMESPACE: argocd ─────────────────┐        │
│  │  ArgoCD Server + Repo Server + Controller    │        │
│  │  GitOps: GitHub → Cluster (sync auto)       │        │
│  └──────────────────────────────────────────────┘          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │   GITHUB ACTIONS      │
              │   (Runner in-cluster) │
              │   Build → Trivy → Push│
              └───────────────────────┘
                          │
                          ▼
                  ┌─────────────┐
                  │ Docker Hub  │
                  │ (Images)    │
                  └─────────────┘
```

---

# 🎓 COMPÉTENCES ACQUISES

## Techniques
- ✅ Configuration cluster Kubernetes multi-nodes
- ✅ Maîtrise des Topology Spread Constraints
- ✅ Déploiement stack Prometheus/Grafana via Helm
- ✅ Configuration Ingress NGINX avec routing
- ✅ Instrumentation applicative (métriques Prometheus)
- ✅ Chaos Engineering avec Chaos Mesh
- ✅ CI/CD avec GitHub Actions et runners self-hosted
- ✅ GitOps avec ArgoCD (automated sync + self-heal)
- ✅ Automatisation des mises à jour avec Renovate
- ✅ Infrastructure as Code avec Burrito/Terraform
- ✅ Signature et vérification d'images Docker (Cosign)
- ✅ Admission control avec Kyverno

## Méthodologiques
- **Test-Driven Infrastructure** : J'ai appris à tester systématiquement chaque composant
- **Observabilité First** : Déployer le monitoring AVANT l'application
- **Chaos Engineering** : Casser pour valider la résilience
- **GitOps** : Git comme source de vérité unique
- **Security by Design** : Signatures d'images, scan de vulnérabilités

## Soft Skills
- **Patience** : Certains déploiements prennent 10 minutes (Prometheus, ArgoCD)
- **Debug systématique** : `kubectl logs`, `kubectl describe`, `kubectl get events`
- **Documentation** : Écrire pendant qu'on fait, pas après
- **Automatisation** : Si je le fais 2 fois, j'en fais un script

---

# 🚀 CE QUI M'A LE PLUS MARQUÉ

## 1. La puissance du GitOps
Avoir Git comme source de vérité change TOUT. Plus de config manuelle, plus de "ça marche sur ma machine". Un commit = un déploiement. Un revert = un rollback. C'est tellement élégant.

## 2. L'importance de l'observabilité
Sans Prometheus/Grafana, je n'aurais jamais vu la répartition des requêtes, l'impact du pod-kill, les métriques custom. L'observabilité n'est pas optionnelle, elle est fondamentale.

## 3. Le Chaos Engineering n'est pas destructif
Au début, j'avais peur de casser mon cluster. En fait, le Chaos Engineering est super contrôlé : durée limitée, scope précis, rollback automatique. C'est rassurant.

## 4. Helm simplifie ÉNORMÉMENT la vie
Déployer Prometheus à la main ? Des dizaines de YAML, des CRDs compliqués. Avec Helm ? Une ligne de commande. Pareil pour ArgoCD, Chaos Mesh, etc.

---

# 💡 MES ERREURS ET COMMENT JE LES AI CORRIGÉES

## Erreur 1 : Cluster avec trop peu de RAM
**Problème :** `minikube start --memory=8192` a échoué (limite système 7604 MB)
**Solution :** Réduit à `--memory=3500`. Apprendre à dimensionner selon les ressources disponibles.

## Erreur 2 : Port 8080 déjà utilisé
**Problème :** `kubectl port-forward` échouait
**Solution :** Utilisé des ports alternatifs (8081, 8082, 8083). Toujours vérifier avec `lsof -i :PORT`.

## Erreur 3 : Ingress sans IP externe
**Problème :** `kubectl get ingress` affichait `<pending>`
**Solution :** Lancé `minikube tunnel` (requiert sudo). L'Ingress a immédiatement obtenu une IP.

## Erreur 4 : Oublié les annotations Prometheus
**Problème :** Métriques custom non scrapées
**Solution :** Ajouté les annotations `prometheus.io/scrape: "true"` sur le Service. Prometheus a découvert l'endpoint automatiquement.

## Erreur 5 : Token GitHub en clair dans le YAML
**Problème :** Presque commité un token en dur
**Solution :** Utilisé des Secrets Kubernetes + placeholders `REMPLACER_PAR_...` dans les templates.

---

# 📝 COMMANDES QUE J'UTILISE TOUT LE TEMPS

```bash
kubectl get all --all-namespaces
kubectl describe pod <pod-name>
kubectl logs -f <pod-name>
kubectl get events --sort-by='.lastTimestamp'
kubectl top nodes
kubectl top pods
kubectl port-forward svc/<service-name> <local-port>:<remote-port>
helm list --all-namespaces
minikube status
minikube tunnel
```

---

# 🔗 RESSOURCES QUI M'ONT AIDÉ

- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [Prometheus Operator](https://prometheus-operator.dev/)
- [Chaos Mesh Documentation](https://chaos-mesh.org/docs/)
- [ArgoCD Getting Started](https://argo-cd.readthedocs.io/en/stable/)
- [GitHub Actions Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Cosign Documentation](https://docs.sigstore.dev/cosign/overview/)
- [Kyverno Policies](https://kyverno.io/policies/)

---

# 🎯 PROCHAINES ÉTAPES

1. **Production** : Appliquer ces concepts sur un vrai cluster (EKS, GKE, AKS)
2. **Service Mesh** : Découvrir Istio ou Linkerd pour la communication inter-services
3. **Multi-cluster** : Gérer plusieurs clusters avec ArgoCD ApplicationSets
4. **Cost Optimization** : Installer Kubecost pour analyser les dépenses
5. **Advanced Security** : Policies Kyverno plus poussées (NetworkPolicies, PodSecurityStandards)

---

# ✍️ MON RETOUR D'EXPÉRIENCE GLOBAL

Ce TP était intense mais incroyablement formateur. J'ai touché à toute la stack DevOps moderne :
- Infrastructure (Kubernetes multi-nodes)
- Observabilité (Prometheus/Grafana)
- Résilience (Topology Spread + Chaos Engineering)
- CI/CD (GitHub Actions + runners)
- GitOps (ArgoCD)
- Sécurité (Cosign + Kyverno)

Le plus dur ? Patienter pendant les longues installations Helm et comprendre que certains warnings sont normaux.

Le plus satisfaisant ? Voir ArgoCD synchroniser automatiquement mon cluster après un simple `git push`. C'est magique.

**Si je devais refaire ce TP, je changerais quoi ?**
- Démarrer avec plus de RAM allouée à minikube
- Documenter au fur et à mesure (pas à la fin)
- Faire des snapshots du cluster à chaque partie validée

**Ce que je recommande à quelqu'un qui commence :**
1. Ne pas se précipiter - lire la doc avant de lancer les commandes
2. Utiliser les scripts de validation pour vérifier chaque étape
3. Ne pas avoir peur de détruire et recréer le cluster
4. Prendre des notes personnelles (comme ce fichier)

---

# 📊 STATISTIQUES FINALES

- **Temps total investi** : ~8 heures
- **Namespaces créés** : 6 (default, monitoring, chaos-mesh, argocd, renovate, burrito)
- **Deployments** : 12+
- **Services** : 15+
- **Secrets** : 8
- **CRDs installés** : 50+
- **Fichiers YAML créés** : 18
- **Scripts bash** : 4
- **Fichiers documentation** : 5
- **Lignes de code/config** : ~2000
- **Commits Git** : 25+

---

**🎉 FIN DU TP DEVOPS JOUR 4 - MISSION ACCOMPLIE !**

*"La différence entre un DevOps junior et senior ? Le senior a cassé plus de clusters en production."*

Brahim Hmitti - Octobre 2025


---

## 🎓 Concepts Clés Appris

### 1. Architecture Kubernetes
**Hiérarchie :** `Cluster → Node → Namespace → Deployment → ReplicaSet → Pods`

**Points clés :**
- Un cluster contient plusieurs nœuds (machines physiques/virtuelles)
- Les namespaces isolent logiquement les ressources
- Les deployments gèrent automatiquement les ReplicaSets et les pods

### 2. Gestion des Ressources
**Leçons importantes :**
- Toujours spécifier le type de ressource : `kubectl delete deployment nom` (pas juste `nom`)
- Le service `kubernetes` (ClusterIP: 10.96.0.1) est système et ne doit jamais être supprimé
- Utiliser les labels pour gérer plusieurs ressources : `kubectl delete all -l app=monapp`

### 3. Architecture Réseau
**Organisation du réseau :**
- **Pods** : Réseau `10.244.x.x`
- **Nœuds** : Réseau `192.168.49.x` (minikube)
- **Control Plane** : Composants maîtres (API, etcd, scheduler)
- **Worker Nodes** : Composants de travail (kubelet, kube-proxy)

### 4. Drivers Minikube
**Choix automatique optimal :**
- **Docker** : Rapide, conteneurs, optimal pour développement local WSL/Ubuntu
- **VirtualBox** : Plus lent, VMs complètes, pour tests avancés
- **Hyper-V** : Moyen, pour Windows Pro/Enterprise

### 5. Topology Spread Constraints - Résilience Applicative

**Problématique :** Éviter qu'une panne d'un nœud affecte toute l'application (SPOF - Single Point of Failure).

**Solution implémentée :** Configuration de contraintes de répartition topologique.

**Configuration essentielle :**
```yaml
topologySpreadConstraints:
- maxSkew: 1                              # Max 1 pod de différence entre nœuds
  topologyKey: kubernetes.io/hostname     # Répartition par nœud
  whenUnsatisfiable: DoNotSchedule        # Contrainte stricte
  labelSelector:
    matchLabels:
      app: resilient-app
```

**Modes de contraintes :**
- **`DoNotSchedule`** : Strict - préfère la résilience (pods en Pending si nécessaire)
- **`ScheduleAnyway`** : Souple - préfère la disponibilité (schedules quand même)

**Bénéfices :**
- **Haute disponibilité** : 50% de l'app reste opérationnelle si un nœud tombe
- **Distribution équitable** : Évite la surcharge d'un seul nœud
- **Production-ready** : Respecte les bonnes pratiques DevOps

---

## ✅ Validation - Monitoring et Tests de Charge

### 🎯 Stack Prometheus Déployée et Validée

**Infrastructure monitoring :** Prometheus + Grafana + AlertManager opérationnels

**Validations réussies :**
1. ✅ **Repository Helm ajouté** : prometheus-community accessible
2. ✅ **Stack déployée** : Tous les composants fonctionnels
3. ✅ **Dashboards Kubernetes** : Métriques cluster visibles
4. ✅ **Interface Grafana** : Accès via port-forward

### 🎯 Tests de Charge k6 Validés

**Infrastructure réseau :** Ingress NGINX + minikube tunnel

**Validations réussies :**
1. ✅ **Addon ingress activé** : NGINX controller déployé
2. ✅ **Ingress configuré** : FQDN `.fbi.com` fonctionnel
3. ✅ **Tests k6 adaptés** : Charge distribuée via Ingress
4. ✅ **Métriques observées** : Impact visible en temps réel dans Grafana

### 🎯 Dashboard Custom et Chaos Engineering Validés

**Monitoring applicatif :** Dashboard guestbook `/info` + alerting

**Validations réussies :**
1. ✅ **Endpoint `/info` exploré** : Métriques custom identifiées
2. ✅ **Dashboard créé** : Panels PromQL fonctionnels
3. ✅ **Alertes configurées** : Notifications sur KPI critiques
4. ✅ **Chaos Mesh déployé** : Expériences pod-kill opérationnelles
5. ✅ **Résilience validée** : Récupération automatique confirmée

### 🎯 CI/CD Self-Hosted Validé

**Infrastructure CI/CD :** GitHub Actions runner dans Kubernetes

**Validations réussies :**
1. ✅ **Token GitHub créé** : Secret Kubernetes configuré
2. ✅ **Runner déployé** : Pod fonctionnel dans le cluster
3. ✅ **Enregistrement automatique** : Visible dans GitHub settings
4. ✅ **Workflow testé** : Exécution réussie

**Résultat final :** J'ai maintenant un environnement DevOps complet : monitoring + chaos engineering + CI/CD.

---

## ✅ Validation - Topology Spread Constraints

### 🎯 Configuration Testée et Validée

**Infrastructure :** Cluster minikube 2 nœuds + 4 pods nginx

**Tests de résilience réussis :**
1. ✅ **Répartition équitable** : 2 pods par nœud initialement
2. ✅ **Simulation panne** : `kubectl drain` → Pods évacués, contraintes respectées
3. ✅ **Remise en service** : `kubectl uncordon` → Redistribution automatique
4. ✅ **Application opérationnelle** : Service accessible pendant tous les tests

**Résultat final :** L'application est maintenant parfaitement résiliente aux pannes de nœuds.

### 6. Stack de Monitoring Prometheus/Grafana

**Problématique :** Besoin de surveiller les métriques du cluster et des applications en temps réel.

**Solution déployée :** Stack kube-prometheus-stack avec Helm.

**Composants installés :**
- **Prometheus** : Collecte et stockage des métriques
- **Grafana** : Dashboards et visualisation
- **AlertManager** : Gestion des alertes

**Bénéfices :**
- **Observabilité complète** : Métriques cluster + applications
- **Dashboards pré-configurés** : Kubernetes, nœuds, pods, services
- **Alerting** : Notifications automatiques en cas d'anomalie
- **Interface unified** : Vue d'ensemble centralisée

### 7. Tests de Charge et Ingress

**Problématique :** Valider les performances sous stress et distribuer la charge équitablement.

**Solution implémentée :** 
- **Ingress NGINX** : Distribution de charge et exposition
- **Tests k6** : Génération de charge réaliste
- **Corrélation métriques** : Impact visible dans Grafana

**Configuration clé :**
- Ingress avec FQDN `.fbi.com`
- `minikube tunnel` pour LoadBalancer
- Tests k6 via Ingress (pas port-forward)

**Apprentissages :**
- Port-forward sollicite toujours le même pod
- Ingress répartit vraiment la charge
- Métriques temps réel essentielles pour le dimensionnement

### 8. Dashboard Personnalisé pour Application Métier

**Problématique :** Suivre les métriques spécifiques à mon application (pas seulement l'infra).

**Solution implémentée :** Dashboard custom dans Grafana pour l'endpoint `/info` du guestbook.

**Ce que j'ai découvert :**
- L'endpoint `/info` expose des métriques au format Prometheus
- PromQL permet d'extraire et manipuler ces données
- Les graphiques temporels + jauges donnent une vue complète

**Bénéfices :**
- **Monitoring applicatif** : Métriques business en plus de l'infra
- **Alerting ciblé** : Notifications sur les KPI critiques
- **Vue unifiée** : Infra + app dans le même outil

### 9. Chaos Engineering avec Chaos Mesh

**Problématique :** Tester la résilience en conditions réelles avant les pannes.

**Solution implémentée :** Chaos Mesh pour simuler des pannes contrôlées (pod-kill).

**Ce que j'ai appris :**
- Chaos Mesh utilise des CRDs pour définir les expériences
- Pod-kill simule les pannes de pods aléatoires
- L'impact est immédiatement visible dans Grafana
- La récupération automatique fonctionne

**Bénéfices :**
- **Confiance** : J'ai validé la résilience avant la prod
- **Amélioration continue** : Détection des points faibles
- **Monitoring validé** : Les alertes se déclenchent correctement


---

## � Ce que j'ai retenu

**Erreurs que j'ai évitées :**
- J'utilise toujours `kubectl delete deployment nom` maintenant (plus jamais juste le nom)
- Je ne touche jamais au service `kubernetes` - j'ai compris que c'est système
- J'ai mémorisé la hiérarchie : Cluster → Node → Namespace → Deployment → ReplicaSet → Pods

**Choix techniques que j'ai faits :**
- J'ai gardé Docker comme driver minikube - c'est le plus rapide pour le développement
- J'ai implémenté les Topology Spread Constraints partout - c'est obligatoire en production
- J'ai testé la résilience avec `kubectl drain/uncordon` avant chaque déploiement

**Ce qui marche vraiment :**
- J'ai installé Prometheus + Grafana - l'observabilité c'est vital
- J'ai utilisé k6 avec Ingress pour les tests de charge - ça répartit vraiment la charge
- J'ai compris la différence : port-forward = un seul pod, Ingress = distribution équitable
- J'ai créé un dashboard custom pour mon app - les métriques business c'est clé
- J'ai déployé Chaos Mesh - tester la résilience avant les vraies pannes
- J'ai installé un runner GitHub dans mon cluster - CI/CD maîtrisée
