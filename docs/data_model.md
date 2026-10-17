# ⭐ Modèle de données – couche Gold

Schéma en étoile construit dans [`03_gold_build_BI_tables`](../databricks/03_gold_build_BI_tables.ipynb) à partir de la table Silver `athletes_transformed_data`.

## Emplacements

| Table | Format | Chemin ADLS Gen2 |
|---|---|---|
| `DimAthlete`, `DimTeam`, `DimGames`, `DimEvent`, `DimMedal` | Delta | `gold/dimensions/<Table>` |
| `fact_table` | Delta | `gold/fact_table/` |
| Snapshots de toutes les tables (pour Synapse) | Parquet | `gold/asa_export/<Table>/` |

## Dimensions

| Dimension | Clé | Grain (colonnes de dédoublonnage) |
|---|---|---|
| `DimAthlete` | `Athlete_ID` | `Name`, `Sex`, `Birth_Year` |
| `DimTeam` | `Team_ID` | `Team`, `NOC` |
| `DimGames` | `Games_ID` | `Year`, `Season`, `City` |
| `DimEvent` | `Event_ID` | `Sport`, `Event` |
| `DimMedal` | `Medal_ID` | `Medal` (Gold / Silver / Bronze, `NULL` exclu) |

Méthode commune :

```sql
WITH deduplicated_data AS (
  SELECT <cols>, ROW_NUMBER() OVER (PARTITION BY <cols> ORDER BY <col>) AS rn
  FROM transformed_data
)
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS <Dim>_ID, <cols>
FROM deduplicated_data WHERE rn = 1;
```

## Table de faits `fact_table`

Grain : **une participation** (un athlète, dans une épreuve, lors d'une édition).

| Colonne | Description |
|---|---|
| `Participation_ID` | Identifiant technique (Silver) |
| `Athlete_ID`, `Team_ID`, `Games_ID`, `Event_ID`, `Medal_ID` | Clés étrangères |
| `hasParticipated` | Toujours 1 → somme = nombre de participations |
| `Medal_flag` | 1 si médaille, sinon 0 → somme = nombre de médailles |
| `Age`, `Height`, `Weight` | Mesures athlète |

Les jointures utilisent l'opérateur **null-safe `<=>`** : une ligne dont un attribut est `NULL` (ex. `Birth_Year` inconnu) retrouve quand même sa dimension. `Medal_ID` reste `NULL` pour les participations sans médaille.

## Pourquoi `Birth_Year` ?

Plusieurs athlètes partagent le même nom. `Birth_Year = Year - Age` (calculé en Silver) permet de distinguer deux homonymes et de reconnaître un même athlète sur plusieurs éditions.
