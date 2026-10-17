# 📊 Dashboard Power BI

Fichier : [`powerbi/Olympic_Dashboard.pbix`](../powerbi/Olympic_Dashboard.pbix)

Modèle : tables `DimAthlete`, `DimTeam`, `DimGames`, `DimEvent`, `DimMedal`, `FactParticipation` (issues de la couche Gold via Synapse) + une table `_Measures` regroupant les mesures DAX.

Navigation entre pages par *page navigator* ; chaque page propose des filtres (Sport, Année, Équipe, Médaille, Saison).

## KPIs (cartes présentes sur chaque page)

- Nombre de participations
- Total athlètes
- Total médailles
- Total pays
- Nombre d'athlètes médaillés
- Taux de médaille (*Medal Rate*)

## Pages

### 🏠 Home
- Yearly Participation Trends (aire, par saison)
- Top Teams by Total Medals (colonnes)
- Total Participations by Sport (treemap)

### 🏃 Athletes
- Gender Distribution of Athletes (anneau)
- Top 5 Teams by Athletes (colonnes)
- Height–Weight Correlation (nuage de points)
- Athlete Performance Table : nom, sexe, participations, médailles

### 🏅 Medals & Podiums
- Athletes by Medal Level (barres)
- Top 5 Teams by Medal Level (colonnes groupées Or / Argent / Bronze)
- Team Performance by Sport : nombre d'Or, d'Argent, de Bronze par équipe et sport
- Medaled Athletes by Gender (anneau)

### ⚽ Sports & Events
- Top 5 Sports by Total Medals
- Top Events by Total Medals

### 📈 Time & Trends
- Top 5 Countries Medal Ranking Over Time (1990–2016) (ribbon chart)
- Yearly Evolution of Total Medals (aire, par saison)
- Total Countries Over Time (courbe)

## Captures d'écran

> Ajouter les captures dans `docs/images/` (ex. `dashboard_home.png`) puis les référencer ici :
>
> `![Home](images/dashboard_home.png)`
