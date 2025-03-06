-- Dataset:  https://www.kaggle.com/datasets/bushraqurban/tourism-and-economic-impact

-------------------------------------------------------------------------------------------------

-- Allocating unconsisting data by finding the the unnecessary rows that has big impact on the dataset

SELECT * FROM world_tourism_economy
ORDER BY tourism_receipts DESC;

-------------------------------------------------------------------------------------------------

-- This query is designed to identify non numeric data in the table using REGEXP function 


SELECT * FROM world_tourism_economy
WHERE tourism_receipts NOT REGEXP '^[0-9]+$'
	OR tourism_arrivals NOT REGEXP '^[0-9]+$'
    OR tourism_exports NOT REGEXP '^[0-9.]+$'
    OR tourism_departures NOT REGEXP '^[0-9]+$'
    OR tourism_expenditures NOT REGEXP '^[0-9.]+$'
    OR gdp NOT REGEXP '^[0-9.]+$'
    OR inflation NOT REGEXP '^[0-9.]+$'
    OR unemployment NOT REGEXP '^[0-9.]+$'
;

-------------------------------------------------------------------------------------------------

-- Updates column data types in the dataset from text format to a more convinent format

ALTER TABLE world_tourism_economy
MODIFY year INT,
MODIFY tourism_receipts BIGINT,
MODIFY tourism_arrivals BIGINT,
MODIFY tourism_exports DECIMAL(30, 10),
MODIFY tourism_departures BIGINT,
MODIFY tourism_expenditures DECIMAL(30, 10),
MODIFY inflation DECIMAL(10, 5),
MODIFY gdp DECIMAL(20, 2),
MODIFY unemployment DECIMAL(10, 2);

-------------------------------------------------------------------------------------------------

-- Deleting rows with unnecessary regions from the country column

DELETE FROM world_tourism_economy
WHERE 
    country LIKE '%Asia%'
    OR country LIKE '%High income%'
    OR country LIKE '%Euro%'
    OR country LIKE 'Post-demographic dividend'
    OR country LIKE 'OECD members'
    OR country LIKE 'Early-demographic dividend'
    OR country LIKE 'Arab World'
    OR country LIKE 'Lower middle income'
	OR country LIKE 'Least developed countries: UN classification'
    OR country LIKE 'Heavily indebted poor countries (HIPC)'
    OR country LIKE 'Pre-demographic dividend'
    OR country LIKE 'Fragile and conflict affected situations'
    OR country LIKE 'IBRD only'
	OR country LIKE 'Late-demographic dividend' 
    OR country LIKE '%income%'
    OR country LIKE 'IDA%'
    OR country LIKE '%small%'
    OR (country LIKE '%america%' AND country NOT LIKE 'American Samoa')
    OR (country LIKE '%africa%' 
        AND country NOT IN ('South Africa', 'Central African Republic'));
        
-------------------------------------------------------------------------------------------------

-- checking up if any duplicate. row_num only shows 1 value then we have no duplicates on our dataset 
 
SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY country, year ORDER BY country) AS row_num
FROM world_tourism_economy
ORDER BY row_num DESC
;

-------------------------------------------------------------------------------------------------

/* Comparing between the North African countries in 2019 tourism receipts. 
Countries are labeled as 'Competitive' if their receipts exceed the average, and the rest as 'Non Competitive'. */

WITH CTE AS (
    SELECT AVG(tourism_receipts) AS Average_Receipt 
    FROM world_tourism_economy
    WHERE year = 2019 
		AND country IN ('Morocco', 'Algeria', 'Tunisia', 'Libya', 'Egypt, Arab Rep.')
)

SELECT 
    country, 
    tourism_receipts, 
    CASE 
        WHEN tourism_receipts > CTE.Average_Receipt THEN 'Competitive' ELSE 'Non Competitive' 
        END AS Performance
FROM world_tourism_economy, CTE
WHERE year = 2019 
  AND country IN ('Morocco', 'Algeria', 'Tunisia', 'Libya', 'Egypt, Arab Rep.');

-------------------------------------------------------------------------------------------------

-- Comparing Morocco and Tunisia's average KPIs (1999-2020): 

SELECT 
    country,
    ROUND(AVG(tourism_receipts)) AS avg_tourism_receipts, 
    ROUND(AVG(tourism_arrivals)) AS avg_tourism_arrivals, 
    ROUND(AVG(gdp)) AS avg_gdp, 
    ROUND(AVG(unemployment),2) AS avg_unemployment
FROM world_tourism_economy
WHERE country IN ('Morocco', 'Tunisia') 
    AND year BETWEEN 1999 AND 2020
GROUP BY country
ORDER BY country;

-- Similar tourist arrivals but Morocco's tourism receipts are more than double Tunisia's.

-------------------------------------------------------------------------------------------------

/* Analyzing yearly changes in tourism receipts, identifying the leading country, 
and comparing Morocco vs. Tunisia (1999-2020) */

SELECT MAR.year,  
       MAR.tourism_receipts AS Morocco_Receipts,
       MAR.tourism_receipts - LAG(MAR.tourism_receipts) OVER (ORDER BY MAR.year) AS MAR_Yearly_Change,
       TUN.tourism_receipts AS Tunisia_Receipts,
       TUN.tourism_receipts - LAG(TUN.tourism_receipts) OVER (ORDER BY MAR.year) AS TUN_Yearly_Change,
       CASE WHEN MAR.tourism_receipts > TUN.tourism_receipts 
			THEN 'Morocco' ELSE 'Tunisia' END AS Receipts_leader,
       ABS(MAR.tourism_receipts - TUN.tourism_receipts) AS MAR_TUN_Difference
FROM world_tourism_economy MAR
JOIN world_tourism_economy TUN ON MAR.year = TUN.year
WHERE MAR.country = 'Morocco' AND TUN.country = 'Tunisia'
AND MAR.year BETWEEN 1999 AND 2020
ORDER BY MAR.year;

-------------------------------------------------------------------------------------------------

/* Analyzing yearly changes in tourism arrivals, identifying the leading country, 
and comparing Morocco vs. Tunisia (1999-2020) */

SELECT MAR.year,  
       MAR.tourism_arrivals AS Morocco_arrivals,
       MAR.tourism_arrivals - LAG(MAR.tourism_arrivals) OVER (ORDER BY MAR.year) AS MAR_Yearly_Change,
       TUN.tourism_arrivals AS Tunisia_arrivals,
       TUN.tourism_arrivals - LAG(TUN.tourism_arrivals) OVER (ORDER BY MAR.year) AS TUN_Yearly_Change,
       CASE WHEN MAR.tourism_arrivals > TUN.tourism_arrivals
			THEN 'Morocco' ELSE 'Tunisia' END AS Arrivals_leader,
       ABS(MAR.tourism_arrivals - TUN.tourism_arrivals) AS MAR_TUN_Difference
FROM world_tourism_economy MAR
JOIN world_tourism_economy TUN ON MAR.year = TUN.year
WHERE MAR.country = 'Morocco' AND TUN.country = 'Tunisia'
AND MAR.year BETWEEN 1999 AND 2020
ORDER BY MAR.year;

-------------------------------------------------------------------------------------------------

/* Despite Tunisia having more arrivals between 1999 and 2005, Morocco has consistently led in tourism 
receipts, which displays that Morocco’s tourism industry is attracting higher-spending tourists */

-------------------------------------------------------------------------------------------------

/* Year-by-year analysis of tourism arrivals, tourism receipts, inflation, and unemployment both 
in Morocco and Tunisia from 1999 to 2020. */

SELECT MAR.year,
       CASE WHEN MAR.tourism_arrivals > TUN.tourism_arrivals
			THEN 'Morocco' ELSE 'Tunisia' END AS Arrivals_leader,
       ABS(MAR.tourism_arrivals - TUN.tourism_arrivals) AS Arrivals_Difference,
       CASE WHEN MAR.tourism_receipts > TUN.tourism_receipts
			THEN 'Morocco' ELSE 'Tunisia' END AS Receipts_leader,
       ABS(MAR.tourism_receipts - TUN.tourism_receipts) AS Receipts_Difference,
       MAR.inflation MAR_inflation,
       MAR.unemployment MAR_unemployment,
       TUN.inflation TUN_inflation,
       TUN.unemployment TUN_unemployment
FROM world_tourism_economy MAR
JOIN world_tourism_economy TUN ON MAR.year = TUN.year
WHERE MAR.country = 'Morocco' AND TUN.country = 'Tunisia'
AND MAR.year BETWEEN 1999 AND 2020
ORDER BY MAR.year;

-------------------------------------------------------------------------------------------------

-- Comparing Moroccan vs Tunisian expenditures (1999 - 2020)

SELECT MAR.year, MAR.tourism_expenditures AS MAR_expenditures, TUN.tourism_expenditures AS TUN_expenditures
FROM world_tourism_economy MAR
JOIN world_tourism_economy TUN ON MAR.year = TUN.year
WHERE MAR.country = 'Morocco' AND TUN.country = 'Tunisia'
AND MAR.year BETWEEN 1999 AND 2020
ORDER BY MAR.year;

-------------------------------------------------------------------------------------------------

/* From the last two queries we can the conclued the following:

From 1999 to 2020, Morocco consistently outperformed Tunisia in tourism receipts, despite Tunisia 
having higher tourism arrivals in certain years. This is likely due to Morocco offering higher-value 
and more diverse tourism experiences, even at a higher cost. 

While Morocco saw a steady decline in unemployment and a relatively stable inflation rate, Tunisia faced 
economic instability with higher inflation and persistent unemployment, especially during 
the Arab Spring (2010), an event that allowed Morocco to shine even more in the North African/Arab World's 
tourism markets.

Additionally, Morocco demonstrated a stronger investment in its tourism sector, as evidenced by its higher 
tourism expenditures as a percentage of imports. While Morocco often reached 4 to 7 percent, 
Tunisia consistently lagged behind at around 2 to 3 percent, with only a rare peak at 5 percent in 2018-2019. 
This disparity indicates that Morocco's commitment to investing in tourism likely contributed to its sustained
success and higher receipts, positioning it as a more competitive destination in the region. */

-------------------------------------------------------------------------------------------------
/* Ranking the top worlds income generating contries from tourism in 2019, the ranking changing by 2020 and 
the dropping percentage of the tourist receipts caused by COVID-19 */

WITH CTE_2019 AS (
    SELECT 
        country, 
        tourism_receipts, 
        tourism_arrivals, 
        tourism_exports, 
        gdp, 
        RANK() OVER (ORDER BY tourism_receipts DESC) AS Country_Rank
    FROM world_tourism_economy
    WHERE country NOT LIKE 'World' 
      AND year = 2019
),
CTE_2020 AS (
    SELECT 
        country, 
        tourism_receipts, 
        tourism_arrivals, 
        tourism_exports, 
        gdp, 
        RANK() OVER (ORDER BY tourism_receipts DESC) AS Country_Rank
    FROM world_tourism_economy
    WHERE country NOT LIKE 'World' 
      AND year = 2020
)

SELECT T19.country, T19.Country_Rank AS Rank_2019, T20.Country_Rank AS Rank_2020, 
       T19.tourism_receipts AS Receipts_2019, T20.tourism_receipts AS Receipts_2020,
       ROUND(100*(T20.tourism_receipts - T19.tourism_receipts)/T19.tourism_receipts,2) Receipts_change_pct
FROM CTE_2019 T19
LEFT JOIN CTE_2020 T20 ON T19.country = T20.country
WHERE T19.Country_Rank <= 15 AND T20.Country_Rank <= 15
ORDER BY Rank_2019;

-------------------------------------------------------------------------------------------------

-- Identifying countries with economies highly dependent on tourism

SELECT country, tourism_receipts, gdp, ROUND(100*tourism_receipts/gdp,2) AS Receipts_GDP_pct
FROM world_tourism_economy
WHERE year = 2019 AND country NOT LIKE 'world'
ORDER BY Receipts_GDP_pct DESC
LIMIT 20
;

/* From the results we notice that the top countries on this list are either tiny geographically (like islands or
independent cities), or economically weak that they mainly just survive on tourism */

-------------------------------------------------------------------------------------------------

-- Ranking the top 20 countries in terms of tourism receipts per tourist in 2019

SELECT country, ROUND(tourism_receipts/tourism_arrivals,2) AS Receipts_per_tourist
FROM world_tourism_economy
WHERE year = 2019 AND country NOT LIKE 'world'
ORDER BY Receipts_per_tourist DESC
LIMIT 20
;

-------------------------------------------------------------------------------------------------

-- The country with the top economic benefit per tourist vs the lowest spending tourist country

WITH CTE AS (
    SELECT 
        country, 
        tourism_receipts/tourism_arrivals AS Receipts_per_tourist
    FROM world_tourism_economy
    WHERE year = 2019 
      AND country NOT LIKE 'world'
)

SELECT * 
FROM CTE
WHERE Receipts_per_tourist = (SELECT MAX(Receipts_per_tourist) FROM CTE)
   OR Receipts_per_tourist = (SELECT MIN(Receipts_per_tourist) FROM CTE);
