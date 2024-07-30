Select *
From [Portfolio Project]..CovidDeaths
where continent is not null
order by 3,4

--Select *
--From [Portfolio Project]..CovidVaccinations
--order by 3,4

Select Location,  date, total_cases, new_cases, total_deaths, population
From [Portfolio Project]..CovidDeaths
order by 1,2

--Looking at Total Cases vs Total Deaths
--shows likelihood of dying if you contract covid at your country
Select Location,  date, total_cases,  total_deaths,(CONVERT(float, total_deaths) /NULLIF(CONVERT(float, total_cases), 0))*100 as DeathPercentage 
From [Portfolio Project]..CovidDeaths
Where location like '%states%'
order by 1,2

--Looking at Total Cases vs Population
--shows what percentage of population got covid
Select Location,  date,population, total_cases,(CONVERT(float, total_cases) /NULLIF(CONVERT(float, population), 0))*100 as PercentPopulationInfected 
From [Portfolio Project]..CovidDeaths
Where location like '%states%'
order by 1,2

--Looking at Countries with highest infection rate compared to population
Select Location, population, MAX (total_cases) AS HighestInfectionCount,MAX(CONVERT(float, total_cases) /NULLIF(CONVERT(float, population), 0))*100 as PercentPopulationInfected 
From [Portfolio Project]..CovidDeaths
--Where location like '%states%'
Group by Location,Population
order by PercentPopulationInfected desc


--Showing Countries with Highest Death Count per Population
Select Location,  MAX(cast(Total_deaths as int)) as TotalDeathCount
From [Portfolio Project]..CovidDeaths
--Where location like '%states%'
Where iso_code NOT IN ('OWID_EUR','OWID_EUN', 'OWID_AFR', 'OWID_ASI', 'OWID_INT', 'OWID_NAM', 'OWID_OCE', 'OWID_WRL', 'OWID_SAM')
Group by Location
order by TotalDeathCount desc

--LETS BREAK THINGS DOWN BY CONTINENT

--Showing the continents with the highest death count per population

Select continent,  MAX(cast(Total_deaths as int)) as TotalDeathCount
From [Portfolio Project]..CovidDeaths
--Where location like '%states%'
Where continent is not null
Group by continent
order by TotalDeathCount desc


--GLOBAL NUMBERS
SELECT date, total_cases, total_deaths, CASE 
WHEN total_cases = 0 THEN 0 
ELSE (CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT)) * 100 
END AS DeathPercentage
FROM [Portfolio Project]..CovidDeaths
ORDER BY date;

--looking at total population vs vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
From [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

--USE CTE

WITH PopvsVac AS
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(COALESCE(CONVERT(bigint, vac.new_vaccinations), 0)) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.location, dea.date
        ) AS RollingPeopleVaccinated
    FROM 
        [Portfolio Project]..CovidDeaths dea
    JOIN 
        [Portfolio Project]..CovidVaccinations vac
    ON 
        dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL
)
SELECT 
    *, 
    (RollingPeopleVaccinated / NULLIF(CAST(Population AS bigint), 0)) * 100 AS VaccinationPercentage
FROM 
    PopvsVac;

--Temp table
DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population BIGINT,
    New_vaccinations BIGINT,
    RollingPeopleVaccinated BIGINT
);

INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(COALESCE(CONVERT(BIGINT, vac.new_vaccinations), 0)) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.location, dea.Date
    ) AS RollingPeopleVaccinated
FROM 
    [Portfolio Project]..CovidDeaths dea
JOIN 
    [Portfolio Project]..CovidVaccinations vac
ON 
    dea.location = vac.location
    AND dea.date = vac.date;

SELECT 
    *, 
    (RollingPeopleVaccinated / NULLIF(Population, 0)) * 100 AS VaccinationPercentage
FROM 
    #PercentPopulationVaccinated;

	--Creating views to store data for later visualisation

	Create View PercentPopulationVaccinated as
	Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
	--, (RollingPeopleVaccinated/population)*100
	From [Portfolio Project]..CovidDeaths dea
	Join [Portfolio Project]..CovidVaccinations vac
	On dea.location = vac.location 
	and dea.date = vac.date
	where dea.continent is not null
	--order by 2,3

	Select *
	From PercentPopulationVaccinated
