# Configuration de Résilience avec Topology Spread Constraints

## Explication des Contraintes

### 1. Configuration Stricte (resilient-app)
```yaml
topologySpreadConstraints:
- maxSkew: 1
  topologyKey: kubernetes.io/hostname
  whenUnsatisfiable: DoNotSchedule
```

**Explication :**
- `maxSkew: 1` : Maximum 1 pod de différence entre les nœuds
- `topologyKey: kubernetes.io/hostname` : Répartition basée sur les noms d'hôte (nœuds)
- `whenUnsatisfiable: DoNotSchedule` : Empêche le scheduling si la contrainte n'est pas respectée

**Comportement attendu avec 4 replicas et 2 nœuds :**
- Nœud 1: 2 pods
- Nœud 2: 2 pods

### 2. Configuration Souple (resilient-app-soft)
```yaml
topologySpreadConstraints:
- maxSkew: 2
  topologyKey: kubernetes.io/hostname
  whenUnsatisfiable: ScheduleAnyway
```

**Explication :**
- `maxSkew: 2` : Tolère jusqu'à 2 pods de différence
- `whenUnsatisfiable: ScheduleAnyway` : Programme quand même le pod même si la contrainte n'est pas respectée

## Avantages des Topology Spread Constraints

1. **Résilience** : Distribution automatique des pods sur différents nœuds
2. **Équilibrage** : Répartition équitable de la charge
3. **Flexibilité** : Contrôle fin avec maxSkew et whenUnsatisfiable
4. **Évolutivité** : S'adapte automatiquement à l'ajout/suppression de nœuds

## Topologies Disponibles

- `kubernetes.io/hostname` : Par nœud
- `kubernetes.io/zone` : Par zone (si configuré)
- `kubernetes.io/region` : Par région (si configuré)
- Labels personnalisés : Rack, datacenter, etc.