--Creating Table
CREATE TABLE employee_errors (
    employee_id VARCHAR(50),
    first_name VARCHAR(50),
    last_name VARCHAR(50) 
);

--Inserting Multiple Values
INSERT ALL 
    INTO employee_errors VALUES ('1001', 'Limbo', 'Halbert')
    INTO employee_errors VALUES ('1002', 'Pamela', 'Beasley')
    INTO employee_errors VALUES ('1005', 'Toby', 'Flenderson - Fired')
SELECT * FROM dual;

--CTE with partition
WITH cte_employee AS(
SELECT first_name, last_name, gender, salary,
        COUNT(gender) OVER (PARTITION BY gender) as totalgender,
        AVG(salary) OVER (PARTITION BY gender) as avgsalary
FROM employee_demographics JOIN employee_salary 
ON employee_demographics.employee_id = employee_salary.employee_id
WHERE salary > '45000'
)
SELECT * FROM cte_employee;

--Temp table 
CREATE GLOBAL TEMPORARY TABLE temp_table (
    employee_id INTEGER,
    job_title VARCHAR2(100),
    salary INTEGER
)ON COMMIT DELETE ROWS 

SELECT * FROM temp_table;

DROP TABLE temp_table;

--Inserting from temp using other table
INSERT INTO temp_table
SELECT * FROM employee_salary; 

-- Using TRIM, LTRIM, RTRIM
SELECT employee_ID, TRIM (employee_id) AS IDTrim 
FROM employee_errors;

SELECT employee_ID, LTRIM (employee_id) AS IDTrim 
FROM employee_errors;

SELECT employee_ID, RTRIM (employee_id) AS IDTrim 
FROM employee_errors;

--Using Replace
SELECT last_name, REPLACE (last_name, ' - Fired', ' ') AS last_name_fixed
FROM employee_errors;

--Using SUBSTR or Substring
SELECT first_name, SUBSTR(first_name, 1, 3) AS substring
FROM employee_errors;

--Using Upper and Lower
SELECT first_name, LOWER(first_name)
FROM employee_errors;

SELECT first_name, UPPER(first_name)
FROM employee_errors;

--Using stored procedure to display
CREATE OR REPLACE PROCEDURE proc_test 
AS
    emp_cursor SYS_REFCURSOR;
BEGIN
    OPEN emp_cursor FOR SELECT * FROM employee_demographics;
    DBMS_SQL.RETURN_RESULT(emp_cursor);
END proc_test;

EXEC proc_test();

--Combining stored procedure and temp table so you can create another one without dropping automatically
CREATE OR REPLACE PROCEDURE create_temp_table(job_title IN VARCHAR2) AS
BEGIN
    --Subqueries to check if there is an existing table, if so delete it
    BEGIN
        EXECUTE IMMEDIATE
            'DROP TABLE temp_table';
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
    END;
    
    --Create a table
    EXECUTE IMMEDIATE
    '
        CREATE GLOBAL TEMPORARY TABLE temp_table(
            job_title VARCHAR2(100),
            job_count INTEGER,
            average_age INTEGER,
            average_salary DECIMAL(10, 2)
            )ON COMMIT DELETE ROWS 
    ';
    
        
    --Insert values on the table using join
    EXECUTE IMMEDIATE
    '
        INSERT INTO temp_table 
        SELECT emp_sal.job_title, 
               COUNT(emp_sal.job_title) AS job_count, 
               AVG(emp_demo.age) AS average_age, 
               AVG(emp_sal.salary) AS average_salary
        FROM employee_demographics emp_demo
        JOIN employee_salary emp_sal
        ON emp_demo.employee_id = emp_sal.employee_id
        WHERE emp_sal.job_title = :job_title
        GROUP BY emp_sal.job_title
    ' USING job_title; --Binding the job_title in the statement to parameter that is passed
    
END create_temp_table;

EXECUTE create_temp_table('Salesman');

DROP TABLE temp_table;

--Subqueries
SELECT employee_id, salary, (SELECT AVG(salary) FROM employee_salary)
FROM employee_salary;

--Partitions
SELECT employee_id, salary, AVG(salary) OVER (PARTITION BY salary) as all_average_salary
FROM employee_salary;

--Group By which doesn't work
SELECT employee_id, salary, AVG(salary) as all_average_salary
FROM employee_salary
GROUP BY employee_id, salary
ORDER BY employee_id, salary;

--Subquery in FROM not recommended just use CTE or Temp table
SELECT part_table.employee_id, all_average_salary
FROM (SELECT employee_id, salary, 
     AVG(salary) 
     OVER (PARTITION BY salary) as all_average_salary
     FROM employee_salary) part_table;
     
--Subquery in WHERE, can only return 1 column in WHERE statement
SELECT employee_id, job_title, salary
FROM employee_salary 
WHERE employee_id IN(
        SELECT employee_id 
        FROM employee_demographics 
        WHERE age > 30
    );













