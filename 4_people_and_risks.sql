-- Analyzing Executive Questions: People and Risks --

-- Top 5 vs Bottom 5 Trucks -- 
-- NOTES: Trucks 7, 19, 58, 92, ad 107 are most efficient. Trucks 1, 11, 24, and 33 least efficient. All ratios are good.--
-- NOTES: High Utilization Across the Fleet -- 
-- Recommendations: Maintenance schedule optimization. Route or assignment review --

WITH truck_summary AS (
    SELECT
        CASE 
            WHEN NULLIF(t.truck_id, '') IS NULL THEN 'Unassigned'
            ELSE t.truck_id
        END AS truck_id,
        COUNT(DISTINCT t.trip_id) AS trips_completed,
        SUM(t.actual_distance_miles) AS total_miles,
        SUM(t.idle_time_hours) AS total_idle_hours,
        COALESCE(SUM(m.downtime_hours), 0) AS total_downtime_hours,
        COALESCE(SUM(m.maintenance_cost), 0) AS total_maintenance_cost,
        ROUND(
            (SUM(t.actual_distance_miles) / NULLIF(SUM(t.actual_distance_miles + t.idle_time_hours + COALESCE(m.downtime_hours,0)), 0))::numeric,
            3
        ) AS utilization_ratio
    FROM base_trips t
    LEFT JOIN base_maintenance_costs m
        ON t.truck_id = m.truck_id
    GROUP BY 1
)
SELECT *
FROM truck_summary
ORDER BY utilization_ratio DESC;

-- Which drivers have elevated risk profiles? --
-- NOTES: No major discrepency between idle hours across drivers (6.7 to 7.35 hours per trip) --
-- Recommendations: For drivers with higher idle times, check: Longer waits at loading/unloading points AND Potential inefficiencies in routing or scheduling --

WITH driver_stats AS (
    SELECT
        driver_id,
        COUNT(trip_id) AS total_trips,
        SUM(actual_distance_miles) AS total_miles,
        SUM(idle_time_hours) AS total_idle_hours,
        ROUND(AVG(idle_time_hours)::NUMERIC, 3) AS avg_idle_per_trip,
        SUM(
            CASE 
                WHEN (CAST(dispatch_date AS DATE) + (typical_transit_days * interval '1 day'))
                     >= (CAST(dispatch_date AS DATE) + (actual_duration_hours / 24) * interval '1 day')
                THEN 1 ELSE 0
            END
        ) AS on_time_trips,
        ROUND(
            AVG(
                CASE 
                    WHEN (CAST(dispatch_date AS DATE) + (typical_transit_days * interval '1 day'))
                         >= (CAST(dispatch_date AS DATE) + (actual_duration_hours / 24) * interval '1 day')
                    THEN 1 ELSE 0
                END
            ), 2
        ) AS on_time_pct,
        MAX(driver_years_experience) AS years_experience
    FROM base_trips
    GROUP BY driver_id
)
SELECT *
FROM driver_stats
WHERE
    avg_idle_per_trip > 2        -- high idle per trip
    OR on_time_pct < 0.90        -- low on-time %
    OR years_experience < 2      -- low experience
ORDER BY avg_idle_per_trip DESC, on_time_pct ASC;

-- How does driver tenure correlate with: mpg, on-time %, safety incidents? --
-- NOTES: Driver experience does not materially impact MPG or on-time delivery --
-- NOTES: Safety risk and cost do vary by tenure - Incidents highest with 10-15 and 16-20 groups (0.0022). At fault highest with <5 group (0.0010). --

WITH driver_trip_perf AS (
    SELECT
        driver_id,
        driver_years_experience,
        AVG(average_mpg) AS avg_mpg,
        COUNT(trip_id) AS total_trips,
        SUM(
            CASE
                WHEN 
                    CAST(dispatch_date AS DATE)
                    + (actual_duration_hours / 24.0) * INTERVAL '1 day'
                    <=
                    CAST(dispatch_date AS DATE)
                    + typical_transit_days * INTERVAL '1 day'
                THEN 1
                ELSE 0
            END
        ) AS on_time_trips
    FROM base_trips
    GROUP BY driver_id, driver_years_experience
),
driver_safety AS (
    SELECT
        driver_id,
        COUNT(incident_id) AS total_incidents,
        SUM(CASE WHEN at_fault_flag THEN 1 ELSE 0 END) AS at_fault_incidents,
        SUM(claim_amount) AS total_claim_amount
    FROM safety_incidents
    GROUP BY driver_id
),
driver_combined AS (
    SELECT
        t.driver_id,
        t.driver_years_experience,
        t.avg_mpg,
        t.total_trips,
        t.on_time_trips,
        COALESCE(s.total_incidents, 0) AS total_incidents,
        COALESCE(s.at_fault_incidents, 0) AS at_fault_incidents,
        COALESCE(s.total_claim_amount, 0) AS total_claim_amount
    FROM driver_trip_perf t
    LEFT JOIN driver_safety s
        ON t.driver_id = s.driver_id
),
tenure_binned AS (
    SELECT
        CASE
            WHEN driver_years_experience < 5 THEN '<5'
            WHEN driver_years_experience BETWEEN 5 AND 9 THEN '5–9'
            WHEN driver_years_experience BETWEEN 10 AND 15 THEN '10–15'
            WHEN driver_years_experience BETWEEN 16 AND 20 THEN '16–20'
            ELSE '20+'
        END AS tenure_band,
        *
    FROM driver_combined
)
SELECT
    tenure_band,
    ROUND(AVG(avg_mpg)::NUMERIC, 2) AS avg_mpg,
    ROUND(
        SUM(on_time_trips)::NUMERIC / NULLIF(SUM(total_trips), 0),
        2
    ) AS on_time_pct,
    ROUND(
        SUM(total_incidents)::NUMERIC / NULLIF(SUM(total_trips), 0),
        4
    ) AS incident_rate_per_trip,
    ROUND(
        SUM(at_fault_incidents)::NUMERIC / NULLIF(SUM(total_trips), 0),
        4
    ) AS at_fault_rate_per_trip,
    ROUND(
        AVG(total_claim_amount)::NUMERIC,
        2
    ) AS avg_claim_cost_per_driver
FROM tenure_binned
GROUP BY tenure_band
ORDER BY tenure_band;
