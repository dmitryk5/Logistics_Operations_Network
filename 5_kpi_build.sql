-- Create KPI-friendly monthly summary table --

WITH trip_costs AS (
    SELECT
        t.trip_id,
        DATE(CAST(t.dispatch_date AS DATE)) AS dispatch_date,
        ROUND(
            t.revenue::NUMERIC 
            + t.fuel_surcharge::NUMERIC 
            + t.accessorial_charges::NUMERIC,
            2
        ) AS trip_revenue,
        ROUND(COALESCE(f.total_cost,0)::NUMERIC, 2) AS trip_fuel_cost,
        ROUND(COALESCE(m.maintenance_cost,0)::NUMERIC, 2) AS trip_maintenance_cost
    FROM base_trips t
    LEFT JOIN base_fuel_costs f ON t.trip_id = f.trip_id
    LEFT JOIN base_maintenance_costs m 
        ON t.truck_id = m.truck_id
       AND CAST(m.service_date AS DATE) <= CAST(t.dispatch_date AS DATE)
    WHERE t.trip_status = 'Completed'
),
monthly_revenue_cost AS (
    SELECT
        DATE_TRUNC('month', dispatch_date)::DATE AS year_month,
        COUNT(trip_id) AS trips_count,
        ROUND(SUM(trip_revenue),2) AS total_revenue,
        ROUND(SUM(trip_fuel_cost + trip_maintenance_cost),2) AS total_cost
    FROM trip_costs
    GROUP BY 1
),
monthly_margin AS (
    SELECT
        year_month,
        trips_count,
        total_revenue,
        total_cost,
        ROUND(total_revenue - total_cost, 2) AS total_margin,
        CASE WHEN total_revenue = 0 THEN 0
             ELSE ROUND((total_revenue - total_cost)/total_revenue, 4) END AS margin_pct
    FROM monthly_revenue_cost
),
monthly_prev AS (
    SELECT
        *,
        LAG(trips_count) OVER (ORDER BY year_month) AS previous_trips_count,
        ROUND(LAG(total_revenue) OVER (ORDER BY year_month), 2) AS previous_total_revenue,
        ROUND(LAG(total_cost) OVER (ORDER BY year_month), 2) AS previous_total_cost,
        ROUND(LAG(total_revenue - total_cost) OVER (ORDER BY year_month), 2) AS previous_total_margin,
        CASE WHEN LAG(total_revenue) OVER (ORDER BY year_month) = 0 THEN 0
             ELSE ROUND((LAG(total_revenue - total_cost) OVER (ORDER BY year_month)) /
                        (LAG(total_revenue) OVER (ORDER BY year_month)), 4) END AS previous_margin_pct
    FROM monthly_margin
)
SELECT *
FROM monthly_prev
ORDER BY year_month;

-- Check Table -- 

SELECT *
FROM base_trips;

SELECT * 
FROM base_maintenance_costs;

SELECT *
FROM base_fuel_costs;
