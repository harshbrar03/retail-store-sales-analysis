SELECT * FROM "Orders";

-- Q1. What is the total sales and profit over time (monthly/yearly)?
SELECT
    DATE_TRUNC('month', "order_date"::date) AS "month",
    ROUND(SUM("sale_price")::numeric, 2) AS "total_sales",
    ROUND(SUM("profit")::numeric, 2) AS "total_profit"
FROM "Orders"
GROUP BY DATE_TRUNC('month', "order_date"::date)
ORDER BY "month";

-- Q2. Which regions are generating the highest profit and sales?
SELECT
    "region",
    ROUND(SUM("sale_price")::numeric, 2) AS total_sales,
    ROUND(SUM("profit")::numeric, 2) AS total_profit
FROM "Orders"
GROUP BY "region"
ORDER BY "total_sales" DESC;

-- Q3. Most profitable categories and sub-categories?
SELECT
    "category",
    "sub_category",
    ROUND(SUM("sale_price")::numeric, 2) AS total_sales,
    ROUND(SUM("profit")::numeric, 2) AS total_profit
FROM
    "Orders"
GROUP BY
    "category", "sub_category"
ORDER BY
    "total_profit" DESC;

-- Q4. Which ship modes are most used and profitable
SELECT
    "ship_mode",
    COUNT(*) AS total_orders,
    ROUND(SUM("sale_price")::numeric, 2) AS total_sales,
    ROUND(SUM("profit")::numeric, 2) AS total_profit
FROM "Orders"
GROUP BY "ship_mode"
ORDER BY "total_orders" DESC;

-- Q5. Top-performing cities/states by sales and profit
SELECT
    "state",
    ROUND(SUM("sale_price")::numeric, 2) AS total_sales,
    ROUND(SUM("profit")::numeric, 2) AS total_profit
FROM "Orders"
GROUP BY "state"
ORDER BY "total_sales" DESC
LIMIT 10;

-- Q6. Impact of discount on profit
SELECT
    CASE
        WHEN "discount" = 0 THEN '0%'
        WHEN "discount" > 0 AND "discount" <= 0.1 THEN '0–10%'
        WHEN "discount" > 0.1 AND "discount" <= 0.2 THEN '10–20%'
        WHEN "discount" > 0.2 AND "discount" <= 0.3 THEN '20–30%'
        WHEN "discount" > 0.3 AND "discount" <= 0.4 THEN '30–40%'
        WHEN "discount" > 0.4 THEN '>40%'
    END AS "discount_range",
    ROUND(AVG("profit")::numeric, 2) AS "avg_profit",
    COUNT(*) AS "order_count"
FROM "Orders"
GROUP BY "discount_range"
ORDER BY "discount_range";

-- Q7. Category-wise Sales and Profit Overview
SELECT 
    "category",
    ROUND(SUM("sale_price")::numeric, 2) AS "total_sales",
    ROUND(SUM("profit")::numeric, 2) AS "total_profit"
FROM "Orders"
GROUP BY "category"
ORDER BY "total_sales" DESC;

-- Q8. Which customer segments bring the most sales and profit?
SELECT 
    "segment",
    COUNT(*) AS "total_orders",
    ROUND(SUM("sale_price")::numeric, 2) AS "total_sales",
    ROUND(SUM("profit")::numeric, 2) AS "total_profit"
FROM "Orders"
GROUP BY "segment"
ORDER BY "total_sales" DESC;

-- Q9. Which regions are most profitable?
SELECT 
    "region",
    COUNT(*) AS "total_orders",
    ROUND(SUM("sale_price")::numeric, 2) AS "total_sales",
    ROUND(SUM("profit")::numeric, 2) AS "total_profit"
FROM "Orders"
GROUP BY "region"
ORDER BY "total_profit" DESC;

-- Q10. Does Profit Margin Vary Across Sub-Categories?
SELECT 
    "sub_category",
    COUNT(*) AS "total_orders",
    ROUND(SUM("sale_price")::numeric, 2) AS "total_sales",
    ROUND(SUM("profit")::numeric, 2) AS "total_profit",
    ROUND(((SUM("profit") / SUM("sale_price")) * 100) ::numeric, 2) AS "profit_margin_pct"
FROM "Orders"
GROUP BY "sub_category"
ORDER BY "profit_margin_pct" DESC;

-- Q11. Find top 10 highest revenue generating products
SELECT 
	"product_id",
	ROUND(SUM("sale_price"):: numeric, 2) AS "sales"
FROM 
	"Orders"
GROUP BY
	"product_id"
ORDER BY
	"sales" DESC
LIMIT 10;

-- Q12. Find top 5 highest selling products in each region
WITH "CTE" AS
(
	SELECT
		"region", 
		"product_id", 
		ROUND(SUM("sale_price"):: numeric, 2) AS "sales"
	FROM
		"Orders"
	GROUP BY
		"region", "product_id"
)
SELECT * FROM
(
	SELECT 
		*,
		row_number() over(partition by "region" order by "sales" desc) AS "rn"
	FROM
		"CTE"
) AS A
WHERE A."rn" <= 5;

-- Q13. Find month over month growth comparison for 2022 and 2023 sales example: jan 2022 vs jan 2023
WITH "CTE" AS
(
	SELECT
		EXTRACT(YEAR FROM "order_date"::date) AS "order_year",
		EXTRACT(MONTH FROM "order_date"::date) AS "order_month",
		TO_CHAR("order_date"::date, 'month') AS "month_name",
		ROUND(SUM("sale_price"):: numeric, 2) AS "sales"
	FROM
		"Orders"
	GROUP BY
		 "order_year", "order_month", "month_name"
)
SELECT 
	"order_month",
	"month_name",
	SUM(CASE WHEN "order_year" = 2022 THEN "sales" ELSE 0 END) AS "year_2022",
	SUM(CASE WHEN "order_year" = 2023 THEN "sales" ELSE 0 END) AS "year_2023"
FROM "CTE"
GROUP BY "order_month", "month_name"
ORDER BY "order_month";

-- Q13. For each category which month had highest sales
WITH "CTE" AS(
	SELECT
		"category",
		EXTRACT(YEAR FROM "order_date"::date) || '-' || EXTRACT(MONTH FROM "order_date"::date) AS "year_month",
		ROUND(SUM("sale_price"):: numeric, 2) as "sales"
	FROM
		"Orders"
	GROUP BY 
		"category",
		EXTRACT(YEAR FROM "order_date"::date) || '-' || EXTRACT(MONTH FROM "order_date"::date)
	)
SELECT * FROM(
	SELECT 
		*, 
		row_number() over(partition by "category" order by "sales" desc) AS "rn"
	FROM "CTE") AS "A"
WHERE "A"."rn" = 1;

-- Q14. Which sub category had the highest growth by profit in 2023 compared to 2022
WITH "CTE" AS(
	SELECT
		EXTRACT(YEAR FROM "order_date"::date) AS "order_year",
		"sub_category",
		ROUND(SUM("sale_price"):: numeric, 2) AS "sales"
	FROM
		"Orders"
	GROUP BY
		 EXTRACT(YEAR FROM "order_date"::date), "sub_category"),
"CTE2" AS
(
SELECT 
	"sub_category",
	SUM(CASE WHEN "order_year" = 2022 THEN "sales" ELSE 0 END) AS "year_2022",
	SUM(CASE WHEN "order_year" = 2023 THEN "sales" ELSE 0 END) AS "year_2023"
FROM "CTE"
GROUP BY "sub_category"
)
SELECT *, ("year_2023"-"year_2022")*100/("year_2022") AS "gowth_by_profit_perct"
FROM "CTE2"
ORDER BY "gowth_by_profit_perct" desc
LIMIT 10;

