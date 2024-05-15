/*
2023 year S&P 500 data exploration
skills used: Joins, Case, Aggregate Functions, Windows Functions, CTE's, Temp Tables, Creating Views, Converting Data Types
*/


SELECT *
FROM [S&P 500 Project].[dbo].[companies]
ORDER BY symbol

SELECT *
FROM [S&P 500 Project]..yearreturn
ORDER BY 2


--------------------------------------------------------------------------------------------------------------------------

-- Basic company information

SELECT MIN(founded) AS oldest_company, MAX(founded) AS newest_company, MIN(CIK) AS oldest_IPO, MAX(CIK) AS newest_IPO
FROM companies;

SELECT *
FROM companies
WHERE founded IN (1784, 2019) OR cik IN (1800, 1996862);


--------------------------------------------------------------------------------------------------------------------------

-- Shows when companies are founded from oldest to newest in California

SELECT symbol, company, GICS_sector, GICS_sub_industry, headquarters_location, founded
FROM companies
WHERE founded IS NOT NULL
	AND headquarters_location LIKE '%alifornia%'
ORDER BY 6,5


--------------------------------------------------------------------------------------------------------------------------

-- Shows when companies are founded using centuries

SELECT symbol, company, GICS_sector, GICS_sub_industry, headquarters_location, CEILING(founded/100) AS century_founded
FROM companies
WHERE founded IS NOT NULL
ORDER BY 6


--------------------------------------------------------------------------------------------------------------------------

-- Number of companies with a secondary category

SELECT GICS_sector, GICS_sub_industry, COUNT(GICS_sub_industry) AS number_of_companies
FROM companies
WHERE GICS_sector = 'Industrials'
GROUP BY GICS_sector, GICS_sub_industry
ORDER BY number_of_companies DESC


--------------------------------------------------------------------------------------------------------------------------

-- Oldest and newest IPO dates by categories

SELECT GICS_sector, MIN(CONVERT(date, date_added)) AS oldest_date, MAX(CONVERT(date, date_added)) AS newest_date
FROM companies
GROUP BY GICS_sector
ORDER BY oldest_date ASC, newest_date DESC


--------------------------------------------------------------------------------------------------------------------------

-- Number of companies with categories

SELECT GICS_sector, COUNT(GICS_sector) AS number_of_companies, CAST(COUNT(GICS_sector) AS float)/500*100 AS percent_ratio
FROM companies
GROUP BY GICS_sector
ORDER BY number_of_companies DESC


-- However, there are three different companies that have the same Central Index Key

SELECT COUNT(DISTINCT CIK)
FROM companies

SELECT CIK
FROM companies
GROUP BY CIK
HAVING COUNT(CIK) > 1

SELECT *
FROM companies
WHERE CIK IN (1564708, 1652044, 1754301)


-- As a result, one of the queries above has to be filtered as below to be accurate

SELECT GICS_sector, COUNT(GICS_sector) AS number_of_companies, CAST(COUNT(GICS_sector) AS float)/500*100 AS percent_ratio
FROM companies
WHERE symbol NOT IN ('GOOGL', 'FOXA', 'NWSA')
GROUP BY GICS_sector
ORDER BY number_of_companies DESC


--------------------------------------------------------------------------------------------------------------------------

-- Yearly performance of individual companies

SELECT c.symbol, y.company, YTD_return,
CASE
	WHEN YTD_return LIKE '%-_.%' THEN 'bad'
	WHEN YTD_return LIKE '%-__.%' THEN 'very bad'
	WHEN YTD_return NOT LIKE '%-%' AND YTD_return LIKE '%1__.%' THEN 'great'
	WHEN YTD_return NOT LIKE '%-%' AND YTD_return LIKE '_____.%' THEN 'very good'
	ELSE 'good'
END AS performance
FROM companies AS c
LEFT JOIN yearreturn AS y
ON c.symbol = y.symbol


--------------------------------------------------------------------------------------------------------------------------

-- Yearly performance by industrial sectors

WITH combinedtable (symbol, GICS_sector, performance) AS
(
SELECT c.symbol, GICS_sector,
CASE
	WHEN YTD_return LIKE '%-%' THEN 'lost'
	ELSE 'earned'
END AS performance
FROM companies AS c
LEFT JOIN yearreturn AS y
ON c.symbol = y.symbol
)
SELECT GICS_sector, performance, COUNT(symbol) AS total
FROM combinedtable
GROUP BY GICS_sector, performance
ORDER BY 1


--------------------------------------------------------------------------------------------------------------------------

-- Completed table with yearly return in numeric data type

WITH perfecttable (symbol, company, sector, CIK, yr_return) AS
(
SELECT c.symbol, y.company, GICS_sector, CIK, CONVERT(float, REPLACE(YTD_return, '%', ' ')) AS year_return
FROM companies AS c
LEFT JOIN yearreturn AS y
ON c.symbol = y.symbol
)
SELECT *
FROM perfecttable
ORDER BY yr_return DESC



-- Using Temp Table to create perfecttable in previous query

DROP TABLE IF EXISTS pttemptable
CREATE TABLE pttemptable (
	symbol nvarchar(255),
	company nvarchar(255),
	sector nvarchar(255),
	CIK float,
	yr_return float
);

INSERT INTO pttemptable
SELECT c.symbol, y.company, GICS_sector, CIK, CONVERT(float, REPLACE(YTD_return, '%', ' ')) AS year_return
FROM companies AS c
LEFT JOIN yearreturn AS y
ON c.symbol = y.symbol;

SELECT *
FROM pttemptable
ORDER BY yr_return DESC



-- Creating View to to create perfecttable in previous query

CREATE VIEW ptviewtable AS
SELECT c.symbol, y.company, GICS_sector, CIK, CONVERT(float, REPLACE(YTD_return, '%', ' ')) AS year_return
FROM companies AS c
LEFT JOIN yearreturn AS y
ON c.symbol = y.symbol;

SELECT *
FROM ptviewtable


--------------------------------------------------------------------------------------------------------------------------

-- Rankings of profits for each sector

WITH pttwo AS
(
SELECT c.symbol, y.company, GICS_sector, CIK, CONVERT(float, REPLACE(YTD_return, '%', ' ')) AS year_return
FROM companies AS c
LEFT JOIN yearreturn AS y
ON c.symbol = y.symbol
)
SELECT *, RANK() OVER(PARTITION BY GICS_sector ORDER BY year_return DESC) AS ranking
FROM pttwo
ORDER BY GICS_sector, ranking


--------------------------------------------------------------------------------------------------------------------------

-- Average returns to compare for each sector when invested evenly

WITH ptthree AS
(
SELECT c.symbol, y.company, GICS_sector, CIK, CONVERT(float, REPLACE(YTD_return, '%', ' ')) AS year_return
FROM companies AS c
LEFT JOIN yearreturn AS y
ON c.symbol = y.symbol
)
SELECT *, ROUND(AVG(year_return) OVER(PARTITION BY GICS_sector), 2) AS avg_return
FROM ptthree
ORDER BY GICS_sector, year_return DESC



--------------------------------------------------------------------------------------------------------------------------
/* miscellaneous works & insignificant analysis */
--------------------------------------------------------------------------------------------------------------------------

-- Type of white spaces
-- CHAR(9): Horizontal Tab
-- CHAR(10): Line Feed
-- CHAR(13): Carriage Return
-- CHAR(32): Space
-- CHAR(160): Non-breaking Space

SELECT LEN(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(YTD_return, CHAR(9), ''), CHAR(10), ''), CHAR(13), ''), CHAR(32), ''), CHAR(160), ''))
FROM yearreturn



-- None of CHAR(9), CHAR(10), CHAR(13) or CHAR(32) worked
-- CHAR(160), non-break space, worked at last

SELECT YTD_return, LEN(YTD_return), LEN(TRIM(CHAR(160) FROM YTD_return))
FROM yearreturn



-- Yearly performance of individual companies using TRIM function and LEN function

WITH trimmedtable AS
(
SELECT c.symbol, y.company, TRIM(REPLACE(YTD_return, CHAR(160), ' ')) AS yearreturn
FROM companies AS c
LEFT JOIN yearreturn AS y
ON c.symbol = y.symbol
)
SELECT symbol, company, yearreturn,
CASE
	WHEN LEN(yearreturn) = 7 AND yearreturn LIKE '%-%' THEN 'very bad'
	WHEN LEN(yearreturn) = 6 AND yearreturn LIKE '%-%' THEN 'bad'
	WHEN LEN(yearreturn) = 7 AND yearreturn NOT LIKE '%-%' THEN 'great'
	WHEN LEN(yearreturn) = 6 AND yearreturn NOT LIKE '%-%' THEN 'very good'
	ELSE 'good'
END AS performance
FROM trimmedtable


--------------------------------------------------------------------------------------------------------------------------

-- CHARINDEX having troubles recognizing multiple commas such as strings with multiple headquarters
-- CHARINDEX returns only the position of first comma
-- AS a result, 'states' column has some rows with errors

SELECT headquarters_location,
SUBSTRING(headquarters_location, 1, CHARINDEX(',', headquarters_location) -1) AS city,
SUBSTRING(headquarters_location, CHARINDEX(',', headquarters_location) +1, LEN(headquarters_location)) AS states
FROM companies



-- Used CASE in order to filter multiple commas and special cases like UK

SELECT headquarters_location, SUBSTRING(headquarters_location, 1, CHARINDEX(',', headquarters_location) -1) AS city,
CASE 
	WHEN headquarters_location LIKE '%;%' THEN SUBSTRING(headquarters_location, CHARINDEX(',', headquarters_location) +2,
	CHARINDEX(';', headquarters_location) - CHARINDEX(',', headquarters_location) -2)
	WHEN headquarters_location LIKE '%kingdom%' THEN 'UK'
	ELSE SUBSTRING(headquarters_location, CHARINDEX(',', headquarters_location) +2, LEN(headquarters_location))
END AS states
FROM companies


--------------------------------------------------------------------------------------------------------------------------