SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

-- Select the data that we'll be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in every Country

SELECT location, date, total_cases, total_deaths, 
	(total_deaths / total_cases ) * 100 AS death_percetange
FROM CovidDeaths
ORDER BY location, date

-- Total cases vs Population
-- Shows what percentage of the population have gotten COVID

SELECT location, date, population, total_cases,  
	(total_cases/population) * 100 AS infected_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

-- Countries with the Highest Infection Rate compared to Population
-- Shows the 15 countries with the Highest Infection Rate

SELECT location, population, MAX (total_cases) AS highest_infection_count,  
	MAX ((total_cases/population) * 100) AS percent_of_population_infected
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_of_population_infected DESC
OFFSET 0 ROWS
FETCH NEXT 15 ROWS ONLY

-- Countries with Highest Death Count 

SELECT location, population, MAX (total_deaths) AS total_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY total_death_count DESC

-- LET'S BREAK THINGS DOWN BY CONTINENT
-- Showing continents with the Highest Death Count 

SELECT location,  MAX (total_deaths) AS total_death_count
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC
OFFSET 1 ROW
FETCH NEXT 7 ROWS ONLY

-- GLOBAL NUMBERS

SELECT date, SUM (new_cases) AS global_cases, SUM (CAST(new_deaths AS INT)) 
	AS global_deaths, SUM (CAST(new_deaths AS INT)) / SUM (new_cases) * 100 
	AS death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL AND location <> 'World'
GROUP BY date
ORDER BY date

-- Total Population vs Vaccinations over time per Location

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM (CONVERT(INT,vac.new_vaccinations)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS running_total_vaccines
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date

-- Using CTE to show % of Vaccination

WITH popvsvac (continent, location, date, population, new_vaccinations, running_total_vaccines)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM (CONVERT(INT,vac.new_vaccinations)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS running_total_vaccines
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

SELECT *, (running_total_vaccines / population) * 100 AS vaccinated_percentage
FROM popvsvac

-- Using a temp table to show MAX % of Vaccination per Location

DROP TABLE IF EXISTS #percertpopulationvaccinated

CREATE TABLE #percertpopulationvaccinated
(continent NVARCHAR(255), 
location NVARCHAR(255), 
date DATETIME, 
population NUMERIC, 
new_vaccinations NUMERIC, 
running_total_vaccines NUMERIC
)

INSERT INTO #percertpopulationvaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM (CONVERT(INT,vac.new_vaccinations)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS running_total_vaccines
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL


SELECT location, MAX ((running_total_vaccines / population) * 100) AS vaccinated_percentage
FROM #percertpopulationvaccinated
GROUP BY location
ORDER BY location

-- Create View for later visualization

CREATE VIEW population_with_covid AS
SELECT location, date, population, total_cases,  
	(total_cases/population) * 100 AS infected_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
