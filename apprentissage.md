# 📚 Apprentissages DevOps - Jour 4

## 🎯 Objectif
Synthèse des concepts clés et leçons apprises sur Kubernetes et la résilience applicative.

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

### 10. GitHub Actions Runner Self-Hosted

**Problématique :** Exécuter les CI/CD dans mon infrastructure (contrôle + sécurité).

**Solution implémentée :** Runner GitHub déployé comme pod dans Kubernetes.

**Configuration réalisée :**
- Token GitHub stocké comme secret Kubernetes
- Image officielle du runner GitHub Actions
- Accès Docker pour build des images

**Bénéfices :**
- **Contrôle total** : Runner dans mon cluster
- **Sécurité** : Pas d'exposition externe
- **Intégration** : Accès direct aux ressources Kubernetes

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
