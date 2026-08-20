# ☸️ Guide d'Architecture et Déploiement Kubernetes (`k8s/`)

Ce dossier contient l'ensemble des manifestes Kubernetes (YAML) permettant d'orchestrer l'application Fullstack e-commerce en environnement de production haute disponibilité.

---

## 📐 1. Architecture du Cluster

L'application est déployée dans l'espace virtuel (**Namespace**) `lab-devops` et se compose de 4 briques principales :

```mermaid
graph TD
    Client([💻 Client Web / Internet]) --> Ingress[🌐 Ingress Router Nginx]
    
    subgraph Namespace: lab-devops
        Ingress -->|/api| SvcBackend[⚙️ backend-service:3001]
        Ingress -->|/| SvcFrontend[🎨 frontend-service:3000]
        
        SvcBackend --> PodBackend1[📦 Pod Backend 1]
        SvcBackend --> PodBackend2[📦 Pod Backend 2]
        
        SvcFrontend --> PodFrontend1[📦 Pod Frontend 1]
        SvcFrontend --> PodFrontend2[📦 Pod Frontend 2]
        
        PodBackend1 --> SvcDB[🗄️ db-service:5432]
        PodBackend2 --> SvcDB
        
        SvcDB --> PodDB[📦 Pod PostgreSQL]
        PodDB --> PVC[(💾 Volume Persistant PVC 1Go)]
        PodDB -. Injecte .-> Secret[🔑 postgres-secret]
    end
```

---

## 📑 2. Explication Fichier par Fichier

### 🗂️ `namespace.yaml` — L'Isolation
- **Rôle** : Crée l'espace virtuel `lab-devops`.
- **Pourquoi ?** : Permet de regrouper toutes nos ressources et de les isoler du reste du cluster Kubernetes.

---

### 🗄️ `postgres/` — La Base de Données
- **`secret.yaml`** : Contient les identifiants de la base de données (`POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`).
- **`pvc.yaml` (PersistentVolumeClaim)** : Demande 1 Go de stockage disque au cluster. Ce stockage est **persistant** : les données ne sont pas perdues si le pod redémarre.
- **`deployment.yaml`** : Lance **1 seule instance** (`replicas: 1`) de PostgreSQL pour éviter toute corruption de données.
- **`service.yaml`** : Expose la base de données sur le réseau interne du cluster au port `5432`. Son nom DNS est `db-service`.

---

### ⚙️ `backend/` — L'API Express Node.js
- **`deployment.yaml`** : Lance **2 répliques** (Pods) de l'API pour assurer la Haute Disponibilité. Connecté à la base de données via l'adresse `postgres://postgres:secretpassword@db-service:5432/lab_ghislain`.
- **`service.yaml`** : Répartit la charge (Load Balancing) entre les 2 pods de l'API sur le port `3001`. Nom DNS interne : `backend-service`.

---

### 🎨 `frontend/` — L'Interface utilisateur React
- **`deployment.yaml`** : Lance **2 répliques** (Pods) du frontend React.
- **`service.yaml`** : Expose le frontend sur le port `3000`. Nom DNS interne : `frontend-service`.

---

### 🌐 `ingress.yaml` — Le Routeur Reverse Proxy
- **Rôle** : Point d'entrée unique HTTP du cluster (équivalent de Nginx en amont).
- **Règles de routage** :
  - `http://<IP_CLUSTER>/api` ➡️ Redirige vers `backend-service:3001`
  - `http://<IP_CLUSTER>/` ➡️ Redirige vers `frontend-service:3000`

---

### 🛠️ `kustomization.yaml` — Le Chef d'Orchestre
- **Rôle** : Fichier Kustomize qui liste tous les fichiers YAML dans l'ordre pour pouvoir tout déployer ou détruire avec **une seule commande**.

---

## 🚀 3. Guide de Déploiement (Commandes)

### 1️⃣ Déployer l'intégralité de l'application :
```bash
kubectl apply -k k8s/
```

### 2️⃣ Vérifier que tout fonctionne :
```bash
# Voir l'état de tous les pods (doivent être en état 'Running')
kubectl get pods -n lab-devops

# Voir les services et leurs IP internes
kubectl get svc -n lab-devops

# Voir le point d'entrée Ingress et son IP publique/externe
kubectl get ingress -n lab-devops
```

### 3️⃣ Suivre les logs d'un composant en temps réel :
```bash
# Logs de l'API Backend
kubectl logs -f deployment/backend-deployment -n lab-devops

# Logs de la Base de données
kubectl logs -f deployment/postgres-deployment -n lab-devops
```

### 4️⃣ Diagnostiquer un Pod en cas de problème :
```bash
kubectl describe pod <nom-du-pod> -n lab-devops
```

### 5️⃣ Supprimer l'ensemble du déploiement :
```bash
kubectl delete -k k8s/
```

---

## 🔄 4. Équivalences Docker Compose vs Kubernetes

| Concept Docker Compose | Équivalent Kubernetes | Utilisation |
| :--- | :--- | :--- |
| `docker-compose.yml` | `kustomization.yaml` | Fichier maître d'orchestration |
| Service / Conteneur | **Pod** & **Deployment** | Exécution des conteneurs |
| Network interne | **Service (ClusterIP)** | Communication DNS entre pods |
| Volumes (`volumes:`) | **PersistentVolumeClaim (PVC)** | Stockage disque durable |
| Environment / `.env` | **Secret** / **ConfigMap** | Variables de configuration |
| Nginx Proxy (`8085:80`) | **Ingress** | Point d'entrée web unique |
