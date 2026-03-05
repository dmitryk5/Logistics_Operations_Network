# 🚛 Logistics Network Operations Analysis
**SQL + Tableau Analytics Project**

This project analyzes **logistics network performance, profitability, and operational efficiency** for a simulated Class 8 trucking company.  
The objective is to uncover **what drives profitability, route performance, fleet utilization, and scalability**, and to identify areas for optimization.

---

## 📌 Executive Summary

This analysis reviews **3 years of logistics operations (2022–2024)** to assess profitability, route and customer performance, fleet efficiency, and operational risk.  

Key insights include:

- **Strong margins:** Overall 82–86% across customers; top routes reach 93%.  
- **Revenue-to-profit efficiency:** Only 14–18% of revenue goes to variable costs (fuel + maintenance).  
- **Opportunities to optimize:** A few routes are loss-making, highlighting potential for rerouting or repricing.  
- **Efficiency trends:** Cost-per-mile decreasing, profit-per-mile increasing.  
- **Next steps:** Focus on asset utilization—identifying underused trucks/drivers and balancing workloads.

**Executive Summary Quote:**  
*"Operations are profitable and efficient, but pockets of underperformance exist. Continued monitoring of costs, route performance, and asset utilization can sustain margins and improve profitability."*

---

**Dashboard Preview**

![Dashboard Preview](1_overview.png)

🔗 **Interactive Tableau Dashboard:**  
[https://public.tableau.com/app/profile/dmitry.kuvyrdin/viz/LogisticsOperationsNetwork/Overview?publish=yes](https://public.tableau.com/app/profile/dmitry.kuvyrdin/viz/LogisticsOperationsNetwork/Overview?publish=yes)

---

## 📌 Project Overview

This analysis evaluates **synthetic logistics operations data (2022–2024)** to understand how revenue, margin, trips, and fleet efficiency evolve across:

- Customers and routes
- Trucks, trailers, and drivers
- Operational performance metrics
- Geographic and seasonal patterns

The project mirrors a **real-world analytics workflow**, progressing from:
**high-level KPIs → diagnostic analysis → actionable insights**.

---

## 🎯 Core Objectives

- Track revenue, margin, and trips over time
- Identify high- and low-performing routes/customers
- Analyze fleet efficiency and asset utilization
- Evaluate cost trends and profit-per-mile
- Assess operational risk and driver performance
- Enable executive-level dashboards with actionable insights

---

## 🗂 Dataset Description

The dataset is a **synthetic but realistic logistics operations database** spanning three years with 85,000+ records across 14 interconnected tables.

### Core Tables

- `drivers.csv` – demographics, employment, CDL info (150 records)
- `trucks.csv` – fleet specs, acquisition dates, status (120 records)
- `trailers.csv` – equipment types, assignments (180 records)
- `customers.csv` – shipper accounts, contract terms (200 records)
- `facilities.csv` – terminals/warehouses with geocoordinates (50 records)
- `routes.csv` – city pairs, distances, rate structures (60+ records)
- `loads.csv` – shipment details, revenue, booking type (57,000+ records)
- `trips.csv` – driver-truck assignments, actual performance (57,000+ records)
- `fuel_purchases.csv` – transaction-level fuel pricing (131,000+ records)
- `maintenance_records.csv` – service history, costs, downtime (6,500+ records)
- `delivery_events.csv` – pickup/delivery timestamps, detention (114,000+ records)
- `safety_incidents.csv` – accidents, violations, claims (114 records)
- `driver_monthly_metrics.csv` – driver performance summaries (5,400+ records)
- `truck_utilization_metrics.csv` – equipment efficiency metrics (3,800+ records)
- `DATABASE_SCHEMA.txt` – relationships and foreign key documentation

### Dataset Features

- Temporal Coverage: **Jan 2022 – Dec 2024**
- Geographic Scope: **25+ major US cities**
- Realistic operational patterns: fuel price trends, seasonal freight, equipment lifecycle, driver retention
- Clean and normalized for SQL, Tableau, and Python analytics

---

## 🧾 SQL Queries

* [`0_base_views.sql`](./sql/0_base_views.sql) – Standardizes column names and builds base views for analysis  
* [`1_profitability.sql`](./sql/1_profitability.sql) – Initial data validation, profitability exploration, and summary metrics  
* [`2_asset_efficiency.sql`](./sql/2_asset_efficiency.sql) – Monthly revenue, cost, margin, and trip trends; analyzes fleet and asset efficiency  
* [`3_operational_performance.sql`](./sql/3_operational_performance.sql) – Route and customer performance analysis; identifies high- and low-performing routes  
* [`4_people_and_risks.sql`](./sql/4_people_and_risks.sql) – Driver and personnel analysis; evaluates performance, safety incidents, and risk profiles  
* [`5_kpi_build.sql`](./sql/5_kpi_build.sql) – Builds KPI tables and dashboards for revenue, margin, trips, and operational metrics  
* [`error_check.sql`](./sql/error_check.sql) – Validates data, analyzes fuel, maintenance, and profit-per-mile trends for consistency
  
---

## ❓ Business Questions Answered

### Customer & Route Profitability
- Which customers generate high value with low revenue?  
- Which routes are most or least profitable?  
- How do costs impact route profitability?

### Fleet & Asset Efficiency
- Which trucks or drivers are underutilized or overworked?  
- How does truck age affect maintenance costs and downtime?  
- Are operations fleet- or demand-constrained?

### Operational Performance
- What is on-time performance by route, city, and customer?  
- Where do detentions occur and why?  
- How do seasonal patterns affect trips and revenue?

### Cost & Margin Trends
- How do revenue-per-mile and cost-per-mile evolve?  
- Are margins improving with scale?  
- Where are opportunities to optimize pricing or efficiency?

### Safety & Risk
- Which drivers or assets have elevated risk profiles?  
- How does driver tenure relate to safety incidents and MPG?

---

## 📊 Tableau Dashboard Structure

### Page 1: Logistic Overview
- KPI Cards: Total Revenue, Total Cost, Total Margin, Margin %, Trips Completed, On-Time %  
- Overall performance metrics and high-level trends  
- Seasonal and geographic heatmaps  

### Page 2: Revenue and Profit Drivers
- Route and customer profitability analysis  
- Top vs bottom revenue-generating lanes  
- Margin per trip and per mile trends  

### Page 3: Fleet Utilization and Efficiency
- Top vs bottom trucks/trailers by efficiency  
- Idle time vs MPG comparisons  
- Maintenance cost trends and utilization metrics  

### Page 4: Lane Reliability and Performance
- On-time performance by route and city-pair  
- Customer SLA compliance  
- Identification of underperforming lanes or recurring delays  

### Page 5: Operational Performance Trends
- Time series of revenue, margin, and trips  
- Profit-per-mile and cost-per-mile trend lines  
- Seasonality and operational risk patterns

---

## 🔍 Key Insights

- Revenue growth is **volume-driven**, revenue-per-trip is stable (~$3,500)  
- Early margin compression occurred during scaling, now steady at ~30–33%  
- Top 5 routes generate >$500M profit each; a few routes are loss-making  
- Cost-per-mile decreasing, profit-per-mile increasing → operational efficiency improving  
- Most trucks operate near full capacity; younger trucks slightly costlier per unit  
- Safety incidents and idle time are generally consistent; targeted coaching recommended  

---

## 📈 Recommendations & Next Steps

### Business Recommendations
- Reroute or reprice loss-making routes  
- Optimize truck/driver assignments for balanced utilization  
- Maintain focus on cost-per-mile reduction strategies  
- Explore pricing strategies to increase revenue-per-mile  

### Future Analysis
- Asset replacement planning by truck age  
- Predictive maintenance and driver performance models  
- Advanced forecasting of trips, revenue, and margin  
- Route optimization simulations  

---

## 👤 Author

**Dmitry Kuvyrdin**  
🔗 LinkedIn: [https://www.linkedin.com/in/dmitry-kuvyrdin/](https://www.linkedin.com/in/dmitry-kuvyrdin/)
