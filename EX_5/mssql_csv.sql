GO
USE master
GO
DROP DATABASE Homework

CREATE DATABASE Homework
GO
USE Homework
GO


IF OBJECT_ID('tempdb..#stage') IS NOT NULL DROP TABLE #stage;
CREATE TABLE #stage
(

	[Country] NVARCHAR(4000),
	[Year] NVARCHAR(4000),
	[Rank] NVARCHAR(4000),
	[Total] NVARCHAR(4000),
	[S1  Demographic Pressures] NVARCHAR(4000),
	[S2  Refugees and IDPs] NVARCHAR(4000),
	[C3  Group Grievance] NVARCHAR(4000),
	[E3  Human Flight and Brain Drain] NVARCHAR(4000),
	[E2  Economic Inequality] NVARCHAR(4000),
	[E1  Economy] NVARCHAR(4000),
	[P1  State Legitimacy] NVARCHAR(4000),
	[P2  Public Services] NVARCHAR(4000),
	[P3  Human Rights] NVARCHAR(4000),
	[C1  Security Apparatus] NVARCHAR(4000),
	[C2  Factionalized Elites] NVARCHAR(4000),
	[X1  External Intervention] NVARCHAR(4000)
);

BULK INSERT #stage
FROM 'C:\FSI-2023-DOWNLOAD.csv'
WITH (
    FIRSTROW = 2,                 -- header is row 1
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0a',       -- <-- LF
    CODEPAGE = '65001',
    TABLOCK,
    KEEPNULLS
);

select * from #stage;

CREATE TABLE [dbo].[FSI-2023](
RN INT IDENTITY(1,1),
	[Country] [varchar](50) NULL,
	[Year] [varchar](50) NULL,
	[Rank] [varchar](50) NULL,
	[Total] [decimal](18, 2) NULL,
	[S1  Demographic Pressures] [decimal](18, 2) NULL,
	[S2  Refugees and IDPs] [decimal](18, 2)  NULL,
	[C3  Group Grievance] [decimal](18, 2)  NULL,
	[E3  Human Flight and Brain Drain] [decimal](18, 2)   NULL,
	[E2  Economic Inequality] [decimal](18, 2)   NULL,
	[E1  Economy] [decimal](18, 2)  NULL,
	[P1  State Legitimacy] [decimal](18, 2) NULL,
	[P2  Public Services] [decimal](18, 2) NULL,
	[P3  Human Rights] [decimal](18, 2)  NULL,
	[C1  Security Apparatus] [decimal](18, 2)  NULL,
	[C2  Factionalized Elites] [decimal](18, 2) NULL,
	[X1  External Intervention] [decimal](18, 2)  NULL
) ON [PRIMARY]
GO
;

INSERT INTO [dbo].[FSI-2023] (
    [Country],
    [Year],
    [Rank],
    [Total],
    [S1  Demographic Pressures],
    [S2  Refugees and IDPs],
    [C3  Group Grievance],
    [E3  Human Flight and Brain Drain],
    [E2  Economic Inequality],
    [E1  Economy],
    [P1  State Legitimacy],
    [P2  Public Services],
    [P3  Human Rights],
    [C1  Security Apparatus],
    [C2  Factionalized Elites],
    [X1  External Intervention]
)
SELECT
    -- Text
    CAST(NULLIF(LTRIM(RTRIM(s.[Country])), '') AS VARCHAR(50)) AS [Country],
    NULLIF(LTRIM(RTRIM(s.[Year])), '')                          AS [Year],
    NULLIF(LTRIM(RTRIM(s.[Rank])), '')                          AS [Rank],

    -- Numbers: strip thousands ('.' and spaces), swap comma?dot, TRY_CAST to DECIMAL(18,2)
    TRY_CAST(REPLACE(REPLACE(REPLACE(NULLIF(s.[Total], ''), '.', ''), ' ', ''), ',', '.') AS DECIMAL(18,2)) AS [Total],
    TRY_CAST(REPLACE(REPLACE(REPLACE(NULLIF(s.[S1  Demographic Pressures], ''), '.', ''), ' ', ''), ',', '.') AS DECIMAL(18,2)) AS [S1  Demographic Pressures],
    TRY_CAST(REPLACE(REPLACE(REPLACE(NULLIF(s.[S2  Refugees and IDPs], ''), '.', ''), ' ', ''), ',', '.') AS DECIMAL(18,2)) AS [S2  Refugees and IDPs],
    TRY_CAST(REPLACE(REPLACE(REPLACE(NULLIF(s.[C3  Group Grievance], ''), '.', ''), ' ', ''), ',', '.') AS DECIMAL(18,2)) AS [C3  Group Grievance],
    TRY_CAST(REPLACE(REPLACE(REPLACE(NULLIF(s.[E3  Human Flight and Brain Drain], ''), '.', ''), ' ', ''), ',', '.') AS DECIMAL(18,2)) AS [E3  Human Flight and Brain Drain],
    TRY_CAST(REPLACE(REPLACE(REPLACE(NULLIF(s.[E2  Economic Inequality], ''), '.', ''), ' ', ''), ',', '.') AS DECIMAL(18,2)) AS [E2  Economic Inequality],
    TRY_CAST(REPLACE(REPLACE(REPLACE(NULLIF(s.[E1  Economy], ''), '.', ''), ' ', ''), ',', '.') AS DECIMAL(18,2)) AS [E1  Economy],
    TRY_CAST(REPLACE(REPLACE(REPLACE(NULLIF(s.[P1  State Legitimacy], ''), '.', ''), ' ', ''), ',', '.') AS DECIMAL(18,2)) AS [P1  State Legitimacy],
    TRY_CAST(REPLACE(REPLACE(REPLACE(NULLIF(s.[P2  Public Services], ''), '.', ''), ' ', ''), ',', '.') AS DECIMAL(18,2)) AS [P2  Public Services],
    TRY_CAST(REPLACE(REPLACE(REPLACE(NULLIF(s.[P3  Human Rights], ''), '.', ''), ' ', ''), ',', '.') AS DECIMAL(18,2)) AS [P3  Human Rights],
    TRY_CAST(REPLACE(REPLACE(REPLACE(NULLIF(s.[C1  Security Apparatus], ''), '.', ''), ' ', ''), ',', '.') AS DECIMAL(18,2)) AS [C1  Security Apparatus],
    TRY_CAST(REPLACE(REPLACE(REPLACE(NULLIF(s.[C2  Factionalized Elites], ''), '.', ''), ' ', ''), ',', '.') AS DECIMAL(18,2)) AS [C2  Factionalized Elites],
    TRY_CAST(REPLACE(REPLACE(REPLACE(NULLIF(s.[X1  External Intervention], ''), '.', ''), ' ', ''), ',', '.') AS DECIMAL(18,2)) AS [X1  External Intervention]
FROM #stage AS s;


SELECT * FROM [dbo].[FSI-2023]

WHERE RN =( SELECT MIN(RN) FROM  [dbo].[FSI-2023])
OR RN =( SELECT MAX(RN) FROM  [dbo].[FSI-2023])
;



WITH R AS (
  SELECT *,
         TRY_CONVERT(int,
           LEFT([Rank], PATINDEX('%[^0-9]%', [Rank] + 'X') - 1)
         ) AS RankNum
  FROM [dbo].[FSI-2023]
)
SELECT TOP (1) WITH TIES *
FROM R
ORDER BY RankNum ASC;  -- first (smallest rank)
-- DESC
-- and for the last (largest rank)

