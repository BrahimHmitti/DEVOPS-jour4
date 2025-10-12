# Dojo DevOps Avancé - Monitoring, CI/CD et Chaos Engineering

Votre objectif est de mettre en place un écosystème DevOps complet avec monitoring, CI/CD et tests de résilience, et d'apprendre un maximum pendant cette session.

## Consignes générales

- **Gardez une trace de vos actions** : créez une documentation en markdown dans ce dépôt, où vous notez les commandes utilisées, les erreurs rencontrées et comment vous les avez résolues.
- **Section "Apprentissages" obligatoire** : pour chaque difficulté, notez :
  - Problème rencontré (et pourquoi il est survenu)
  - Solution apportée (et pourquoi elle fonctionne)
  - Nouveau savoir (et pourquoi il est utile)

---

## 0. Préparer votre environnement

### Pourquoi

Pour ce jour 4, nous allons travailler avec des outils avancés de monitoring, CI/CD et chaos engineering. Il faut un cluster Kubernetes robuste avec suffisamment de ressources.

### Comment

Créez un cluster minikube avec 2 nœuds et plus de ressources :
- 3 CPUs minimum par nœud
- 3Go RAM minimum par nœud
- Activez les addons nécessaires

### Vérifications

- [ ] Vous avez un cluster minikube avec 2 nœuds fonctionnels
- [ ] Chaque nœud a les ressources suffisantes
- [ ] Kubectl peut accéder au cluster

## 1. Rendre l'application résiliente (Topology Spread Constraints)

### Pourquoi

Pour éviter qu'une panne d'un nœud affecte toute votre application, il faut distribuer les pods sur différents nœuds. Les Topology Spread Constraints permettent de contrôler finement cette répartition.

### Comment

1. **Vérifiez le nombre de nœuds disponibles**
2. **Ajoutez des [Topology Spread Constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/) à votre deployment**
3. **Déployez et observez la répartition**
4. **Testez la résilience** en simulant une panne de nœud
5. **Remettez le nœud en service**

### Indices

- `maxSkew: 1` signifie qu'au maximum 1 pod de différence entre nœuds
- `DoNotSchedule` empêche le scheduling si la contrainte n'est pas respectée
- Utilisez `ScheduleAnyway` pour une contrainte souple

### Vérifications

- [ ] Mes pods sont répartis équitablement sur les nœuds
- [ ] En cas de panne d'un nœud, l'application reste accessible
- [ ] Les nouveaux pods respectent les contraintes de topologie

## 2. Déployer la stack Prometheus avec les dashboards Kubernetes par défaut

### Pourquoi

[Prometheus](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) est l'outil de monitoring de référence dans l'écosystème Kubernetes. Il permet de collecter, stocker et analyser les métriques de votre infrastructure et applications.

### Comment

1. **Ajoutez le repository Helm de Prometheus Community**
2. **Déployez la stack kube-prometheus-stack** qui inclut Prometheus, Grafana, et AlertManager
3. **Configurez l'accès aux interfaces web**
4. **Explorez les dashboards par défaut** pour Kubernetes

### Indices

- La stack kube-prometheus-stack déploie tout l'écosystème de monitoring
- Grafana est accessible avec des credentials par défaut
- Les dashboards Kubernetes sont pré-configurés

### Vérifications

- [ ] Prometheus collecte les métriques du cluster
- [ ] Grafana affiche les dashboards Kubernetes
- [ ] AlertManager est configuré et fonctionnel

## 3. Relancer les tests de charge k6 et observer les métriques

### Pourquoi

Les tests de charge permettent de valider la performance de votre application et d'observer le comportement des métriques sous stress. C'est essentiel pour dimensionner correctement votre infrastructure. Nous utiliserons [k6](https://github.com/grafana/k6) pour générer la charge.

### Comment

> :info: Lorsque vous ouvrez un port-forward, même sur un service, le tunnel est fait sur le pod.
> Donc ceci interfère dans la manière dont nous executons les tests de charge k6. puisque ce sera toujours le même pod qui sera sollicité.
> Pour palier à cela, nous pouvons utiliser un Ingress avec son ingress controller pour répartir la charge.

Prerequis : un Ingress controller (comme NGINX) doit être déployé dans le cluster.

1. **Installer l'addon ingress sur minikube**
2. **Déployer un Ingress** pour le service guestbook (avec un fqdn en .fbi.com)
3. **Lancer `minikube tunnel`** pour exposer le LoadBalancer
4. **Tester localement avec curl** pour vérifier l'accès via le fqdn
5. **Mettre à jour les tests k6** pour utiliser le fqdn du Ingress

Ensuite :

1. **Relancez vos tests k6** développés dans les sessions précédentes
2. **Observez les métriques** dans Grafana pendant les tests
3. **Analysez l'impact** sur les ressources du cluster
4. **Corréllez** les métriques applicatives avec l'infrastructure

### Indices

- Utilisez les dashboards Kubernetes pour voir l'impact sur les nœuds
- Observez les métriques de CPU, mémoire et réseau
- Le HPA devrait réagir aux tests de charge

### Vérifications

- [ ] Les tests k6 génèrent une charge significative
- [ ] Les métriques sont visibles dans Grafana
- [ ] Le HPA réagit correctement à la charge

## 4. Créer un dashboard personnalisé pour monitorer le guestbook sur /info

### Pourquoi

Les dashboards métiers permettent de suivre les métriques spécifiques à votre application. L'endpoint /info du guestbook expose des métriques custom qu'il faut visualiser.

### Comment

1. **Explorez l'endpoint /info** du guestbook pour comprendre les métriques exposées
2. **Créez un nouveau dashboard** dans Grafana
3. **Ajoutez des panels** pour visualiser les métriques applicatives
4. **Configurez des alertes** sur les métriques critiques

### Indices

- L'endpoint /info expose des métriques au format Prometheus
- Utilisez les requêtes PromQL pour extraire les données
- Créez des graphiques temporels et des jauges
- Il peut être intéressant de port-forward Prometheus pour regarder ce qu'il scrappe

### Vérifications

- [ ] Le dashboard affiche les métriques custom du guestbook
- [ ] Les visualisations sont pertinentes et lisibles
- [ ] Des alertes sont configurées sur les métriques importantes

## 5. Déployer Chaos Mesh et lancer une expérience pod-kill sur le guestbook

### Pourquoi

Le chaos engineering permet de tester la résilience de votre système en simulant des pannes contrôlées. [Chaos Mesh](https://github.com/chaos-mesh/chaos-mesh) est l'outil de référence pour Kubernetes.

### Comment

1. **Installez Chaos Mesh** via son chart Helm
2. **Créez une expérience pod-kill** ciblant les pods guestbook
3. **Observez l'impact** dans les métriques et dashboards
4. **Analysez la récupération** automatique du système

### Indices

- Chaos Mesh utilise des CRDs pour définir les expériences
- Commencez par des expériences simples (pod-kill)
- Observez les métriques pendant l'expérience

### Vérifications

- [ ] Chaos Mesh est déployé et accessible
- [ ] L'expérience pod-kill fonctionne
- [ ] L'application récupère automatiquement
- [ ] L'impact est visible dans les métriques

## 6. Déployer un runner GitHub self-hosted dans le cluster minikube

### Pourquoi

Les runners self-hosted permettent d'exécuter vos workflows GitHub Actions directement dans votre infrastructure, offrant plus de contrôle et de sécurité.

### Comment

1. **Créez un token** pour le runner dans les paramètres de votre repository GitHub
2. **Déployez le runner** en tant que pod dans Kubernetes
3. **Configurez l'enregistrement** automatique auprès de GitHub
4. **Testez l'exécution** d'un workflow simple

### Indices

- Utilisez l'image officielle du runner GitHub Actions
- Le token doit être stocké comme secret Kubernetes
- Le runner doit avoir accès à Docker pour build les images

### Vérifications

- [ ] Le runner apparaît dans les paramètres GitHub
- [ ] Il peut exécuter des workflows
- [ ] Il a accès aux ressources nécessaires

## 7. Écrire une GitHub Action pour build, tag et push l'image guestbook vers Docker Hub

### Pourquoi

L'automatisation du build et du déploiement d'images est essentielle pour un workflow CI/CD efficace. GitHub Actions permet d'automatiser ces tâches.

### Comment

1. **Créez un workflow GitHub Actions** qui se déclenche sur push
2. **Configurez l'authentification** Docker Hub (via des secrets GitHub dans les CICD variables)
3. **Implémentez le build** de l'image avec tag basé sur le SHA du commit
4. **Poussez l'image** vers Docker Hub
5. **Testez le workflow** avec un commit

### Indices

- Utilisez les 'Actions' officielles Docker pour build et push
- Le tag doit inclure le SHA du commit pour l'unicité
- Stockez les credentials Docker Hub comme secrets GitHub

### Vérifications

- [ ] Le workflow se déclenche automatiquement sur push
- [ ] L'image est construite avec le bon tag
- [ ] L'image est poussée vers Docker Hub
- [ ] Le runner self-hosted exécute le workflow

## 8. Déployer Renovate bot avec credentials pour ouvrir des PR sur le repo

### Pourquoi

[Renovate](https://github.com/renovatebot/renovate) automatise la mise à jour des dépendances dans vos projets, garantissant la sécurité et la maintenance. Il est essentiel pour maintenir un projet à jour.

### Comment

1. **Déployez Renovate** comme une application dans Kubernetes
2. **Configurez les credentials GitHub** pour permettre la création de PR
3. **Créez la configuration Renovate** pour votre repository
4. **Testez l'ouverture automatique** de PR de mise à jour

### Indices

- Renovate a besoin de permissions pour lire et écrire sur le repository
- La configuration peut être dans renovate.json ou .github/renovate.json
- Commencez avec une configuration simple

### Vérifications

- [ ] Renovate est déployé et fonctionne
- [ ] Il peut accéder au repository GitHub
- [ ] Des PR de mise à jour sont créées automatiquement

## 9. Déployer ArgoCD via un chart Helm et écrire une application pour déployer guestbook depuis le repo

### Pourquoi

[ArgoCD](https://github.com/argoproj/argo-cd) implémente le pattern GitOps pour Kubernetes, permettant de gérer les déploiements de manière déclarative depuis Git. C'est l'outil de référence pour le CD.

### Comment

1. **Déployez ArgoCD** via son chart Helm officiel
2. **Configurez l'accès** à l'interface web
3. **Créez une Application ArgoCD** pointant vers votre repository
4. **Configurez la synchronisation automatique** des déploiements
5. **Testez un déploiement** via GitOps

### Indices

- ArgoCD surveille les changements dans Git
- ArgoCD Stocke son mot de passe initial dans un secret Kubernetes : argocd-initial-admin-secret
- L'application doit pointer vers le dossier contenant les chart Helm
- La synchronisation peut être manuelle ou automatique

### Vérifications

- [ ] ArgoCD est déployé et accessible
- [ ] L'application guestbook est synchronisée depuis Git
- [ ] Les changements Git se reflètent automatiquement dans le cluster

## 10. (Optionnel) Écrire un app-of-apps pour déployer ArgoCD et guestbook

### Pourquoi

Le [pattern app-of-apps](https://argo-cd.readthedocs.io/en/latest/operator-manual/cluster-bootstrapping/) permet de gérer plusieurs applications ArgoCD de manière centralisée, facilitant la gestion d'un cluster complet via GitOps.

### Comment

1. **Créez une Application ArgoCD** qui déploie d'autres applications
2. **Configurez la pour watch les applications du directory dans lequel elle est** (ArgoCD lui-même, guestbook, etc.)

### Indices

- L'app-of-apps pointe vers un dossier contenant plusieurs définitions d'applications
- Elle peut se déployer elle-même (bootstrap)
- Utilisez des valeurs Helm pour paramétrer les applications

### Vérifications

- [ ] L'app-of-apps déploie toutes les applications
- [ ] Elle peut se déployer elle-même
- [ ] La gestion centralisée fonctionne
- [ ] Il y a une proposition de MaJ lorsque je commit une modification dans le repo

## 11. (Optionnel) Ajouter des applications pour Prometheus, Chaos Mesh et le runner GitHub avec sync sur commit

### Pourquoi

L'intégration complète de tous les outils dans GitOps garantit une infrastructure comme code cohérente et versionée.

### Comment

1. **Créez des Applications ArgoCD** pour chaque outil
2. **Configurez la synchronisation automatique** sur commit
3. **Organisez la structure** des manifests dans Git
4. **Testez la synchronisation** de l'ensemble

### Indices

- Chaque outil doit avoir sa propre application ArgoCD
- Utilisez des dossiers séparés pour organiser les manifests
- La synchronisation doit être rapide et fiable

### Vérifications

- [ ] Toutes les applications sont gérées par ArgoCD
- [ ] Les changements Git se synchronisent automatiquement
- [ ] L'infrastructure complète est versionnée

## 12. (Optionnel) Déployer ArgoCD Image Updater et adapter l'application guestbook pour mise à jour automatique

### Pourquoi

[ArgoCD Image Updater](https://github.com/argoproj-labs/argocd-image-updater) automatise la mise à jour des images d'applications quand de nouvelles versions sont disponibles, complétant le cycle CI/CD.

### Comment

1. **Déployez ArgoCD Image Updater**
2. **Configurez l'application guestbook** avec les annotations appropriées
3. **Testez la mise à jour automatique** avec une nouvelle image
4. **Observez le cycle complet** CI/CD → registry → déploiement

### Indices

- Image Updater surveille les registries d'images
- Les annotations sur l'Application définissent le comportement
- Il peut créer des commits automatiques ou des PR

### Vérifications

- [ ] Image Updater détecte les nouvelles images
- [ ] L'application guestbook se met à jour automatiquement
- [ ] Le cycle complet CI/CD fonctionne

## 13. (Optionnel) Déployer Burrito et appliquer le code Terraform pour les random pets

### Pourquoi

[Burrito](https://github.com/padok-team/burrito) permet d'exécuter Terraform dans Kubernetes de manière GitOps, étendant le modèle déclaratif à l'infrastructure.

### Comment

1. **Déployez Burrito** dans le cluster
2. **Créez une TerraformRepository** pointant vers votre code
3. **Appliquez le code** des random pets depuis le jour 1
4. **Observez l'exécution** Terraform dans Kubernetes

### Indices

- Burrito utilise des CRDs pour gérer Terraform
- Il faut configurer les providers et backends
- L'exécution se fait dans des pods

### Vérifications

- [ ] Burrito exécute Terraform avec succès
- [ ] Les ressources Terraform sont créées
- [ ] L'intégration GitOps fonctionne

## Évaluation finale

### Connaissances à maîtriser

**Monitoring et observabilité :**
- [ ] Je sais déployer et configurer Prometheus
- [ ] Je sais créer des dashboards Grafana personnalisés
- [ ] Je comprends les métriques Kubernetes et applicatives
- [ ] Je sais configurer des alertes pertinentes

**CI/CD et GitOps :**
- [ ] Je sais créer des workflows GitHub Actions
- [ ] Je comprends les principes GitOps avec ArgoCD
- [ ] Je sais automatiser les déploiements
- [ ] Je maîtrise le pattern app-of-apps

**Chaos Engineering :**
- [ ] Je comprends les principes du chaos engineering
- [ ] Je sais analyser l'impact des expériences de chaos

**Infrastructure avancée :**
- [ ] Je sais rendre mon application résiliente avec Topology Spread Constraints
- [ ] Je comprends les enjeux de résilience multi-nœuds
- [ ] Je sais automatiser la gestion des dépendances

### Conseils pour aller plus loin

- **Explorez d'autres outils** : Istio pour service mesh, Tekton pour CI/CD natif Kubernetes
- **Approfondissez le monitoring** : métriques custom, tracing distribué avec Jaeger
- **Maîtrisez le chaos engineering** : expériences réseau, stress tests, pannes de composants
- **Étudiez les patterns avancés** : canary deployments, blue-green, feature flags
