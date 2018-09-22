/*Look at the first 100 rows of data in the subscriptions table.
How many different segments do you see?*/
SELECT *
FROM subscriptions
LIMIT 100;

SELECT DISTINCT segment AS Segments
FROM subscriptions
ORDER BY segment;

/*Determine the range of months of data provided.
For which months will you be able to calculate churn?*/
SELECT
	MIN(subscription_start) AS 'Earliest Start',
	MAX(subscription_end) AS 'Latest End'
FROM subscriptions;
/*Codeflix requires a minimum subscription length of 31 days, so a user can never start and end their subscription in the same month.*/

/*Create a temporary table of months.*/
WITH months AS (
	SELECT
		'2017-01-01' AS first_day,
		'2017-01-31' AS last_day
	UNION
	SELECT
		'2017-02-01' AS first_day,
		'2017-02-28' AS last_day
	UNION
	SELECT
		'2017-03-01' AS first_day,
		'2017-03-31' AS last_day
),
/*Create a temporary table, cross_join, from subscriptions and months.*/
cross_join AS (
	SELECT *
	FROM subscriptions 
	CROSS JOIN months
),
/*Create a temporary table, status, from cross_join*/
status AS (
	SELECT
		id,
		first_day AS month,
		CASE
			WHEN segment = 87 AND subscription_start < first_day AND (subscription_end >= first_day OR subscription_end IS NULL) THEN 1
			ELSE 0
			END AS is_active_87,
		CASE
			WHEN segment = 30 AND subscription_start < first_day AND (subscription_end >= first_day OR subscription_end IS NULL) THEN 1
			ELSE 0
			END AS is_active_30,
/*Add is_canceled columns to the status table.*/
		CASE
			WHEN segment = 87 AND subscription_end BETWEEN first_day AND last_day THEN 1
			ELSE 0
			END AS is_canceled_87,
		CASE
			WHEN segment = 30 AND subscription_end BETWEEN first_day AND last_day THEN 1
			ELSE 0
			END AS is_canceled_30
	FROM cross_join
),
/*Create a temporary table, status_aggregate, that is a sum of the active and canceled subscriptions for each segment, for each month.*/
status_aggregate AS (
	SELECT
		month,
		SUM(is_active_87) AS sum_active_87,
		SUM(is_active_30) AS sum_active_30,
		SUM(is_canceled_87) AS sum_canceled_87,
		SUM(is_canceled_30) AS sum_canceled_30
	FROM status
	GROUP BY month
)
/*Calculate the churn rates for the two segments over the three month period.*/
SELECT
	month,
	1.0* sum_canceled_87 / sum_active_87 AS churn_87,
	1.0* sum_canceled_30 / sum_active_30 AS churn_30,
/*What is the overall churn trend since the company started?*/
	1.0* (sum_canceled_87 + sum_canceled_30) / (sum_active_87 + sum_active_30) AS total_churn /*this works because there are no null values for segment*/
FROM status_aggregate
GROUP BY month;

/*double-check total_churn for accuracy, would need this for total if there were values for segment other than 87 and 30*/
WITH months AS (
	SELECT
		'2017-01-01' AS first_day,
		'2017-01-31' AS last_day
	UNION
	SELECT
		'2017-02-01' AS first_day,
		'2017-02-28' AS last_day
	UNION
	SELECT
		'2017-03-01' AS first_day,
		'2017-03-31' AS last_day
),
cross_join AS (
	SELECT *
	FROM subscriptions
	CROSS JOIN months
),
status AS (
	SELECT
		id,
		first_day AS month,
		CASE
			WHEN subscription_start < first_day AND (subscription_end >= first_day OR subscription_end IS NULL) THEN 1
			ELSE 0
			END AS is_active,
		CASE 
			WHEN subscription_end BETWEEN first_day AND last_day THEN 1
			ELSE 0
			END AS is_canceled
	FROM cross_join
),
status_aggregate AS (
	SELECT
		month,
		SUM(is_active) AS active,
		SUM(is_canceled) AS canceled
	FROM status
	GROUP BY month
)
SELECT
	month,
	1.0*canceled/active AS total_churn
FROM status_aggregate;

/*find new starts, by segment*/
WITH months AS (
	SELECT
 		'2016-12-01' AS first_day,
 		'2016-12-31' AS last_day
	UNION
	SELECT
		'2017-01-01' AS first_day,
		'2017-01-31' AS last_day
	UNION
	SELECT
		'2017-02-01' AS first_day,
		'2017-02-28' AS last_day
	UNION
	SELECT
		'2017-03-01' AS first_day,
		'2017-03-31' AS last_day
),
cross_join AS (
	SELECT *
		FROM subscriptions
		CROSS JOIN months
),
new_starts AS (
	SELECT
		first_day AS month,
		CASE
			WHEN segment = 87 THEN 1
			ELSE 0
			END AS is_started_87,
		CASE
			WHEN segment = 30 THEN 1
			ELSE 0
			END AS is_started_30
	FROM cross_join
	WHERE subscription_start BETWEEN first_day AND last_day
)
SELECT
	month,
	SUM(is_started_87) AS start_87,
	SUM(is_started_30) AS start_30,
	SUM(is_started_87 + is_started_30) AS total_starts
FROM new_starts
GROUP BY month;

/*find active subsriptions at the start of each month*/
WITH months AS (
	SELECT
		'2016-12-01' AS first_day,
		'2016-12-31' AS last_day
	UNION
	SELECT
		'2017-01-01' AS first_day,
		'2017-01-31' AS last_day
	UNION
	SELECT
		'2017-02-01' AS first_day,
		'2017-02-28' AS last_day
	UNION
	SELECT
		'2017-03-01' AS first_day,
		'2017-03-31' AS last_day
	UNION
	SELECT
		'2017-04-01' AS first_day,
		'2017-04-30' AS last_day
),
cross_join AS (
	SELECT *
	FROM subscriptions
	CROSS JOIN months
),
status AS (
	SELECT
		id,
		first_day AS month,
		CASE
			WHEN segment = 87 AND subscription_start < first_day AND (subscription_end >= first_day OR subscription_end IS NULL) THEN 1
			ELSE 0
			END AS is_active_87,
		CASE
			WHEN segment = 30 AND subscription_start < first_day AND (subscription_end >= first_day OR subscription_end IS NULL) THEN 1
			ELSE 0
			END AS is_active_30
	FROM cross_join
)
SELECT
	month,
	SUM(is_active_87) AS active_87,
	SUM(is_active_30) AS active_30
FROM status
GROUP BY month;

/*Modify the code to support a large number of segments.*/
WITH months AS (
	SELECT
		'2017-01-01' AS first_day,
		'2017-01-31' AS last_day
	UNION
	SELECT
		'2017-02-01' AS first_day,
		'2017-02-28' AS last_day
	UNION
	SELECT
		'2017-03-01' AS first_day,
		'2017-03-31' AS last_day
),
cross_join AS (
	SELECT *
	FROM subscriptions
	CROSS JOIN months
),
status AS (
	SELECT
		id,
		first_day AS month,
		segment,
		CASE
			WHEN subscription_start < first_day AND (subscription_end >= first_day OR subscription_end IS NULL) THEN 1
			ELSE 0
			END AS is_active,
		CASE
			WHEN subscription_end BETWEEN first_day AND last_day THEN 1
			ELSE 0
			END AS is_canceled
	FROM cross_join
),
status_aggregate AS (
	SELECT
		month,
		segment,
		SUM(is_active) AS sum_active,
		SUM(is_canceled) AS sum_canceled
	FROM status
	GROUP BY month,segment
)
SELECT
	month AS Month,
	segment AS Segment,
	ROUND(1.0* sum_canceled / sum_active,4) AS Churn
FROM status_aggregate
GROUP BY month,segment;

/*uncomment for testing:
INSERT INTO subscriptions VALUES (3001,'2018-03-03','2018-05-16',87);
*/

/*extract each of the 12 months as columns across, and a column for year*/
WITH months AS (
	SELECT 
		DATE(subscription_start,'start of month') AS first_day,
		DATE(subscription_start,'start of month','+1 month','-1 day') AS last_day
	FROM subscriptions
	WHERE subscription_start >= '2017-01-01' /*first and last for Dec2016 don't need to be generated, and would result in rows of null churn values*/
	UNION
	SELECT
		DATE(subscription_end,'start of month') AS first_day,
		DATE(subscription_end,'start of month','+1 month','-1 day') AS last_day
	FROM subscriptions /*in case there's a month with no new starts, it can still calculate*/
),
cross_join AS (
	SELECT *
	FROM subscriptions
	CROSS JOIN months
),
status AS (
	SELECT
		id,
		first_day,
		segment,
		CASE
			WHEN subscription_start < first_day AND (subscription_end >= first_day OR subscription_end IS NULL) THEN 1
			ELSE 0
			END AS is_active,
		CASE
			WHEN subscription_end BETWEEN first_day AND last_day THEN 1
			ELSE 0
			END AS is_canceled
	FROM cross_join
),
status_aggregate AS (
	SELECT
		first_day,
		segment,
		SUM(is_active) AS sum_active,
		SUM(is_canceled) AS sum_canceled
	FROM status
	GROUP BY first_day,segment
)
/*SQLite uses strftime, other RDBMSs may use a different function to extract the year and month*/
SELECT
	STRFTIME('%Y',first_day) AS 'Year',
	segment AS 'Segment',
	SUM(CASE 
		WHEN STRFTIME('%m',first_day) = '01' THEN ROUND(1.0*sum_canceled/sum_active*100,4)
		END) AS 'Jan Churn %',
	SUM(CASE
		WHEN STRFTIME('%m',first_day) = '02' THEN ROUND(1.0*sum_canceled/sum_active*100,4)
		END) AS 'Feb Churn %',
	SUM(CASE
		WHEN STRFTIME('%m',first_day) = '03' THEN ROUND(1.0*sum_canceled/sum_active*100,4)
		END) AS 'Mar Churn %',
	SUM(CASE
		WHEN STRFTIME('%m',first_day) = '04' THEN ROUND(1.0*sum_canceled/sum_active*100,4)
		END) AS 'Apr Churn %',
	SUM(CASE
		WHEN STRFTIME('%m',first_day) = '05' THEN ROUND(1.0*sum_canceled/sum_active*100,4)
		END) AS 'May Churn %',
	SUM(CASE
		WHEN STRFTIME('%m',first_day) = '06' THEN ROUND(1.0*sum_canceled/sum_active*100,4)
		END) AS 'Jun Churn %',
	SUM(CASE
		WHEN STRFTIME('%m',first_day) = '07' THEN ROUND(1.0*sum_canceled/sum_active*100,4)
		END) AS 'Jul Churn %',
	SUM(CASE
		WHEN STRFTIME('%m',first_day) = '08' THEN ROUND(1.0*sum_canceled/sum_active*100,4)
		END) AS 'Aug Churn %',
	SUM(CASE
		WHEN STRFTIME('%m',first_day) = '09' THEN ROUND(1.0*sum_canceled/sum_active*100,4)
		END) AS 'Sep Churn %',
	SUM(CASE
		WHEN STRFTIME('%m',first_day) = '10' THEN ROUND(1.0*sum_canceled/sum_active*100,4)
		END) AS 'Oct Churn %',
	SUM(CASE
		WHEN STRFTIME('%m',first_day) = '11' THEN ROUND(1.0*sum_canceled/sum_active*100,4)
		END) AS 'Nov Churn %',
	SUM(CASE
		WHEN STRFTIME('%m',first_day) = '12' THEN ROUND(1.0*sum_canceled/sum_active*100,4)
		END) AS 'Dec Churn %'
FROM status_aggregate
WHERE Year > 2016 /*to rid null year rows*/
GROUP BY Year,Segment;