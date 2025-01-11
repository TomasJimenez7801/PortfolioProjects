/*
Covid-19 Data Exploration Project

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select * 
From PortfolioProject..CovidDeaths
order by 3,4

Select * 
From PortfolioProject..CovidVaccinations
order by 3,4

-----------------------------------------------------------------------------------------------------------------
-- Select starting data
Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null
order by 1,2


-----------------------------------------------------------------------------------------------------------------
-- Total Cases vs Total Deaths

-- Shows likelihood of death if infected (in USA)
Select location, CONVERT(VARCHAR, date, 23) AS DateYYYYMMDD, total_cases, total_deaths
, Format((total_deaths/total_cases)*100,'0.####') + '%' as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
order by 1,2
-- Shows likelihood of death if infected (in Spain)
Select location, CONVERT(VARCHAR, date, 23) AS DateYYYYMMDD, total_cases, total_deaths
, Format((total_deaths/total_cases)*100,'0.####') + '%' as DeathPercentage
From PortfolioProject..CovidDeaths
Where location = 'Spain'
order by 1,2


-----------------------------------------------------------------------------------------------------------------
-- Total Cases vs Population

-- Percentage of population infected by COVID-19 (in Spain)
Select location, CONVERT(VARCHAR, date, 23) AS DateYYYYMMDD, population, total_cases
, Format((total_cases/population)*100,'0.####') + '%' as PopulationInfectionPercentage
From PortfolioProject..CovidDeaths
Where location = 'Spain'
order by 1,2
-- Percentage of population infected by Covid-19 (Worldwide)
Select location, CONVERT(VARCHAR, date, 23) AS DateYYYYMMDD, population, total_cases
, Format((total_cases/population)*100,'0.####') + '%' as PopulationInfectionPercentage
From PortfolioProject..CovidDeaths
order by 1,2


-----------------------------------------------------------------------------------------------------------------
-- Top 10 countries (population 500,000+) with highest infection rate compared to population
Select Top 10 location, population, MAX(total_cases) as HighestInfectionCount 
, Format(MAX((total_cases/population))*100, '0.####') + '%'  as PopulationInfectionPercentage 
From PortfolioProject..CovidDeaths
Where population > 500000
Group by Location, population
order by MAX((total_cases/population))*100 desc


-----------------------------------------------------------------------------------------------------------------
-- Day-to-day infection rate per country 
Select location, population, CONVERT(VARCHAR, date, 23) AS DateYYYYMMDD, MAX(total_cases) as HighestInfectionCount
, Format(MAX((total_cases/population))*100, '0.####') + '%' as PopulationInfectionPercentage 
From PortfolioProject..CovidDeaths
Group by Location, population, date
order by MAX((total_cases/population))*100 desc


-----------------------------------------------------------------------------------------------------------------
-- Death count per country
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location
Order by TotalDeathCount desc 


-- GROUPING BY CONTINENT ----------------------------------------------------------------------------------------

-- Death count by continent
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is null
and location not in ('World', 'European Union', 'International')
Group by location
Order by TotalDeathCount desc


-----------------------------------------------------------------------------------------------------------------
-- Global numbers
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths
, Format(SUM(cast(new_deaths as int))/SUM(new_cases)*100, '0.####') + '%' as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
order by 1,2


-----------------------------------------------------------------------------------------------------------------
-- Total population vs vaccinations 

-- Percent of population that has received at least 1 vaccine (monthly results)
SELECT dea.continent, dea.location, YEAR(dea.date) AS Year, MONTH(dea.date) AS Month, dea.population
, SUM(CONVERT(int, vac.new_vaccinations)) AS MonthlyVaccinations
, SUM(SUM(CONVERT(int, vac.new_vaccinations))) OVER (PARTITION BY dea.location ORDER BY YEAR(dea.date), MONTH(dea.date)) AS RollingCountVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.continent, dea.location, dea.population, YEAR(dea.date), MONTH(dea.date)
ORDER BY dea.location, Year, Month;


-----------------------------------------------------------------------------------------------------------------
--Create CTE with extra column to demonstrate percent vaccinations daily
With PopvsVacc (Continent, Location, Date, Population, new_vaccinations, RollingCountVaccinations)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, 
	dea.date) as RollingCountVaccinations
	-- , (RollingCountVaccinations/dea.population)*100 as Vav
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select *, (RollingCountVaccinations/population)*100 as PercentageVaccinated
From PopvsVacc


-----------------------------------------------------------------------------------------------------------------
--Create TEMP table with extra column to demonstrate percent vaccinations daily
DROP Table if exists PercentPopulationVaccinated
Create Table PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingCountVaccinations numeric,
)

Insert into PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, 
	dea.date) as RollingCountVaccinations
	-- , (RollingCountVaccinations/dea.population)*100 as Vav
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select *, (RollingCountVaccinations/population)*100 as PercentageVaccinated
From PercentPopulationVaccinated


-----------------------------------------------------------------------------------------------------------------
--Create VIEW to store data
Create View PctPopulationVaccinatedView as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, 
	dea.date) as RollingCountVaccinations
	-- , (RollingCountVaccinations/dea.population)*100 as Vav
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select * 
From PctPopulationVaccinatedView
