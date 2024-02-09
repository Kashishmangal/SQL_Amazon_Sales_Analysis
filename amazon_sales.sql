#1.
# Counting Of the number of Columns
SELECT COUNT(*) AS Column_numbers FROM
    information_schema.columns
WHERE TABLE_NAME = "amazon_sales";


#2. 
# Case statement
SELECT Order_ID, Fulfilment, Amount,
    CASE 
        WHEN Fulfilment = 'Merchant' THEN 
            CASE 
                WHEN Amount > 5000 THEN 'High priority'
                WHEN Amount BETWEEN 4500 AND 2000 THEN 'Average priority'
                WHEN Amount < 1000 THEN 'Low priority'
            END
        ELSE NULL 
    END AS Priority
FROM amazon_sales
WHERE Fulfilment = 'Merchant'
LIMIT 100;


#3.
# Aggregate the total sales amount for each category in the amazon_sales table by joining with the sale_report table on matching sizes. 
# Provide the category and the corresponding total sales amount.
SELECT a.Category, SUM(a.Amount) 
FROM amazon_sales a 
INNER JOIN sale_report b ON a.Size = b.Size 
GROUP BY a.Category;

#4. 
# Retrieve the ship_city and ship_state from the amazon_sales table for records where the size is not 'L' 
# and is not present in the distinct sizes listed in the sale_report table with the size 'L'.
SELECT ship_city, ship_state
FROM amazon_sales
WHERE size <> 'L' 
AND size NOT IN (SELECT DISTINCT size FROM sale_report WHERE size = 'L');


#5. 
#Top 20 categories in the 'may_2022' table based on the sum of 'Final_MRP_Old,' considering only those records associated with the 'Moments' catalog.
# Method1 (Without join function)
SELECT Category, Catalog, SUM(MRP_Old) AS MRP,
 SUM(Final_MRP_Old) AS Final_MRP
FROM may_2022
WHERE Catalog IN (SELECT Catalog FROM may_2022
WHERE Catalog = "Moments"
)
GROUP BY Category
ORDER BY SUM(Final_MRP_Old) DESC
LIMIT 20;


#Method 2 (By join function)
SELECT m.Category, m.Catalog, SUM(m.MRP_Old) AS MRP, SUM(m.Final_MRP_Old) AS Final_MRP
FROM may_2022 m
JOIN amazon_sales a ON m.Sr_No = a.Sr_No
WHERE m.Catalog IN (
    SELECT Catalog 
    FROM may_2022 
    WHERE Catalog = 'Moments'
)
GROUP BY m.Category
ORDER BY SUM(m.Final_MRP_Old) DESC
LIMIT 20;


#6. 
#FInd the category who's amount where better than the average amount across all the categories
#Method1 (without with function)
SELECT *
FROM (SELECT Category, sum(Amount) as total_amount
	FROM amazon_sales
	GROUP BY Category) amt
JOIN (SELECT avg(Total_amount) as amt
	FROM (SELECT Category, sum(Amount) as total_amount
		FROM amazon_sales
		GROUP BY Category) x) avg_amount
	on amt.total_amount > avg_amount.amt;
   
   
#Method2 (with function)
	WITH amt as 
	(SELECT Category, sum(Amount) as total_amount
		FROM amazon_sales
		GROUP BY Category)
	SELECT *
	FROM amt
	JOIN (SELECT avg(Total_amount) as amt
		FROM amt x) avg_amount
		on amt.total_amount > avg_amount.amt;
    

#7. 
#Provide the top 100 combinations of 'Fulfilment' and 'Category' in 'amazon_sales,' aggregating sales data from 'international_sale_report' based on 'Style' 
# and ordered by the total amount in descending order.
SELECT Fulfilment, Category, SUM(Amount) AS Total_amount
FROM (
    SELECT a.Fulfilment, a.Category, SUM(Amount) AS Amount
    FROM amazon_sales a
    JOIN international_sale_report i ON a.Style = i.Style
    GROUP BY a.Fulfilment, a.Category, a.Style
) AS Subquery
GROUP BY Fulfilment, Category
ORDER BY Total_amount DESC
LIMIT 100;


#8.
# Provide a breakdown of the total quantities in the amazon_sales table based on the Courier_Status.
# Include both the Courier_Status and the corresponding total quantity, ordering the results in descending order by total quantity.
SELECT a.Courier_Status, COUNT(*) AS Total_Qty
FROM amazon_sales a
LEFT JOIN amazon_sales b ON a.ship_country = b.Courier_Status
GROUP BY a.Courier_Status
ORDER BY Total_Qty DESC;
  
  
#9.
# Retrieve the Style, Category, Qty, Amount, and the ranked quantity (RankedQty) for records in the amazon_sales table
# table joined with the international_sale_report table on the Style. 
# Where the Amount is less than or equal to 1000, and the ranking is based on the Amount within each combination of Qty and Style.
SELECT Style, Category, Qty, Amount, RankedQty
FROM (
    SELECT a.Style, a.Category, a.Qty, a.Amount,
           ROW_NUMBER() OVER (PARTITION BY a.Qty, a.Style ORDER BY a.Amount) AS RankedQty
    FROM amazon_sales a
    JOIN international_sale_report i ON a.Style = i.Style
) AS RankedData
WHERE Amount <= 1000;


	#10. 
    # How does the recursive common table expression "Category" contribute to summarizing the total quantity of orders for each Courier_Status
    # in the amazon_sales and sale_report tables.
	WITH RECURSIVE Category AS (
	  SELECT Courier_Status, COUNT(*) AS Order_ID_Count
	  FROM amazon_sales 
	  GROUP BY Courier_Status
	  UNION ALL
	  SELECT a.Courier_Status, COUNT(*) AS Order_ID_Count
	  FROM amazon_sales a
	  JOIN sale_report s ON a.Size = s.Size
	  GROUP BY a.Courier_Status
	)
	SELECT Courier_Status, SUM(Order_ID_Count) AS Total_Qty
	FROM Category
	GROUP BY Courier_Status
	ORDER BY Total_Qty DESC;


#11. 
# Retrieve the SKU, Design_No, and Color from the sale_report table for items with size 'L' 
# the maximum stock, based on the condition that the stock for size 'L' is at its maximum in the same table.
SELECT SKU, Design_No, Color
FROM sale_report
WHERE Size = 'L'
and Stock = (
	SELECT max(Stock)
    FROM sale_report
    WHERE Size = 'L');


#12. 
# Retrieve the Order_ID and Status1 from the amazon_sales table for orders 
# with the maximum amount in the city of 'JALANDHAR'.
 SELECT Order_ID, Status1
 FROM amazon_sales
 WHERE (ship_city, Amount) IN (SELECT ship_city, MAX(Amount)
								FROM amazon_sales WHERE ship_city = 'JALANDHAR'
                                GROUP BY ship_city);

 
#13. 
# It identify the Status1 with the maximum count of occurrences in the amazon_sales table.
SELECT Status1, COUNT(*) AS Status_Count
FROM amazon_sales
GROUP BY Status1
HAVING COUNT(*) = (
    SELECT MAX(Status_Count)
    FROM (
        SELECT COUNT(*) AS Status_Count
        FROM amazon_sales
        GROUP BY Status1
    ) AS Subquery
);


#14. 
# How does recursive common table expression (CTE) named “units” contribute 
# obtaining the maximum total amount for each ship_city in the amazon_sales and may_2022 tables.
WITH RECURSIVE units AS (
    SELECT ship_city, MAX(Amount) AS Total_amount
    FROM amazon_sales
    GROUP BY ship_city
    UNION ALL
    SELECT a.ship_city, MAX(a.Amount) AS Total_amount
    FROM amazon_sales a
    JOIN may_2022 m ON a.Category = m.Category
    GROUP BY a.ship_city
)
SELECT ship_city, MAX(Total_amount) AS Total_Amt
FROM units
GROUP BY ship_city;