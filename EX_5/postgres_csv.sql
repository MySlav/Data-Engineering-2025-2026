-- Use the right database (connect in pgAdmin/psql first), e.g. mydatabase

-- 1) TEMP staging table (text columns, quoted names to keep spaces)
DROP TABLE IF EXISTS temp_stage;
CREATE TEMP TABLE temp_stage
(
  "Country" text,
  "Year" text,
  "Rank" text,
  "Total" text,
  "S1  Demographic Pressures" text,
  "S2  Refugees and IDPs" text,
  "C3  Group Grievance" text,
  "E3  Human Flight and Brain Drain" text,
  "E2  Economic Inequality" text,
  "E1  Economy" text,
  "P1  State Legitimacy" text,
  "P2  Public Services" text,
  "P3  Human Rights" text,
  "C1  Security Apparatus" text,
  "C2  Factionalized Elites" text,
  "X1  External Intervention" text
);

-- 2) Bulk load CSV -> staging
--   - HEADER reads the first row as column names
--   - DELIMITER ';'
--   - NULL '' treats empty fields as SQL NULL (like KEEPNULLS intent)
COPY temp_stage
FROM '/var/lib/postgresql/import/fsi.csv'
WITH (
  FORMAT csv,
  HEADER true,
  DELIMITER ';',
  QUOTE '"',
  ESCAPE '"',
  ENCODING 'UTF8',
  NULL ''
);

-- 3) Final table 
DROP TABLE IF EXISTS public.fsi_2023;
CREATE TABLE public.fsi_2023
(
  rn bigserial PRIMARY KEY,
  country varchar(50),
  "year" varchar(50),
  "rank" varchar(50),
  "Total" numeric(18,2),
  "S1  Demographic Pressures" numeric(18,2),
  "S2  Refugees and IDPs" numeric(18,2),
  "C3  Group Grievance" numeric(18,2),
  "E3  Human Flight and Brain Drain" numeric(18,2),
  "E2  Economic Inequality" numeric(18,2),
  "E1  Economy" numeric(18,2),
  "P1  State Legitimacy" numeric(18,2),
  "P2  Public Services" numeric(18,2),
  "P3  Human Rights" numeric(18,2),
  "C1  Security Apparatus" numeric(18,2),
  "C2  Factionalized Elites" numeric(18,2),
  "X1  External Intervention" numeric(18,2)
);

-- Helper: convert text with EU-style numbers to numeric(18,2)
--  - strip thousands separators '.' and spaces
--  - replace comma decimal with dot
--  - cast to numeric


INSERT INTO public.fsi_2023
(
  country, "year", "rank",
  "Total",
  "S1  Demographic Pressures",
  "S2  Refugees and IDPs",
  "C3  Group Grievance",
  "E3  Human Flight and Brain Drain",
  "E2  Economic Inequality",
  "E1  Economy",
  "P1  State Legitimacy",
  "P2  Public Services",
  "P3  Human Rights",
  "C1  Security Apparatus",
  "C2  Factionalized Elites",
  "X1  External Intervention"
)
SELECT
  NULLIF(btrim("Country"), '')::varchar(50)                                        AS country,
  NULLIF(btrim("Year"), '')::varchar(50)                                           AS "year",
  NULLIF(btrim("Rank"), '')::varchar(50)                                           AS "rank",

  CAST(replace(translate(NULLIF("Total", ''), '. ', ''), ',', '.') AS numeric(18,2)),
  CAST(replace(translate(NULLIF("S1  Demographic Pressures", ''), '. ', ''), ',', '.') AS numeric(18,2)),
  CAST(replace(translate(NULLIF("S2  Refugees and IDPs", ''), '. ', ''), ',', '.')     AS numeric(18,2)),
  CAST(replace(translate(NULLIF("C3  Group Grievance", ''), '. ', ''), ',', '.')       AS numeric(18,2)),
  CAST(replace(translate(NULLIF("E3  Human Flight and Brain Drain", ''), '. ', ''), ',', '.') AS numeric(18,2)),
  CAST(replace(translate(NULLIF("E2  Economic Inequality", ''), '. ', ''), ',', '.')   AS numeric(18,2)),
  CAST(replace(translate(NULLIF("E1  Economy", ''), '. ', ''), ',', '.')               AS numeric(18,2)),
  CAST(replace(translate(NULLIF("P1  State Legitimacy", ''), '. ', ''), ',', '.')      AS numeric(18,2)),
  CAST(replace(translate(NULLIF("P2  Public Services", ''), '. ', ''), ',', '.')       AS numeric(18,2)),
  CAST(replace(translate(NULLIF("P3  Human Rights", ''), '. ', ''), ',', '.')          AS numeric(18,2)),
  CAST(replace(translate(NULLIF("C1  Security Apparatus", ''), '. ', ''), ',', '.')    AS numeric(18,2)),
  CAST(replace(translate(NULLIF("C2  Factionalized Elites", ''), '. ', ''), ',', '.')  AS numeric(18,2)),
  CAST(replace(translate(NULLIF("X1  External Intervention", ''), '. ', ''), ',', '.') AS numeric(18,2))
FROM temp_stage;


SELECT *
FROM public.fsi_2023
WHERE rn IN (
  (SELECT MIN(rn) FROM public.fsi_2023),
  (SELECT MAX(rn) FROM public.fsi_2023)
);

WITH r AS (
  SELECT
    *,
    substring("rank" from '^\d+')::int AS ranknum
  FROM public.fsi_2023
)
SELECT *
FROM r
ORDER BY ranknum ASC -- use DESC for the largest rank
LIMIT 1;  

