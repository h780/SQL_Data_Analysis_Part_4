SELECT
    *
FROM
    locations;

SELECT
    *
FROM
    departments;

SELECT
    *
FROM
    jobs;

SELECT
    *
FROM
    employees;

SELECT
    *
FROM
    job_history;

SELECT
    *
FROM
    regions;

SELECT
    *
FROM
    countries;

SELECT
    *
FROM
    non_functional_locations;

/********************************************** count(*) vs count(column_name) **********************************************/
--Finding the country wise number of records and states
SELECT
    country_id,
    COUNT(*),
    COUNT(state_province)
FROM
    locations
GROUP BY
    country_id
ORDER BY
    country_id;

--In the above query we get two different results for IT department states when we use count(*) and count(column_name)
--count(*) will also return the null values, but count(column_name) will not return the null values
--count(*) will count the number of *'s for each and every row where it is matching
--count(column_name) will ignore the null values

--finding department wise number of managers and number of records
SELECT
    d.department_name,
    COUNT(*),
    COUNT(e.manager_id)
FROM
         employees e
    JOIN departments d ON e.department_id = d.department_id
GROUP BY
    d.department_name
ORDER BY
    d.department_name;

/********************************************** Categorization **********************************************/

--Categorize employees based on the hired date

SELECT
    hire_date,
    COUNT(employee_id)
FROM
    employees
GROUP BY
    hire_date;

--Above query gives us count values for each hire date in the table, but we need to categorize the hire_date column based on 5 years of seggregation
--1. before 1990
--2. between 1990 - 1995
--3. between 1995 - 2000
--4. after 2000

SELECT
    first_name
    || ' '
    || last_name AS employee_name,
    hire_date,
    CASE
        WHEN hire_date < TO_DATE('01-JAN-1990', 'dd-MM-yyyy') THEN
            'Before 1990'
        WHEN hire_date >= TO_DATE('01-JAN-1990', 'dd-MM-yyyy')
             AND hire_date < TO_DATE('01-JAN-1995', 'dd-MM-yyyy') THEN
            'Between 1990 and 1995'
        WHEN hire_date >= TO_DATE('01-JAN-1995', 'dd-MM-yyyy')
             AND hire_date < TO_DATE('01-JAN-2000', 'dd-MM-yyyy') THEN
            'Between 1995 and 2000'
        WHEN hire_date > TO_DATE('01-JAN-2000', 'dd-MM-yyyy') THEN
            'After 2000'
        ELSE
            'Not Categroized'
    END          hire_date_category
FROM
    employees
ORDER BY
    hire_date;
    

/********************************************** WITH Clause **********************************************/
--Finding all employees whose salary is more than the average salary of all employees

SELECT
    employee_id,
    salary,
    avg_salary
FROM
    employees e,
    (
        SELECT
            round(AVG(salary), 2) AS avg_salary
        FROM
            employees
    )
WHERE
    e.salary > avg_salary;

--using with clause
WITH avg_sal AS (
    SELECT
        round(AVG(salary), 2) AS avg_salary
    FROM
        employees
)
SELECT
    e.employee_id,
    salary,
    avg_salary
FROM
    employees e,
    avg_sal
WHERE
    e.salary > avg_sal.avg_salary;

--Finding all the departments where total salary of all employees in that department is more than the average salary of all employees in the database

WITH dep_wise_sal AS (
    SELECT
        department_id,
        SUM(salary) AS total_sal_dept_wise
    FROM
        employees
    GROUP BY
        department_id
), avg_sal AS (
    SELECT
        round(AVG(salary), 2) AS avg_salary_from_all_dept
    FROM
        employees
)
SELECT
    *
FROM
    dep_wise_sal,
    avg_sal
WHERE
    dep_wise_sal.total_sal_dept_wise > avg_sal.avg_salary_from_all_dept;
    
/********************************************** Simplified query using WITH Clause and views **********************************************/

--WITH clause and inline views are good when we breakdown complex statements into simpler ones
--WITH clause is an drop-in replacement to the sub-query

--Finding all department related details

WITH department_salary_detail AS (
    SELECT
        department_id,
        MAX(salary)           AS max_salary,
        MIN(salary)           AS min_salary,
        round(AVG(salary), 2) AS avg_salary,
        COUNT(*)              AS num_of_employees,
        SUM(salary)           AS total_salary
    FROM
        employees
    GROUP BY
        department_id
), emp_resigned_details AS (
    SELECT
        department_id,
        COUNT(*) AS num_of_employees_resigned
    FROM
        job_history
    GROUP BY
        department_id
)
SELECT
    departments.department_id,
    departments.department_name,
    employees.first_name
    || ' '
    || employees.last_name AS manager_name,
    locations.city,
    max_salary,
    min_salary,
    avg_salary,
    num_of_employees,
    total_salary,
    num_of_employees_resigned
FROM
    departments
    LEFT JOIN employees ON departments.manager_id = employees.employee_id
    LEFT JOIN locations ON locations.location_id = departments.location_id
    LEFT JOIN department_salary_detail ON departments.department_id = department_salary_detail.department_id
    LEFT JOIN emp_resigned_details ON departments.department_id = emp_resigned_details.department_id
ORDER BY
    departments.department_id;
    
--same above query was written as below one using sub-query and inline view'

SELECT
    departments.department_id,
    departments.department_name,
    employees.first_name
    || ' '
    || employees.last_name AS manager_name,
    locations.city,
    max_salary,
    min_salary,
    avg_salary,
    num_of_employees,
    total_salary,
    num_of_employees_resigned
FROM
    departments
    LEFT JOIN employees ON departments.manager_id = employees.employee_id
    LEFT JOIN locations ON locations.location_id = departments.location_id
    LEFT JOIN (
        SELECT
            department_id,
            MAX(salary)           AS max_salary,
            MIN(salary)           AS min_salary,
            round(AVG(salary), 2) AS avg_salary,
            COUNT(*)              AS num_of_employees,
            SUM(salary)           AS total_salary
        FROM
            employees
        GROUP BY
            department_id
    ) department_salary_detail ON departments.department_id = department_salary_detail.department_id
    LEFT JOIN (
        SELECT
            department_id,
            COUNT(*) AS num_of_employees_resigned
        FROM
            job_history
        GROUP BY
            department_id
    ) emp_resigned_details ON departments.department_id = emp_resigned_details.department_id
ORDER BY
    departments.department_id;

--Now, when such big queries are there in the script and we need to access these queries every now and then, we can use it as a view
--Above query can be created as a view and then we just need to run the view to exectue the query

--If the view is not created, then the syntax will create it or it will replace it

CREATE OR REPLACE VIEW dept_details_view AS
    WITH department_salary_detail AS (
        SELECT
            department_id,
            MAX(salary)           AS max_salary,
            MIN(salary)           AS min_salary,
            round(AVG(salary), 2) AS avg_salary,
            COUNT(*)              AS num_of_employees,
            SUM(salary)           AS total_salary
        FROM
            employees
        GROUP BY
            department_id
    ), emp_resigned_details AS (
        SELECT
            department_id,
            COUNT(*) AS num_of_employees_resigned
        FROM
            job_history
        GROUP BY
            department_id
    )
    SELECT
        departments.department_id,
        departments.department_name,
        employees.first_name
        || ' '
        || employees.last_name AS manager_name,
        locations.city,
        max_salary,
        min_salary,
        avg_salary,
        num_of_employees,
        total_salary,
        num_of_employees_resigned
    FROM
        departments
        LEFT JOIN employees ON departments.manager_id = employees.employee_id
        LEFT JOIN locations ON locations.location_id = departments.location_id
        LEFT JOIN department_salary_detail ON departments.department_id = department_salary_detail.department_id
        LEFT JOIN emp_resigned_details ON departments.department_id = emp_resigned_details.department_id
    ORDER BY
        departments.department_id;

--To exectue the view
SELECT
    *
FROM
    dept_details_view;
    
/********************************************** Fetching employee record with third highest salary w/o using analytical functions **********************************************/

--ROWNUM is a 'Psuedocolumn' that assign a number to each row returned by the 
--query indicating the order in which Oracle select the row from a table.
--The first row selected has a ROWNUM of 1, the second has 2, and so on

--This query assign a row number to each row that it is fetching 
SELECT
    t.*,
    ROWNUM
FROM
    employees t;

WITH third_max_sal AS (
    SELECT
        MAX(salary) AS third_max_salary
    FROM
        employees
    WHERE
        salary NOT IN (
            SELECT
                *
            FROM
                (
                    SELECT
                        salary
                    FROM
                        employees
                    GROUP BY
                        salary
                    ORDER BY
                        salary DESC
                )
            WHERE
                ROWNUM < 3
        )
)
SELECT
    *
FROM
         employees
    JOIN third_max_sal ON employees.salary = third_max_sal.third_max_salary;

/********************************************** Find duplicate location_id along with details **********************************************/

SELECT
    location_id,
    postal_code,
    city,
    country_id
FROM
    locations
UNION
SELECT
    location_id,
    CAST(postal_code AS VARCHAR2(12)),
    city,
    country_id
FROM
    non_functional_locations;

--after running the above query we get to know that some of the location_ids for different cities are same. This can be a data quality issue and we need to highlight this.
--Below method allows us to find duplication issue

WITH all_locations AS (
    SELECT
        location_id,
        postal_code,
        city,
        country_id
    FROM
        locations
    UNION
    SELECT
        location_id,
        CAST(postal_code AS VARCHAR2(12)),
        city,
        country_id
    FROM
        non_functional_locations
), duplicate_loc_id AS (
    SELECT
        location_id,
        COUNT(*) AS duplicate_count
    FROM
        all_locations
    GROUP BY
        location_id
    HAVING
        COUNT(*) > 1
)
SELECT
    all_locations.location_id,
    postal_code,
    city,
    country_id,
    duplicate_count count
FROM
         all_locations
    JOIN duplicate_loc_id ON all_locations.location_id = duplicate_loc_id.location_id;

/********************************************** Select unique city along with location details **********************************************/

WITH all_locations AS (
    SELECT
        location_id,
        postal_code,
        city,
        country_id
    FROM
        locations
    UNION
    SELECT
        location_id,
        CAST(postal_code AS VARCHAR2(12)),
        city,
        country_id
    FROM
        non_functional_locations
), unique_city AS (
    SELECT
        city,
        MAX(location_id) AS max_location_id
    FROM
        all_locations
    GROUP BY
        city
)
SELECT
    all_locations.location_id,
    postal_code,
    all_locations.city,
    country_id
FROM
         unique_city
    JOIN all_locations ON all_locations.location_id = unique_city.max_location_id
                          AND all_locations.city = unique_city.city
ORDER BY
    location_id;

/********************************************** Display city (record) in a comma seperated manner **********************************************/

--with duplicates using listagg function and order by clause
WITH all_locations AS (
    SELECT
        location_id,
        postal_code,
        city,
        country_id
    FROM
        locations
    UNION
    SELECT
        location_id,
        CAST(postal_code AS VARCHAR2(12)),
        city,
        country_id
    FROM
        non_functional_locations
)
SELECT
    LISTAGG(city, ',') WITHIN GROUP(
    ORDER BY
        city
    ) AS city
FROM
    all_locations;

--without duplicates using listagg function and order by clause
WITH all_locations AS (
    SELECT
        location_id,
        postal_code,
        city,
        country_id
    FROM
        locations
    UNION
    SELECT
        location_id,
        CAST(postal_code AS VARCHAR2(12)),
        city,
        country_id
    FROM
        non_functional_locations
), unique_city AS (
    SELECT
        city,
        MAX(location_id) AS max_location_id
    FROM
        all_locations
    GROUP BY
        city
), unique_locations_with_details AS (
    SELECT
        all_locations.location_id,
        postal_code,
        all_locations.city,
        country_id
    FROM
             unique_city
        JOIN all_locations ON all_locations.location_id = unique_city.max_location_id
                              AND all_locations.city = unique_city.city
)
SELECT
    country_id,
    LISTAGG(city, ',') WITHIN GROUP(
    ORDER BY
        city
    ) AS city
FROM
    unique_locations_with_details
GROUP BY
    country_id;

/********************************************** Find all employees whose salary is not in job range **********************************************/

SELECT
    employee_id,
    first_name,
    last_name,
    email,
    phone_number,
    hire_date,
    e.job_id,
    salary,
    min_salary,
    max_salary
FROM
         jobs j
    JOIN employees e ON j.job_id = e.job_id
                        AND ( salary < min_salary
                              OR salary > max_salary ); 

