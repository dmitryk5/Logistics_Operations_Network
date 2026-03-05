-- Analyzing Executive Questions: Profitability --

-- Which customers generate high value but low revenue? --
-- Notes: Margin percentage is 82–86% across all customers --
-- Notes: Most revenue is converting into profit, with only 14–18% going to direct variable costs (fuel + maintenance) --
-- Notes: No low-margin customers dragging profitability down --
-- Recommendations: No issues here. How can we continue our success and how can we bring the margins to be even higher? -- 

WITH trip_costs AS (
    SELECT
        t.trip_id,
        t.customer_id,
        t.revenue::numeric AS revenue,
        COALESCE(f.total_cost, 0)::numeric AS fuel_cost,
        COALESCE(m.maintenance_cost, 0)::numeric * 
            (t.actual_distance_miles / NULLIF(SUM(m.odometer_miles) OVER (PARTITION BY m.truck_id), 0)) AS maintenance_cost
    FROM base_trips t
    LEFT JOIN base_fuel_costs f ON t.trip_id = f.trip_id
    LEFT JOIN base_maintenance_costs m ON t.truck_id = m.truck_id
)
SELECT
    customer_id,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(SUM(fuel_cost + maintenance_cost), 2) AS total_cost,
    ROUND(SUM(revenue - (fuel_cost + maintenance_cost)), 2) AS total_margin,
    ROUND(SUM(revenue - (fuel_cost + maintenance_cost)) / SUM(revenue), 3) AS margin_pct
FROM trip_costs
GROUP BY customer_id
ORDER BY total_revenue DESC, margin_pct DESC;

-- Which routes are most/least profitable after fuel and maintenance? (profitability by route) --
-- Notes: Top 5 routes all have a margin of 93% and over 500 million in profit. --
-- Notes: Some routes are actually losing money (negative total profit, negative profit per mile). Costs exceed revenue. --
-- Recommendations: Fleet relocation. -- 

WITH trip_costs AS (
    SELECT
        t.trip_id,
        t.route_id,
        t.actual_distance_miles,
        t.revenue::numeric AS revenue,
        COALESCE(f.total_cost, 0)::numeric AS fuel_cost,
        COALESCE(m.maintenance_cost, 0)::numeric *
            (t.actual_distance_miles /
             NULLIF(SUM(m.odometer_miles) OVER (PARTITION BY m.truck_id), 0)
            ) AS maintenance_cost
    FROM base_trips t
    LEFT JOIN base_fuel_costs f ON t.trip_id = f.trip_id
    LEFT JOIN base_maintenance_costs m ON t.truck_id = m.truck_id
)
SELECT
    route_id,
    COUNT(DISTINCT trip_id) AS trip_count,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(SUM(fuel_cost + maintenance_cost), 2) AS total_cost,
    ROUND(SUM(revenue - (fuel_cost + maintenance_cost)), 2) AS total_profit,
    ROUND(SUM(revenue - (fuel_cost + maintenance_cost)) / SUM(revenue), 2) AS margin_pct,
    ROUND(SUM(revenue - (fuel_cost + maintenance_cost)) / SUM(actual_distance_miles), 2) AS profit_per_mile
FROM trip_costs
GROUP BY route_id
ORDER BY total_profit DESC;

-- How does cost-per-mile trend over time? -- 
-- Notes: Cost-per-mile has a trend of decreasing over time, revenue-per-mile has generally stood stagnant, profit-per-mile is steadily rising --
-- Recommendations: Efficiency and profitability are growing. What are we doing correctly? How can we continue the success and continue growing efficiency? --

WITH trip_costs AS (
    SELECT
        t.trip_id,
        t.dispatch_date::date AS dispatch_date,
        t.actual_distance_miles,
        t.revenue::numeric AS revenue,
        COALESCE(f.total_cost, 0)::numeric AS fuel_cost,
        COALESCE(m.maintenance_cost, 0)::numeric *
            (t.actual_distance_miles /
             NULLIF(SUM(m.odometer_miles) OVER (PARTITION BY m.truck_id), 0)
            ) AS maintenance_cost
    FROM base_trips t
    LEFT JOIN base_fuel_costs f ON t.trip_id = f.trip_id
    LEFT JOIN base_maintenance_costs m ON t.truck_id = m.truck_id
)
SELECT
    TO_CHAR(DATE_TRUNC('month', dispatch_date), 'YYYY-MM') AS month,
    SUM(fuel_cost + maintenance_cost) AS total_cost,
    SUM(revenue) AS total_revenue,
    SUM(actual_distance_miles) AS total_miles,
    ROUND(SUM(fuel_cost + maintenance_cost)/NULLIF(SUM(actual_distance_miles),0), 2) AS cost_per_mile,
    ROUND(SUM(revenue)/NULLIF(SUM(actual_distance_miles),0), 2) AS revenue_per_mile,
    ROUND((SUM(revenue) - SUM(fuel_cost + maintenance_cost))/NULLIF(SUM(actual_distance_miles),0), 2) AS profit_per_mile
FROM trip_costs
GROUP BY 1
ORDER BY month;
