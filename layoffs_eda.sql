/*
Exploratory Data Analysis 

Explore each column to identify patterns in the data and answer questions regarding:

- Identify the timing of layoffs: When did they occur?
- Determine the industry with the highest number of layoffs.
- Investigate if there is a particular pattern or trend in the timing of layoffs.
- Find out which industry experienced the fewest layoffs.
- Analyze how layoffs vary by country.
- Explore whether funding levels influence the frequency of layoffs.
*/ 

-- Retrieve all data for review
SELECT *
FROM layoffs_staging2;

-- Determine the date range 
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;
-- Date range spans from 2020 to 2023; consider COVID-19's potential impact on widespread layoffs.
-- Maximum number of layoffs recorded
-- 12,000 total layoffs with 100% of employees laid off (company went under)
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- Investigate companies with total layoffs
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

/*
Major global companies with significant layoffs:
Amazon: 18,150
Google: 12,000
Meta: 11,000
Salesforce: 10,090
Microsoft: 10,000
Philips: 10,000

The smallest number of layoffs recorded is 35 employees.
*/

-- Analyze layoffs by industry
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

/*
Top 5 industries most affected by layoffs:
1. Consumer: 45,182
2. Retail: 43,613
3. Other: 36,289
4. Transportation: 33,748
5. Finance: 28,344
*/

-- Analyze layoffs by country
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2 
GROUP BY country
ORDER BY 2 DESC;  
-- The United States has the highest total layoffs, surpassing all other countries combined in the dataset.

-- Examine layoffs by date for the United States
SELECT YEAR(`date`),country, SUM(total_laid_off)
FROM layoffs_staging2 
WHERE country = 'United States'
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;  

-- Analyze layoffs by date across all countries
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2 
GROUP BY YEAR(`date`)
ORDER BY 2 DESC;  

/*
2022 recorded the highest number of layoffs, while 2021 had the lowest.
Note: Data for 2023 covers only three months, but total layoffs are already at 125,677.
*/

SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2 
GROUP BY YEAR(`date`)
ORDER BY 2 DESC; 

-- Analyze layoffs by company stage
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;
-- Companies in the Post-IPO stage experienced the most layoffs (204,132).
-- Subsidiary and Seed stages had the fewest layoffs.

-- Monthly layoffs data across the years (excluding NULLs)
SELECT substring(`date`,1,7) AS `Month`, sum(total_laid_off)
FROM layoffs_staging2
WHERE substring(`date`,1,7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ASC; 

-- Total number of layoffs is 383,159 (383,659 including NULLs). Analyze the distribution across months and years.
SELECT sum(total_laid_off)
FROM layoffs_staging2; 

/*
Generate a cumulative total of layoffs by month and year to observe the total accumulation.
*/

WITH Rolling_Total AS
( 
SELECT substring(`date`,1,7) AS `Month`, sum(total_laid_off) As total_layoffs
FROM layoffs_staging2
WHERE substring(`date`,1,7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ASC
)
SELECT `Month`, total_layoffs
, sum(total_layoffs) OVER (ORDER BY `Month`) As rolling_total 
FROM Rolling_Total;
-- In 2022, the rolling total for layoffs increased significantly from 96,821 to 257,482.

-- Include a percentage column to better understand the impact of layoffs per month and year 
WITH Rolling_Total AS
( 
    SELECT 
        SUBSTRING(`date`, 1, 7) AS `Month`, 
        SUM(total_laid_off) AS total_layoffs
    FROM layoffs_staging2
    WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
    GROUP BY `Month`
    ORDER BY 1 ASC
)
SELECT 
    `Month`, 
    total_layoffs,
    ROUND((total_layoffs / SUM(total_layoffs) OVER ()) * 100, 2) AS percentage_of_total,
    SUM(total_layoffs) OVER (ORDER BY `Month`) AS rolling_total 
FROM Rolling_Total;
-- January 2023 had the highest percentage of global layoffs.

-- Identify the country with the highest number of layoffs
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;
-- The United States had the majority of layoffs (256,559 out of 383,659, which is 67% of the total).

-- Identify the company with the highest number of layoffs by year
SELECT company, YEAR (`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

/*
The majority of layoffs are attributed to major American companies such as Amazon, Google, Meta, and Microsoft.
2023 saw the highest layoff percentage, despite having only three months of recorded data.
*/
