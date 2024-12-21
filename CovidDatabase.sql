SELECT * FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;

--Select Data that we are going to be using 
SELECT location, cases_date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
ORDER BY 1, 2;

--Looking at total cases vs total deaths (mortality rate)
SELECT location, cases_date, total_cases, total_deaths, (total_deaths / total_cases) * 100 mortality_rate
FROM covid_deaths
WHERE location = 'Philippines'
ORDER BY 1, 2;

--Looking at total cases vs population (infection rate)
SELECT location, cases_date, population, total_cases, (total_cases / population) * 100 infection_rate
FROM covid_deaths
WHERE location = 'Philippines'
ORDER BY 1, 2;

--Highest infection rate in the whole world
SELECT location, population, MAX(total_cases) highest_case, MAX((total_cases / population) * 100) infection_rate
FROM covid_deaths
GROUP BY location, population
ORDER BY infection_rate DESC NULLS LAST;

--Country with highest death count
SELECT location, MAX(total_deaths) as total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC NULLS LAST;

--Continents with highest death count
SELECT location, MAX(total_deaths) as total_death_count
FROM covid_deaths
WHERE continent IS NULL AND location NOT IN ('World', 'International')
GROUP BY location
ORDER BY total_death_count DESC NULLS LAST;

--Global Numbers by date
SELECT cases_date, SUM(new_cases) total_cases, SUM(new_deaths) total_deaths, SUM(new_deaths) / SUM(new_cases) * 100 mortality_rate
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY cases_date
ORDER BY 1, 2 DESC NULLS LAST;

--Global Numbers total
SELECT SUM(new_cases) total_cases, SUM(new_deaths) total_deaths, SUM(new_deaths) / SUM(new_cases) * 100 mortality_rate
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1, 2 DESC NULLS LAST;

--Join Table covid_deaths and covid_vaccinations
SELECT * FROM covid_deaths covdeaths
JOIN covid_vaccinations covvac
ON covdeaths.location = covvac.location 
AND covdeaths.cases_date = covvac.cases_date;

--Total vaccinations vs total populations using CTE
SELECT covdeaths.continent, covdeaths.location, covdeaths.cases_date, covdeaths.population, covvac.new_vaccinations,
    SUM(covvac.new_vaccinations) OVER 
    (PARTITION BY covdeaths.location ORDER BY covdeaths.location, covdeaths.cases_date) cumulative_frequency
FROM covid_deaths covdeaths
JOIN covid_vaccinations covvac
    ON covdeaths.location = covvac.location 
    AND covdeaths.cases_date = covvac.cases_date
WHERE covdeaths.continent IS NOT NULL 
ORDER BY covdeaths.location, covdeaths.cases_date;

--Use CTE to find the total vaccinated people(the parameters must be the same number of column inside the CTE)
WITH cte_total_vaccinated AS
(
    SELECT covdeaths.continent, covdeaths.location, covdeaths.cases_date, covdeaths.population, covvac.new_vaccinations,
        SUM(covvac.new_vaccinations) OVER 
        (PARTITION BY covdeaths.location ORDER BY covdeaths.location, covdeaths.cases_date) cumulative_frequency
    FROM covid_deaths covdeaths
    JOIN covid_vaccinations covvac
        ON covdeaths.location = covvac.location 
        AND covdeaths.cases_date = covvac.cases_date
    WHERE covdeaths.continent IS NOT NULL 
)
SELECT continent, location, cases_date, population, new_vaccinations, cumulative_frequency , 
      (cumulative_frequency / population) * 100 total_percent_vaccinated
FROM cte_total_vaccinated
--uncomment this if you do not want NULL values
--WHERE new_vaccinations IS NOT NULL
ORDER BY location, cases_date;

--Use Temp table to find the total vaccinated people
CREATE GLOBAL TEMPORARY TABLE temp_cumulative_frequency (
    continent VARCHAR(50), 
    location VARCHAR(50), 
    cases_date DATE,
    population NUMBER(38), 
    new_vaccinations NUMBER(38),
    cumulative_frequency NUMBER(38)
)ON COMMIT DELETE ROWS 

INSERT INTO temp_cumulative_frequency 
    SELECT covdeaths.continent, covdeaths.location, covdeaths.cases_date, covdeaths.population, covvac.new_vaccinations,
        SUM(covvac.new_vaccinations) OVER 
        (PARTITION BY covdeaths.location ORDER BY covdeaths.location, covdeaths.cases_date) cumulative_frequency
    FROM covid_deaths covdeaths
    JOIN covid_vaccinations covvac
        ON covdeaths.location = covvac.location 
        AND covdeaths.cases_date = covvac.cases_date
    WHERE covdeaths.continent IS NOT NULL ;
    
SELECT continent , location, cases_date, population, new_vaccinations, cumulative_frequency,
    (cumulative_frequency / population) * 100 total_percent_vaccinated
FROM temp_cumulative_frequency;

--Creating View for visualization (highest death count for every country) Note: Read-Only Values cannot edit
CREATE VIEW country_death_count AS
    SELECT 
        location,
        MAX(total_deaths) total_death_count
    FROM 
        covid_deaths 
    WHERE 
        continent IS NOT NULL
    GROUP BY 
        location
    ORDER BY 
        total_death_count WITH READ ONLY

--Creating View for visualization (highest death count for every continent)
CREATE VIEW continent_death_count AS
    SELECT 
        location,
        MAX(total_deaths) total_death_count
    FROM 
        covid_deaths 
    WHERE 
        continent IS NULL AND location NOT IN ('World', 'International')
    GROUP BY 
        location
    ORDER BY 
        total_death_count WITH READ ONLY
        
--Creating View for visualization (total death count in the whole world)
CREATE VIEW world_death_count AS
    SELECT 
        location,
        MAX(total_deaths) total_death_count
    FROM 
        covid_deaths 
    WHERE 
        continent IS NULL AND location = 'World'
    GROUP BY 
        location WITH READ ONLY
        






