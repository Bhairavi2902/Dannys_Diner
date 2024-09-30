-- 1. What is the total amount each customer spent at the restaurant?

-- First joined the sales and menu tables

SELECT *
FROM sales
JOIN menu
ON sales.product_id=menu.product_id;

-- Followed by grouping based on customer_id and utilized SUM() function to get total amount spent

SELECT sales.customer_id,SUM(menu.price) as Total_Spent
FROM sales
JOIN menu
ON sales.product_id=menu.product_id
GROUP BY sales.customer_id;

-- 2. How many days has each customer visited the restaurant?

-- Performed grouping based on customer_id and utilized COUNT(DISTINCT) function to count number of days on sales table

SELECT customer_id,COUNT(DISTINCT order_date) AS days_visited
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

-- Used ROW_NUMBER() function over the partition by customer_id , then used the table as CTE
WITH first_purchase AS (
SELECT sales.customer_id,sales.order_date,menu.product_name,
RANK() OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date ASC) AS RW
FROM sales 
JOIN menu
ON sales.product_id=menu.product_id
)
SELECT customer_id,product_name
FROM first_purchase
WHERE RW=1
GROUP BY customer_id,product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

-- joined sales and menu table and utilised COUNT() function to get the count of product_name By aggregating by product_name
SELECT menu.product_name,COUNT(menu.product_name)
FROM sales
JOIN menu
ON sales.product_id=menu.product_id
GROUP BY menu.product_name;

-- To get the product ordered maximum times, sorted the column by COUNT() in descending and limit the output to the top 1 result.
SELECT menu.product_name,COUNT(menu.product_name) As Purchase_Count
FROM sales
JOIN menu
ON sales.product_id=menu.product_id
GROUP BY menu.product_name
order BY COUNT(menu.product_name) desc
LIMIT 1;

-- 5. Which item was the most popular for each customer?

-- Used Inner Join for sales and menu table and utilized RANK() function for Total Product count for each customer

WITH popular AS
(
SELECT sales.customer_id,menu.product_name,COUNT(menu.product_name) AS Purchase_Count,
RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(menu.product_name) DESC) AS RNK
FROM sales
JOIN menu
ON sales.product_id=menu.product_id
GROUP BY sales.customer_id,menu.product_name
)
SELECT customer_id,product_name,Purchase_Count
FROM popular
WHERE RNK=1;

-- 6. Which item was purchased first by the customer after they became a member?

-- Inner Joining tables with RANK() function 

WITH CTE AS
(
SELECT sales.customer_id,sales.order_date,members.join_date,menu.product_name,
RANK() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date ASC) AS RNK
FROM sales
JOIN members
ON sales.customer_id=members.customer_id
JOIN menu
ON sales.product_id=menu.product_id
WHERE sales.order_date>=members.join_date
)
SELECT customer_id,product_name,order_date,join_date
FROM CTE
WHERE RNK=1;

-- 7.Which item was purchased just before the customer became a member?

WITH CTE AS
(
SELECT sales.customer_id,sales.order_date,members.join_date,menu.product_name,
RANK() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date DESC) AS RNK
FROM sales
JOIN members
ON sales.customer_id=members.customer_id
JOIN menu
ON sales.product_id=menu.product_id
WHERE sales.order_date<members.join_date
)
SELECT customer_id,product_name
FROM CTE
WHERE RNK=1;

-- 8.What is the total items and amount spent for each member before they became a member?

-- Inner Join for all 3 tables followed by  Aggregation function SUM() and COUNT()

SELECT sales.customer_id,COUNT(menu.product_id) AS Total_items,SUM(menu.price) AS Amt_Spent
FROM sales
JOIN members
ON sales.customer_id=members.customer_id
JOIN menu
ON sales.product_id=menu.product_id
WHERE sales.order_date<members.join_date
GROUP BY sales.customer_id;

-- 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

-- Inner JOIN for tables followed by case startement to perform logical functions

SELECT sales.customer_id,
SUM(
CASE
   WHEN product_name="sushi" THEN price*10*2
   ELSE price*10
END
)
AS points
FROM menu
JOIN sales
ON menu.product_id=sales.product_id
GROUP BY sales.customer_id;

-- 10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- Inner join for all 3 tables followed by Case statement

WITH CTE AS
(
	SELECT sales.customer_id,sales.order_date,members.join_date,menu.product_name,menu.price,
	(
		CASE
			WHEN sales.order_date BETWEEN members.join_date AND DATE_ADD(members.join_date,INTERVAL 7 day) THEN menu.price*2*10
			WHEN menu.product_name="sushi" THEN menu.price*2*10
			ELSE menu.price*10
		END
	)
	AS points
	FROM menu
	JOIN sales
	ON sales.product_id=menu.product_id
	JOIN members
	ON sales.customer_id=members.customer_id
	WHERE sales.order_date<"2021-02-01"
)
SELECT customer_id,SUM(points) AS Total_Points_Jan
FROM CTE
GROUP BY customer_id;


-- Bonus Question -- join tables

-- Here, SQL query is designed to summarize data from all three tables by joining.

SELECT sales.customer_id,sales.order_date,menu.product_name,price,
	(
		CASE
		WHEN sales.order_date>=members.join_date THEN "Y"
		ELSE "N"
		END 
	)
	AS membership
FROM sales
LEFT JOIN members
ON sales.customer_id=members.customer_id
JOIN menu
ON sales.product_id=menu.product_id
ORDER BY sales.customer_id, sales.order_date ASC;

-- BONUS QUESTION -- RANKING

-- Here, SQL query is designed to summarize data from all three tables by joining.

WITH CTE AS 
(
SELECT sales.customer_id,sales.order_date,menu.product_name,price,members.join_date,
	(
		CASE
		WHEN sales.order_date>=members.join_date THEN "Y"
		ELSE "N"
		END 
	)
	AS membership
FROM sales
LEFT JOIN members
ON sales.customer_id=members.customer_id
JOIN menu
ON sales.product_id=menu.product_id
ORDER BY sales.customer_id, sales.order_date ASC
)
SELECT *,
CASE
    WHEN membership="N" then "NULL"
    ELSE ROW_NUMBER() OVER(PARTITION BY sales.customer_id,membership ORDER BY sales.order_date ASC)
END AS Ranking
FROM CTE;