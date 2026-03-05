-- Analyzing Executive Questions: Asset Efficiency --

-- Which trucks are underutilized vs. overworked? --
-- NOTES: Average maintenace cost ranges from 1200 to 2600. Why? Look into routes, truck-specific factors, etc. -- 
-- NOTES: Top 5 trucks very efficient, Bottom 5 trucks inefficient. Look into why later. -- 

WITH truck_activity AS (
    SELECT
        CASE 
            WHEN NULLIF(t.truck_id, '') IS NULL THEN 'Unassigned'
            ELSE t.truck_id
        END AS truck_id_clean,
        COUNT(DISTINCT t.trip_id) AS trips_completed,
        SUM(t.actual_distance_miles) AS total_miles,
        SUM(t.idle_time_hours) AS total_idle_hours
    FROM base_trips t
    GROUP BY 1
),
truck_maintenance AS (
    SELECT
        CASE 
            WHEN NULLIF(truck_id, '') IS NULL THEN 'Unassigned'
            ELSE truck_id
        END AS truck_id_clean,
        SUM(downtime_hours) AS total_downtime_hours,
        SUM(maintenance_cost) AS total_maintenance_cost,
        AVG(maintenance_cost) AS avg_maintenance_cost
    FROM base_maintenance_costs
    GROUP BY 1
)
SELECT
    a.truck_id_clean AS truck_id,
    a.trips_completed,
    a.total_miles,
    a.total_idle_hours,
    COALESCE(m.total_downtime_hours,0) AS total_downtime_hours,
    COALESCE(m.total_maintenance_cost,0) AS total_maintenance_cost,
    ROUND(COALESCE(m.avg_maintenance_cost,0)::numeric, 2) AS avg_maintenance_cost,
    ROUND(
        (a.total_miles / NULLIF(a.total_miles + a.total_idle_hours + COALESCE(m.total_downtime_hours,0),0))::numeric,
        2
    ) AS utilization_ratio
FROM truck_activity a
LEFT JOIN truck_maintenance m
    ON a.truck_id_clean = m.truck_id_clean
ORDER BY avg_maintenance_cost  ASC;

-- How does truck age affect downtime and maintenance cost? --
-- NOTES: Fleet composition drives total impact --
-- NOTES: Per-truck performance is stable --
-- NOTES: Younger trucks are fewer and slightly costlier per unit --
-- NOTES: Only 7.5% of trucks are <= 5 years --

WITH truck_summary AS (
    SELECT
        tr.truck_id,
        2024 - tr.model_year AS truck_age,
        SUM(d.downtime_hours) AS total_downtime_hours,
        SUM(d.maintenance_cost) AS total_maintenance_cost,
        AVG(d.maintenance_cost) AS avg_maintenance_cost,
        AVG(d.downtime_hours) AS avg_downtime_hours
    FROM base_maintenance_costs d
    JOIN trucks tr USING (truck_id)
    GROUP BY tr.truck_id, truck_age
)
SELECT
    truck_age,
    COUNT(truck_id) AS num_trucks,
    SUM(total_downtime_hours) AS downtime_hours,
    ROUND(AVG(avg_downtime_hours)::numeric, 2) AS avg_downtime_hours,
    SUM(total_maintenance_cost) AS maintenance_cost,
    ROUND(AVG(avg_maintenance_cost)::numeric, 2) AS avg_maintenance_cost
FROM truck_summary
GROUP BY truck_age
ORDER BY truck_age;

-- Are we fleet-constrained or demand-constrained? --
-- NOTES: Most trucks are operating near maximum capacity (0.99–1.00) --
-- NOTES: Expansion might be necessary if growth is expected -- 

WITH truck_activity AS (
    SELECT
        CASE 
            WHEN NULLIF(truck_id, '') IS NULL THEN 'Unassigned'
            ELSE truck_id
        END AS truck_id_clean,
        COUNT(DISTINCT trip_id) AS trips_completed,
        SUM(actual_distance_miles) AS total_miles,
        SUM(actual_duration_hours) AS total_hours_worked,
        SUM(idle_time_hours) AS total_idle_hours,
        ROUND(
            (SUM(actual_distance_miles) / NULLIF(SUM(actual_distance_miles + idle_time_hours), 0))::numeric, 
            2
        ) AS utilization_ratio
    FROM base_trips
    GROUP BY 1
),
fleet_summary AS (
    SELECT
        COUNT(DISTINCT truck_id_clean) AS total_trucks,
        SUM(trips_completed) AS total_trips_completed,
        SUM(total_miles) AS total_miles_completed,
        SUM(total_hours_worked) AS total_hours_worked,
        SUM(total_idle_hours) AS total_idle_hours,
        ROUND(AVG(utilization_ratio), 2) AS avg_utilization,
        MIN(utilization_ratio) AS min_utilization,
        MAX(utilization_ratio) AS max_utilization
    FROM truck_activity
)
SELECT *
FROM fleet_summary;
