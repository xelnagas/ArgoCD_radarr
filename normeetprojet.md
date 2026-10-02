# Normes, Contraintes et Bonnes Pratiques GitOps (Argo CD) - Media Stack

Ce document formalise les règles architecturales, contraintes opérationnelles et bonnes pratiques applicables à ce repository. Ce repository constitue la **source unique de vérité (Single Source of Truth - SSoT)** pour l'état désiré de la suite applicative d'automatisation multimédia (**Jellyseerr, Radarr, Sonarr, Prowlarr, qBittorrent**) déployée par **Argo CD** sur le cluster Kubernetes (K3s).

---

## 1. Principes Fondamentaux GitOps

1. **Source Unique de Vérité (SSoT)** :
   - Tout ce qui est déployé sur le cluster Kubernetes **doit** être décrit dans ce repository Git (`https://github.com/xelnagas/ArgoCD_radarr.git`).
   - Toute modification sur le cluster doit transiter par un commit / Pull Request Git.
2. **Interdiction des modifications manuelles (Anti-Drift)** :
   - L'usage de `kubectl apply`, `kubectl edit`, `kubectl patch` directement en dehors du cadre GitOps est strictement proscrit en production.
   - Argo CD est configuré avec l'auto-guérison (`selfHeal: true`) : toute modification hors-Git sera écrasée et réalignée sur le repository.
3. **Traçabilité & Immutabilité** :
   - Tout changement d'état est auditable grâce à l'historique Git (qui, quoi, quand, pourquoi).
   - Les rollbacks s'effectuent par un `git revert` du commit concerné.

---

## 2. Structure Recommandée du Repository

```text
.
├── .github/                           # Intégration GitHub Actions & CI
│   └── workflows/
│       └── validate.yaml              # Validation Kustomize en CI
│
├── apps/                              # Déclarations des Applications Argo CD
│   └── workloads/
│       └── media-stack.yaml           # Application CRD Argo CD
│
├── manifests/                         # Manifests Kubernetes applicatifs (Kustomize)
│   └── workloads/
│       └── media-stack/
│           ├── base/                  # Configuration socle mutualisée
│           │   ├── namespace.yaml
│           │   ├── pv-pvc-media.yaml
│           │   ├── pv-pvc-configs.yaml
│           │   ├── qbittorrent/
│           │   │   ├── deployment.yaml
│           │   │   └── service.yaml
│           │   ├── prowlarr/
│           │   │   ├── deployment.yaml
│           │   │   └── service.yaml
│           │   ├── radarr/
│           │   │   ├── deployment.yaml
│           │   │   └── service.yaml
│           │   ├── sonarr/
│           │   │   ├── deployment.yaml
│           │   │   └── service.yaml
│           │   ├── jellyseerr/
│           │   │   ├── deployment.yaml
│           │   │   └── service.yaml
│           │   ├── ingress.yaml
│           │   └── kustomization.yaml
│           └── overlays/              # Déclinaisons par environnement
│               └── prod/
│                   └── kustomization.yaml
│
├── scripts/                           # Scripts utilitaires d'administration
│   └── init-directories.sh
│
├── normeetprojet.md                   # Ce document de référence
├── README.md                          # Présentation générale du projet
└── action.md                          # Suivi opérationnel du plan d'action
```

---

## 3. Contraintes et Normes Argo CD

### 3.1. Ordonnancement des Déploiements (Sync Waves)
Pour garantir que les dépendances (PV/PVC avant Pods, Services avant Ingress) démarrent dans l'ordre requis, l'annotation `argocd.argoproj.io/sync-wave` est obligatoire :

| Vague (Wave) | Rôle | Exemples |
| :--- | :--- | :--- |
| **Wave -2** | Namespaces | `namespace: media` |
| **Wave 0** | Dépendances & Stockage | `PersistentVolume`, `PersistentVolumeClaim`, `Service` |
| **Wave 2** | Workloads applicatifs | `Deployment` (Radarr, Sonarr, Prowlarr, qBittorrent, Jellyseerr) |
| **Wave 3** | Ingress & Routage | `Ingress` (Traefik) |

---

## 4. Normes de Qualité des Manifests Kubernetes

### 4.1. Ordonnancement Nœud (`nodeSelector`)
Tous les workloads accédant aux montages de disques locaux de la machine de stockage doivent comporter :
```yaml
nodeSelector:
  kubernetes.io/hostname: linux2
```

### 4.2. Labels Standards Kubernetes
```yaml
metadata:
  labels:
    app.kubernetes.io/name: <app-name>
    app.kubernetes.io/instance: <app-name>-prod
    app.kubernetes.io/component: <role>
    app.kubernetes.io/part-of: media-stack
    app.kubernetes.io/managed-by: argocd
    env: prod
```

### 4.3. Gestion des Images Docker
- **Interdiction formelle du tag `:latest`** :
  - Toujours utiliser un tag immuable SemVer (ex: `5.19.3.9730-ls243`).
- **Image Pull Policy** :
  - Définir `imagePullPolicy: IfNotPresent`.

### 4.4. Dimensionnement des Ressources (`requests` / `limits`)
Chaque conteneur doit obligatoirement définir des limites et demandes de ressources pour éviter les crashs OOM et permettre un ordonnancement prévisible.

### 4.5. Sondes de Santé (Health Checks)
Tout workload doit implémenter :
- `startupProbe` : Pour laisser le temps aux bases SQLite de migrer sans redémarrage prématuré.
- `livenessProbe` : Vérifie que le processus est actif.
- `readinessProbe` : Contrôle la capacité à servir les requêtes.

### 4.6. Droits d'Exécution et Utilisateurs
Les conteneurs de la suite LinuxServer et Jellyseerr tournent avec :
```yaml
securityContext:
  fsGroup: 1000
env:
  - name: PUID
    value: "1000"
  - name: PGID
    value: "1000"
  - name: TZ
    value: Europe/Paris
```
