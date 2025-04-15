/* ================================================================================== 
Query Title: Easter days list
Description: This query generates dates from Easter Friday to Easter Monday of any year.
==================================================================================
Anna Horáková | MeasureDesign www.measuredesign.cz anna.horakova@measuredesign.cz

Created On: 2024-08-01 Last Updated: 2025-04-10

Usage: The output is useful when you need to know the exact dates of Easter holidays for specific years (in past as well as in the future). For example when determining bank holidays during Easter which is a movable feast (the date changes every year).
By default it generates a list of Easter days from 2024 to 2100. You can easily change this at the beginning of the script (see the comment below).

For questions or contributions, please send us an e-mail: info@measuredesign.cz 
Or submit an issue on our GitHub repository.

================================================================================== */

-- Your SQL query starts here

WITH years AS (
  SELECT * 
  FROM UNNEST(GENERATE_ARRAY(2024, 2100)) AS year_col /* CHANGE YEAR RANGE */

), 

mods AS (
  SELECT 
    CAST(year_col AS INT64) as year_col,
    MOD (year_col,19) as a,
    MOD (year_col, 4) as b,
    MOD (year_col, 7) as c,
  FROM years
), 
mods2 AS (
  SELECT 
    CAST (year_col as string) as year_col,
    a, b, c,
    MOD ((19*a)+24, 30) as d
  FROM mods
),

mods3 AS (
  SELECT
    *,
    MOD (5+(2*b)+(4*c)+(6*d), 7) as e
  FROM mods2
),

concat_dates as (
  SELECT 
    *,
    CONCAT (
      CAST (mods3.year_col as string),
      CASE 
        WHEN d = 29 and e = 6 then cast ("0419" as string)
        WHEN d = 28 and e = 6 then cast ("0418" as string)
        WHEN (22+d+e) > 31 then cast ((concat ("04", FORMAT('%02d', (22+d+e-31)))) as string)
        ELSE cast ((concat ("03", FORMAT('%02d', (22+d+e)))) as string)
      END
    ) as easter_sunday

  FROM mods3),

easter_dates as (
  SELECT *
  FROM concat_dates
)

SELECT
  FORMAT_DATE('%Y-%m-%d', DATE_ADD(PARSE_DATE('%Y%m%d', easter_sunday), INTERVAL i DAY)) AS easter_date,

/* MARK DAYS WITH DAY OF WEEK */
/*
  (CASE 
    WHEN i = -2 THEN "Easter Friday"
    WHEN i = -1 THEN "Easter Saturday"
    WHEN i = 0 THEN "Easter Sunday"
    WHEN i = 1 THEN "Easter Monday"
    ELSE "N/A"
    END
  ) as easter_day_of_week
*/
  FROM easter_dates
    CROSS JOIN UNNEST(GENERATE_ARRAY(-2, 1)) AS i
    WHERE DATE_ADD(PARSE_DATE('%Y%m%d', easter_sunday), INTERVAL i DAY) BETWEEN DATE_SUB(PARSE_DATE('%Y%m%d', easter_sunday), INTERVAL 2 DAY) AND DATE_ADD(PARSE_DATE('%Y%m%d', easter_sunday), INTERVAL 1 DAY)
    
order by easter_date;
