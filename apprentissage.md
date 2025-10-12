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
 J'ai installé Chaos Mesh pour casser volontairement des pods et tester si l'application survit.

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

# 🚀 CE QUI M'A LE PLUS MARQUÉ

## 1. La puissance du GitOps
Avoir Git comme source de vérité change TOUT. Plus de config manuelle, plus de "ça marche sur ma machine". Un commit = un déploiement. Un revert 


## 2. Le Chaos Engineering n'est pas destructif
on a souvent  peur de casser nos cluster. En fait, le Chaos Engineering est super contrôlé : durée limitée, scope précis, rollback automatique. C'est rassurant.



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

