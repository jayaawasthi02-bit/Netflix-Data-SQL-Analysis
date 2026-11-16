CREATE DATABASE OTTdb;

USE OTTdb


SELECT * FROM netflix_data


;

--checking null values
SELECT 
SUM(CASE WHEN show_id IS NULL THEN 1 ELSE 0 END) AS null_id,
SUM(CASE WHEN type IS NULL THEN 1 ELSE 0 END) AS null_type,
SUM(CASE WHEN title IS NULL THEN 1 ELSE 0 END) AS null_title,
SUM(CASE WHEN director IS NULL THEN 1 ELSE 0 END) AS null_director,
SUM(CASE WHEN cast IS NULL THEN 1 ELSE 0 END) AS null_cast,
SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS null_country,
SUM(CASE WHEN date_added IS NULL THEN 1 ELSE 0 END) AS null_date,
SUM(CASE WHEN release_year IS NULL THEN 1 ELSE 0 END) AS null_year,
SUM(CASE WHEN rating IS NULL THEN 1 ELSE 0 END) AS null_rating,
SUM(CASE WHEN duration IS NULL THEN 1 ELSE 0 END) AS null_duration,
SUM(CASE WHEN listed_in IS NULL THEN 1 ELSE 0 END) AS null_list,
SUM(CASE WHEN description IS NULL THEN 1 ELSE 0 END) AS null_description
FROM netflix_data

-- removing null
DELETE FROM netflix_data
WHERE director IS NULL OR
cast IS NULL OR
country IS NULL OR
date_added IS NULL OR 
rating IS NULL OR 
duration IS NULL 

-- checking duplicate values 
SELECT 
	show_id,type,title,director,cast,country,date_added,release_year,rating,duration,listed_in,description, COUNT(*) AS duplicates 
FROM netflix_data
GROUP BY 
	show_id,type,title,director,cast,country,date_added,release_year,rating,duration,listed_in,description
HAVING 
	COUNT(*) > 1

-- 15 Business Problems & Solutions

--1. Count the number of Movies vs TV Shows
SELECT 
	type, COUNT(show_id) AS numshows
FROM netflix_data
GROUP BY 
	type;

--1. Percentage contribution of movies vs TV shows 
SELECT  
	 LTRIM(RTRIM(type)) AS type ,
	COUNT(show_id) AS shows,
	CONVERT(DECIMAL(10,2),COUNT(show_id)*100.0/(SELECT COUNT(show_id) FROM netflix_data)) AS percentage_contribution 
	FROM netflix_data
	GROUP BY 
		 LTRIM(RTRIM(type));

--2. Find the most common rating for movies and TV shows
WITH rating_count AS (
SELECT 
	type,
	rating,
	COUNT(*) AS Total_rating,
	RANK() OVER ( PARTITION BY type ORDER BY COUNT(*) DESC) AS rting_rank
	FROM netflix_data
	GROUP BY
		type,
		rating)
SELECT type,
	rating,
	Total_rating,
	rting_rank
	FROM rating_count
	WHERE rting_rank = 1
	 

--3. List all movies released in a specific year (e.g., 2020)
SELECT  *
	-- type,title,release_year
	 FROM netflix_data
	 WHERE 
		release_year = 2020 AND type = 'movie'

--4. Find the top 5 countries with the most content on Netflix
SELECT TOP 5
	 country,COUNT(type) AS content
	 FROM netflix_data
	 GROUP BY 
		country
	 ORDER BY 
		content DESC;

--5. Identify the longest movie
SELECT TOP 1 WITH TIES 
title,duration 
FROM netflix_data
WHERE type='Movie'
ORDER BY LEN(duration) DESC,duration desc

--6. Find content added in the last 5 years
						
	SELECT 
		 title,
		 director,
		 cast,
		 release_year,
		 date_added FROM netflix_data
		 WHERE try_cast(date_added as date)>= dateadd(year,-10, getdate());

		

--7. Find all the movies/TV shows by director 'Rajiv Chilaka'!
 SELECT 
  title 
  FROM netflix_data
WHERE 
	director = 'Rajiv Chilaka'

--8. List all TV shows with more than 5 seasons
	SELECT 
		type,title,
		duration
		FROM netflix_data
	WHERE type = 'TV show' AND duration > '5seasons' 				

--9. Count the number of content items in each genre
	SELECT 
		
		 listed_in AS genre , Count(*) AS content_each_genre
		 FROM netflix_data
		 GROUP BY 
			listed_in
		ORDER BY
			content_Each_genre DESC
			

--10.Find each year and the average numbers of content release in India on netflix. 
--return top 5 year with highest avg content release!

SELECT TOP 5
	release_year,
	country,
	COUNT(title) AS Content
FROM netflix_data
	WHERE 
		 Country = 'India'
	GROUP BY 
		release_year,
		country 
	ORDER BY 
		Content DESC
		
--11. List all movies that are documentaries
SELECT 
	type,
	title,
	listed_in
	FROM netflix_data
WHERE listed_in = 'documentaries'

--12. Find all content without a director
SELECT 
	title
	FROM netflix_data
	WHERE director = ' '

--13. Find how many movies actor 'Salman Khan' appeared in last 10 years!
 SELECT 
  type,
	title,
	cast,
	release_year
	FROM netflix_data
	WHERE type = 'Movie' AND
		cast LIKE '%Salman khan%' AND release_year >= YEAR(GETDATE()) - 10
--14. Find the top 10 actors who have appeared in the highest number of movies produced in India.
SELECT TOP 10
	LTRIM(RTRIM(value)) AS actor_name,
	country,
	COUNT(*) AS total_movies
	FROM netflix_data
	CROSS APPLY string_split(cast, ',')
	WHERE type = 'Movie'
		AND country = 'India'
	GROUP BY 
		LTRIM(RTRIM(value)),
		country
	ORDER BY 
		total_movies DESC

--15.Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
--the description field. Label content containing these keywords as 'Bad' and all other 
--content as 'Good'. Count how many items fall into each category.

	SELECT 
		 CASE 
			WHEN lower(description) LIKE '%Kill%' OR lower(description) LIKE '%Violence%' THEN 'Bad'
			ELSE 'Good'
			END AS categories ,
		 COUNT(*) AS category_content 
		FROM netflix_data
		GROUP BY 
		CASE 
			WHEN lower(description) LIKE '%Kill%' OR lower(description) LIKE '%Violence%' THEN 'Bad'
			ELSE 'Good'
			END;
	
--16. cleaned dataset with content age and content category
WITH clean_dataset AS (
SELECT 
	show_id,
	LTRIM(RTRIM(title))  AS  cleaned_title,
	LTRIM(RTRIM(type)) AS types,
	LTRIM(RTRIM(country)) AS country,
	TRY_CAST(date_added AS DATE) AS dates,
DATEDIFF(YEAR, TRY_CAST(date_added AS date), GETDATE()) AS year_since_addition 
FROM netflix_data), 
Category AS ( 
	SELECT *,
		CASE 
			WHEN year_since_addition > 5 THEN 'Old Content'
			WHEN year_since_addition BETWEEN 1 AND 5 THEN 'Moderately Old'
			WHEN year_since_addition IS NULL THEN 'Unknown'
			ELSE 'Recently added'
		END AS content_category
	FROM clean_dataset) SELECT * FROM Category;

--17. Find top 5 years with the most number of content added?
	SELECT TOP 5 WITH TIES
		YEAR(date_added) AS year,
		COUNT(show_id) AS conter_added
		
		FROM netflix_data
		GROUP BY 
		YEAR(date_added)
		ORDER BY 
		conter_added DESC



