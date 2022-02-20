

select * from PortfolioProject..['covid-deaths']
where continent IS NOT NULL

select * from PortfolioProject..['covid-vaccinations']

--1) Looking at the state of affairs during covid

select location, date, total_cases,new_cases, total_deaths, population
from PortfolioProject..['covid-deaths']
order by 1,2

--2) Looking at Total Cases vs Total Deaths


select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 DeathPercentage
from PortfolioProject..['covid-deaths']
where total_deaths IS NOT NULL 
and continent IS NOT NULL
order by 1,2

--3) Looking at Total Cases vs Population

select location, date, population, total_cases, (total_cases/population)*100 as "Infected Population"
from PortfolioProject..['covid-deaths']
where total_deaths IS NOT NULL 
and continent IS NOT NULL
order by 1,2


--4) fix the following query to achieve the goal.
--Looking at countries with the Highest Infection rate compared to Population

select location, population, max(total_cases) HighestInfectionCount, max((total_cases/population)*100) PercentPopulationInfected 
from PortfolioProject..['covid-deaths']
group by location, population
order by PercentPopulationInfected desc

--5) Showing Countries with Highest Death Count per Population

select location, max(total_deaths) HighestDeathCount
from PortfolioProject..['covid-deaths']
where total_deaths IS NOT NULL 
and continent IS NOT NULL
group by location
order by 2 desc

--Note that order by is not listing descending values correctly. 
--Some smaller values are listed first. The reason is the total_deaths datatype is varchar. 
--So you must cast it to an integer before using in order by, as in:

select location, max( cast(total_deaths as int) ) HighestDeathCount
from PortfolioProject..['covid-deaths']
where total_deaths IS NOT NULL 
and continent IS NOT NULL
group by location
order by 2 desc

--6) Fix this and title appropriatley Breaking Things down by Continent

select continent, max( cast(total_deaths as int) ) TotalDeathCount
from PortfolioProject..['covid-deaths']
where total_deaths IS NOT NULL 
group by continent
order by 2 desc

--The above is still not getting the correct result because 'South America' only shows the count of Brazil. 
--This is because we have continent wide data lumped together with country wide data wherever the continent is null. 
--It can be corrected by:


select location, max( cast(total_deaths as int) ) TotalDeathCount
from PortfolioProject..['covid-deaths']
where continent IS NULL 
group by location
order by 2 desc

--7) Fix this and title appropriatley

--My own query trying to subvert the anomaly of the data like having NULL's in Continent column. But it retrieves
-- double entries for the continent. Fix that

select continent,  sum( cast(total_deaths as int) ) TotalDeathCount
from PortfolioProject..['covid-deaths']
where continent IS NOT NULL
group by continent
union all
select location,  sum( cast(total_deaths as int) ) TotalDeathCount
from PortfolioProject..['covid-deaths']
where continent IS  NULL
group by continent,location
order by 1

--8) Showing maximum death by continent

select continent, max( cast(total_deaths as int) ) MaximumDeathCount
from PortfolioProject..['covid-deaths']
where continent IS NOT NULL 
group by continent
order by 2 desc

--9) Showing total death count by continent

select continent, sum( cast(total_deaths as int) ) TotalDeathCount
from PortfolioProject..['covid-deaths']
where continent IS NOT NULL 
group by continent
order by 2 desc

--10)  Global Numbers:  Total Cases and Total Deaths  and Total New Cases and Total New Deaths

select date, sum(new_cases) TotalNewCases, sum(cast(new_deaths as int)) TotalNewDeaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from PortfolioProject..['covid-deaths']
where continent is not null
group by date
order by 1,2

--or

select sum(new_cases) TotalNewCases, sum(cast(new_deaths as int)) TotalNewDeaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from PortfolioProject..['covid-deaths']
where continent is not null
order by 1,2

-- Total Cases and Total Deaths

select sum(total_cases) TotalCases, sum(cast(total_deaths as int)) TotalDeaths, sum(cast(total_deaths as int))/sum(total_cases)*100 as DeathPercentage
from PortfolioProject..['covid-deaths']
where continent is not null
order by 1,2

--11) Joining both covid_death and covid_vaccinations

select *
from PortfolioProject..['covid-deaths'] dea
join PortfolioProject..['covid-vaccinations'] vac
on dea.location = vac.location
and dea.date = vac.date


--12) Looking at Total Population vs Vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum( convert(int, vac.new_vaccinations) ) over (Partition by dea.location)
from PortfolioProject..['covid-deaths'] dea
join PortfolioProject..['covid-vaccinations'] vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

--This gives me error:
--Msg 8115, Level 16, State 2, Line 1
--Arithmetic overflow error converting expression to data type int.
--Warning: Null value is eliminated by an aggregate or other SET operation.

--This has to do with converting to a smaller data_type. Using 'float' instead of int, solved it.

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum( convert(float, vac.new_vaccinations) ) over (Partition by dea.location)
from PortfolioProject..['covid-deaths'] dea
join PortfolioProject..['covid-vaccinations'] vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

--The above query shows the total number of people vaccinated for each country. It shows the same number for each record within that country group.

--13)  The following shows the cumulative sum of people vaccinated for each record. It gives you a running total per record within that country group.

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum( convert(float, vac.new_vaccinations) ) 
over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..['covid-deaths'] dea
join PortfolioProject..['covid-vaccinations'] vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
and vac.new_vaccinations is not null
order by 2,3

--14) With CTE queries (Common Table Expression)


With PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum( convert(float, vac.new_vaccinations) ) 
over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..['covid-deaths'] dea
join PortfolioProject..['covid-vaccinations'] vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
and vac.new_vaccinations is not null
)
select *
from PopvsVac;

--Note: You have to run this whole query as 1 unit starting from With and to the end
--Removed order by 2,3 from this query since cte does  not work with order by.

--14)  Now doing our calculations with the CTE query


With PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum( convert(float, vac.new_vaccinations) ) 
over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..['covid-deaths'] dea
join PortfolioProject..['covid-vaccinations'] vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
and vac.new_vaccinations is not null
order by 2,3 (cte does  not work with order by)
)

select *, (RollingPeopleVaccinated/Population)*100
from PopvsVac

--15)  TEMP TABLE

Drop table if exists #PercentPopulationVaccinated
create the table with this option. This enables you to fix errors
create table #PercentPopulationVaccinated
( Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum( convert(float, vac.new_vaccinations) ) 
over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..['covid-deaths'] dea
join PortfolioProject..['covid-vaccinations'] vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
and vac.new_vaccinations is not null
order by 2,3 (cte does  not work with order by)

select *, (RollingPeopleVaccinated/Population)*100
from #PercentPopulationVaccinated

--16)  Creating Views to store data for later visualization

create view PercentPopulationVaccinated
as
(select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum( convert(float, vac.new_vaccinations) ) 
over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..['covid-deaths'] dea
join PortfolioProject..['covid-vaccinations'] vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
and vac.new_vaccinations is not null)
--order by 2,3 
--(order by clause is invalid in views, inline functions, derived tables, subqueries, CTE's, unless TOP, OFFSET


--17)

select continent, sum( cast(new_deaths as int) ) TotalDeathCount
from PortfolioProject..['covid-deaths']
where continent IS NOT NULL
and location not in ('World', 'European Union', 'International','High Income')
group by continent
order by 2

