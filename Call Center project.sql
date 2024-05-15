/*
Cleaning Data in SQL Queries for Call Center Project
*/

SELECT *
FROM [Call Center Project].dbo.callcenter


-- Creating a temporary table to protect raw data in the original table

DROP TABLE IF EXISTS temptable

SELECT TOP 0 *
INTO temptable
FROM callcenter

INSERT INTO temptable
SELECT *
FROM callcenter

SELECT *
FROM temptable


--------------------------------------------------------------------------------------------------------------------------

-- Standardize date format

SELECT call_timestamp, CONVERT(date, call_timestamp) AS call_timestamp_converted
FROM temptable

ALTER TABLE temptable
ALTER COLUMN call_timestamp date


-- If it doesn't ALTER properly, then UPDATE

ALTER TABLE temptable
ADD call_timestamp_converted date

UPDATE temptable
SET call_timestamp_converted = CONVERT(date, call_timestamp)


 --------------------------------------------------------------------------------------------------------------------------

-- Populate csat_score data or filling NULL values with string data type

SELECT *
FROM temptable

ALTER TABLE temptable
ALTER COLUMN csat_score nvarchar(255)

UPDATE temptable
SET csat_score = ISNULL(csat_score, 'Unknown')


--------------------------------------------------------------------------------------------------------------------------

-- Breaking out address into individual columns (city, state)

SELECT call_center
FROM temptable

SELECT SUBSTRING( call_center , 1 , CHARINDEX('/', call_center) -1 ) AS city, 
SUBSTRING( call_center , CHARINDEX('/', call_center) + 1 , LEN(call_center) ) AS states
FROM temptable


ALTER TABLE temptable
ADD call_center_split_city nvarchar(255);

UPDATE temptable
SET call_center_split_city = SUBSTRING( call_center , 1 , CHARINDEX('/', call_center) -1 )

ALTER TABLE temptable
ADD call_center_split_state nvarchar(255);

UPDATE temptable
SET call_center_split_state = SUBSTRING( call_center , CHARINDEX('/', call_center) + 1 , LEN(call_center) )


SELECT *
FROM temptable


-- breaking out the address using different method

SELECT
PARSENAME(REPLACE(call_center, '/', '.'), 2) AS splited_city, 
PARSENAME(REPLACE(call_center, '/', '.'), 1) AS splited_state
FROM temptable


ALTER TABLE temptable
ADD call_center_splited_city nvarchar(255)

UPDATE temptable
SET call_center_splited_city = PARSENAME(REPLACE(call_center, '/', '.'), 2)

ALTER TABLE temptable
ADD call_center_splited_state nvarchar(255)

UPDATE temptable
SET call_center_splited_state = PARSENAME(REPLACE(call_center, '/', '.'), 1)


SELECT *
FROM temptable


--------------------------------------------------------------------------------------------------------------------------

-- Change 'Call-Center' to 'Calling' in "channel" field

SELECT DISTINCT channel
FROM temptable

SELECT channel, COUNT(id)
FROM temptable
GROUP BY channel
ORDER BY 2

SELECT channel,
CASE WHEN channel = 'Call-Center' THEN 'Calling'
	 ELSE channel
	 END AS new_channel
FROM temptable

UPDATE temptable
SET channel = CASE WHEN channel = 'Call-Center' THEN 'Calling'
			  ELSE channel
			  END


SELECT *
FROM temptable


-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove duplicates

WITH Row_num_cte AS
(
SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_name,
	                                      sentiment,
	                                      call_timestamp_converted,
	                                      reason,
	                                      channel ORDER BY call_timestamp_converted) AS row_num
FROM temptable
)
DELETE
FROM Row_num_cte
WHERE row_num > 1


---------------------------------------------------------------------------------------------------------

-- Delete unused columns


SELECT *
FROM temptable


ALTER TABLE temptable
DROP COLUMN call_timestamp, call_center, call_center_splited_city, call_center_splited_state



---------------------------------------------------------------------------------------------------------
/* Miscellaneous */

-- Copying a table at once without INSERT statement

DROP TABLE IF EXISTS temptable2

SELECT *
INTO temptable2
FROM callcenter
--WHERE 1 = 0                   -- same as TOP 0



---------------------------------------------------------------------------------------------------------