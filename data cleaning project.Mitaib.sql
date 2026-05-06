-- ============================================
-- DATA CLEANING PROJECT
-- ============================================

-- STEP 1: Create staging table
CREATE TABLE layoffs_staging 
LIKE layoffs;

INSERT INTO layoffs_staging
SELECT *
FROM layoffs;

-- STEP 2: View staging table
SELECT *
FROM layoffs_staging;

-- STEP 3: Check for duplicates
WITH duplicate_cte AS (
    SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, total_laid_off, 
        percentage_laid_off, date, stage, country, funds_raised
    ) AS row_num 
    FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- STEP 4: Create staging2 table with row_num column
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `total_laid_off` double DEFAULT NULL,
  `date` text,
  `percentage_laid_off` text,
  `industry` text,
  `source` text,
  `stage` text,
  `funds_raised` int DEFAULT NULL,
  `country` text,
  `date_added` text,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- STEP 5: Insert data into staging2 with row_num
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER (
    PARTITION BY company, location, industry, total_laid_off, 
    percentage_laid_off, date, stage, country, funds_raised
) AS row_num 
FROM layoffs_staging;

-- STEP 6: Delete duplicates
SET SQL_SAFE_UPDATES = 0;

DELETE FROM layoffs_staging2
WHERE row_num > 1;

-- Verify duplicates removed
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- ============================================
-- STANDARDIZING DATA
-- ============================================

-- STEP 7: Trim company names
UPDATE layoffs_staging2
SET company = TRIM(company);

-- STEP 8: Fix industry naming inconsistencies
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- STEP 9: Fix country naming inconsistencies
UPDATE layoffs_staging2
SET country = 'United Arab Emirates'
WHERE country = 'UAE';

-- STEP 10: Fix date format
UPDATE layoffs_staging2
SET date_added = STR_TO_DATE(date_added, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN date_added DATE;

-- ============================================
-- HANDLING NULLS & BLANKS
-- ============================================

-- STEP 11: Convert blank percentage_laid_off to NULL
UPDATE layoffs_staging2
SET percentage_laid_off = NULL
WHERE percentage_laid_off = '';

-- STEP 12: Fill in missing industries using self join
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- Verify remaining NULLs
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- ============================================
-- FINAL CLEANUP
-- ============================================

-- STEP 13: Drop row_num column
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Final check
SELECT *
FROM layoffs_staging2;