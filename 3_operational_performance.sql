-- Analyzing Executive Questions: Operational Performance -- 

-- On time performance by route, city pair, customer -- 
-- NOTES: Only on-time discrepancies are on the same route from Philidelphia to Minneapolis --
-- Recommendations: Look into why these 7 trips have had trouble arriving on time. Why the same route? -- 

WITH trip_arrival AS (
    SELECT
        trip_id,
        route_id,
        origin_city,
        destination_city,
        customer_id,
        customer_name,
        dispatch_date,
        typical_transit_days,
        actual_duration_hours,
        (dispatch_date::timestamp + (actual_duration_hours / 24) * interval '1 day') AS actual_arrival_date,
        (dispatch_date::timestamp + (typical_transit_days * interval '1 day')) AS expected_arrival_date,
        CASE
            WHEN (dispatch_date::timestamp + (actual_duration_hours / 24) * interval '1 day') 
                 <= (dispatch_date::timestamp + (typical_transit_days * interval '1 day'))
            THEN 1
            ELSE 0
        END AS on_time_flag
    FROM base_trips
)
SELECT
    route_id,
    origin_city,
    destination_city,
    customer_id,
    customer_name,
    COUNT(trip_id) AS total_trips,
    SUM(on_time_flag) AS trips_on_time,
    ROUND(SUM(on_time_flag)::numeric / COUNT(trip_id), 2) AS on_time_percentage
FROM trip_arrival
GROUP BY 1,2,3,4,5
ORDER BY on_time_percentage ASC, total_trips DESC;

-- Where does detention usually happen? -- 
-- NOTES: Again we see the route from Philadelphia to Minneapolis. --
-- Recommendations: Find the source for why detention hours happen here specifically. --

WITH trip_detention AS (
    SELECT
        trip_id,
        route_id,
        origin_city,
        destination_city,
        customer_id,
        customer_name,
        dispatch_date::timestamp AS dispatch_ts,
        actual_duration_hours,
        typical_transit_days,
        -- approximate detention hours
        GREATEST(actual_duration_hours - (typical_transit_days * 24), 0) AS detention_hours
    FROM base_trips
)
SELECT
    origin_city,
    destination_city,
    customer_id,
    customer_name,
    COUNT(trip_id) AS total_trips,
    SUM(detention_hours) AS total_detention_hours,
    ROUND(AVG(detention_hours)::NUMERIC, 2) AS avg_detention_hours
FROM trip_detention
WHERE detention_hours > 0
GROUP BY 1,2,3,4
ORDER BY total_detention_hours DESC, avg_detention_hours DESC;

-- Does performance degrade during peak seasons? --
-- NOTES: February has substantially fewer trips than the other months. September worth looking into as well. -- 

WITH trip_performance AS (
    SELECT
        trip_id,
        dispatch_date::date AS dispatch_date,
        EXTRACT(MONTH FROM dispatch_date::date) AS dispatch_month,
        customer_id,
        customer_name,
        origin_city,
        destination_city,
        typical_transit_days,
        actual_duration_hours,
        -- calculate actual arrival
        dispatch_date::date + (actual_duration_hours / 24) * interval '1 day' AS actual_arrival_date,
        dispatch_date::date + (typical_transit_days * interval '1 day') AS expected_arrival_date,
        CASE
            WHEN dispatch_date::date + (actual_duration_hours / 24) * interval '1 day' 
                 <= dispatch_date::date + (typical_transit_days * interval '1 day')
            THEN 1
            ELSE 0
        END AS on_time_flag,
        GREATEST(actual_duration_hours - (typical_transit_days * 24), 0) AS detention_hours
    FROM base_trips
)
SELECT
    dispatch_month,
    COUNT(trip_id) AS total_trips,
    SUM(on_time_flag) AS trips_on_time,
    ROUND(SUM(on_time_flag)::numeric / COUNT(trip_id), 2) AS on_time_percentage,
    ROUND(AVG(detention_hours)::NUMERIC, 2) AS avg_detention_hours
FROM trip_performance
GROUP BY dispatch_month
ORDER BY dispatch_month;
