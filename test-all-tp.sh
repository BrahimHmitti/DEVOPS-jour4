#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

PASSED=0
FAILED=0

print_header() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  🚀 TEST COMPLET - TP DEVOPS JOUR 4 (13 PARTIES)              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}\n"
}

print_section() {
    echo -e "\n${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}  PARTIE $1${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED++))
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    ((FAILED++))
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

test_command() {
    local description=$1
    local command=$2
    local expected=$3
    
    print_info "Test: $description"
    if eval "$command" | grep -q "$expected"; then
        print_success "$description"
        return 0
    else
        print_error "$description"
        return 1
    fi
}

print_header

print_section "0 : CLUSTER MINIKUBE MULTI-NODES"
print_info "Vérification du cluster Kubernetes..."

if kubectl cluster-info &>/dev/null; then
    print_success "Cluster Kubernetes accessible"
    
    NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    if [ "$NODE_COUNT" -ge 2 ]; then
        print_success "Cluster multi-nodes détecté : $NODE_COUNT nœuds"
        kubectl get nodes -o wide
    else
        print_error "Cluster multi-nodes : seulement $NODE_COUNT nœud(s)"
    fi
else
    print_error "Cluster Kubernetes non accessible"
    print_warning "Lancer: minikube start --nodes 2 --driver=docker"
    exit 1
fi

print_section "1 : TOPOLOGY SPREAD CONSTRAINTS"
print_info "Vérification de l'application résiliente..."

if kubectl get deployment resilient-app &>/dev/null; then
    print_success "Deployment resilient-app existe"
    
    REPLICAS=$(kubectl get deployment resilient-app -o jsonpath='{.spec.replicas}')
    READY=$(kubectl get deployment resilient-app -o jsonpath='{.status.readyReplicas}')
    
    if [ "$READY" = "$REPLICAS" ]; then
        print_success "Tous les replicas sont prêts ($READY/$REPLICAS)"
    else
        print_warning "Replicas: $READY/$REPLICAS prêts"
    fi
    
    if kubectl get deployment resilient-app -o yaml | grep -q "topologySpreadConstraints"; then
        print_success "Topology Spread Constraints configuré"
        
        echo -e "\n${BLUE}Répartition des pods:${NC}"
        kubectl get pods -l app=resilient-app -o wide --no-headers | awk '{print $7}' | sort | uniq -c
    else
        print_error "Topology Spread Constraints absent"
    fi
    
    if kubectl get svc resilient-app-service &>/dev/null; then
        print_success "Service resilient-app-service existe"
    else
        print_warning "Service resilient-app-service absent"
    fi
else
    print_error "Deployment resilient-app non déployé"
    print_info "Commande: kubectl apply -f resilient-app-deployment.yaml"
fi

print_section "2 : PROMETHEUS ET GRAFANA"
print_info "Vérification de la stack de monitoring..."

if kubectl get namespace monitoring &>/dev/null; then
    print_success "Namespace monitoring existe"
    
    PROM_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --no-headers 2>/dev/null | wc -l)
    GRAFANA_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --no-headers 2>/dev/null | wc -l)
    
    if [ "$PROM_PODS" -gt 0 ]; then
        print_success "Prometheus déployé ($PROM_PODS pods)"
    else
        print_error "Prometheus non déployé"
    fi
    
    if [ "$GRAFANA_PODS" -gt 0 ]; then
        print_success "Grafana déployé ($GRAFANA_PODS pods)"
        
        if kubectl get secret -n monitoring kube-prometheus-stack-grafana &>/dev/null; then
            PASSWORD=$(kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" 2>/dev/null | base64 -d)
            print_info "Mot de passe Grafana: $PASSWORD"
        fi
    else
        print_error "Grafana non déployé"
    fi
    
    ALERTMANAGER_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager --no-headers 2>/dev/null | wc -l)
    if [ "$ALERTMANAGER_PODS" -gt 0 ]; then
        print_success "AlertManager déployé"
    fi
else
    print_error "Namespace monitoring absent"
    print_info "Commande: helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring --create-namespace"
fi

print_section "3 : INGRESS NGINX ET TESTS DE CHARGE"
print_info "Vérification de l'Ingress..."

if kubectl get ingress guestbook-ingress &>/dev/null; then
    print_success "Ingress guestbook-ingress existe"
    
    HOST=$(kubectl get ingress guestbook-ingress -o jsonpath='{.spec.rules[0].host}')
    print_info "Host configuré: $HOST"
    
    INGRESS_CLASS=$(kubectl get ingressclass -o name 2>/dev/null | wc -l)
    if [ "$INGRESS_CLASS" -gt 0 ]; then
        print_success "IngressClass configuré"
    fi
else
    print_error "Ingress guestbook-ingress absent"
fi

if kubectl get deployment guestbook &>/dev/null; then
    print_success "Deployment guestbook existe"
    
    READY=$(kubectl get deployment guestbook -o jsonpath='{.status.readyReplicas}')
    print_info "Replicas prêts: $READY"
else
    print_error "Deployment guestbook absent"
fi

if [ -f "load-test.js" ]; then
    print_success "Script load-test.js présent"
else
    print_warning "Script load-test.js absent"
fi

print_section "4 : DASHBOARD GRAFANA PERSONNALISÉ"
print_info "Vérification des métriques custom..."

if kubectl get deployment guestbook-with-metrics &>/dev/null; then
    print_success "Deployment guestbook-with-metrics existe"
    
    if kubectl get svc guestbook-metrics-service &>/dev/null; then
        print_success "Service guestbook-metrics-service existe"
        
        POD_NAME=$(kubectl get pods -l app=guestbook-metrics -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        if [ -n "$POD_NAME" ]; then
            print_info "Test de l'endpoint /info..."
            if kubectl exec $POD_NAME -- curl -s http://localhost/info | grep -q "http_requests_total"; then
                print_success "Endpoint /info retourne des métriques Prometheus"
            else
                print_warning "Endpoint /info ne retourne pas de métriques valides"
            fi
        fi
    else
        print_error "Service guestbook-metrics-service absent"
    fi
else
    print_error "Deployment guestbook-with-metrics absent"
fi

print_section "5 : CHAOS ENGINEERING - CHAOS MESH"
print_info "Vérification de Chaos Mesh..."

if kubectl get namespace chaos-mesh &>/dev/null; then
    print_success "Namespace chaos-mesh existe"
    
    CHAOS_PODS=$(kubectl get pods -n chaos-mesh --no-headers 2>/dev/null | wc -l)
    if [ "$CHAOS_PODS" -gt 0 ]; then
        print_success "Chaos Mesh déployé ($CHAOS_PODS pods)"
        
        if kubectl get crd podchaos.chaos-mesh.org &>/dev/null; then
            print_success "CRD PodChaos installé"
            
            EXPERIMENTS=$(kubectl get podchaos --all-namespaces --no-headers 2>/dev/null | wc -l)
            if [ "$EXPERIMENTS" -gt 0 ]; then
                print_success "Expériences Chaos actives: $EXPERIMENTS"
                kubectl get podchaos --all-namespaces
            else
                print_warning "Aucune expérience Chaos active"
            fi
        else
            print_error "CRD PodChaos non installé"
        fi
        
        if kubectl get svc -n chaos-mesh chaos-dashboard &>/dev/null; then
            print_success "Dashboard Chaos Mesh disponible"
        fi
    else
        print_error "Chaos Mesh non déployé"
    fi
else
    print_error "Namespace chaos-mesh absent"
    print_info "Commande: helm install chaos-mesh chaos-mesh/chaos-mesh -n chaos-mesh --create-namespace"
fi

print_section "6 : GITHUB RUNNER SELF-HOSTED"
print_info "Vérification du GitHub Runner..."

if kubectl get deployment github-runner &>/dev/null; then
    print_success "Deployment github-runner existe"
    
    READY=$(kubectl get deployment github-runner -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
    if [ "$READY" -gt 0 ]; then
        print_success "GitHub Runner actif ($READY replicas)"
    else
        print_warning "GitHub Runner non prêt"
    fi
    
    if kubectl get secret github-runner-token &>/dev/null; then
        print_success "Secret github-runner-token configuré"
    else
        print_error "Secret github-runner-token absent"
    fi
else
    print_error "Deployment github-runner absent"
    print_info "Fichier: github-runner-deployment.yaml"
fi

print_section "7 : PIPELINE CI/CD GITHUB ACTIONS"
print_info "Vérification du pipeline CI/CD..."

if [ -f ".github/workflows/docker-build.yaml" ]; then
    print_success "Workflow GitHub Actions existe"
    
    if grep -q "runs-on: self-hosted" .github/workflows/docker-build.yaml; then
        print_success "Pipeline configuré pour runner self-hosted"
    fi
    
    if grep -q "trivy" .github/workflows/docker-build.yaml; then
        print_success "Scan de sécurité Trivy configuré"
    fi
else
    print_error "Workflow .github/workflows/docker-build.yaml absent"
fi

if [ -f "Dockerfile" ]; then
    print_success "Dockerfile présent"
else
    print_error "Dockerfile absent"
fi

print_section "8 : RENOVATE BOT"
print_info "Vérification de Renovate Bot..."

if kubectl get namespace renovate &>/dev/null; then
    print_success "Namespace renovate existe"
    
    if kubectl get cronjob -n renovate renovate &>/dev/null; then
        print_success "CronJob renovate configuré"
        
        SCHEDULE=$(kubectl get cronjob -n renovate renovate -o jsonpath='{.spec.schedule}')
        print_info "Planification: $SCHEDULE"
        
        if kubectl get secret -n renovate renovate-github-token &>/dev/null; then
            print_success "Secret renovate-github-token configuré"
        else
            print_error "Secret renovate-github-token absent"
        fi
    else
        print_error "CronJob renovate absent"
    fi
else
    print_error "Namespace renovate absent"
    print_info "Commande: kubectl apply -f renovate-deployment.yaml"
fi

print_section "9 : ARGOCD GITOPS"
print_info "Vérification d'ArgoCD..."

if kubectl get namespace argocd &>/dev/null; then
    print_success "Namespace argocd existe"
    
    ARGOCD_PODS=$(kubectl get pods -n argocd --no-headers 2>/dev/null | wc -l)
    if [ "$ARGOCD_PODS" -gt 0 ]; then
        print_success "ArgoCD déployé ($ARGOCD_PODS pods)"
        
        if kubectl get secret -n argocd argocd-initial-admin-secret &>/dev/null; then
            PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)
            print_info "Mot de passe ArgoCD: $PASSWORD"
        fi
        
        APPS=$(kubectl get application -n argocd --no-headers 2>/dev/null | wc -l)
        if [ "$APPS" -gt 0 ]; then
            print_success "Applications ArgoCD configurées: $APPS"
            kubectl get application -n argocd
        else
            print_warning "Aucune application ArgoCD déployée"
        fi
    else
        print_error "ArgoCD non déployé"
    fi
else
    print_error "Namespace argocd absent"
    print_info "Commande: kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
fi

print_section "10 : BURRITO (Infrastructure as Code)"
print_info "Vérification de Burrito..."

if kubectl get namespace burrito &>/dev/null; then
    print_success "Namespace burrito existe"
    
    if kubectl get deployment -n burrito burrito-controller &>/dev/null; then
        print_success "Burrito controller déployé"
        
        if kubectl get crd terraformlayers.config.terraform.io &>/dev/null; then
            print_success "CRD TerraformLayer installé"
            
            LAYERS=$(kubectl get terraformlayers -n burrito --no-headers 2>/dev/null | wc -l)
            if [ "$LAYERS" -gt 0 ]; then
                print_success "TerraformLayers configurés: $LAYERS"
            else
                print_warning "Aucun TerraformLayer déployé"
            fi
        else
            print_warning "CRD TerraformLayer absent"
        fi
    else
        print_error "Burrito controller non déployé"
    fi
else
    print_warning "Namespace burrito absent (Partie optionnelle)"
fi

print_section "11 : SIGNATURE D'IMAGES AVEC COSIGN"
print_info "Vérification de Cosign..."

if command -v cosign &>/dev/null; then
    print_success "Cosign installé"
    cosign version
    
    if [ -f "cosign.key" ] && [ -f "cosign.pub" ]; then
        print_success "Paire de clés Cosign présente"
    else
        print_warning "Paire de clés Cosign absente"
        print_info "Commande: cosign generate-key-pair"
    fi
else
    print_warning "Cosign non installé (Partie optionnelle)"
    print_info "Installation: https://docs.sigstore.dev/cosign/installation/"
fi

print_section "12 : VÉRIFICATION DES SIGNATURES"
print_info "Vérification de la policy de signatures..."

if kubectl get crd clusterpolicies.kyverno.io &>/dev/null; then
    print_success "Kyverno installé"
    
    POLICIES=$(kubectl get clusterpolicy --no-headers 2>/dev/null | wc -l)
    if [ "$POLICIES" -gt 0 ]; then
        print_success "Policies configurées: $POLICIES"
    else
        print_warning "Aucune policy configurée"
    fi
else
    print_warning "Kyverno non installé (Partie optionnelle)"
fi

print_section "13 : DOCUMENTATION FINALE"
print_info "Vérification de la documentation..."

if [ -f "apprentissage.md" ]; then
    print_success "apprentissage.md présent"
    
    LINES=$(wc -l < apprentissage.md)
    print_info "Lignes de documentation: $LINES"
else
    print_error "apprentissage.md absent"
fi

if [ -f "README.md" ]; then
    print_success "README.md présent"
fi

if [ -f "STATUS.md" ]; then
    print_success "STATUS.md présent"
fi

if [ -f "RECAP.md" ]; then
    print_success "RECAP.md présent"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  RÉSUMÉ DES TESTS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}✅ Tests réussis: $PASSED${NC}"
echo -e "${RED}❌ Tests échoués: $FAILED${NC}"
echo ""

TOTAL=$((PASSED + FAILED))
if [ $TOTAL -gt 0 ]; then
    PERCENTAGE=$(( PASSED * 100 / TOTAL ))
    echo -e "${BLUE}📊 Taux de réussite: $PERCENTAGE%${NC}"
fi

echo ""
echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║  📋 ACCÈS AUX SERVICES${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}🌐 Grafana:${NC}      kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
echo -e "${BLUE}🌐 Prometheus:${NC}   kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090"
echo -e "${BLUE}💥 Chaos Mesh:${NC}   kubectl port-forward -n chaos-mesh svc/chaos-dashboard 2333:2333"
echo -e "${BLUE}🎯 ArgoCD:${NC}       kubectl port-forward -n argocd svc/argocd-server 8080:443"
echo -e "${BLUE}📈 Métriques:${NC}    kubectl port-forward svc/guestbook-metrics-service 8082:80"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  🎉 FÉLICITATIONS ! TOUS LES TESTS SONT PASSÉS !              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  ⚠️  CERTAINS TESTS ONT ÉCHOUÉ - VÉRIFIER LA CONFIGURATION    ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════╝${NC}"
    exit 1
fi