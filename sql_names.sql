-- Exploratory data analysis in SQL Server 2019 on US baby names

--1. Work on database and create new table

use baby_names

create table dbo.names (
name varchar(20),
gender varchar(1),
births int,
years_bir int);

--2. Find number of rows, unique names, and years

select
count(*) as num_rows,
count(distinct name) as num_names,
count(distinct years) as num_years
from names;

--3. Are there any null values?

select
count(*) - count(name) as name_nulls,
count(*) - count(years) as years_nulls,
count(*) - count(gender) as gender_nulls,
count(*) - count(births) as births_nulls
from names;

--or

select
count(name) as name_nulls,
count(years) as years_nulls,
count(gender) as gender_nulls,
count(births) as births_nulls
from names
where name is null
or years is null
or gender is null
or births is null;

--4. Display all births per year (regardless of gender)

select years, sum(births) as total_births
from names
group by years
order by years asc;

--5. Display all births per year by gender

select years, [M] as male_births, [F] as female_births
from
(select births, gender, years from names) as tab1
pivot
(
sum(births)
for gender in ([M], [F])) as tab2
order by years asc;

--6. Find number of years which have more male births than female

select count([years]) as num_years
from
(select births, gender, [years] from names) as tab1
pivot
(
sum(births)
for gender in (M, F)) as tab2
where M > F;

--7. Display births for all names in year range 2000 - 2003

select name, [2000], [2001], [2002], [2003]
from (select distinct name, births, years from names) as tab1
pivot
(
sum(births)
for years in ([2000], [2001], [2002], [2003])) as tab2
order by name asc;

--8. Find longest name(s) and its length

select name, len(name) as name_length
from names
where len(name) = (select max(len(name)) from names);

--9. Display the longest name for each year (regardless of gender)

select name, years from names as tab1
where len(name) >= (select max(len(name)) from names
where years=tab1.years) and not exists
(select name from names
where years=tab1.years and len(name) = len(tab1.name) and name < tab1.name)
order by years asc;

--10. Find unique number of names for each gender

select count(distinct(name)) as count_names, 'M' as gender from names
where gender = 'M'
union all
select count(distinct(name)), 'F' from names
where gender = 'F';

--11. Display most popular name by year for each gender (two rows per year)

select years, name, gender, births from names as tab1
where not exists (
select name from names as tab2
where tab2.years = tab1.years
and tab2.gender = tab1.gender
and tab2.births > tab1.births
)
order by years asc, births asc;

--12. Display unisex names (those who have both genders)

select name, count(distinct gender) as num_gender
from names
group by name 
having count(distinct gender) = 2;

--13. Find 5 least popular female names for last decade (2010s)

select top (5) name, floor(years/10)*10 as decade
from names
where floor(years/10)*10 = 2010 and gender = 'F'
order by births asc;

--14. Display total births (regardless of gender) for each decade.

select floor(years/10)*10 as decade, sum(births) as total_births
from names
group by floor(years/10)*10
order by decade asc;

--15. Display total births for each decade by gender.

select decade, [M] as male_births, [F] as female_births
from (select births, gender, floor(years/10)*10 as decade from names) as tab1
pivot
(
sum(births)
for gender in ([M], [F])) as tab2
order by decade asc;

--16. Baby name researcher Laura Wattenberg pointed out on her website that the distribution
--of boy names by final letter has changed significantly over the last century. Display total
--births for male names ending in each letter throughout the 20th century (for example in
--years 1900, 1950, and 2000).

select tab1.last_letter, births_1900, births_1950, births_2000
from

(select distinct(right(name, 1)) as last_letter, sum(births) as births_1900
from names
where years = 1900 and gender = 'M'
group by right(name, 1)) as tab1

left join

(select distinct(right(name, 1)) as last_letter, sum(births) as births_1950
from names
where years = 1950 and gender = 'M'
group by right(name, 1)) as tab2
on tab1.last_letter=tab2.last_letter

left join

(select distinct(right(name, 1)) as last_letter, sum(births) as births_2000
from names
where years = 2000 and gender = 'M'
group by right(name, 1)) as tab3
on tab2.last_letter=tab3.last_letter

order by births_1900 desc;

--17. Find number of female names ending with 'e' for last 30 years from today.

with tab1 as (
select *, right(name, 1) as letter_e
from names
where gender = 'F' and years >= year(getdate()) - 30 and right(name, 1) = 'e'
)
select years, count(letter_e) as ends_with_e
from tab1
group by years
order by years desc;

--18. Display name diversity over time (number of unique baby names per year).

select years, [M] AS male_names, [F] AS female_names
from 
(select distinct name, gender, years from names) as ps
pivot
(count(name)
for gender in ([M], [F])) as pvt
order by years asc;

--19. Find number of given names by first letter regardless od sex and year.

select distinct(left(name, 1)) as last_letter, sum(births) as total_births
from names
group by left(name, 1)
order by total_births desc;

--20. Find 15 most popular male names of all time.

select top (15) name, sum(births) as total_births
from names
where gender = 'M'
group by name
order by total_births desc;

--21. Some names changed their gender over years (for example: Jean, Donnie, Leslie, Lauren).
--Display an example throughout time.

select years, name, [M] - [F] as gender_diff
from names
pivot
(sum(births)
for gender in ([M], [F])) as pvt
where name = 'Jean'
order by years asc;

--22. Find overall percentage of each gender.

select
count(gender) * 100/(select count(*) from names) as male_percent,
100 - count(gender) * 100/(select count(*) from names) as female_percent
from names
where gender = 'M';

--23. Find years with advantage of female births upon male births. This can be described as
--the number of males per 100 females (gender ratio).

select years, [M]*100 / [F] as gender_ratio
from
(select births, gender, years from names) as tab1
pivot
(
sum(births)
for gender in ([M], [F])) as tab2
where [M] * 100 / [F] < 100
order by years asc;