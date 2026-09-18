-- ###---------------------------------------------- DATA EXPLORATION:

-- ##-------------coviddeaths:

-- Data I am going to use:
select
	location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
from coviddeaths
order by location, date;



-- Let's take a look: total cases vs total deaths (DEATH PERCENTAGE)
select
	location,
    date,
    total_cases,
    total_deaths,
    (total_deaths/total_cases)*100 as Death_Percentage
from coviddeaths
where location like '%col%'
order by date;



-- Let's take a look at Total Cases v Population 
select 
	location,
    date,
    total_cases,
    population,
    (total_cases/population) * 100 AS Percent_Population_Infected
from coviddeaths
where location = 'Colombia'
order by date;



-- Let's take a look at Countries with Highest Infection rate (compared to Population)
select 
	location,
    population,
    MAX(total_cases) as HighestInfectionCount,
    MAX((total_cases/population)) * 100 AS Percent_Population_Infected
from coviddeaths
group by location, population
order by Percent_Population_Infected desc;



-- Let's take a look at the Maximum Number of new Cases (NO DATE)
SELECT
  location,
  MAX(new_cases) as MaxNewCases
FROM coviddeaths
WHERE continent is not null AND continent != ''
GROUP BY location
order by MaxNewCases desc;



-- Let's show countries with Highest Death percentage per Population
select
	location,
    MAX(total_deaths) as TotalDeathCount
from coviddeaths
where continent is not null AND continent != ''
group by location
order by TotalDeathCount desc;



-- Let's show CONTINENTS with Highest Death count
select 
	continent,
    SUM(new_deaths) as TotalDeathCount
from coviddeaths
where continent != '' AND continent is not null
group by continent
order by totalDeathCOunt desc;



-- Let's see countries with more number of cases
WITH RankedCases AS (
    SELECT 
        location,
        date,
        new_cases,
        ROW_NUMBER() OVER (PARTITION BY location ORDER BY new_cases DESC) AS rn
    FROM coviddeaths
    WHERE continent IS NOT NULL AND continent != ''
)
SELECT 
    location,
    date,
    new_cases AS MaxNewCases
FROM RankedCases
WHERE rn = 1
ORDER BY MaxNewCases DESC;





-- ##-------------covidvaccinations:

-- Let's take a look at Global Testing & Positivity Rate (Testing Focus)
-- My goal: Find the top 10 countries with the highest average COVID test positivity rate (positive_rate).
SELECT 
	location,
    AVG(positive_rate)*100 as Average_Positive_Rate
FROM covidvaccinations
WHERE continent != '' AND continent IS NOT NULL
GROUP BY location
ORDER BY Average_Positive_Rate desc
LIMIT 10;



-- Vaccination Rollout Speed vs. Complete Vaccination (Vaccination Focus)
-- My goal: Goal: Find the maximum percentage of fully vaccinated people for each country, filtered to show only countries that managed to fully vaccinate over 55% of their population.
SELECT
	location,
    MAX(people_fully_vaccinated_per_hundred) as  Max_Fully_Vaccinated_People
FROM covidvaccinations
WHERE continent != '' AND continent IS NOT NULL
GROUP BY location
HAVING Max_Fully_Vaccinated_People > 50
ORDER BY Max_Fully_Vaccinated_People DESC;



-- Let's look at how Canada government restrictions related to testing volumes over time.
-- My goal now is: Compare Canada government strictness against testing volume. Find the average stringency_index and the total new_tests for a specific country grouped by year or month.
SELECT
	location,
    date,
    stringency_index,
    new_tests
FROM covidvaccinations
WHERE location = 'Colombia' AND stringency_index IS NOT NULL AND new_tests IS NOT NULL
ORDER BY date;



-- Let's take a look at the Socio-Economic Focus: The Wealth vs. Vaccination Gap 
-- Goal: Compare gdp_per_capita against the maximum people_fully_vaccinated_per_hundred per country, ordered from wealthiest country to poorest, to see if GDP directly correlated with vaccine access.
SELECT
	location,
	gdp_per_capita,
    MAX(people_fully_vaccinated_per_hundred) AS MaxVaccinatedRate
FROM covidvaccinations
WHERE gdp_per_capita IS NOT NULL
GROUP BY location, gdp_per_capita
HAVING MaxVaccinatedRate IS NOT NULL
ORDER BY gdp_per_capita DESC;



-- USE of JOIN's
SELECT *
FROM coviddeaths dea
JOIN covidvaccinations vac 
    ON dea.location = vac.location 
   AND dea.date = vac.date;
   


-- Looking at Total Population v Vaccinations
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
  AND dea.continent != ''
  AND vac.new_vaccinations IS NOT NULL
ORDER BY dea.location, dea.date;



-- USE CTE
WITH PopvsVac AS (
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        COALESCE(vac.new_vaccinations, 0) AS new_vaccinations,
        SUM(COALESCE(vac.new_vaccinations, 0)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS rolling_people_vaccinated
    FROM coviddeaths dea
    JOIN covidvaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *,
       (rolling_people_vaccinated * 1.0 / population) AS pct_vaccinated
FROM PopvsVac
ORDER BY location, date;

