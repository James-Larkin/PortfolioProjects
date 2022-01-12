-- Showing Total Cases vs Total Deaths, and the Fatality Rate
SELECT location, date, total_cases, total_deaths, 
(total_deaths/total_cases) * 100 AS fatality_rate
FROM coviddeaths
WHERE location LIKE '%ireland%'
ORDER BY 1, 2

-- Showing Total Cases vs Population, and the Infection Rate 
SELECT location, date, total_cases, total_deaths, 
(total_cases/population) * 100 AS infection_rate 
FROM coviddeaths WHERE location LIKE '%ireland%' 
ORDER BY 1, 2;

-- Showing Highest Infection Rate Countries
SELECT location, population, MAX(total_cases) AS highest_infection_count, 
MAX((total_cases/population))*100 AS infection_rate
FROM coviddeaths 
GROUP BY location, population
ORDER BY infection_rate DESC;

-- Showing Highest Death Rate Countries
SELECT location, MAX(cast(total_deaths as int)) AS total_death_count
FROM coviddeaths 
WHERE continent <>'' 
GROUP BY location
ORDER BY total_death_count DESC;

-- Showing Global Infections, Deaths and Fatality Rate
SELECT SUM(new_cases) as total_infections, SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as fatality_rate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Showing Global Numbers by Date
SELECT date, SUM(new_cases) as total_infections, SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as fatality_rate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2


-- Showing Rolling Vax Count, Rolling Percentage Vaxxed
-- 1. Using a CTE
WITH PopVsVac (continent, location, date, population, new_vaccinations, rolling_vax_count)
AS
(
SELECT T1.continent, T1.location, T1.date, T1.population, T2.new_vaccinations, 
SUM(CONVERT(bigint, T2.new_vaccinations)) 
OVER (Partition by T1.location ORDER BY T1.location, T1.date) AS rolling_vax_count
FROM PortfolioProject..CovidDeaths T1
JOIN PortfolioProject..CovidVaccines T2
	ON T1.location = T2.location
	AND T1.date = T2.date
WHERE T1.continent IS NOT NULL 
)
SELECT *, (rolling_vax_count/population)*100 As percentage_vaccinated
FROM PopVsVac

-- Using a Temp Table
DROP TABLE IF EXISTS #PercentPopVax
CREATE TABLE #PercentPopVax
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime, 
Population numeric,
New_vaccinations numeric, 
Rolling_vax_count numeric
)

Insert into #PercentPopVax
SELECT T1.continent, T1.location, T1.date, T1.population, T2.new_vaccinations, 
SUM(CONVERT(bigint, T2.new_vaccinations)) 
OVER (Partition by T1.location ORDER BY T1.location, T1.date) AS rolling_vax_count
FROM PortfolioProject..CovidDeaths T1
JOIN PortfolioProject..CovidVaccines T2
	ON T1.location = T2.location
	AND T1.date = T2.date
WHERE T1.continent IS NOT NULL 

SELECT *, (rolling_vax_count/population)*100 As percentage_vaccinated
FROM #PercentPopVax

-- 3. Creating a View
CREATE VIEW PercentPopulationVaccinated AS 
SELECT T1.continent, T1.location, T1.date, T1.population, T2.new_vaccinations, 
SUM(CONVERT(bigint, T2.new_vaccinations)) 
OVER (Partition by T1.location ORDER BY T1.location, T1.date) AS rolling_vax_count
FROM PortfolioProject..CovidDeaths T1
JOIN PortfolioProject..CovidVaccines T2
	ON T1.location = T2.location
	AND T1.date = T2.date
WHERE T1.continent IS NOT NULL 

SELECT * FROM PercentPopulationVaccinated
