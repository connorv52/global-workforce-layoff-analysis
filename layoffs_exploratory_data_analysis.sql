-- Exploratory Data Analysis

SELECT * FROM layoffs_staging2
LIMIT 10;

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

SELECT * 
FROM layoffs_staging2
WHERE percentage_laid_off = '1'
ORDER BY funds_raised_millions DESC;

-- Sum of each company's layoffs throughout the time period
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY company
ORDER BY 2 DESC;
-- We can expand this query for other analysis-related questions, such as layoffs with regard to 
-- funding raised or perhaps industry

-- Date range of world layoffs
SELECT MIN(date), MAX(date)
FROM layoffs_staging2;
-- The dataset appears to consist of world layoffs between March 2020 and March 2023

-- Sum of world layoffs for each industry (i.e., retail, finance)
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY industry
ORDER BY 2 DESC;
-- Consumer and Retail are the two industries with the most worldwide layoffs

-- We can also utilize the country column to get a better sense of how
-- each country has differed over the last several years with layoffs

SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY country
ORDER BY 2 DESC;
-- Evidently, the United States exceeds all other countries by a large margin

-- Since the COVID-19 Pandemic had a significant impact on layoffs and the labor market at large, it might
-- be a good idea to consider the total world layoffs by year
SELECT date, SUM(total_laid_off)
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
AND date IS NOT NULL
GROUP BY date
ORDER BY 1 DESC;

-- The EXTRACT() function will allow us to properly look at world layoffs by year
SELECT EXTRACT(YEAR FROM date) AS year, SUM(total_laid_off)
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
AND date IS NOT NULL
GROUP BY year
ORDER BY 1 DESC;

-- We can also group layoffs by the stage (Post-IPO, etc.) of the company
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
AND stage IS NOT NULL
GROUP BY stage
ORDER BY 2 DESC;
-- Post-IPO far exceeds any other company stage with regard to layoffs, which makes sense
-- considering their average size


SELECT * FROM layoffs_staging2
LIMIT 10;

-- Rolling total of layoffs based by month
SELECT EXTRACT(MONTH FROM date) AS month, SUM(total_laid_off)
FROM layoffs_staging2
WHERE date IS NOT NULL
GROUP BY month;

-- Using TO_CHAR will allow us to get the month associated with the respective year, making it 
 -- considerably more specific and accurate
SELECT 
    TO_CHAR(date, 'YYYY-MM') AS month_year,
    SUM(total_laid_off) AS total_laid_off
FROM 
    layoffs_staging2
WHERE 
    total_laid_off IS NOT NULL
	AND date IS NOT NULL
GROUP BY 
    month_year
ORDER BY 
    month_year;

-- To make the rolling total possible, it will be a lot easier for us to combine 
-- a window function with a CTE!
WITH Rolling_Total AS
(SELECT 
    TO_CHAR(date, 'YYYY-MM') AS month_year,
    SUM(total_laid_off) AS total_laid_off
FROM 
    layoffs_staging2
WHERE 
    total_laid_off IS NOT NULL
	AND date IS NOT NULL
GROUP BY 
    month_year
ORDER BY 
    month_year)
	SELECT month_year, total_laid_off,
	SUM(total_laid_off) OVER(ORDER BY month_year) AS rolling_total
	FROM Rolling_Total;
-- This rolling total reveals that from March 2020 to March 2023, approximately 380,000
-- people across the world lost their jobs (using only the data in this dataset)

-- We can also see how each company's layoffs differed by year
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY company
ORDER BY 2 DESC;

SELECT company, EXTRACT(YEAR FROM date) AS year, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, year
ORDER BY company ASC;

SELECT company, EXTRACT(YEAR FROM date) AS year, SUM(total_laid_off)
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY company, year
ORDER BY 3 DESC; 

-- CTE in order to rank the largest company layoffs
WITH Company_Year (company, years, total_laid_off) AS (
SELECT company, EXTRACT(YEAR FROM date) AS year, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, year
)
SELECT *
FROM Company_Year;

-- Partition by year and rank by how many the company laid off in that year using the CTE
-- 
WITH Company_Year (company, years, total_laid_off) AS (
SELECT company, EXTRACT(YEAR FROM date) AS year, SUM(total_laid_off)
FROM layoffs_staging2
	WHERE total_laid_off IS NOT NULL
GROUP BY company, year
)
SELECT *, DENSE_RANK() OVER (PARTITION BY  years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
ORDER BY Ranking ASC;
-- This query allows us to easily see which companies had the most layoffs, ranked by each year (2020-2023)

-- We can also constrain the ranking to only the top 5 for each year
WITH Company_Year (company, years, total_laid_off) AS (
SELECT company, EXTRACT(YEAR FROM date) AS year, SUM(total_laid_off)
FROM layoffs_staging2
	WHERE total_laid_off IS NOT NULL
GROUP BY company, year
	-- first CTE
), Company_Year_Rank AS 
(SELECT *, DENSE_RANK() OVER (PARTITION BY  years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
 -- final CTE
 )
 SELECT * 
 FROM Company_Year_Rank
 WHERE Ranking <= 5;
 -- Subqueries make it possible for us to more easily display the top company ranks by year
 -- We notice that some companies were among the highest in layoffs for one year and then proceeded
 -- to be among the highest in layoffs the next year. Most companies rarely made multiple appearances
 -- in the top ranks for layoffs, but more analysis outside of this dataset could determine whether 
 -- that is simply a byproduct of the company's reduced total workforce. Even the largest Post-IPO companies
 -- have vastly different workforces both in size and capabilities.
 
 