/* =====================================================================
   Préparation de la base SQL Server on-premise pour Azure Data Factory
   - Création d'un login + user dédié à ADF
   - Attribution des droits de lecture
   Le mot de passe n'est jamais stocké dans ADF : il est enregistré
   comme secret dans Azure Key Vault, que le Linked Service ADF lit.
   ===================================================================== */

-- 1) Login au niveau serveur (mot de passe à stocker dans Key Vault)
USE master;
GO
CREATE LOGIN <login_name> WITH PASSWORD = '*****';
GO

-- 2) User dans la base qui contient la table dbo.athlete_events
USE <database_name>;
GO
CREATE USER <user_name> FOR LOGIN <login_name>;
GO

-- 3) Droits : lecture seule suffit pour l'activité Copy d'ADF
ALTER ROLE db_datareader ADD MEMBER <user_name>;
GO

-- Alternative (permissions fines, principe du moindre privilège) :
-- GRANT SELECT ON dbo.athlete_events TO <user_name>;
