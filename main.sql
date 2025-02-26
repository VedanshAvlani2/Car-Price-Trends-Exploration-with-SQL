use ap;

-- Question 1: Which car brands have shown the most price appreciation over the past few years?
WITH price_trend AS (
    SELECT make, year, AVG(sellingprice) AS avg_price
    FROM vehicle_sales
    GROUP BY make, year
)
SELECT make, (MAX(avg_price) - MIN(avg_price))/MIN(avg_price) AS relative_price_appreciation
FROM price_trend
GROUP BY make
HAVING COUNT(year) > 1 
ORDER BY relative_price_appreciation DESC;

-- Question 2: What is the overall market performance for used cars in different states?
SELECT state, COUNT(*) AS total_sales, AVG(sellingprice) AS average_price
FROM vehicle_sales
GROUP BY state
ORDER BY average_price DESC;

-- Question 3: How does the year of manufacture influence the depreciation of car prices?
SELECT year, AVG(mmr - sellingprice) AS average_depreciation
FROM vehicle_sales
GROUP BY year
ORDER BY average_depreciation;

-- Question 4: What is the impact of a car's condition on its price across different make and model categories?
SELECT make, model, `condition`, AVG(sellingprice) AS average_price
FROM vehicle_sales
WHERE `condition` IS NOT NULL and make IS NOT NULL AND TRIM(model) <> '' and model IS NOT NULL AND TRIM(model) <> ''
GROUP BY make, model, `condition`
ORDER BY make, model, `condition` ;


/* [5]-What is the distribution of car prices in different regions, and are there notable regional price differences?*/

/* For buyers-  Identify regions with affordable pricing (low average price)*/
/*Solution-- nm,ma,ok,md,va,nc these 6v regions have car affordable pricing*/
SELECT state, AVG(sellingprice) AS Avg_price
FROM vehicle_sales
GROUP BY state
ORDER BY AVG(sellingprice) asc;


/* For Sellers: Target regions with higher average prices for better profits.
Target regions are - on, tn, pa,co,nv are the top 5 */

SELECT state, AVG(sellingprice) AS Avg_price
FROM vehicle_sales
GROUP BY state
ORDER BY AVG(sellingprice) desc;

/* [6]  How do odometer readings correlate with selling price across various car makes[brands] and models?*/

select make, model, 
Avg(odometer) AS odometer_readings,
Avg(sellingprice) AS Avg_price
from vehicle_sales
Group by make, model
order by Avg_price DESC;

/* [7] To correlate odometer readings with price and understand how mileage affects a car's value*/

select make, model,
Avg(odometer) AS Avg_odometer_readings,
Avg(sellingprice) AS Avg_price,
Count(*) AS Total_sales,
CASE 
when Avg(sellingprice)/Avg(odometer) > 5 THEN 'High Value Retention'
when Avg(sellingprice) /Avg(odometer) Between 2.5 AND 5 Then 'moderate value Retention'
Else 'Low value retention'
END AS Value_Category
from vehicle_sales
group by make, model
order by Avg_price DESC;

/* Insights - to understand the general price trends and mileage associated with each car model and brand.*/

/* Indights - Cars with a higher price-to-odometer ratio (e.g., Avg(price)/Avg(odometer) > 50) 
are categorized as "High Value Retention." This doesn't necessarily mean they are more popular but 
rather that they retain their value well despite higher mileage.
On the flip side, cars with lower ratios (e.g., <50) lose value more quickly as mileage increases,
 which could indicate they are less desirable in terms of resale value. 
 However, Cars with Low Value Retention might appeal to budget-conscious buyers but are
 less likely to maintain a high resale price.*/

/* [8] What are the most expensive cars sold by body type and their average market performance?*/
select body, max(sellingprice) AS Max_price , make, model
from vehicle_sales
Group by body,make, model
Order by Max_price DESC;

/* Insights - top most exoensive cars sold by body type  are -Ford, Ferrari, Mercedes-Benz, Rolls-Royance, BMW*/

/* [9] Which transmission types (automatic/manual) tend to fetch higher prices in the used car market?*/
SELECT transmission, Avg(sellingprice) as Avg_price, Count(*) as car_count
from vehicle_sales
where transmission IN ('automatic', 'manual')
Group by transmission
order by Avg_price DESC;

/* Insights The automatic transmission type price  is > then manual type cars.*/


-- 10 only focusing on hatchback, sedan, coupe and SUV
select year, body, avg(sellingprice)
from vehicle_sales
where body in ("Hatchback","SUV","Sedan","Coupe")
group by year, body
order by year,body;

-- 11 Identify Makes and Models with the Most Price Volatility
WITH price_stats AS (
    SELECT 
        make,
        model,
        STDDEV_SAMP(sellingprice) AS price_std_dev,
        AVG(sellingprice) AS average_price
    FROM vehicle_sales
    WHERE 
        sellingprice IS NOT NULL
        AND make IS NOT NULL AND TRIM(make) <> ''
        AND model IS NOT NULL AND TRIM(model) <> ''
    GROUP BY make, model
)
SELECT 
    make, 
    model, 
    price_std_dev, 
    average_price,
    (price_std_dev / average_price) * 100 AS volatility_percentage
FROM price_stats
WHERE average_price > 0
ORDER BY volatility_percentage DESC
LIMIT 10;

-- 12 Detecting Price Outliers by Make and Model
WITH ranked_prices AS (
    SELECT 
        make,
        model,
        sellingprice,
        NTILE(100) OVER (PARTITION BY make, model ORDER BY sellingprice) AS percentile_rank
    FROM vehicle_sales
    WHERE 
        make IS NOT NULL AND TRIM(make) <> ''
        AND model IS NOT NULL AND TRIM(model) <> ''
        AND sellingprice IS NOT NULL
)
SELECT 
    make, 
    model, 
    sellingprice
FROM ranked_prices
WHERE percentile_rank > 95;





-- 13 counting car sales as per each quarter
SELECT
  EXTRACT(year FROM saledate) AS year, 
  count(CASE WHEN EXTRACT(quarter FROM saledate) = 1
  THEN 1 END) AS Q1,
  count(CASE WHEN EXTRACT(quarter FROM saledate) = 2
  THEN 1 END) AS Q2,
  count(CASE WHEN EXTRACT(quarter FROM saledate) = 3
  THEN 1 END) AS Q3,
  count(CASE WHEN EXTRACT(quarter FROM saledate) = 4
  THEN 1 END) AS Q4
FROM vehicle_sales
where EXTRACT(year FROM saledate) is not null
GROUP BY EXTRACT(year FROM saledate)
ORDER BY EXTRACT(year FROM saledate);


-- 14 finding delta change in sales price for kia and bmw in 2014 and 2015

SELECT
  EXTRACT(year FROM saledate) AS revenue_year,
  EXTRACT(quarter FROM saledate) AS revenue_quarter, 
  sum(case when make = "kia" then sellingprice else 0 end) AS total_revenue_kia,
  ROUND(
    100 * (
       sum(case when make = "kia" then sellingprice else 0 end) - LAG( sum(case when make = "kia" then sellingprice else 0 end), 1) OVER
  (ORDER BY EXTRACT(year FROM saledate), EXTRACT(quarter FROM saledate)))/
    cast(LAG(sum(case when make = "kia" then sellingprice else 0 end), 1) OVER
  (ORDER BY EXTRACT(year FROM saledate), EXTRACT(quarter FROM saledate)) as decimal(10,3)),3
           )
  AS delta_kia,
  sum(case when make = "BMW" then sellingprice else 0 end) AS total_revenue_bmw,
  ROUND(
    100 * (
       sum(case when make = "BMW" then sellingprice else 0 end) - LAG( sum(case when make = "BMW" then sellingprice else 0 end), 1) OVER
  (ORDER BY EXTRACT(year FROM saledate), EXTRACT(quarter FROM saledate)))/
    cast(LAG(sum(case when make = "BMW" then sellingprice else 0 end), 1) OVER
  (ORDER BY EXTRACT(year FROM saledate), EXTRACT(quarter FROM saledate)) as decimal(10,3)),3
           )
  AS delta_bmw
FROM vehicle_sales
where EXTRACT(year FROM saledate) is not null
GROUP BY
  EXTRACT(year FROM saledate),
  EXTRACT(quarter FROM saledate)
ORDER BY
  EXTRACT(year FROM saledate),
  EXTRACT(quarter FROM saledate);

-- 15 avg price change
SELECT
  EXTRACT(year FROM saledate) AS revenue_year,
  EXTRACT(quarter FROM saledate) AS revenue_quarter, 
  cast( sum(case when make = "kia" then sellingprice else 0 end) / count(case when make = "kia" then 1 end) as
  decimal(10,3)) AS avg_revenue_kia,
  ROUND(
    100 * (
         cast( sum(case when make = "kia" then sellingprice else 0 end) / count(case when make = "kia" then 1 end) as
  decimal(10,3)) - LAG(   cast( sum(case when make = "kia" then sellingprice else 0 end) / count(case when make = "kia" then 1 else 0 end) as
  decimal(10,3)), 1) OVER
  (ORDER BY EXTRACT(year FROM saledate), EXTRACT(quarter FROM saledate)))/
    cast(LAG(  cast( sum(case when make = "kia" then sellingprice else 0 end) / count(case when make = "kia" then 1 end) as
  decimal(10,3)), 1) OVER
  (ORDER BY EXTRACT(year FROM saledate), EXTRACT(quarter FROM saledate)) as decimal(10,3)),3
           )
  AS delta_kia,
  cast( sum(case when make = "bmw" then sellingprice else 0 end) / count(case when make = "bmw" then 1  end) as
  decimal(10,3)) as avg_revenue_bmw,
  ROUND(
    100 * (
        cast( sum(case when make = "bmw" then sellingprice else 0 end) / count(case when make = "bmw" then 1  end) as
  decimal(10,3)) - LAG(  cast( sum(case when make = "bmw" then sellingprice else 0 end) / count(case when make = "bmw" then 1 end) as
  decimal(10,3)), 1) OVER
  (ORDER BY EXTRACT(year FROM saledate), EXTRACT(quarter FROM saledate)))/
    cast(LAG( cast( sum(case when make = "bmw" then sellingprice else 0 end) / count(case when make = "bmw" then 1 end) as
  decimal(10,3)), 1) OVER
  (ORDER BY EXTRACT(year FROM saledate), EXTRACT(quarter FROM saledate)) as decimal(10,3)),3
           )
  AS delta_bmw
FROM vehicle_sales
where EXTRACT(year FROM saledate) is not null
GROUP BY
  EXTRACT(year FROM saledate),
  EXTRACT(quarter FROM saledate)
ORDER BY
  EXTRACT(year FROM saledate),
  EXTRACT(quarter FROM saledate);