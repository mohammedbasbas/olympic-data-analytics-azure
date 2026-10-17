# 🛠 Guide de mise en place

Étapes réalisées dans le portail Azure, Azure Data Factory et Azure Databricks.

---

## 1. Provisionnement des ressources

Dans **Azure Portal** :

1. Créer un **Resource Group**
2. Créer **Azure Data Factory**
3. Créer un **Storage Account** en activant le **Hierarchical namespace** → **ADLS Gen2**
4. Créer un workspace **Azure Databricks**
5. Créer **Azure Synapse Analytics**
6. Créer un **Key Vault** (rôle *Key Vault Administrator* nécessaire pour gérer les secrets)
7. Dans le Storage Account, créer les containers : `bronze`, `silver`, `gold`

---

## 2. Préparation de SQL Server (source on-premise)

- Créer un **login** et un **user** dédiés → [`sql/onprem_sqlserver_setup.sql`](../sql/onprem_sqlserver_setup.sql)
- Donner au user les droits de lecture sur les tables (`db_datareader` ou `GRANT SELECT`)
- Stocker le **mot de passe** dans **Key Vault** (Secrets → Generate/Import) : ADF le lira au moment de la connexion

| Besoin | Rôle SQL |
|---|---|
| Lire des tables (`SELECT`) | `db_datareader` |
| Écrire (`INSERT`, `UPDATE`, `DELETE`) | `db_datawriter` |
| Tous les droits | `db_owner` |

---

## 3. Ingestion avec Azure Data Factory

1. Créer un **pipeline** avec une activité **Copy data**
2. **Source** – Linked Service SQL Server :
   - Créer un **nouvel Integration Runtime** de type **Self-Hosted** (ex. `SHIR`).
     L'`AutoResolveIntegrationRuntime` ne permet de joindre que des services Azure ; pour une base **on-premise**, il faut un SHIR installé sur la machine qui héberge (ou voit) le serveur SQL (*Option 1 : express setup*).
   - *Server name* : nom de l'instance SQL Server
   - Authentification : user SQL + **mot de passe lu depuis Azure Key Vault**
   - Si ADF n'a pas accès au Key Vault : **Key Vault → Access control (IAM) → Key Vault Secrets User** pour l'identité managée d'ADF
   - *Encrypt* : `Optional`
   - *Import schema* : *From connection/store*
3. **Sink** – Linked Service **ADLS Gen2**, format **Parquet**, container `bronze`
4. Exécuter le pipeline → `bronze/dbo.athlete_events.parquet`

---

## 4. Connexion Databricks → ADLS Gen2 (Service Principal + OAuth)

### Pourquoi ?
Le cluster Databricks doit prouver **qui** il est et **s'il a le droit** de lire/écrire dans le Data Lake. Plutôt qu'une clé de stockage ou un compte utilisateur, on utilise une **identité d'application** : un **Service Principal**.

### 4.1 Créer l'identité (Microsoft Entra ID)
1. **Entra ID → App registrations → New registration** → récupérer :
   - **Application (client) ID** → `client_id`
   - **Directory (tenant) ID** → `tenant_id`
2. **Certificates & secrets → New client secret** → récupérer la **valeur** du secret

### 4.2 Donner les droits sur le Data Lake
**Storage Account → Access control (IAM) → Add role assignment** → **Storage Blob Data Contributor** (ou *Reader* en lecture seule) → assigner au Service Principal.

### 4.3 Stocker le secret
**Key Vault → Secrets → Generate/Import** → secret `secretKey` contenant le *client secret*.

### 4.4 Secret scope Databricks
Créer un **Key Vault-backed secret scope** (`secretScope`) depuis l'UI Databricks (`#secrets/createScope`). Le secret devient lisible via :

```python
dbutils.secrets.get(scope="secretScope", key="secretKey")
```

### 4.5 Configuration Spark (OAuth ABFS, sans mount)
Voir [`databricks/00_auth.ipynb`](../databricks/00_auth.ipynb) :

| Paramètre | Rôle |
|---|---|
| `fs.azure.account.auth.type` = `OAuth` | Authentification OAuth pour ce storage account |
| `oauth.provider.type` = `ClientCredsTokenProvider` | Flux *client credentials* (Service Principal) |
| `oauth2.client.id` | Client ID de l'App Registration |
| `oauth2.client.secret` | Secret lu dans Key Vault via le scope |
| `oauth2.client.endpoint` | `https://login.microsoftonline.com/<tenant_id>/oauth2/token` |

### Flux d'authentification
1. Databricks envoie **client id + client secret** à Microsoft Entra ID
2. Entra ID vérifie l'identité
3. Entra ID renvoie un **access token OAuth**
4. Databricks utilise ce token pour accéder à ADLS Gen2

Les données sont ensuite accessibles via le protocole **ABFS** (HTTPS) :

```
abfss://<container>@<storage_account>.dfs.core.windows.net/
```

---

## 5. Traitements Databricks

1. Créer un **cluster** (compute) pour exécuter les notebooks
2. Exécuter dans l'ordre :
   - [`01_bronze_ingest_athletes`](../databricks/01_bronze_ingest_athletes.ipynb)
   - [`02_silver_transform_athletes`](../databricks/02_silver_transform_athletes.ipynb)
   - [`03_gold_build_BI_tables`](../databricks/03_gold_build_BI_tables.ipynb)

---

## 6. Azure Synapse Analytics

Les tables Gold sont exportées en **Parquet** dans `gold/asa_export/<table>/` (notebook 03). Synapse lit ces fichiers depuis ADLS Gen2 pour le calcul des KPIs en SQL et sert de source au dashboard **Power BI**.
