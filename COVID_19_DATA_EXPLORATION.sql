

--EXEC sp_columns 'Covid_Deaths_25';
--EXEC sp_columns 'Covid_Vaccinations_25';

 -- > SHOWS THE NUMBER OF COLUMNS IN BOTH TABLES. 

--DROP TABLE Covid_Deaths_25;
--DROP TABLE Covid_Vaccinations_25;

  --- > DELETES THE ENTIRE TABLE(S) FROM THE DATABASE (IF EXISTS)


-- --BASIC FETCH COMMANDS FOR ALL DATA FROM 2 TABLES :
SELECT *
FROM Covid19_Analysis25.dbo.CovidDeaths_DATA
WHERE continent != ''
ORDER BY 3;


SELECT *
FROM Covid19_Analysis25.dbo.CovidVaccinations_DATA
WHERE continent != ''
ORDER BY 3;


----------------------------------------------------------------------------------------------------------------------
							--STAGE 1 : STANDARDIZING THE DATE-FORMAT :




SELECT TOP 10 *
FROM Covid19_Analysis25.dbo.CovidDeaths_DATA;

						-- CovidDeaths_DATA  TABLE :

--Step 1: Back up the date column in a NEW COLUMN ->'date' (recommended) :
 ALTER TABLE CovidDeaths_DATA
ADD date_backup VARCHAR(50);  -- Adjust size as needed

UPDATE CovidDeaths_DATA
SET date_backup = [date];

--Step 2: Convert and update the 'date' column in place to a 'DATE' Datatype FORMAT.

UPDATE CovidDeaths_DATA
SET date = TRY_CONVERT(DATE, REPLACE([date], '-', '/'), 103);




SELECT TOP 10 *
FROM Covid19_Analysis25.dbo.CovidVaccinations_DATA;


							-- CovidVaccinations_DATA  TABLE :


--Step 1: Back up the date column in a NEW COLUMN ->'date' (recommended) :
 ALTER TABLE CovidVaccinations_DATA
ADD date_backup VARCHAR(50);  -- Adjust size as needed

UPDATE CovidVaccinations_DATA
SET date_backup = [date];

--Step 2: Convert and update the 'date' column in place to a 'DATE' Datatype FORMAT.

UPDATE CovidVaccinations_DATA
SET date = TRY_CONVERT(DATE, REPLACE([date], '-', '/'), 103);





----------------------------------------------------------------------------------------------------------------------									
								--STAGE 2 : ANALYSIS    : 


--1)  1st SELECTION : 

SELECT location,date, total_cases, new_cases, total_deaths, population
FROM Covid19_Analysis25.dbo.CovidDeaths_DATA; 

UPDATE Covid19_Analysis25.dbo.CovidDeaths_DATA
SET new_cases = NULL
WHERE new_cases = 0; 


UPDATE Covid19_Analysis25.dbo.CovidDeaths_DATA
SET new_cases = 0
WHERE new_cases = NULL;


--2) TOTAL CASES Vs. TOTAL DEATHS : MORTALITY RATE IN THE WORLD (%) (CALCULATE % OF PPL DYING [MORTALITY RATE, %])

SELECT location,date, total_cases, total_deaths, total_deaths/NULLIF(total_cases,0)*100 AS 'MORTALITY_RATE (%)'
FROM Covid19_Analysis25.dbo.CovidDeaths_DATA
WHERE continent != ''
ORDER BY 1;
--MORTALITY RATE = 0 ; TOTAL_DEATHS = 0, INSPITE OF COVID-CASES

--3) TOTAL CASES Vs. TOTAL DEATHS : MORTALITY RATE IN 'INDIA' (%) : 

SELECT location,date, total_cases, total_deaths, total_deaths/NULLIF(total_cases,0)*100 AS 'MORTALITY_RATE (%)'
FROM Covid19_Analysis25.dbo.CovidDeaths_DATA
WHERE location LIKE 'India%'
AND  continent != ''



--3) TOTAL CASES Vs. POPULATION : (CALCULATE % POPULATION INFECTED(%))

SELECT location,date, total_cases, population, total_cases/NULLIF(population,0)*100  AS '% INFECTED(%)'
FROM Covid19_Analysis25.dbo.CovidDeaths_DATA
WHERE continent != ''
ORDER BY 1,2;

--4)  MAX(TOTAL CASES) Vs. POPULATION W.R.T COUNTRIES  -> COUNTRIES WITH  HIGHEST 'INFECTION  COUNT'/ 'HEAD' W.R.T COUNTRIES :

SELECT location, MAX(total_cases) AS HIGHEST_INFECTED_COUNTRY_COUNT ,population, MAX(total_cases/NULLIF(population,0))*100  AS 'MAX % INFECTED(%)'
FROM Covid19_Analysis25.dbo.CovidDeaths_DATA
WHERE continent != ''
GROUP BY  location, population
ORDER BY 'MAX % INFECTED(%)' DESC;

 --17.12%


--5)  MAX(TOTAL DEATHS) Vs. POPULATION W.R.T COUNTRIES  -> COUNTRIES/LOCATIONS  WITH  HIGHEST 'DEATH COUNT'/ 'HEAD' W.R.T COUNTRIES :

SELECT location, MAX(total_deaths) AS HIGHEST_DEATH_COUNTPER_HEAD_COUNTRY ,population, MAX(total_deaths/NULLIF(population,0))*100  AS '% DEATH COUNT (%)'
FROM Covid19_Analysis25.dbo.CovidDeaths_DATA
WHERE continent != ''
GROUP BY  location, population
ORDER BY '% DEATH COUNT (%)' DESC;




--6)   BY LOCATION - > COUNTRIES/LOCATIONS  WITH  HIGHEST 'DEATH COUNT' W.R.T COUNTRIES :

SELECT location, MAX(total_deaths) AS HIGHEST_DEATH_COUNT_COUNTRY 
FROM Covid19_Analysis25.dbo.CovidDeaths_DATA
WHERE continent != ''
GROUP BY  location
ORDER BY  HIGHEST_DEATH_COUNT_COUNTRY  DESC;


--7)   BY CONTINENT - > ('CONTIENT' -> NOT EMPTY STRING VALUES) COUNTRIES/LOCATIONS(shown as CONTINENTS)  WITH  HIGHEST 'DEATH COUNT'/ 'HEAD' W.R.T COUNTRIES :

SELECT continent, MAX(total_deaths) AS HIGHEST_DEATH_COUNT_COUNTRY 
FROM Covid19_Analysis25.dbo.CovidDeaths_DATA
WHERE continent != ''
GROUP BY  continent
ORDER BY  HIGHEST_DEATH_COUNT_COUNTRY  DESC;



--8) BY CONTINENT - > ('CONTIENT' -> ARE EMPTY STRING VALUES) CONTINENTS  WITH  HIGHEST 'DEATH COUNT'/ 'HEAD' W.R.T COUNTRIES :

SELECT continent, location, MAX(total_deaths) AS HIGHEST_DEATH_COUNT_COUNTRY 
FROM Covid19_Analysis25.dbo.CovidDeaths_DATA
WHERE continent = ''
GROUP BY  location, continent
ORDER BY  HIGHEST_DEATH_COUNT_COUNTRY  DESC;



--9) GLOBAL NUMBERS : (DELETE THIS FROM UR ACTUAL ANALYSIS) -- OPTIONAL*** 

--SELECT date, SUM(new_cases) AS TOTAL_NEW_CASES, SUM(new_deaths), SUM(new_deaths)/SUM(new_cases)*100 AS 'LATEST_MORTALITY_RATE (%)'
--FROM Covid19_Analysis25.dbo.CovidDeaths_DATA
--WHERE continent != ''
--GROUP BY date
--ORDER BY date;




										---------PART 2--------- :  JOINS, GROUP BY, ORDER BY etc

--10) JOIN BOTH THE TABLES TO PERFORM OPERATIONS ON ALL RELATED COLUMNS IN BOTH OF THEM : 

SELECT * 
FROM Covid19_Analysis25.dbo.CovidDeaths_DATA AS d
JOIN Covid19_Analysis25.dbo.CovidVaccinations_DATA AS v
	ON d.location = v.location
	AND d.date = d.date
	ORDER BY d.continent



--10) SELECT THE TOTAL POPULATIONS Vs. VACCINATIONS :

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations AS v
FROM Covid19_Analysis25.dbo.CovidDeaths_DATA AS d
JOIN Covid19_Analysis25.dbo.CovidVaccinations_DATA AS v
	ON d.location = v.location
	AND d.date = v.date
	WHERE d.continent <> ''
ORDER BY v.location,v.date;




--Outliers in Death Rate (Where death rate > 10%)

SELECT location, date,total_cases,total_deaths,
       ROUND(total_deaths * 100.0 / NULLIF(total_cases, 0), 2) AS '% DEATH RATE(%)'
FROM CovidDeaths_DATA
WHERE continent != ''
    AND total_cases > 1000
    AND total_deaths * 100.0 / total_cases > 15
	GROUP BY location,date,total_cases,total_deaths
	ORDER BY '% DEATH RATE(%)' DESC;





					  ---------PART 3--------- :  CREATING VIEWS TO STORE DATA FOR LATER VISUALIZATION



--1) VIEW OF "HIGHEST DEATH COUNTS" : 

CREATE VIEW HighestDeathCounts AS
SELECT continent, MAX(total_deaths) AS HIGHEST_DEATH_COUNT_COUNTRY 
FROM Covid19_Analysis25.dbo.CovidDeaths_DATA
WHERE continent != ''
GROUP BY  continent


SELECT * FROM HighestDeathCounts
ORDER BY HIGHEST_DEATH_COUNT_COUNTRY DESC;


 --2) VIEW OF OUTLIER DEATH RATES : 

CREATE VIEW OUTLIERS_DeathRates AS
SELECT location, date,total_cases,total_deaths,
       ROUND(total_deaths * 100.0 / NULLIF(total_cases, 0), 2) AS '% DEATH RATE(%)'
FROM CovidDeaths_DATA
WHERE continent != ''
    AND total_cases > 1000
    AND total_deaths * 100.0 / total_cases > 15
	GROUP BY location,date,total_cases,total_deaths

SELECT * 
FROM OUTLIERS_DeathRates; 








