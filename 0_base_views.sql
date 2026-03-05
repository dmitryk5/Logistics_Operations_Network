-- Building SQL Layers -- Create View --

--
-- Base Trips Layer --
--

CREATE VIEW base_trips AS
SELECT
    t.trip_id,
    t.load_id,
    t.driver_id,
    t.truck_id,
    t.trailer_id,
    t.dispatch_date,
    t.trip_status,
    l.load_date,
    l.load_status,
    t.actual_distance_miles,
    t.actual_duration_hours,
    t.idle_time_hours,
    t.fuel_gallons_used,
    t.average_mpg,
    l.revenue,
    l.fuel_surcharge,
    l.accessorial_charges,
    l.load_type,
    l.booking_type,
    r.route_id,
    r.origin_city,
    r.origin_state,
    r.destination_city,
    r.destination_state,
    r.typical_distance_miles,
    r.typical_transit_days,
    d.hire_date AS driver_hire_date,
    d.employment_status AS driver_employment_status,
    d.years_experience AS driver_years_experience,
    d.home_terminal AS driver_home_terminal,
    c.customer_id,
    c.customer_name,
    c.customer_type,
    c.account_status,
    c.primary_freight_type,
    c.contract_start_date
FROM trips t
LEFT JOIN loads l
    ON t.load_id = l.load_id
LEFT JOIN routes r
    ON l.route_id = r.route_id
LEFT JOIN drivers d
    ON t.driver_id = d.driver_id
LEFT JOIN customers c
    ON l.customer_id = c.customer_id;

-- Validate Table --

-- Trips table row count -- 
SELECT COUNT(*) AS trips_count
FROM trips;

-- Base view row count -- 
SELECT COUNT(*) AS base_trips_count
FROM base_trips;

-- Unique ID check -- 
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT trip_id) AS distinct_trip_ids
FROM base_trips;

-- Revenue integrity check -- 

SELECT
    SUM(revenue) AS base_revenue
FROM base_trips;

SELECT
    SUM(revenue) AS raw_revenue
FROM loads;

-- Check for NULLS -- 

SELECT
    COUNT(*) FILTER (WHERE fuel_gallons_used IS NULL) AS null_fuel_rows,
    COUNT(*) FILTER (WHERE accessorial_charges IS NULL) AS null_accessorials
FROM base_trips;

--
-- Base Fuel Costs Layer --
--

CREATE VIEW base_fuel_costs AS
SELECT
    fuel_purchase_id,
    trip_id,
    truck_id,
    driver_id,
    purchase_date AS fuel_purchase_date,
    location_city,
    location_state,
    gallons,
    price_per_gallon,
    total_cost,
    fuel_card_number
FROM fuel_purchases;

-- Row count check -- 

SELECT COUNT(*) FROM base_fuel_costs;
SELECT COUNT(*) FROM fuel_purchases;

-- Price consistency check -- 

SELECT
    MIN(price_per_gallon),
    MAX(price_per_gallon),
    AVG(price_per_gallon)
FROM base_fuel_costs;

--
-- Base Maintenance Costs Layer --
--

CREATE VIEW base_maintenance_costs AS
SELECT
    maintenance_id,
    truck_id,
    maintenance_date AS service_date,
    total_cost AS maintenance_cost,
    maintenance_type AS service_type,
    odometer_reading AS odometer_miles,
    downtime_hours
FROM maintenance_records;

-- Count rows in base view

SELECT COUNT(*) AS base_maintenance_count
FROM base_maintenance_costs;

-- Count rows in raw table

SELECT COUNT(*) AS raw_maintenance_count
FROM maintenance_records;

-- Unique ID check -- 
SELECT maintenance_id, COUNT(*) AS cnt
FROM base_maintenance_costs
GROUP BY maintenance_id
HAVING COUNT(*) > 1;

-- Cost check -- 

SELECT 
    COUNT(*) FILTER (WHERE maintenance_cost <= 0) AS zero_or_negative_costs
FROM base_maintenance_costs;

--
-- Base Delivery Performance Layer --
--

CREATE VIEW base_delivery_performance AS
SELECT
    de.event_id,
    de.load_id,
    de.trip_id,
    de.event_type,
    de.facility_id,
    de.scheduled_datetime,
    de.actual_datetime,
    de.detention_minutes,
    de.on_time_flag,
    de.location_city,
    de.location_state,
    t.truck_id,
    t.driver_id,
    t.dispatch_date,
    t.trip_status,
    l.customer_id,
    l.load_type,
    l.booking_type,
    l.load_status
FROM delivery_events de
LEFT JOIN trips t
    ON de.trip_id = t.trip_id
LEFT JOIN loads l
    ON de.load_id = l.load_id;

-- Row count check

SELECT COUNT(*) AS delivery_events_count
FROM base_delivery_performance;

SELECT COUNT(*) AS raw_events_count
FROM delivery_events;

-- Unique ID Check --

SELECT event_id, COUNT(*)
FROM base_delivery_performance
GROUP BY event_id
HAVING COUNT(*) > 1;

-- Check for NULLS -- 

SELECT 
    COUNT(*) FILTER (WHERE truck_id IS NULL) AS missing_trips,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_loads
FROM base_delivery_performance;

-- New base view for Tableau to include coordinates --

CREATE VIEW base_trips_v2 AS
SELECT
    t.trip_id,
    t.load_id,
    t.driver_id,
    t.truck_id,
    t.trailer_id,
    t.dispatch_date,
    t.trip_status,
    l.load_date,
    l.load_status,
    t.actual_distance_miles,
    t.actual_duration_hours,
    t.idle_time_hours,
    t.fuel_gallons_used,
    t.average_mpg,
    l.revenue,
    l.fuel_surcharge,
    l.accessorial_charges,
    l.load_type,
    l.booking_type,
    r.route_id,
    r.origin_city,
    r.origin_state,
    r.destination_city,
    r.destination_state,
    r.typical_distance_miles,
    r.typical_transit_days,
    d.hire_date AS driver_hire_date,
    d.employment_status AS driver_employment_status,
    d.years_experience AS driver_years_experience,
    d.home_terminal AS driver_home_terminal,
    c.customer_id,
    c.customer_name,
    c.customer_type,
    c.account_status,
    c.primary_freight_type,
    c.contract_start_date,
    f.facility_id,
    f.facility_name,
    f.facility_type,
    f.latitude,
    f.longitude
FROM trips t
LEFT JOIN loads l
    ON t.load_id = l.load_id
LEFT JOIN routes r
    ON l.route_id = r.route_id
LEFT JOIN drivers d
    ON t.driver_id = d.driver_id
LEFT JOIN customers c
    ON l.customer_id = c.customer_id
LEFT JOIN delivery_events de 
	ON t.load_id = de.load_id
LEFT JOIN facilities f
	ON de.facility_id = f.facility_id;

-- Adding fields --

CREATE VIEW base_trips_v3 AS
SELECT
    bt.trip_id,
    bt.load_id,
    bt.driver_id,
    bt.truck_id,
    bt.trailer_id,
    bt.dispatch_date,
    bt.trip_status,
    bt.load_date,
    bt.load_status,
    bt.actual_distance_miles,
    bt.actual_duration_hours,
    bt.idle_time_hours,
    bt.fuel_gallons_used,
    bt.average_mpg,
    bt.revenue,
    bt.fuel_surcharge,
    bt.accessorial_charges,
    bt.load_type,
    bt.booking_type,
    bt.route_id,
    bt.origin_city,
    bt.origin_state,
    bt.destination_city,
    bt.destination_state,
    bt.typical_distance_miles,
    bt.typical_transit_days,
    bt.driver_hire_date,
    bt.driver_employment_status,
    bt.driver_years_experience,
    bt.driver_home_terminal,
    bt.customer_id,
    bt.customer_name,
    bt.customer_type,
    bt.account_status,
    bt.primary_freight_type,
    bt.contract_start_date,
    fo.facility_id AS origin_facility_id,
    fd.facility_id AS destination_facility_id
FROM base_trips_v2 bt
LEFT JOIN facilities fo
    ON bt.origin_city = fo.city
   AND bt.origin_state = fo.state
LEFT JOIN facilities fd
   ON bt.destination_city = fd.city
   AND bt.destination_state = fd.state;

-- Check and Validation -- 

SELECT *
FROM base_trips_v3
LIMIT 2;

SELECT
    COUNT(*) AS total_trips,
    COUNT(origin_facility_id) AS origin_mapped,
    COUNT(destination_facility_id) AS destination_mapped
FROM base_trips_v3;
