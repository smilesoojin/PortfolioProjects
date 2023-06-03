-- Portfolio Project 1

-- Covid Data Exploration with SQL
-- Data from https://ourworldindata.org/covid-deaths
-- Data tables saved as CovidDeaths & CovidVaccinations


-- Quick look at both tables (ordered by location & date)
SELECT *
FROM PortfolioProject1..CovidDeaths
ORDER BY 3,4

SELECT *
FROM PortfolioProject1..CovidVaccinations
ORDER BY 3,4

-- Selecting data of interest
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject1..CovidDeaths
ORDER BY 1,2

-- Total Cases vs. Total Deaths
-- Shows the likelihood of dying from Covid in the United States
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject1..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

-- Total Cases vs. Population
-- Percentage of population who got Covid in the United States
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject1..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

-- Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject1..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Countries with Highest Death Rate compared to Population
SELECT location, MAX(CAST(total_deaths AS BIGINT)) AS TotalDeathCount
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Continents with Highest Death Count per Population (North America only contains count from US not Canada)
SELECT continent, MAX(CAST(total_deaths AS BIGINT)) AS TotalDeathCount
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Continents with Highest Death Count per Population (A little tweak so that North America contains both US & Canada)
-- This shows more than what we need but the numbers are more accurate
SELECT location, MAX(CAST(total_deaths AS BIGINT)) AS TotalDeathCount
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Global Numbers per date
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS BIGINT)) AS total_deaths, SUM(CAST(new_deaths AS BIGINT))/SUM(new_cases)*100 AS deathpercentage
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1


-- Working with both data tables
-- Total Population vs. Vaccinations (using CTE)
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingVaccinated)
AS
(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
			SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER(
									PARTITION BY dea.location
									ORDER BY dea.location, dea.date
									) AS RollingVaccinated
			--, (RollingVaccinated/dea.population)*100 -- can't do this, need to make a "new table"
	FROM PortfolioProject1..CovidDeaths dea
	JOIN PortfolioProject1..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	--ORDER BY 2,3
)
SELECT *, (RollingVaccinated/Population)*100
FROM PopvsVac

-- Total Population vs. Vaccinations (using TEMP TABLE)
DROP TABLE IF EXISTS #PercentPopulationVaccinated		-- resets the temp table in case we need to make adjustments
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
			SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER(
									PARTITION BY dea.location
									ORDER BY dea.location, dea.date
									) AS RollingPeopleVaccinated
			--(RollingVaccinated/dea.population)*100
	FROM PortfolioProject1..CovidDeaths dea
	JOIN PortfolioProject1..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL

SELECT *, (RollingVaccinated/Population)*100
FROM #PercentPopulationVaccinated


-- Creating view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
			SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER(
									PARTITION BY dea.location
									ORDER BY dea.location, dea.date
									) AS RollingVaccinated
			--(RollingPeopleVaccinated/population)*100
	FROM PortfolioProject1..CovidDeaths dea
	JOIN PortfolioProject1..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentPopualationVaccinated

