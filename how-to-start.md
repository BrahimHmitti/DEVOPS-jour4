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
