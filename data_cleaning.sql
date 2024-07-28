-- Initial overview of Data  
SELECT *
FROM layoffs;

-- Create staging tables to preserve original data 
CREATE TABLE layoffs_staging
LIKE layoffs; 

-- Check that staging table is empty
SELECT *
FROM layoffs_staging;  

-- Insert data into staging table from layoffs dataset
INSERT layoffs_staging
SELECT * 
FROM layoffs;


-- Check staging table is filled 
SELECT *
FROM layoffs_staging; 

-- Now that staging table is complete, data cleaning can start
	-- Duplicated
    -- Removing columns 
    -- Standardization 
    
-- Duplicates: This dataset has no unique identifier 
/*
Make a unique identifier with all the rows to identify which entries have duplicates using 'PARTITION BY' for each column.
This will be a cte and the row_num will identify if that row is unique or not.  
*/

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Create second staging table to delete values where row_num > 1
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int -- add row_num 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- Check that second staging table is empty
SELECT *
FROM layoffs_staging2;

-- Insert from layoffs_staging into layoffs_staging2 
INSERT INTO layoffs_staging2
(`company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
`row_num`)
SELECT `company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM layoffs_staging;

-- Check layoffs_staging2 has the data inserted. Filter row_num > 1 
SELECT * 
FROM layoffs_staging2 
WHERE row_num > 1;

-- Delete duplicates where row_num > 1
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- Check table does not have row_num >1 
SELECT * 
FROM layoffs_staging2 
WHERE row_num > 1;

-- Standardization
SELECT company, TRIM(company)   
FROM layoffs_staging2; 
    
-- Update table with TRIM(company)
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Investigate industry columns
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;  

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%'; -- various naming methods used

-- Update all crypto currency variation to = 'Crypto'
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT industry 
FROM layoffs_staging2
ORDER BY 1; 

-- Investigate country column
SELECT DISTINCT(country)
FROM layoffs_staging2
ORDER BY 1; 
 
-- United States has 2 naming methods
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Verify it changed to 'United States'
SELECT * 
FROM layoffs_staging2
WHERE country LIKE 'United States';

-- Change date column datatype from string to datetime
SELECT `date`
FROM layoffs_staging2;

SELECT `date`,
str_to_date(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = str_to_date(`date`,'%m/%d/%Y');

-- Alter table to date format 
ALTER TABLE layoffs_staging2
MODIFY COLUMN  `date` DATE; 

-- Review date column 
SELECT * 
FROM layoffs_staging2;

-- Find same company columns with blank values and fill them in 
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2 
	ON t1.company = t2.company 
    AND t1.location = t2.location
WHERE (t1.industry IS NULL or t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company 
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL; 

-- Check that blank values are handled 
SELECT company, industry
FROM layoffs_staging2;


/*
Unsuccessful
Next approach: Change the blank values to NULL and then join the tables from t1 to t2 for industry 
*/ 

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = ''; 

-- Check blanks changed to NULL 
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2 
	ON t1.company = t2.company 
    AND t1.location = t2.location
WHERE (t1.industry IS NULL or t1.industry = '')
AND t2.industry IS NOT NULL;

-- Update table from NULL and fill NULL values with industry for same company name 
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company 
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL; 

-- Review it worked 
SELECT *
FROM layoffs_staging2 
WHERE industry IS NULL;

-- Review other columns with missing values 
SELECT *
FROM layoffs_staging2 
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

/*
Deleting total_laid_off and percentage_laid_off values that are NULL -> can affect EDA
*/ 

-- Delete NULLs 
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Review columns
SELECT *
FROM layoffs_staging2 
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Drop row_num column
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging2;

/*
Data cleaning process has been completed 
*/ 