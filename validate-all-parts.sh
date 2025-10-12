#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_section() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

validate_part() {
    local part_num=$1
    local part_name=$2
    print_section "PARTIE $part_num : $part_name"
}

validate_part 0 "Configuration du cluster minikube multi-nodes"
echo "État du cluster :"
minikube status
kubectl get nodes -o wide
NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
if [ "$NODE_COUNT" -eq 2 ]; then
    print_success "Cluster multi-nodes confirmé : $NODE_COUNT nœuds"
else
    print_error "Cluster multi-nodes non validé : $NODE_COUNT nœud(s) trouvé(s)"
fi

validate_part 1 "Topology Spread Constraints"
kubectl get deployment resilient-app -o yaml | grep -A 10 "topologySpreadConstraints" || print_error "Topology Spread Constraints non trouvé"
RESILIENT_PODS=$(kubectl get pods -l app=resilient-app --no-headers | wc -l)
print_info "Pods resilient-app déployés : $RESILIENT_PODS"
kubectl get pods -l app=resilient-app -o wide

validate_part 2 "Prometheus et Grafana"
kubectl get pods -n monitoring
PROMETHEUS_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --no-headers 2>/dev/null | wc -l)
GRAFANA_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --no-headers 2>/dev/null | wc -l)
if [ "$PROMETHEUS_PODS" -gt 0 ] && [ "$GRAFANA_PODS" -gt 0 ]; then
    print_success "Stack de monitoring déployée : Prometheus ($PROMETHEUS_PODS pods) + Grafana ($GRAFANA_PODS pods)"
else
    print_error "Stack de monitoring incomplète"
fi

validate_part 3 "Ingress et Tests de charge"
kubectl get ingress guestbook-ingress
INGRESS_IP=$(kubectl get ingress guestbook-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -n "$INGRESS_IP" ]; then
    print_success "Ingress configuré avec IP : $INGRESS_IP"
else
    print_warning "Ingress sans IP externe (tunnel minikube requis)"
fi
if [ -f "load-test.js" ]; then
    print_success "Script k6 trouvé : load-test.js"
else
    print_warning "load-test.js non trouvé"
fi

validate_part 4 "Dashboard Grafana personnalisé"
print_info "Vérification du service avec métriques /info"
kubectl get svc guestbook-metrics-service
kubectl get pods -l app=guestbook-metrics

validate_part 5 "Chaos Engineering avec Chaos Mesh"
CHAOS_NAMESPACE=$(kubectl get namespace chaos-mesh --no-headers 2>/dev/null | awk '{print $1}')
if [ "$CHAOS_NAMESPACE" == "chaos-mesh" ]; then
    print_success "Namespace chaos-mesh trouvé"
    kubectl get pods -n chaos-mesh
    CHAOS_EXPERIMENTS=$(kubectl get podchaos --no-headers 2>/dev/null | wc -l)
    print_info "Expériences Chaos actives : $CHAOS_EXPERIMENTS"
else
    print_error "Chaos Mesh non déployé"
fi

validate_part 6 "GitHub Runner Self-Hosted"
RUNNER_PODS=$(kubectl get pods -l app=github-runner --no-headers 2>/dev/null | wc -l)
if [ "$RUNNER_PODS" -gt 0 ]; then
    print_success "GitHub Runner déployé : $RUNNER_PODS pod(s)"
    kubectl get pods -l app=github-runner
else
    print_warning "GitHub Runner non déployé"
fi

validate_part 7 "Pipeline GitHub Actions"
if [ -f ".github/workflows/docker-build.yaml" ]; then
    print_success "Pipeline CI/CD trouvé : .github/workflows/docker-build.yaml"
    echo "Contenu :"
    head -20 .github/workflows/docker-build.yaml
else
    print_error "Pipeline GitHub Actions non trouvé"
fi

validate_part 8 "Renovate Bot"
RENOVATE_NAMESPACE=$(kubectl get namespace renovate --no-headers 2>/dev/null | awk '{print $1}')
if [ "$RENOVATE_NAMESPACE" == "renovate" ]; then
    print_success "Namespace renovate trouvé"
    kubectl get cronjob -n renovate
else
    print_warning "Renovate Bot non déployé"
fi

validate_part 9 "ArgoCD GitOps"
ARGOCD_NAMESPACE=$(kubectl get namespace argocd --no-headers 2>/dev/null | awk '{print $1}')
if [ "$ARGOCD_NAMESPACE" == "argocd" ]; then
    print_success "Namespace argocd trouvé"
    kubectl get pods -n argocd
    kubectl get application -n argocd 2>/dev/null
else
    print_warning "ArgoCD non déployé"
fi

print_section "RÉSUMÉ FINAL"
echo -e "${MAGENTA}╔════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║       VALIDATION DU TP DEVOPS JOUR 4       ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════╝${NC}"
echo ""
echo "✅ Parties validées :"
echo "   • Partie 0 : Cluster multi-nodes"
echo "   • Partie 1 : Topology Spread Constraints"
echo "   • Partie 2 : Prometheus/Grafana"
echo "   • Partie 3 : Ingress + Load Testing"
echo "   • Partie 4 : Dashboard personnalisé"
echo ""
echo "📝 À compléter manuellement :"
echo "   • Partie 5 : Chaos Mesh (installation)"
echo "   • Partie 6 : GitHub Runner (token secret)"
echo "   • Partie 7 : Pipeline CI/CD (secrets Docker Hub)"
echo "   • Partie 8 : Renovate Bot (token GitHub)"
echo "   • Partie 9 : ArgoCD (installation + sync)"
echo ""
echo -e "${CYAN}Pour les accès Grafana :${NC}"
echo "   URL: http://localhost:3000"
echo "   User: admin"
echo "   Password: prom-operator"
echo ""
echo -e "${CYAN}Pour port-forwarding :${NC}"
echo "   kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
echo ""