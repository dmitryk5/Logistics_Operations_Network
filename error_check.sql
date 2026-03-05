-- Missing trucks? -- 

WITH maintenance_per_truck AS (
    SELECT truck_id,
           SUM(maintenance_cost) AS total_maintenance_cost,
           SUM(downtime_hours) AS total_downtime_hours
    FROM base_maintenance_costs
    GROUP BY truck_id
)
SELECT
    t.truck_id,
    COUNT(*) AS trips_completed,
    SUM(t.actual_distance_miles) AS total_miles,
    SUM(t.idle_time_hours) AS total_idle_hours,
    COALESCE(m.total_downtime_hours,0) AS total_downtime_hours,
    COALESCE(m.total_maintenance_cost,0) AS total_maintenance_cost
FROM base_trips t
LEFT JOIN maintenance_per_truck m
  ON t.truck_id = m.truck_id
GROUP BY t.truck_id, m.total_downtime_hours, m.total_maintenance_cost
ORDER BY truck_id;

SELECT COUNT(*) AS trips_missing_truck
FROM base_trips
WHERE truck_id IS NULL OR truck_id = '';

-- Trips without matching maintenance or fuel tables --

SELECT t.trip_id, t.truck_id, t.driver_id, t.dispatch_date
FROM base_trips t
LEFT JOIN base_maintenance_costs m ON t.truck_id = m.truck_id
LEFT JOIN base_fuel_costs f ON t.trip_id = f.trip_id
WHERE m.truck_id IS NULL AND f.trip_id IS NULL
ORDER BY driver_id;

-- Check truck_id contents -- 
-- NOTE: 1,672 unassigned trucks. Important to understand why these are unassigned. --

SELECT truck_id, COUNT(*) 
FROM base_trips
GROUP BY truck_id
ORDER BY COUNT(*) DESC;

SELECT
    CASE 
        WHEN NULLIF(truck_id, '') IS NULL THEN 'Unassigned'
        ELSE truck_id
    END AS truck_id_clean,
    COUNT(*) AS trips_per_truck
FROM base_trips
GROUP BY 1
ORDER BY trips_per_truck DESC;

SELECT *
FROM base_trips
LIMIT 10;

SELECT 
	MAX(dispatch_date),
	MIN(dispatch_date)
FROM
	base_trips;

-- --

SELECT *
FROM base_trips_v3 btv 
LIMIT 5;
