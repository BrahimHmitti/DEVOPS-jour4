#!/bin/bash

echo "🚀 COMMANDES RAPIDES - TP DEVOPS JOUR 4"
echo "========================================"
echo ""
echo "📋 CHOISISSEZ UNE ACTION :"
echo ""
echo "CLUSTER & BASE"
echo "  1) Démarrer cluster (2 nœuds)"
echo "  2) Afficher état cluster"
echo "  3) Arrêter cluster"
echo "  4) Supprimer cluster"
echo ""
echo "DÉPLOIEMENT"
echo "  5) Déployer Partie 1 (Topology Spread)"
echo "  6) Déployer Partie 2 (Prometheus/Grafana)"
echo "  7) Déployer Partie 3 (Ingress)"
echo "  8) Déployer Partie 4 (Métriques custom)"
echo "  9) Déployer Partie 5 (Chaos Mesh)"
echo " 10) Déployer Partie 6 (GitHub Runner)"
echo " 11) Déployer Partie 9 (ArgoCD)"
echo ""
echo "VALIDATION & TESTS"
echo " 12) Valider toutes les parties"
echo " 13) Tester résilience (drain node)"
echo " 14) Load test (100 requêtes)"
echo " 15) Test métriques /info"
echo ""
echo "ACCÈS DASHBOARDS"
echo " 16) Ouvrir Grafana (localhost:3000)"
echo " 17) Ouvrir Chaos Dashboard (localhost:2333)"
echo " 18) Ouvrir ArgoCD (localhost:8080)"
echo " 19) Ouvrir métriques (localhost:8082)"
echo ""
echo " 20) Tout déployer (automatique)"
echo ""
echo "  0) Quitter"
echo ""
read -p "Votre choix : " choice

case $choice in
    1)
        echo "🚀 Démarrage du cluster minikube..."
        minikube start --nodes 2 --driver=docker --cpus=2 --memory=3500
        kubectl get nodes -o wide
        ;;
    2)
        echo "📊 État du cluster :"
        echo ""
        echo "=== NODES ==="
        kubectl get nodes -o wide
        echo ""
        echo "=== PODS PAR NAMESPACE ==="
        kubectl get pods --all-namespaces
        echo ""
        echo "=== SERVICES ==="
        kubectl get svc --all-namespaces
        echo ""
        echo "=== INGRESS ==="
        kubectl get ingress
        ;;
    3)
        echo "⏸️  Arrêt du cluster..."
        minikube stop
        ;;
    4)
        read -p "⚠️  Supprimer TOUT le cluster ? (y/N) " confirm
        if [ "$confirm" = "y" ]; then
            minikube delete --all
            echo "✅ Cluster supprimé"
        fi
        ;;
    5)
        echo "🔄 Déploiement Topology Spread Constraints..."
        kubectl apply -f resilient-app-deployment.yaml
        kubectl apply -f resilient-app-service.yaml
        kubectl wait --for=condition=Ready pods -l app=resilient-app --timeout=120s
        kubectl get pods -l app=resilient-app -o wide
        ;;
    6)
        echo "📊 Installation Prometheus + Grafana..."
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
        helm repo update
        kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
        helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
          --namespace monitoring \
          --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
          --wait --timeout=10m
        echo ""
        echo "✅ Installation terminée !"
        echo "🌐 Accès Grafana : kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
        echo "   URL : http://localhost:3000"
        echo "   User : admin"
        echo "   Pass : prom-operator"
        ;;
    7)
        echo "🌐 Déploiement Ingress..."
        minikube addons enable ingress
        kubectl apply -f guestbook-deployment.yaml
        kubectl apply -f guestbook-ingress.yaml
        kubectl wait --for=condition=Ready pods -l app=guestbook --timeout=120s
        echo ""
        echo "✅ Ingress déployé !"
        echo "🚇 Lancer le tunnel : sudo minikube tunnel"
        echo "🧪 Tester : curl -H 'Host: guestbook.fbi.com' http://\$(minikube ip)"
        ;;
    8)
        echo "📈 Déploiement application avec métriques..."
        kubectl apply -f guestbook-with-metrics.yaml
        kubectl wait --for=condition=Ready pods -l app=guestbook-metrics --timeout=120s
        echo ""
        echo "✅ Métriques déployées !"
        echo "🔗 Port-forward : kubectl port-forward svc/guestbook-metrics-service 8082:80"
        echo "🧪 Tester : curl http://localhost:8082/info"
        ;;
    9)
        echo "💥 Installation Chaos Mesh..."
        helm repo add chaos-mesh https://charts.chaos-mesh.org
        helm repo update
        kubectl create namespace chaos-mesh --dry-run=client -o yaml | kubectl apply -f -
        helm upgrade --install chaos-mesh chaos-mesh/chaos-mesh \
          --namespace chaos-mesh \
          --set chaosDaemon.runtime=containerd \
          --set chaosDaemon.socketPath=/run/containerd/containerd.sock \
          --set dashboard.create=true \
          --wait --timeout=10m
        echo ""
        echo "Applying pod-kill experiment..."
        kubectl apply -f chaos-pod-kill-experiment.yaml
        echo ""
        echo "✅ Chaos Mesh installé !"
        echo "🎯 Dashboard : kubectl port-forward -n chaos-mesh svc/chaos-dashboard 2333:2333"
        echo "   URL : http://localhost:2333"
        ;;
    10)
        echo "⚠️  Configuration requise :"
        echo "1. Obtenir un token GitHub : Settings > Developer settings > Personal access tokens"
        echo "2. Éditer github-runner-deployment.yaml et remplacer REMPLACER_PAR_VOTRE_TOKEN_GITHUB"
        echo ""
        read -p "Token configuré ? (y/N) " confirm
        if [ "$confirm" = "y" ]; then
            kubectl apply -f github-runner-deployment.yaml
            kubectl get pods -l app=github-runner
            echo "✅ Runner déployé ! Vérifier dans GitHub Settings > Actions > Runners"
        fi
        ;;
    11)
        echo "🎯 Installation ArgoCD..."
        kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        echo ""
        echo "Attente des pods ArgoCD (cela peut prendre 5-10 min)..."
        kubectl wait --for=condition=Ready pods --all -n argocd --timeout=600s
        echo ""
        PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
        echo "✅ ArgoCD installé !"
        echo "🔑 Mot de passe admin : $PASSWORD"
        echo "🌐 Port-forward : kubectl port-forward -n argocd svc/argocd-server 8080:443"
        echo "   URL : https://localhost:8080"
        echo ""
        echo "📁 N'oubliez pas de :"
        echo "   1. Créer le dossier manifests/ dans le repo"
        echo "   2. Y copier guestbook-deployment.yaml et guestbook-ingress.yaml"
        echo "   3. Push sur GitHub"
        echo "   4. kubectl apply -f argocd-application.yaml"
        ;;
    12)
        echo "✅ Validation de toutes les parties..."
        ./validate-all-parts.sh
        ;;
    13)
        echo "🧪 Test de résilience..."
        echo "Avant drain :"
        kubectl get pods -l app=resilient-app -o wide
        echo ""
        read -p "Drainer minikube-m02 ? (y/N) " confirm
        if [ "$confirm" = "y" ]; then
            kubectl drain minikube-m02 --ignore-daemonsets
            echo ""
            echo "Après drain :"
            kubectl get pods -l app=resilient-app -o wide
            echo ""
            read -p "Restaurer le nœud ? (y/N) " confirm2
            if [ "$confirm2" = "y" ]; then
                kubectl uncordon minikube-m02
                echo "✅ Nœud restauré"
            fi
        fi
        ;;
    14)
        echo "🚀 Load test avec 100 requêtes..."
        INGRESS_IP=$(minikube ip)
        echo "Target : $INGRESS_IP (Host: guestbook.fbi.com)"
        echo ""
        for i in {1..100}; do
            curl -s -H "Host: guestbook.fbi.com" http://$INGRESS_IP > /dev/null && echo -n "."
        done
        echo ""
        echo "✅ 100 requêtes terminées"
        ;;
    15)
        echo "📈 Test endpoint métriques..."
        echo "Port-forwarding du service..."
        kubectl port-forward svc/guestbook-metrics-service 8082:80 > /dev/null 2>&1 &
        PF_PID=$!
        sleep 3
        echo ""
        curl http://localhost:8082/info
        echo ""
        kill $PF_PID 2>/dev/null
        ;;
    16)
        echo "📊 Ouverture Grafana..."
        kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80 &
        echo ""
        echo "✅ Grafana disponible sur : http://localhost:3000"
        echo "   User : admin"
        echo "   Pass : prom-operator"
        echo ""
        echo "Appuyez sur Entrée pour arrêter le port-forward..."
        read
        pkill -f "port-forward.*grafana"
        ;;
    17)
        echo "💥 Ouverture Chaos Dashboard..."
        kubectl port-forward -n chaos-mesh svc/chaos-dashboard 2333:2333 &
        echo ""
        echo "✅ Chaos Dashboard disponible sur : http://localhost:2333"
        echo ""
        echo "Appuyez sur Entrée pour arrêter le port-forward..."
        read
        pkill -f "port-forward.*chaos"
        ;;
    18)
        PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)
        echo "🎯 Ouverture ArgoCD..."
        kubectl port-forward -n argocd svc/argocd-server 8080:443 &
        echo ""
        echo "✅ ArgoCD disponible sur : https://localhost:8080"
        echo "   User : admin"
        echo "   Pass : $PASSWORD"
        echo ""
        echo "Appuyez sur Entrée pour arrêter le port-forward..."
        read
        pkill -f "port-forward.*argocd"
        ;;
    19)
        echo "📈 Ouverture métriques custom..."
        kubectl port-forward svc/guestbook-metrics-service 8082:80 &
        echo ""
        echo "✅ Métriques disponibles sur : http://localhost:8082/info"
        echo ""
        echo "Appuyez sur Entrée pour arrêter le port-forward..."
        read
        pkill -f "port-forward.*8082"
        ;;
    20)
        echo "🚀 DÉPLOIEMENT COMPLET AUTOMATIQUE"
        echo "=================================="
        echo ""
        read -p "⚠️  Cela va tout déployer (parties 0-4). Continuer ? (y/N) " confirm
        if [ "$confirm" = "y" ]; then
            ./deploy-full-tp.sh
        fi
        ;;
    0)
        echo "👋 Au revoir !"
        exit 0
        ;;
    *)
        echo "❌ Choix invalide"
        ;;
esac

echo ""
echo "✅ Terminé !"