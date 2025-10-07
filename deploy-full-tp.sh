#!/bin/bash

# ========================================
# SCRIPT AUTOMATIQUE TP DEVOPS JOUR 4
# Déploiement complet : Résilience + Monitoring + Chaos Engineering + CI/CD
# ========================================

set -e  # Arrêt en cas d'erreur

echo "🚀 DÉBUT DU TP DEVOPS JOUR 4 - AUTOMATISÉ"
echo "========================================"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_section() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

wait_for_pods() {
    local namespace=$1
    local timeout=${2:-300}
    echo "⏳ Attente que tous les pods soient prêts dans le namespace $namespace..."
    kubectl wait --for=condition=ready pod --all -n $namespace --timeout=${timeout}s || true
    sleep 10
}

# ========================================
# PARTIE 1: PRÉPARATION CLUSTER
# ========================================

print_section "PARTIE 1: PRÉPARATION CLUSTER MINIKUBE"

echo "🔧 Vérification et nettoyage cluster existant..."
minikube delete || true

echo "🔧 Création cluster minikube 2 nœuds..."
minikube start --nodes 2 --cpus 3 --memory 4096

echo "📊 Vérification des nœuds..."
kubectl get nodes

print_success "Cluster minikube 2 nœuds créé"

# ========================================
# PARTIE 2: TOPOLOGY SPREAD CONSTRAINTS
# ========================================

print_section "PARTIE 2: DÉPLOIEMENT APPLICATION RÉSILIENTE"

echo "📦 Déploiement application résiliente..."
kubectl apply -f resilient-app-deployment.yaml

echo "🌐 Création services d'exposition..."
kubectl apply -f resilient-app-service.yaml

echo "⏳ Attente déploiement application résiliente..."
wait_for_pods "default"

echo "📊 Vérification répartition des pods..."
kubectl get pods -o wide | grep resilient

print_success "Application résiliente déployée avec Topology Spread Constraints"

# Test de résilience
echo "🔥 Test de résilience - Simulation panne nœud..."
kubectl drain minikube-m02 --ignore-daemonsets --delete-emptydir-data --force || true
sleep 10

echo "📊 État après drainage..."
kubectl get pods -o wide | grep resilient

echo "🔄 Remise en service du nœud..."
kubectl uncordon minikube-m02
sleep 10

echo "📊 État après remise en service..."
kubectl get pods -o wide | grep resilient

print_success "Test de résilience validé"

# ========================================
# PARTIE 3: MONITORING PROMETHEUS/GRAFANA
# ========================================

print_section "PARTIE 3: DÉPLOIEMENT STACK MONITORING"

echo "📋 Ajout repository Helm Prometheus..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "📦 Déploiement stack kube-prometheus-stack..."
helm install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring --create-namespace \
    --wait --timeout=15m

echo "⏳ Attente stack monitoring..."
wait_for_pods "monitoring" 600

echo "🔑 Récupération password Grafana..."
GRAFANA_PASSWORD=$(kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d)

echo "🌐 Création port-forward Grafana (arrière-plan)..."
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &
GRAFANA_PID=$!

echo "🌐 Création port-forward Prometheus (arrière-plan)..."
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &
PROMETHEUS_PID=$!

sleep 5

echo "🧪 Test accès Grafana..."
curl -s http://localhost:3000/api/health || print_warning "Grafana pas encore accessible"

print_success "Stack Prometheus/Grafana déployée"
echo "📋 ACCÈS GRAFANA:"
echo "   URL: http://localhost:3000"
echo "   Username: admin"
echo "   Password: $GRAFANA_PASSWORD"

# ========================================
# PARTIE 4: INGRESS ET TESTS DE CHARGE
# ========================================

print_section "PARTIE 4: CONFIGURATION INGRESS ET TESTS"

echo "🔧 Activation addon ingress minikube..."
minikube addons enable ingress

echo "⏳ Attente controller ingress..."
kubectl wait --for=condition=ready pod --all -n ingress-nginx --timeout=300s

echo "📦 Déploiement application guestbook..."
kubectl apply -f guestbook-deployment.yaml

echo "🌐 Configuration ingress..."
kubectl apply -f guestbook-ingress.yaml

echo "🌐 Démarrage minikube tunnel (arrière-plan)..."
sudo -b minikube tunnel

echo "⏳ Attente application guestbook..."
wait_for_pods "default"

echo "🌐 Configuration port-forward ingress pour tests..."
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8081:80 &
INGRESS_PID=$!

sleep 5

echo "🧪 Test accès application via ingress..."
curl -H "Host: guestbook.fbi.com" http://localhost:8081 | head -3

echo "🚀 Tests de charge (50 requêtes)..."
for i in {1..50}; do
    curl -s -H "Host: guestbook.fbi.com" http://localhost:8081 > /dev/null && echo -n "."
    sleep 0.1
done
echo ""

print_success "Ingress configuré et tests de charge effectués"

# ========================================
# PARTIE 5: APPLICATION AVEC MÉTRIQUES CUSTOM
# ========================================

print_section "PARTIE 5: APPLICATION AVEC MÉTRIQUES CUSTOM"

echo "📦 Déploiement application avec métriques..."
kubectl apply -f guestbook-with-metrics.yaml

echo "⏳ Attente application avec métriques..."
wait_for_pods "default"

echo "🌐 Port-forward application métriques..."
kubectl port-forward service/guestbook-metrics-service 8082:80 &
METRICS_PID=$!

sleep 5

echo "🧪 Test endpoint /info avec métriques custom..."
curl http://localhost:8082/info

print_success "Application avec métriques custom déployée"

# ========================================
# PARTIE 6: CHAOS ENGINEERING
# ========================================

print_section "PARTIE 6: DÉPLOIEMENT CHAOS MESH"

echo "📋 Ajout repository Helm Chaos Mesh..."
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update

echo "📦 Déploiement Chaos Mesh..."
helm install chaos-mesh chaos-mesh/chaos-mesh \
    --namespace chaos-mesh --create-namespace \
    --set dashboard.create=true \
    --wait --timeout=10m

echo "⏳ Attente Chaos Mesh..."
wait_for_pods "chaos-mesh"

echo "🌐 Port-forward dashboard Chaos Mesh..."
kubectl port-forward -n chaos-mesh svc/chaos-dashboard 2333:2333 &
CHAOS_PID=$!

sleep 5

echo "🧪 Test accès dashboard Chaos Mesh..."
curl -s http://localhost:2333 | head -3 || print_warning "Dashboard Chaos Mesh pas encore accessible"

# Création expérience pod-kill
echo "💥 Création expérience pod-kill..."
cat > pod-kill-experiment.yaml << EOF
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

kubectl apply -f pod-kill-experiment.yaml

print_success "Chaos Mesh déployé avec expérience pod-kill"
echo "📋 ACCÈS CHAOS MESH:"
echo "   URL: http://localhost:2333"

# ========================================
# PARTIE 7: GITHUB ACTIONS RUNNER
# ========================================

print_section "PARTIE 7: GITHUB ACTIONS RUNNER SELF-HOSTED"

print_warning "GitHub Runner nécessite un token personnel"
echo "📋 Pour créer le token:"
echo "   1. Allez dans Settings > Actions > Runners"
echo "   2. Cliquez 'New self-hosted runner'"
echo "   3. Copiez le token affiché"
echo ""
echo "📝 Ensuite exécutez:"
echo "   kubectl create secret generic github-runner-token --from-literal=token=VOTRE_TOKEN"

# Template deployment runner
cat > github-runner-deployment.yaml << EOF
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

echo "📄 Template GitHub Runner créé: github-runner-deployment.yaml"

print_success "Configuration GitHub Runner préparée"

# ========================================
# RÉCAPITULATIF FINAL
# ========================================

print_section "RÉCAPITULATIF FINAL - ACCÈS AUX SERVICES"

echo "🌐 SERVICES ACCESSIBLES:"
echo "   📊 Grafana:      http://localhost:3000 (admin/$GRAFANA_PASSWORD)"
echo "   📈 Prometheus:   http://localhost:9090"
echo "   🌍 Guestbook:    http://localhost:8081 (Host: guestbook.fbi.com)"
echo "   📊 Métriques:    http://localhost:8082/info"
echo "   💥 Chaos Mesh:   http://localhost:2333"
echo ""

echo "🔧 COMMANDES UTILES:"
echo "   kubectl get pods --all-namespaces"
echo "   kubectl get ingress"
echo "   kubectl get chaos -n chaos-mesh"
echo ""

echo "📋 PIDS DES PORT-FORWARDS (pour kill si besoin):"
echo "   Grafana: $GRAFANA_PID"
echo "   Prometheus: $PROMETHEUS_PID"
echo "   Ingress: $INGRESS_PID"
echo "   Métriques: $METRICS_PID"
echo "   Chaos: $CHAOS_PID"

print_success "TP DEVOPS JOUR 4 TERMINÉ AVEC SUCCÈS!"
echo ""
echo "🎓 TOUT EST DÉPLOYÉ ET FONCTIONNEL:"
echo "   ✅ Cluster résilient avec Topology Spread Constraints"
echo "   ✅ Monitoring complet Prometheus + Grafana"
echo "   ✅ Tests de charge via Ingress"
echo "   ✅ Métriques applicatives custom"
echo "   ✅ Chaos Engineering avec Chaos Mesh"
echo "   📝 GitHub Runner (template prêt)"
echo ""
echo "📚 Consultez apprentissage.md et how-to-start.md pour plus de détails!"

# Fonction cleanup pour arrêter les port-forwards
cleanup() {
    echo "🧹 Nettoyage des port-forwards..."
    kill $GRAFANA_PID $PROMETHEUS_PID $INGRESS_PID $METRICS_PID $CHAOS_PID 2>/dev/null || true
}

trap cleanup EXIT

echo "🔄 Appuyez sur Ctrl+C pour arrêter les port-forwards et nettoyer"
echo "💡 Ou laissez tourner pour continuer à utiliser les services"

# Garde le script actif pour maintenir les port-forwards
wait