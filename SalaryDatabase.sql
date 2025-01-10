--What are some of the highest paying role for data analyst based on location and company
SELECT job_title, job_location, com_dim.name AS company_name, salary_year_avg
FROM job_postings_fact job_post
INNER JOIN company_dim com_dim ON job_post.company_id = com_dim.company_id
WHERE job_title_short = 'Data Analyst'
      AND salary_year_avg IS NOT NULL
      AND (job_location LIKE 'Manila%' OR job_location LIKE 'Taguig%' OR job_location LIKE 'Makati%')
      AND job_country = 'Philippines'
ORDER BY salary_year_avg DESC
FETCH FIRST 10 ROWS ONLY;

--What are the skills required to have a high paying salary for Data Analyst jobs
WITH cte_top_jobs AS(
    SELECT job_id, job_title, job_location, com_dim.name AS company_name, salary_year_avg
    FROM job_postings_fact job_post
    INNER JOIN company_dim com_dim ON job_post.company_id = com_dim.company_id
    WHERE job_title_short = 'Data Analyst'
          AND salary_year_avg IS NOT NULL
          AND job_location LIKE '%Philippines' 
          AND job_country = 'Philippines'
    ORDER BY salary_year_avg DESC
)
SELECT job_title, job_location, company_name, sk_dim.skills AS skill, salary_year_avg
FROM cte_top_jobs cte_jobs
INNER JOIN skills_job_dim sk_job ON sk_job.job_id = cte_jobs.job_id
INNER JOIN skills_dim sk_dim ON sk_job.skill_id = sk_dim.skill_id
ORDER BY salary_year_avg DESC;

--Results
--Number of Job Postings:
--SQL, Excel, and Tableau are the most frequently mentioned skills in job postings.

--Average Salaries:
--Skills like Python, R, and Tableau command higher average salaries compared to others.

--What are the most sought after skills on a high paying jobs as a data analyst
WITH cte_skills_info AS(
    SELECT sk_job_dim.job_id AS job_id,
           sk_dim.skill_id AS skill_id,
           sk_dim.skills AS skill_name
    FROM skills_job_dim sk_job_dim
    INNER JOIN skills_dim sk_dim ON sk_job_dim.skill_id = sk_dim.skill_id
)
SELECT MAX(cte_info.skill_id) AS skill_id, cte_info.skill_name, COUNT(job_post.job_id) AS posting_count
FROM cte_skills_info cte_info
LEFT JOIN job_postings_fact job_post ON cte_info.job_id = job_post.job_id
WHERE job_title_short = 'Data Analyst' AND job_post.job_location LIKE '%Philippines' 
GROUP BY cte_info.skill_name
ORDER BY posting_count DESC;

--What are the top skills based on salary
WITH cte_top_salary AS(
    SELECT skill_id, job_title_short, salary_year_avg
    FROM job_postings_fact
    INNER JOIN skills_job_dim sk_job ON job_postings_fact.job_id = sk_job.job_id
    WHERE salary_year_avg IS NOT NULL AND job_title_short = 'Data Analyst' AND job_location LIKE '%Philippines'
    ORDER BY salary_year_avg DESC
)
SELECT sk_dim.skills AS skill, ROUND(AVG(salary_year_avg),0) AS average_salary
FROM cte_top_salary
INNER JOIN skills_dim sk_dim ON cte_top_salary.skill_id = sk_dim.skill_id
GROUP BY skill
ORDER BY average_salary DESC;

--What are the most optimal skills to learn based on demand and salary
WITH cte_top_salary AS(
    SELECT skill_id, job_title_short, salary_year_avg
    FROM job_postings_fact
    INNER JOIN skills_job_dim sk_job ON job_postings_fact.job_id = sk_job.job_id
    WHERE salary_year_avg IS NOT NULL AND job_title_short = 'Data Analyst' AND job_location LIKE '%Philippines'
    ORDER BY salary_year_avg DESC
)
SELECT sk_dim.skills AS skill, COUNT(sk_dim.skills) AS demand_count, ROUND(AVG(salary_year_avg),0) AS average_salary
FROM cte_top_salary
INNER JOIN skills_dim sk_dim ON cte_top_salary.skill_id = sk_dim.skill_id
GROUP BY skill
ORDER BY average_salary DESC, demand_count DESC
FETCH FIRST 25 ROWS ONLY




