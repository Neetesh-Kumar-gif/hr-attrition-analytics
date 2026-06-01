# hr-attrition-analytics
This repo contains analysis of HR Attrition of IBM Company using tools PostgreSQL and Power BI
# HR Attrition Analytics Dashboard

## Business Problem
IBM HR dataset analysis to identify attrition drivers,
quantify replacement costs, and flag at-risk employees
for proactive HR intervention.

## Tools
PostgreSQL 18 · Power BI Desktop · DAX · PL/pgSQL

## Dataset
1,470 employees · 3 normalized tables · IBM HR dataset

## Key Findings
- Overall attrition rate: 16.12% (above 10-15% benchmark)
- Sales department highest attrition: 20.63%
- Sales Representatives leaving at 39.76% — critical
- Overtime employees 2.9x more likely to leave
- Employees who left earned $2,046/month less on average
- Total cost of attrition: $6,807,246
- 114 current employees flagged as high flight risk
- 20% attrition reduction saves $1.36M in replacement costs

## SQL Concepts Used
Normalized schema design 
· Attrition rate calculations.
**Window functions (DENSE_RANK, PARTITION BY).
Stored procedures with RECORD loops.
Composite indexing 
· EXPLAIN ANALYZE optimization

## Power BI Features
3-page dark theme dashboard · Live PostgreSQL connection ·
DAX measures (CALCULATE, SUMX, SWITCH, DIVIDE) ·
What-If parameter · Dynamic KPI selector ·
Drill-through navigation · Conditional formatting ·
Scatter plot · Engagement score analysis

## Dashboard Pages
Page 1 — Executive Overview: Company-wide KPIs and trends
Page 2 — Employee Risk Analysis: Scatter, What-If simulator,
          High-risk employee table
Page 3 — Department Detail: Drill-through from Page 1,
          dept-specific attrition, age, salary analysis
