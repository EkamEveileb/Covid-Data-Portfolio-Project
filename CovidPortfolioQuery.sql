--			LOOKING AT OUR DATA

SELECT *
FROM CovidDeaths
ORDER BY 3,4

SELECT *
FROM CovidVaccinations
ORDER BY 3,4

--			CHANGING DATA TYPES

ALTER TABLE CovidDeaths
ALTER COLUMN Date DATE

ALTER TABLE CovidVaccinations
ALTER COLUMN Date DATE

--			SELECT THE DATA THAT WILL BE USED

SELECT location, Date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2

--			LOOKING AT TOTAL CASES VS TOTAL DEATHS (LIKELIHOOD OF DYING WHEN HAVING COVID)

SELECT location, Date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercent
FROM CovidDeaths
WHERE location LIKE 'Lithuania'
ORDER BY 1,2

--			LOOKING AT TOTAL CASES VS POPULATION (LIKELIHOOD OF HAVING COVID AT ANY POINT)

SELECT location, Date, population, total_cases, (total_cases/population)*100 AS CovidPercent
FROM CovidDeaths
WHERE location LIKE 'Lithuania'
ORDER BY 1,2

--			LOOKING AT COUNTRY WITH HIGHEST INFECTION RATE COMPARED TO POPULATION

SELECT location, population, MAX(total_cases) AS MaxTotalCases, MAX((total_cases/population)*100) AS MAXCovidPercent
FROM CovidDeaths
GROUP BY location,population
ORDER BY 4 DESC

--			LOOKING AT COUNTRY WITH HIGHEST DEATH COUNT

SELECT location, MAX(CAST(total_deaths AS BIGINT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC

--			LOOKING AT PARTS OF THE WORLD WITH HIGHEST DEATH COUNT

SELECT location, MAX(CAST(total_deaths AS BIGINT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NULL 
	AND location IN ('Europe', 'Asia', 'North America', 'South America', 'Africa', 'Oceania')
GROUP BY location
ORDER BY 2 DESC

--			GLOBAL NUMBERS 

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercent
FROM CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 2 DESC

--			TOTAL POPULATION VS VACCINATION

SELECT dea.continent, dea.location, dea.date, dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(BIGINT, vac.new_vaccinations))
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccination
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3

--			USING CTE FOR CALCULATIONS BASED ON AGRIGATED NUMBERS

WITH PopVsVac (continent,location,date, population, new_vaccinations, RollingVaccination)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(BIGINT, vac.new_vaccinations))
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccination
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
)
SELECT *, (RollingVaccination/population)
FROM PopVsVac
ORDER BY 2,3


--			USING TEMP TABLE FOR CALCULATIONS BASED ON AGRIGATED NUMBERS

DROP TABLE IF EXISTS #PopVsVac

CREATE TABLE #PopVsVac
(
continent NVARCHAR(255),
location NVARCHAR(255),
date DATE,
population BIGINT,
new_vaccinations NUMERIC,
RollingVaccination NUMERIC
)

INSERT INTO #PopVsVac
SELECT dea.continent, dea.location, dea.date, dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(BIGINT, vac.new_vaccinations))
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccination
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 

SELECT *, (RollingVaccination/population)*100
FROM #PopVsVac
WHERE RollingVaccination IS NOT NULL
ORDER BY 2,3

--			VACCINATION PERCENTAGE GLOBAL RATING

SELECT 
	Location,
	MAX(population) AS CurrentPopulation, 
	CAST(MAX(RollingVaccination/population)*100 AS DECIMAL(10,3)) AS VaccinationPercentage
FROM #PopVsVac
WHERE RollingVaccination IS NOT NULL
GROUP BY location
ORDER BY 3 DESC

--			CREATING VIEW TO STORE DATA FOR VISUALISATIONS

/*
DROP VIEW IF EXISTS PopVsVac
*/
CREATE VIEW PopVsVac AS
SELECT dea.continent, dea.location, dea.date, dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(BIGINT, vac.new_vaccinations))
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccination
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 

SELECT *
FROM PopVsVac
