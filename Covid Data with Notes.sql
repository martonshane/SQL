/*

Data Exploration with Covid 19

Skills displayed: Subquery, Joins, CTEs, Windows Functions, Creating Views, Aggregate Functions, Converting Data Types

*/

--Let's see what data we're working with

SELECT *
FROM 
	dbo.CovidDeaths
WHERE 
	continent IS NOT NULL




-- Select Data to be used

SELECT 
	location,
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM 
	dbo.CovidDeaths
ORDER BY 
	1,2


-- Total cases vs Total deaths
-- with death rate

SELECT 
	location, 
	date,
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases)*100 as 'Death Rate'
FROM 
	dbo.CovidDeaths
WHERE 
	location = 'United States'
ORDER BY 
	1,2

--Total Cases v Population

SELECT 
	Location, 
	date, 
	total_cases, 
	population, 
	(total_cases/population)*100 as 'case per population'
FROM 
	dbo.CovidDeaths
WHERE 
	location like '%states'
ORDER BY 
	1,2




-- Countries with highest covid rate v population

SELECT 
	location, 
	population, 
	MAX(total_cases) AS 'Infection Count', 
	MAX((total_cases/population)*100) as 'Countries Infection Rate vs Population'
FROM 
	dbo.CovidDeaths
Group by 
	location, 
	population
ORDER BY 
	[Countries Infection Rate vs Population] desc


--Deaths per country

SELECT 
	location, 
	MAX(cast(total_deaths as int)) as 'Total Death Count'
FROM 
	dbo.CovidDeaths
WHERE 
	continent is null
Group by 
	location
ORDER BY [Total Death Count] desc


-- Continent death count

SELECT 
	continent,
	MAX(cast(total_deaths as int)) as 'Total Death Count'
FROM 
	dbo.CovidDeaths
WHERE
	continent is not null
GROUP BY
	continent
ORDER BY 
	[Total Death Count] desc

--More accurate NA count -- Subquery
SELECT 
	SUM(totaldeaths)
FROM
(
SELECT DISTINCT
	(location),	
	MAX(cast(total_deaths as int)) totaldeaths
FROM 
	dbo.CovidDeaths
WHERE 
	continent = 'North America'
GROUP BY 
	location
) x



--Global Death percentage per day - WORLD
SELECT 
	date, 
	SUM(new_cases) 'Total New Cases', 
	SUM(cast(new_deaths as INT)) AS 'Total New Deaths', 
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as 'Death Percentage'
FROM 
	dbo.CovidDeaths
WHERE 
	continent IS NOT NULL
GROUP BY 
	DATE
ORDER BY 
	1,2


--ALTER DATA TYPE FOR new_deaths column 
ALTER TABLE CovidDeaths
ALTER COLUMN new_deaths int;

--Overall Global Death percentage 
SELECT 
	SUM(new_cases) 'Total New Cases', 
	SUM(cast(new_deaths as INT)) AS 'Total New Deaths', 
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as 'Death Percentage'
FROM 
	dbo.CovidDeaths
WHERE 
	continent IS NOT NULL
ORDER BY 
	1,2


--Total world population vs vaccination -- PARTITION BY for rolling number of people vaccinated
--This will allow us to add the vaccinated count for each day automatically

SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location order by DEA.LOCATION, DEA.DATE) AS 'RollingPeopleVaccinated'
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccinations vac ON
	dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3







--Common Table Expression (CTE)
--Using CTE to show a new column for getting the percentage of people vaccinated in the country. 
WITH PopVsVac(continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)

AS
(
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location order by DEA.LOCATION, DEA.DATE) AS 'RollingPeopleVaccinated'
FROM 
	dbo.CovidDeaths dea
JOIN dbo.CovidVaccinations vac 
	ON dea.location = vac.location AND dea.date = vac.date
WHERE 
	dea.continent IS NOT NULL
)

SELECT *, (RollingPeopleVaccinated/Population)*100 
FROM PopVsVac


--TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated

--COMMENT TO SEPARATE DROP FROM TABLE CREATION
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

--INSERTING DATA INTO THE CREATED TABLE
INSERT INTO #PercentPopulationVaccinated
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location order by DEA.LOCATION, DEA.DATE) AS 'RollingPeopleVaccinated'
FROM 
	dbo.CovidDeaths dea
JOIN dbo.CovidVaccinations vac 
ON dea.location = vac.location 
	AND dea.date = vac.date


SELECT * 
FROM
	PercentPopulationVaccinated



--VIEW CREATION FOR VISUALIZATIONS
CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location order by DEA.LOCATION, DEA.DATE) AS 'RollingPeopleVaccinated'
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccinations vac ON
	dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT 
	*
FROM
	PercentPopulationVaccinated
