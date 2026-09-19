CREATE DATABASE ATLIQ_EV;
USE ATLIQ_EV;

SELECT * FROM atliq_ev.dim_date_cleaned LIMIT 10;

SELECT * FROM atliq_ev.electric_vehicle_sales_by_makers_cleaned LIMIT 10;

SELECT sum(total_vehicles_sold)  FROM atliq_ev.electric_vehicle_sales_by_state_cleaned ;




SELECT distinct FISCAL_YEAR FROM atliq_ev.dim_date_cleaned ;


-- 1)List the top 3 and bottom 3 makers for FY2023 and FY2024 in terms of the number of 2-wheelers sold.
WITH maker_sales AS (
    SELECT
        fiscal_year,
        maker,
        SUM(electric_vehicles_sold) AS total_2w_sales
    FROM atliq_ev.electric_vehicle_sales_by_makers_cleaned
    WHERE vehicle_category = '2-Wheelers'
      AND fiscal_year IN (2023, 2024)
    GROUP BY
        fiscal_year,
        maker
),

ranked_makers AS (
    SELECT
        fiscal_year,
        maker,
        total_2w_sales,

        -- Highest sales = Rank 1
        DENSE_RANK() OVER (
            PARTITION BY fiscal_year
            ORDER BY total_2w_sales DESC
        ) AS top_rank,

        -- Lowest sales = Rank 1
        DENSE_RANK() OVER (
            PARTITION BY fiscal_year
            ORDER BY total_2w_sales ASC
        ) AS bottom_rank

    FROM maker_sales
)

SELECT
    fiscal_year,
    maker,
    total_2w_sales,

    CASE
        WHEN top_rank <= 3 THEN 'Top 3'
        WHEN bottom_rank <= 3 THEN 'Bottom 3'
    END AS category,

    CASE
        WHEN top_rank <= 3 THEN top_rank
        WHEN bottom_rank <= 3 THEN bottom_rank
    END AS rank_position

FROM ranked_makers

WHERE top_rank <= 3
   OR bottom_rank <= 3

ORDER BY
    fiscal_year,
    category,
    rank_position;


-- 2)Identify the top 5 states with the highest penetration rate in 2-wheeler 
-- and 4-wheeler EV sales in FY 2024. 

WITH state_penetration AS (
    SELECT
        d.fiscal_year,
        s.state,
        s.vehicle_category,

        SUM(s.electric_vehicles_sold) AS ev_sales,

        SUM(s.total_vehicles_sold) AS total_vehicle_sales,

        ROUND(
            SUM(s.electric_vehicles_sold)
            / NULLIF(SUM(s.total_vehicles_sold), 0) * 100,
            2
        ) AS penetration_rate

    FROM atliq_ev.electric_vehicle_sales_by_state_cleaned AS s

    JOIN atliq_ev.dim_date_cleaned AS d
        ON s.date = d.date

    WHERE d.fiscal_year = 2024

    GROUP BY
        d.fiscal_year,
        s.state,
        s.vehicle_category
),

ranked_states AS (
    SELECT
        fiscal_year,
        state,
        vehicle_category,
        ev_sales,
        total_vehicle_sales,
        penetration_rate,

        DENSE_RANK() OVER (
            PARTITION BY vehicle_category
            ORDER BY penetration_rate DESC
        ) AS penetration_rank

    FROM state_penetration
)

SELECT
    fiscal_year,
    state,
    vehicle_category,
    ev_sales,
    total_vehicle_sales,
    penetration_rate,
    penetration_rank

FROM ranked_states

WHERE penetration_rank <= 5

ORDER BY
    vehicle_category,
    penetration_rank;
    
 -- 3) List the states with negative penetration (decline) in EV sales from 2022 
-- to 2024?    
WITH state_penetration AS (
    SELECT
        d.fiscal_year,
        s.state,
        s.vehicle_category,

        SUM(s.electric_vehicles_sold) AS ev_sales,

        SUM(s.total_vehicles_sold) AS total_vehicle_sales,

      Round(  SUM(s.electric_vehicles_sold)
        / NULLIF(SUM(s.total_vehicles_sold), 0) * 100,2)
        AS penetration_rate

    FROM atliq_ev.electric_vehicle_sales_by_state_cleaned AS s

    JOIN atliq_ev.dim_date_cleaned AS d
        ON s.date = d.date

    WHERE d.fiscal_year IN (2022, 2024)

    GROUP BY
        d.fiscal_year,
        s.state,
        s.vehicle_category
)

SELECT *
FROM state_penetration
ORDER BY
    state,
    vehicle_category,
    fiscal_year asc;
    
-- 4)What are the quarterly trends based on sales volume for the top 5 EV 
-- makers (4-wheelers) from 2022 to 2024? 
WITH maker_sales AS (
    SELECT
        maker,
        SUM(electric_vehicles_sold) AS total_sales
    FROM atliq_ev.electric_vehicle_sales_by_makers_cleaned
    WHERE vehicle_category = '4-Wheelers'
      AND fiscal_year IN (2022, 2023, 2024)
    GROUP BY maker
),

top_5_makers AS (
    SELECT
        maker,
        total_sales,
        DENSE_RANK() OVER (
            ORDER BY total_sales DESC
        ) AS maker_rank
    FROM maker_sales
)

SELECT
    m.fiscal_year,
    m.quarter,
    m.maker,
    SUM(m.electric_vehicles_sold) AS quarterly_sales
FROM atliq_ev.electric_vehicle_sales_by_makers_cleaned AS m
JOIN top_5_makers AS t
    ON m.maker = t.maker
WHERE m.vehicle_category = '4-Wheelers'
  AND m.fiscal_year IN (2022, 2023, 2024)
  AND t.maker_rank <= 5
GROUP BY
    m.fiscal_year,
    m.quarter,
    m.maker
ORDER BY
    m.fiscal_year,
    m.quarter,
    t.maker_rank;
    
-- 5)How do the EV sales and penetration rates in Delhi compare to 
-- Karnataka for 2024? 
SELECT
    s.state,
    s.vehicle_category,

    SUM(s.electric_vehicles_sold) AS ev_sales,

    SUM(s.total_vehicles_sold) AS total_vehicle_sales,

    ROUND(
        SUM(s.electric_vehicles_sold) /
        NULLIF(SUM(s.total_vehicles_sold), 0) * 100,
        2
    ) AS penetration_rate

FROM atliq_ev.electric_vehicle_sales_by_state_cleaned AS s

JOIN atliq_ev.dim_date_cleaned AS d
    ON s.date = d.date

WHERE d.fiscal_year = 2024
  AND s.state IN ('Delhi', 'Karnataka')

GROUP BY
    s.state,
    s.vehicle_category

ORDER BY
    s.state,
    s.vehicle_category;
-- 6)
