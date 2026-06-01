-- ============================================
-- HR Analytics Database — PostgreSQL Schema
-- Project 2 | Junior Data Analyst Training
-- ============================================

-- Drop if exists (clean start)
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS dim_department CASCADE;
DROP TABLE IF EXISTS dim_education CASCADE;

-- TABLE 1: Department dimension

CREATE TABLE dim_department (
    dept_id    					INT PRIMARY KEY,
    dept_name  					VARCHAR(50) UNIQUE NOT NULL
);

-- TABLE 2: Education dimension (decode numbers to text)

CREATE TABLE dim_education(
	education_level 			INT PRIMARY KEY,
	education_lebel 			VARCHAR(50) NOT NULL 
);

-- TABLE 3: Main employee fact table


CREATE TABLE employees (
    employee_id                 INT PRIMARY KEY,
    age                         INT,
    gender                      VARCHAR(10),
    marital_status              VARCHAR(15),
    education                   INT REFERENCES dim_education(education_level),
    education_field             VARCHAR(30),
    dept_id                     INT REFERENCES dim_department(dept_id),
    job_role                    VARCHAR(50),
    job_level                   INT,
    business_travel             VARCHAR(20),
    monthly_income              NUMERIC(10,2),
    percent_salary_hike         INT,
    stock_option_level          INT,
    distance_from_home          INT,
    over_time                   INT,
    attrition                   INT,
    total_working_years         INT,
    years_at_company            INT,
    years_in_current_role       INT,
    years_since_last_promotion  INT,
    years_with_curr_manager     INT,
    num_companies_worked        INT,
    training_times_last_year    INT,
    job_satisfaction            INT,
    environment_satisfaction    INT,
    relationship_satisfaction   INT,    -- ← added back
    work_life_balance           INT,
    job_involvement             INT,
    performance_rating          INT,
    hourly_rate                 NUMERIC(8,2),
    daily_rate                  NUMERIC(8,2)
);

INSERT INTO dim_department VALUES
(1, 'Sales'),
(2, 'Research & Development'),
(3, 'Human Resources');

INSERT INTO dim_education VALUES
(1, 'Below College'),
(2, 'College'),
(3, 'Bachelor'),
(4, 'Master'),
(5, 'Doctor');


COPY employees (
    age,
    attrition,
    business_travel,
    daily_rate,
    dept_id,        -- col 6 (your dept_id column)
    distance_from_home,
    education,
    education_field,
    employee_id,    -- EmployeeNumber = employee_id
    environment_satisfaction,
    gender,
    hourly_rate,
    job_involvement,
    job_level,
    job_role,
    job_satisfaction,
    marital_status,
    monthly_income,
    num_companies_worked,
    over_time,
    percent_salary_hike,
    performance_rating,
    relationship_satisfaction,
    stock_option_level,
    total_working_years,
    training_times_last_year,
    work_life_balance,
    years_at_company,
    years_in_current_role,
    years_since_last_promotion,
    years_with_curr_manager
)
FROM 'C:\Program Files\PostgreSQL\My_learnings\SQL\HR Attrition Analysis\01_Dataset\HR-Employee-Attrition.csv'DELIMITER ','CSV HEADER;

--veriying imported tables

SELECT 'dim_department' AS tbl, COUNT(*) FROM dim_department
UNION ALL
SELECT 'dim_education',  COUNT(*) FROM dim_education
UNION ALL
SELECT 'employees',      COUNT(*) FROM employees;

--Task 1 — Overall attrition rate
CREATE OR REPLACE PROCEDURE generate_attrition_report()
LANGUAGE plpgsql
AS $$
DECLARE
	
SELECT 
	ROUND(SUM(attrition)*100.0/ COUNT(*),2) AS attrition_rate
FROM employees;

--Task 2 — Attrition rate by department

WITH dept_attrition_rate AS
(SELECT
	d.dept_name AS depat_name,
	COUNT(e.dept_id) AS total_employees,
	SUM(CASE WHEN e.attrition = 1 THEN 1 ELSE 0 END) AS left_employees
FROM employees e JOIN dim_department d ON e.dept_id = d.dept_id
GROUP BY d.dept_name)

SELECT 
	depat_name, total_employees , left_employees,
	ROUND(left_employees *100.0 / total_employees,2) AS attrition_rate
FROM dept_attrition_rate
ORDER BY attrition_rate DESC;
	
--Task 3 — Attrition by job role

WITH job_attrition_rate AS
(SELECT
	job_role,
	COUNT(job_role) AS total_employees,
	SUM(CASE WHEN attrition = 1 THEN 1 ELSE 0 END) AS left_employees
FROM employees
GROUP BY job_role)

SELECT 
	job_role,total_employees,left_employees,
	ROUND(left_employees *100.0 / total_employees,2) AS attrition_rate
FROM job_attrition_rate
ORDER BY attrition_rate DESC;

--Task 4 — Overtime impact

WITH overtime AS
(SELECT
	CASE WHEN over_time = 1 THEN 'Overtime' ELSE 'No_Overtime' END AS Overtime,
	COUNT(over_time) AS total_employees,
	SUM(CASE WHEN attrition = 1 THEN 1 ELSE 0 END) AS left_employees
FROM employees
GROUP BY Overtime)

SELECT 
	Overtime, total_employees, left_employees,
	ROUND(left_employees *100.0 / total_employees,2) AS attrition_rate	
FROM overtime
ORDER BY attrition_rate;
	
/* Task 5 — Cost of attrition
How much money did we lose entirely because people quit?" (Cost of Attrition)*/

SELECT 
	ROUND(SUM(monthly_income)*12*0.5 ,2) AS attrition_cost
FROM employees
WHERE attrition = 1;

END;
$$;
CALL procedure_name();

/*Task 6 Show me engagement factor by combining all job satisfaction, environment satisfaction, relationship satisfaction and work-life balance.
Then tell me how many are critically disengaged.*/

SELECT
	ROUND((job_satisfaction + environment_satisfaction + relationship_satisfaction + work_life_balance) /4.0 , 2) AS 
	engagement_score,
	attrition
FROM employees
ORDER BY engagement_score ASC
LIMIT 20;
	
/* Task-7 HR manager asks: within each department, who are the top 3 highest paid employees? And are high earners leaving or staying*/

WITH monthly_income_rank AS
(SELECT
	e.employee_id 	AS employee_id,
	d.dept_name 	AS department_name,
	e.job_role		AS Job_role,
	e.monthly_income AS Monthly_salary,
	e.attrition,
	DENSE_RANK() OVER(PARTITION BY d.dept_name ORDER BY e.monthly_income DESC) as ranked_salary
FROM employees e JOIN dim_department d ON e.dept_id = d.dept_id)

SELECT 
	employee_id , department_name, Job_role ,Monthly_salary ,ranked_salary ,attrition
FROM monthly_income_rank
WHERE ranked_salary <= 3;


--The Complete Stored Procedure-HR Attrition report


CREATE OR REPLACE PROCEDURE generate_attrition_report()
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_employees     INT;
    v_total_left          INT;
    v_attrition_rate      NUMERIC(5,2);
    v_attrition_cost      NUMERIC(12,2);
    v_overtime_rate       NUMERIC(5,2);
    v_no_overtime_rate    NUMERIC(5,2);
	v_avg_years_left	  NUMERIC(5,2);
	v_avg_years_stayed    NUMERIC(5,2);
	
    dept_row              RECORD;
    role_row              RECORD;

BEGIN
    -- SECTION 1: Overall attrition
    SELECT COUNT(*), SUM(attrition),
           ROUND(SUM(attrition)*100.0/COUNT(*),2)
    INTO v_total_employees, v_total_left, v_attrition_rate
    FROM employees;

    RAISE NOTICE '========== HR ATTRITION REPORT ==========';
    RAISE NOTICE 'Total Employees   : %', v_total_employees;
    RAISE NOTICE 'Employees Left    : %', v_total_left;
    RAISE NOTICE 'Overall Attrition : % %%', v_attrition_rate;
    RAISE NOTICE '------------------------------------------';

    -- SECTION 2: By department
    RAISE NOTICE 'ATTRITION BY DEPARTMENT:';
    FOR dept_row IN
        SELECT d.dept_name,
               COUNT(*)                                   AS total_emp,
               SUM(e.attrition)                           AS left_emp,
               ROUND(SUM(e.attrition)*100.0/COUNT(*),2)  AS dept_rate
        FROM employees e
        JOIN dim_department d ON e.dept_id = d.dept_id
        GROUP BY d.dept_name
        ORDER BY dept_rate DESC
    LOOP
        RAISE NOTICE '  % | Total: % | Left: % | Rate: % %%',
            dept_row.dept_name,
            dept_row.total_emp,
            dept_row.left_emp,
            dept_row.dept_rate;
    END LOOP;
    RAISE NOTICE '------------------------------------------';

    -- SECTION 3: Top 3 job roles
    RAISE NOTICE 'TOP 3 HIGH ATTRITION JOB ROLES:';
    FOR role_row IN
        SELECT job_role,
               COUNT(*)                                   AS total_emp,
               SUM(attrition)                             AS left_emp,
               ROUND(SUM(attrition)*100.0/COUNT(*),2)     AS role_rate
        FROM employees
        GROUP BY job_role
        ORDER BY role_rate DESC
        LIMIT 3
    LOOP
        RAISE NOTICE '  % → Rate: % %%',
            role_row.job_role,
            role_row.role_rate;
    END LOOP;
    RAISE NOTICE '------------------------------------------';

    -- SECTION 4: Overtime impact
    SELECT ROUND(SUM(attrition)*100.0/COUNT(*),2)
    INTO v_overtime_rate
    FROM employees WHERE over_time = 1;

    SELECT ROUND(SUM(attrition)*100.0/COUNT(*),2)
    INTO v_no_overtime_rate
    FROM employees WHERE over_time = 0;

    RAISE NOTICE 'OVERTIME IMPACT:';
    RAISE NOTICE '  With Overtime    : % %%', v_overtime_rate;
    RAISE NOTICE '  Without Overtime : % %%', v_no_overtime_rate;
    RAISE NOTICE '  Multiplier       : %x more likely to leave',
        ROUND(v_overtime_rate / v_no_overtime_rate, 1);
    RAISE NOTICE '------------------------------------------';

    -- SECTION 5: Cost of attrition
    SELECT ROUND(SUM(monthly_income)*12*0.5, 2)
    INTO v_attrition_cost
    FROM employees WHERE attrition = 1;

    RAISE NOTICE 'TOTAL COST OF ATTRITION: $%', v_attrition_cost;
    RAISE NOTICE '==========================================';

	---SECTION 6 Average Tenure Comparison--
	RAISE NOTICE '-- Avg tenure comparison----:';

	SELECT
		ROUND(AVG(years_at_company), 2)
	INTO v_avg_years_left 
	FROM employees WHERE attrition = 1;

	SELECT
		ROUND(AVG(years_at_company), 2)
	INTO v_avg_years_stayed 
	FROM employees WHERE attrition = 0;

	RAISE NOTICE 'Avg_Years Who left: %' ,v_avg_years_left;
	RAISE NOTICE 'Avg_Years Who Stayed: %' ,v_avg_years_stayed;
	
END;
$$;

-- Run it
CALL generate_attrition_report();


--INDEXING-Checking query plan BEFORE index:

EXPLAIN ANALYZE
SELECT dept_id ,COUNT(*) ,SUM(attrition)
FROM employees
WHERE attrition = 1
GROUP BY dept_id;


--CREATING INDEXES--

CREATE INDEX idx_employees_attrition
ON employees (attrition);

CREATE INDEX idx_employees_dept
ON emeployees(dept_id);

CREATE INDEX idx_employees_overtime
ON employees(over_time);


CREATE INDEX idx_dept_attrition
ON employees(dept_id , attrition);

-- Checking query plan AFTER index:

EXPLAIN ANALYZE
SELECT dept_id , COUNT(*) , SUM(attrition)
FROM employees
WHERE attrition = 1
GROUP BY dept_id;

	
	


	

