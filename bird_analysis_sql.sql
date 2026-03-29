create database birds_db;
use birds_db;

describe bird;
SET GLOBAL local_infile = 1;

select count(*) as total_bird_observation from bird;

SHOW KEYS FROM bird WHERE Key_name = 'PRIMARY';
ALTER TABLE bird
ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY;

SELECT 
  COUNT(*) AS total_rows,
  COUNT(Date) AS date_filled,
  COUNT(Common_Name) AS species_filled
FROM bird;

DESCRIBE bird;

SELECT DISTINCT Flyover_Observed
FROM bird;


ALTER TABLE bird
ADD COLUMN Date_new DATE,
ADD COLUMN Start_Time_new TIME,
ADD COLUMN End_Time_new TIME;

SET SQL_SAFE_UPDATES = 0;
UPDATE bird
SET 
  Date_new = CASE 
    WHEN Date IS NOT NULL THEN DATE(Date)
    ELSE NULL END,
    
  Start_Time_new = CASE 
    WHEN Start_Time IS NOT NULL THEN TIME(Start_Time)
    ELSE NULL END,

  End_Time_new = CASE 
    WHEN End_Time IS NOT NULL THEN TIME(End_Time)
    ELSE NULL END;

SELECT Date, Date_new, Start_Time, Start_Time_new
FROM bird
LIMIT 20;

ALTER TABLE bird
DROP COLUMN Date,
DROP COLUMN Start_Time,
DROP COLUMN End_Time;

ALTER TABLE bird
CHANGE Date_new Date DATE,
CHANGE Start_Time_new Start_Time TIME,
CHANGE End_Time_new End_Time TIME;

SELECT Site_Name, Date, Start_Time, Observer, Habitat, COUNT(*)
FROM bird
GROUP BY Site_Name, Date, Start_Time, Observer, Habitat
HAVING COUNT(*) > 1;

SELECT SUM(cnt - 1) AS total_duplicates
FROM (
    SELECT COUNT(*) AS cnt
    FROM bird
    GROUP BY Site_Name, Date, Start_Time, Observer,  Habitat,
    HAVING cnt > 1
) t;

-- Temperature sanity check
SELECT *
FROM bird
WHERE Temperature < -10 OR Temperature > 60;

-- Humidity check
SELECT *
FROM bird
WHERE Humidity < 0 OR Humidity > 100;

-- View: Seasonal Trend
CREATE VIEW v_seasonal_trends AS
SELECT 
    Year,
    Season,
    COUNT(*) AS total_observations,
    COUNT(DISTINCT Scientific_Name) AS species_count
FROM bird
GROUP BY Year, Season;
select * from v_seasonal_trends;

-- View: Time of Day Activity
CREATE VIEW v_time_activity AS
SELECT 
    Time_of_Day,
    COUNT(*) AS total_observations,
    AVG(Count_per_Min) AS avg_activity
FROM bird
GROUP BY Time_of_Day;
select * from v_time_activity;

-- View: Location Biodiversity
CREATE VIEW v_location_biodiversity AS
SELECT 
    Location_Type,
    COUNT(DISTINCT Scientific_Name) AS species_richness,
    COUNT(*) AS total_records
FROM bird
GROUP BY Location_Type;

-- View: Plot Performance
CREATE VIEW v_plot_analysis AS
SELECT 
    Plot_Name,
    COUNT(DISTINCT Scientific_Name) AS species_count,
    SUM(Detected) AS total_birds
FROM bird
GROUP BY Plot_Name;

-- 3. SPECIES ANALYSIS

CREATE VIEW v_species_abundance AS
SELECT 
    Common_Name,
    Scientific_Name,
    SUM(Detected) AS total_count
FROM bird
GROUP BY Common_Name, Scientific_Name
ORDER BY total_count DESC;

-- View: Sex Ratio
CREATE VIEW v_sex_ratio AS
SELECT 
    Scientific_Name,
    Sex,
    COUNT(*) AS count
FROM bird
GROUP BY Scientific_Name, Sex;

-- 4. ENVIRONMENTAL ANALYSIS 
-- View: Weather Impact
CREATE VIEW v_weather_impact AS
SELECT 
    Sky,
    Wind,
    AVG(Detected) AS avg_bird_count,
    AVG(Count_per_Min) AS avg_activity
FROM bird
GROUP BY Sky, Wind;

-- View: Temperature vs Activity
CREATE VIEW v_temp_activity AS
SELECT 
    Temp_Category,
    AVG(Detected) AS avg_detected,
    AVG(Count_per_Min) AS avg_activity
FROM bird
GROUP BY Temp_Category;

-- 5. DISTANCE & BEHAVIOR
-- View: Distance Analysis
CREATE VIEW v_distance_analysis AS
SELECT 
    Distance,
    COUNT(*) AS observations
FROM bird
GROUP BY Distance;

-- View: Flyover Trends
CREATE VIEW v_flyover AS
SELECT 
    Flyover_Observed,
    COUNT(*) AS total
FROM bird
GROUP BY Flyover_Observed;

-- 6. OBSERVER ANALYSIS
-- View: Observer Performance
CREATE VIEW v_observer_analysis AS
SELECT 
    Observer,
    COUNT(*) AS total_records,
    COUNT(DISTINCT Scientific_Name) AS species_recorded
FROM bird
GROUP BY Observer;

-- Visit Impact
CREATE VIEW v_visit_analysis AS
SELECT 
    Visit,
    COUNT(DISTINCT Scientific_Name) AS species_count,
    AVG(Detected) AS avg_detected
FROM bird
GROUP BY Visit;

-- 7. CONSERVATION ANALYSIS
-- view: conservation focus
CREATE VIEW v_conservation AS
SELECT 
    PIF_Watchlist_Status,
    Regional_Stewardship_Status,
    COUNT(DISTINCT Scientific_Name) AS species_count,
    SUM(Detected) AS total_detected
FROM bird
GROUP BY PIF_Watchlist_Status, Regional_Stewardship_Status;


-- SPECIES DIVERSITY RANKING PER LOCATION
WITH seasonal_counts AS (
    SELECT 
        Year,
        Season,
        Scientific_Name,
        SUM(Detected) AS total_detected
    FROM bird
    GROUP BY Year, Season, Scientific_Name
),
ranked AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY Year, Season ORDER BY total_detected DESC) AS species_rank
    FROM seasonal_counts
)
SELECT *
FROM ranked
WHERE species_rank <= 5;

-- OBSERVER PERFORMANCE ANALYSIS
WITH observer_visits AS (
    SELECT 
        Observer,
        Visit,
        COUNT(DISTINCT Scientific_Name) AS species_count
    FROM bird
    GROUP BY Observer, Visit
)
SELECT
    Observer,
    Visit,
    species_count,
    RANK() OVER (PARTITION BY Observer ORDER BY species_count DESC) AS visit_rank
FROM observer_visits;

-- WEATHER IMPACT WITH AVERAGE RANK
WITH temp_activity AS (
    SELECT 
        Temp_Category,
        AVG(Count_per_Min) AS avg_activity
    FROM bird
    GROUP BY Temp_Category
)
SELECT
    *,
    RANK() OVER (ORDER BY avg_activity DESC) AS activity_rank
FROM temp_activity;

-- WITH temp_activity AS (

WITH temp_activity AS (
    SELECT 
        Temp_Category,
        AVG(Count_per_Min) AS avg_activity
    FROM bird
    GROUP BY Temp_Category
)
SELECT
    *,
    RANK() OVER (ORDER BY avg_activity DESC) AS activity_rank
FROM temp_activity;

-- view of top species by season
CREATE VIEW v_top_species_per_season AS
WITH seasonal_counts AS (
    SELECT Year, Season, Scientific_Name, SUM(Detected) AS total_detected
    FROM bird
    GROUP BY Year, Season, Scientific_Name
)
SELECT *,
       RANK() OVER (PARTITION BY Year, Season ORDER BY total_detected DESC) AS species_rank
FROM seasonal_counts;

select * from v_top_species_per_season;

-- CREATE VIEW v_observer_top_visits AS
WITH observer_visits AS (
    SELECT 
        Observer,
        Visit,
        COUNT(DISTINCT Scientific_Name) AS species_count
    FROM bird
    GROUP BY Observer, Visit
),
ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY Observer ORDER BY species_count DESC) AS visit_rank
    FROM observer_visits
)
SELECT *
FROM ranked
WHERE visit_rank <= 3;

SHOW TABLES;













