# 🚀 Guide Pratique DevOps - Kubernetes Résilience et Monitoring

---

## 📋 **PARTIE 1 : Topology Spread Constraints**

## 🔧 Étape 1 : Préparation du Cluster

### Créer un cluster multi-nœuds
```bash
# Supprimer un cluster existant si nécessaire
minikube delete

# Créer un cluster avec 2 nœuds
minikube start --nodes 2 --cpus 3 --memory 4096

# Vérifier les nœuds
kubectl get nodes
```

**Résultat attendu :**
```
NAME           STATUS   ROLES           AGE   VERSION
minikube       Ready    control-plane   10m   v1.34.0
minikube-m02   Ready    <none>          10m   v1.34.0
```

---

## 📦 Étape 2 : Déploiement de l'Application Résiliente

### Déployer l'application
```bash
# Appliquer le deployment avec Topology Spread Constraints
kubectl apply -f resilient-app-deployment.yaml

# Créer le service d'exposition
kubectl apply -f resilient-app-service.yaml
```

### Vérifier le déploiement
```bash
# Voir tous les pods avec leur répartition
kubectl get pods -o wide | grep resilient

# Vérifier les services
kubectl get services | grep resilient

# Voir le statut du deployment
kubectl get deployment resilient-app
```

**Résultat attendu :**
- 4 pods déployés
- 2 pods sur chaque nœud (répartition équitable)
- Services créés et accessibles

---

## 🧪 Étape 3 : Tests de Fonctionnement

### Test de base de l'application
```bash
# Tester l'application depuis un pod
kubectl exec -it $(kubectl get pods | grep resilient | head -1 | awk '{print $1}') -- curl localhost

# Voir les détails de configuration
kubectl get deployment resilient-app -o yaml | grep -A 10 -B 5 topologySpreadConstraints
```

### Vérifier la répartition des pods
```bash
# Voir la répartition détaillée
kubectl get pods -l app=resilient-app -o wide

# Compter les pods par nœud
echo "Pods sur minikube:"
kubectl get pods -o wide | grep resilient | grep minikube | grep -v minikube-m02 | wc -l

echo "Pods sur minikube-m02:"
kubectl get pods -o wide | grep resilient | grep minikube-m02 | wc -l
```

---

## 🔥 Étape 4 : Tests de Résilience

### Test 1 - Simulation de panne d'un nœud
```bash
echo "=== AVANT - Répartition des pods ==="
kubectl get pods -o wide | grep resilient

echo "=== SIMULATION PANNE - Drainage du nœud minikube-m02 ==="
kubectl drain minikube-m02 --ignore-daemonsets --delete-emptydir-data --force

echo "=== PENDANT - État des pods après drainage ==="
kubectl get pods -o wide | grep resilient

echo "=== ANALYSE - Pourquoi certains pods sont Pending ==="
kubectl describe pod $(kubectl get pods | grep Pending | head -1 | awk '{print $1}') | grep -A 5 "Events:"
```

### Test 2 - Remise en service
```bash
echo "=== REMISE EN SERVICE du nœud ==="
kubectl uncordon minikube-m02

echo "=== Attendre la redistribution (5 secondes) ==="
sleep 5

echo "=== APRÈS - Nouvelle répartition ==="
kubectl get pods -o wide | grep resilient
```

### Test 3 - Vérification fonctionnelle après tests
```bash
echo "=== TEST FONCTIONNEL - L'application fonctionne-t-elle ? ==="
kubectl exec -it $(kubectl get pods | grep resilient | grep Running | head -1 | awk '{print $1}') -- curl localhost | head -3
```

---

## 📊 Étape 5 : Validation et Nettoyage

### Valider que tous les critères sont respectés
```bash
echo "=== VALIDATION FINALE ==="

echo "1. Nombre de nœuds disponibles:"
kubectl get nodes | grep Ready | wc -l

echo "2. Répartition équitable des pods:"
kubectl get pods -l app=resilient-app -o wide

echo "3. Status du deployment:"
kubectl get deployment resilient-app

echo "4. Services accessibles:"
kubectl get services | grep resilient

echo "5. Test application:"
kubectl exec -it $(kubectl get pods | grep resilient | grep Running | head -1 | awk '{print $1}') -- curl -s localhost | grep -o "<title>.*</title>"
```

### Nettoyage (optionnel)
```bash
# Supprimer l'application
kubectl delete -f resilient-app-deployment.yaml
kubectl delete -f resilient-app-service.yaml

# Ou supprimer tout par label
kubectl delete all -l app=resilient-app
```

---

## 🔍 Commandes de Diagnostic

### Debug en cas de problème
```bash
# Voir tous les événements récents
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -20

# Diagnostiquer un pod en erreur
kubectl describe pod <nom-du-pod>

# Voir les logs d'un pod
kubectl logs <nom-du-pod>

# Vérifier l'état des nœuds
kubectl describe nodes

# Voir les contraintes de topologie appliquées
kubectl get deployment resilient-app -o jsonpath='{.spec.template.spec.topologySpreadConstraints}' | jq .
```

### Commandes de surveillance
```bash
# Surveiller les pods en temps réel
kubectl get pods -w

# Voir l'utilisation des ressources
kubectl top nodes
kubectl top pods

# Vérifier les services
kubectl get endpoints
kubectl describe service resilient-app
```

---

## 📋 **PARTIE 2 : Stack Monitoring Prometheus/Grafana**

## 🔧 Étape 6 : Installation de la Stack de Monitoring

### Ajouter le repository Helm Prometheus
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### Déployer la stack kube-prometheus-stack
```bash
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
```

### Vérifier le déploiement
```bash
kubectl get pods -n monitoring
kubectl get services -n monitoring
```

---

## 🔧 Étape 7 : Configuration des Accès Web

### Accéder à Grafana
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &
```

### Accéder à Prometheus
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &
```

### Récupérer les credentials Grafana
```bash
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

---

## 🔧 Étape 8 : Validation du Monitoring

### Tester l'accès aux interfaces
```bash
curl http://localhost:3000/api/health
curl http://localhost:9090/-/healthy
```

### Vérifier les dashboards Kubernetes
```bash
kubectl get configmaps -n monitoring | grep dashboard
```

---

## 📋 **PARTIE 3 : Tests de Charge avec Ingress**

## 🔧 Étape 9 : Configuration Ingress

### Activer l'addon ingress minikube
```bash
minikube addons enable ingress
kubectl get pods -n ingress-nginx
```

### Créer l'Ingress pour guestbook
```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: guestbook-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: guestbook.fbi.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: guestbook-service
            port:
              number: 80
EOF
```

### Démarrer minikube tunnel
```bash
minikube tunnel &
```

---

## 🔧 Étape 10 : Tests de Charge k6

### Tester l'accès via Ingress
```bash
echo "$(minikube ip) guestbook.fbi.com" | sudo tee -a /etc/hosts
curl http://guestbook.fbi.com
```

### Créer le script de test k6
```bash
cat > load-test.js <<EOF
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 10 },
    { duration: '5m', target: 50 },
    { duration: '2m', target: 0 },
  ],
};

export default function () {
  let response = http.get('http://guestbook.fbi.com');
  check(response, {
    'status is 200': (r) => r.status === 200,
  });
}
EOF
```

### Lancer les tests k6
```bash
k6 run load-test.js
```

---

## 🔧 Étape 11 : Observation des Métriques

### Surveiller pendant les tests
```bash
kubectl get pods -w
kubectl top nodes
kubectl top pods
```

### Vérifier les métriques dans Grafana
```bash
echo "Accédez à http://localhost:3000"
echo "Username: admin"
echo "Password: $(kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)"
```

🚀 **J'ai maintenant un monitoring complet avec tests de performance validés !**

---

## 📋 **PARTIE 4 : Dashboard Custom pour Application**

## 🔧 Étape 12 : Exploration Endpoint Métriques

### Explorer l'endpoint /info du guestbook
```bash
kubectl port-forward service/guestbook-service 8080:80 &
curl http://localhost:8080/info
```

### Vérifier ce que Prometheus scrappe
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &
curl "http://localhost:9090/api/v1/label/__name__/values" | jq
```

---

## 🔧 Étape 13 : Création Dashboard Grafana

### Créer un nouveau dashboard dans Grafana
```bash
echo "Accédez à http://localhost:3000"
echo "Cliquez sur '+' > Dashboard > Add Panel"
```

### Exemples de requêtes PromQL pour panels
```bash
# Taux de requêtes par seconde
rate(http_requests_total[5m])

# Latence moyenne
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Erreurs par minute
increase(http_requests_total{status=~"5.."}[1m])
```

---

## 🔧 Étape 14 : Configuration Alertes

### Créer des alertes sur métriques critiques
```bash
# Dans Grafana: Alerting > Alert Rules > New Rule
# Condition: http_requests_total rate > 100
# Evaluation: every 10s for 30s
```

---

## 📋 **PARTIE 5 : Chaos Engineering avec Chaos Mesh**

## 🔧 Étape 15 : Installation Chaos Mesh

### Ajouter le repository Helm Chaos Mesh
```bash
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update
```

### Déployer Chaos Mesh
```bash
helm install chaos-mesh chaos-mesh/chaos-mesh --namespace chaos-mesh --create-namespace --set dashboard.create=true
```

### Vérifier l'installation
```bash
kubectl get pods -n chaos-mesh
kubectl get crd | grep chaos
```

---

## 🔧 Étape 16 : Accès Dashboard Chaos Mesh

### Accéder au dashboard
```bash
kubectl port-forward -n chaos-mesh svc/chaos-dashboard 2333:2333 &
echo "Dashboard accessible: http://localhost:2333"
```

---

## 🔧 Étape 17 : Expérience Pod-Kill

### Créer l'expérience pod-kill
```bash
kubectl apply -f - <<EOF
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: guestbook-pod-kill
  namespace: default
spec:
  action: pod-kill
  mode: one
  duration: "30s"
  selector:
    labelSelectors:
      app: guestbook
  scheduler:
    cron: "@every 2m"
EOF
```

### Surveiller l'impact
```bash
kubectl get pods -w
kubectl logs -f deployment/guestbook
```

---

## 📋 **PARTIE 6 : GitHub Actions Runner Self-Hosted**

## 🔧 Étape 18 : Préparation Token GitHub

### Créer un token dans GitHub
```bash
echo "1. Allez dans Settings > Actions > Runners"
echo "2. Cliquez 'New self-hosted runner'"
echo "3. Copiez le token affiché"
```

### Créer le secret Kubernetes
```bash
kubectl create secret generic github-runner-token --from-literal=token=YOUR_TOKEN_HERE
```

---

## 🔧 Étape 19 : Déploiement Runner

### Déployer le runner comme pod
```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: github-runner
spec:
  replicas: 1
  selector:
    matchLabels:
      app: github-runner
  template:
    metadata:
      labels:
        app: github-runner
    spec:
      containers:
      - name: runner
        image: sumologic/github-runner:latest
        env:
        - name: GITHUB_TOKEN
          valueFrom:
            secretKeyRef:
              name: github-runner-token
              key: token
        - name: GITHUB_OWNER
          value: "BrahimHmitti"
        - name: GITHUB_REPOSITORY
          value: "DEVOPS-jour4"
        volumeMounts:
        - name: docker-sock
          mountPath: /var/run/docker.sock
      volumes:
      - name: docker-sock
        hostPath:
          path: /var/run/docker.sock
EOF
```

---

## 🔧 Étape 20 : Test du Runner

### Vérifier l'enregistrement
```bash
kubectl logs deployment/github-runner
kubectl get pods -l app=github-runner
```

### Créer un workflow de test
```bash
mkdir -p .github/workflows
cat > .github/workflows/test-runner.yml <<EOF
name: Test Self-Hosted Runner
on: [push]
jobs:
  test:
    runs-on: self-hosted
    steps:
    - uses: actions/checkout@v3
    - name: Test
      run: echo "Runner fonctionne dans Kubernetes!"
EOF
```

### Pousser et vérifier
```bash
git add .github/
git commit -m "Test runner self-hosted"
git push
```

🚀 **J'ai maintenant un environnement DevOps complet : monitoring + chaos engineering + CI/CD !**
