#!/bin/bash

# ========================================
# SCRIPT DE VÉRIFICATION TP DEVOPS JOUR 4
# Teste rapidement tous les composants
# ========================================

echo "🔍 VÉRIFICATION RAPIDE TP DEVOPS JOUR 4"
echo "======================================="

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_ok() {
    echo -e "${GREEN}✅ $1${NC}"
}

check_fail() {
    echo -e "${RED}❌ $1${NC}"
}

check_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

# Vérification cluster
echo "🔧 Vérification cluster..."
if kubectl get nodes &>/dev/null; then
    NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
    if [ $NODE_COUNT -eq 2 ]; then
        check_ok "Cluster minikube 2 nœuds opérationnel"
    else
        check_warning "Cluster actif mais $NODE_COUNT nœud(s) au lieu de 2"
    fi
else
    check_fail "Cluster minikube non accessible"
    exit 1
fi

# Vérification application résiliente
echo "🛡️ Vérification application résiliente..."
RESILIENT_PODS=$(kubectl get pods -l app=resilient-app --no-headers 2>/dev/null | wc -l)
if [ $RESILIENT_PODS -eq 4 ]; then
    check_ok "Application résiliente: 4 pods déployés"
    
    # Vérification répartition
    NODE1_PODS=$(kubectl get pods -l app=resilient-app -o wide --no-headers | grep minikube | grep -v minikube-m02 | wc -l)
    NODE2_PODS=$(kubectl get pods -l app=resilient-app -o wide --no-headers | grep minikube-m02 | wc -l)
    
    if [ $NODE1_PODS -eq 2 ] && [ $NODE2_PODS -eq 2 ]; then
        check_ok "Répartition équitable: 2 pods par nœud"
    else
        check_warning "Répartition: $NODE1_PODS pods sur minikube, $NODE2_PODS sur minikube-m02"
    fi
else
    check_fail "Application résiliente: $RESILIENT_PODS pods au lieu de 4"
fi

# Vérification Prometheus/Grafana
echo "📊 Vérification stack monitoring..."
MONITORING_PODS=$(kubectl get pods -n monitoring --no-headers 2>/dev/null | grep Running | wc -l)
if [ $MONITORING_PODS -gt 5 ]; then
    check_ok "Stack Prometheus/Grafana: $MONITORING_PODS pods actifs"
    
    # Test port-forward Grafana
    kubectl port-forward -n monitoring svc/prometheus-grafana 3001:80 &>/dev/null &
    PF_PID=$!
    sleep 3
    
    if curl -s http://localhost:3001/api/health &>/dev/null; then
        check_ok "Grafana accessible sur port 3001"
    else
        check_warning "Grafana déployé mais pas accessible"
    fi
    
    kill $PF_PID 2>/dev/null
else
    check_fail "Stack monitoring: seulement $MONITORING_PODS pods actifs"
fi

# Vérification Ingress
echo "🌐 Vérification ingress..."
INGRESS_PODS=$(kubectl get pods -n ingress-nginx --no-headers 2>/dev/null | grep Running | wc -l)
if [ $INGRESS_PODS -gt 0 ]; then
    check_ok "Controller ingress: $INGRESS_PODS pod(s) actif(s)"
    
    INGRESS_COUNT=$(kubectl get ingress --no-headers 2>/dev/null | wc -l)
    if [ $INGRESS_COUNT -gt 0 ]; then
        check_ok "Ingress configuré: $INGRESS_COUNT règle(s)"
    else
        check_warning "Controller ingress actif mais aucune règle configurée"
    fi
else
    check_fail "Controller ingress non déployé"
fi

# Vérification application avec métriques
echo "📈 Vérification application métriques..."
METRICS_PODS=$(kubectl get pods -l app=guestbook-metrics --no-headers 2>/dev/null | wc -l)
if [ $METRICS_PODS -gt 0 ]; then
    check_ok "Application métriques: $METRICS_PODS pod(s) déployé(s)"
    
    # Test endpoint /info
    kubectl port-forward service/guestbook-metrics-service 8083:80 &>/dev/null &
    PF_PID=$!
    sleep 3
    
    if curl -s http://localhost:8083/info | grep "http_requests_total" &>/dev/null; then
        check_ok "Endpoint /info avec métriques Prometheus accessible"
    else
        check_warning "Application déployée mais endpoint /info non accessible"
    fi
    
    kill $PF_PID 2>/dev/null
else
    check_fail "Application avec métriques non déployée"
fi

# Vérification Chaos Mesh
echo "💥 Vérification Chaos Mesh..."
CHAOS_PODS=$(kubectl get pods -n chaos-mesh --no-headers 2>/dev/null | grep Running | wc -l)
if [ $CHAOS_PODS -gt 3 ]; then
    check_ok "Chaos Mesh: $CHAOS_PODS pods actifs"
    
    EXPERIMENTS=$(kubectl get podchaos --no-headers 2>/dev/null | wc -l)
    if [ $EXPERIMENTS -gt 0 ]; then
        check_ok "Expériences chaos: $EXPERIMENTS configurée(s)"
    else
        check_warning "Chaos Mesh déployé mais aucune expérience configurée"
    fi
else
    check_fail "Chaos Mesh: seulement $CHAOS_PODS pods actifs"
fi

# Vérification GitHub Runner
echo "🤖 Vérification GitHub Runner..."
RUNNER_PODS=$(kubectl get pods -l app=github-runner --no-headers 2>/dev/null | wc -l)
if [ $RUNNER_PODS -gt 0 ]; then
    check_ok "GitHub Runner: $RUNNER_PODS pod(s) déployé(s)"
else
    check_warning "GitHub Runner non déployé (nécessite token)"
fi

# Résumé final
echo ""
echo "📋 RÉSUMÉ DE L'ÉTAT DU TP:"
echo "=========================="

TOTAL_CHECKS=7
PASSED_CHECKS=0

# Recompte rapide
kubectl get nodes &>/dev/null && ((PASSED_CHECKS++))
[ $RESILIENT_PODS -eq 4 ] && ((PASSED_CHECKS++))
[ $MONITORING_PODS -gt 5 ] && ((PASSED_CHECKS++))
[ $INGRESS_PODS -gt 0 ] && ((PASSED_CHECKS++))
[ $METRICS_PODS -gt 0 ] && ((PASSED_CHECKS++))
[ $CHAOS_PODS -gt 3 ] && ((PASSED_CHECKS++))
[ $RUNNER_PODS -gt 0 ] && ((PASSED_CHECKS++))

echo "✅ Composants validés: $PASSED_CHECKS/$TOTAL_CHECKS"

if [ $PASSED_CHECKS -eq $TOTAL_CHECKS ]; then
    echo -e "${GREEN}🎉 TP COMPLET - TOUS LES COMPOSANTS FONCTIONNELS!${NC}"
elif [ $PASSED_CHECKS -gt 4 ]; then
    echo -e "${YELLOW}🔧 TP MAJORITAIREMENT FONCTIONNEL - Quelques ajustements nécessaires${NC}"
else
    echo -e "${RED}🚨 TP PARTIELLEMENT DÉPLOYÉ - Redéploiement recommandé${NC}"
fi

echo ""
echo "🚀 Pour relancer le déploiement complet:"
echo "   ./deploy-full-tp.sh"
echo ""
echo "📚 Pour plus de détails:"
echo "   cat apprentissage.md"
echo "   cat how-to-start.md"