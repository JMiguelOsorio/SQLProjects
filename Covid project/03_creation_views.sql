-- ###----------------------------------------------CREATION OF VIEWS

-- Cumulative Vaccination Progress by Country
DROP VIEW IF EXISTS vw_percent_population_vaccinated;
CREATE VIEW vw_percent_population_vaccinated AS
WITH PopvsVac AS (
SELECT 
	dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(COALESCE(vac.new_vaccinations,0)) OVER (
    PARTITION BY dea.location
    ORDER BY dea.date
    ) AS rolling_people_vaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
	AND dea.continent != ''
)
SELECT
	*,
	(rolling_people_vaccinated / population) * 100 AS pct_population_vaccinated
FROM PopvsVac;


-- Fatality_rate by Country
DROP VIEW IF EXISTS vw_country_covid_summary;
CREATE VIEW vw_country_covid_summary AS
SELECT 
    dea.location,
    dea.population,
    MAX(dea.total_cases) AS max_total_cases,
    MAX(dea.total_deaths) AS max_total_deaths,
    MAX(dea.total_cases / dea.population) * 100 AS percent_population_infected,
    MAX(dea.total_deaths / dea.total_cases) * 100 AS fatality_rate
FROM coviddeaths dea
WHERE dea.continent IS NOT NULL
  AND dea.continent != ''
GROUP BY 
    dea.location,
    dea.population;


-- Socioeconomic Factors vs Vaccine Rollout
DROP VIEW IF EXISTS vw_gdp_vs_vaccination;
CREATE VIEW vw_gdp_vs_vaccination AS
SELECT 
	location,
    gdp_per_capita,
    MAX(people_fully_vaccinated_per_hundred) AS max_fully_vaccinated_pct
FROM covidvaccinations
WHERE continent IS NOT NULL
  AND continent != ''
  AND gdp_per_capita IS NOT NULL
GROUP BY
	location,
    gdp_per_capita
HAVING max_fully_vaccinated_pct > 45;


-- Lethality Curve During Peaks vs. Progress of Vaccination
DROP VIEW IF EXISTS vw_vaccine_impact_over_time;

CREATE VIEW vw_vaccine_impact_over_time AS
SELECT 
    dea.location,
    dea.date,
    dea.new_cases_smoothed,
    dea.new_deaths_smoothed,
    vac.people_fully_vaccinated_per_hundred AS pct_fully_vaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
  AND dea.continent != '';
  
  
-- Healthcare capacity vs mortality
DROP VIEW IF EXISTS vw_healthcare_capacity_vs_mortality;

CREATE VIEW vw_healthcare_capacity_vs_mortality AS
SELECT 
    dea.location,
    vac.hospital_beds_per_thousand,
    MAX(dea.icu_patients_per_million) AS max_icu_patients_per_million,
    MAX(dea.hosp_patients_per_million) AS max_hosp_patients_per_million,
    MAX(dea.total_deaths / dea.population) * 100 AS death_rate_per_population
FROM coviddeaths dea
JOIN covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
  AND dea.continent != ''
  AND vac.hospital_beds_per_thousand IS NOT NULL
GROUP BY 
    dea.location,
    vac.hospital_beds_per_thousand;
    
    
-- Risk factor Analysis
DROP VIEW IF EXISTS vw_risk_factors_analysis;

CREATE VIEW vw_risk_factors_analysis AS
SELECT 
    dea.location,
    vac.median_age,
    vac.aged_65_older,
    vac.diabetes_prevalence,
    vac.cardiovasc_death_rate,
    (MAX(dea.total_deaths) / MAX(dea.total_cases)) * 100 AS fatality_rate
FROM coviddeaths dea
JOIN covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
  AND dea.continent != ''
  AND vac.median_age IS NOT NULL
GROUP BY 
    dea.location,
    vac.median_age,
    vac.aged_65_older,
    vac.diabetes_prevalence,
    vac.cardiovasc_death_rate;