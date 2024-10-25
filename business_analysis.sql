USE magist;
-- product questions

-- What categories of tech products does Magist have?
-- tech categories:
-- list english: ('audio', 'electronics', 'computers_accessories', 'computers', 'telephony')
-- list port: ('audio', 'eletronicos', 'informatica_acessorios', 'pcs', 'telefonia')

-- How many products of these tech categories have been sold (within the time window of the database snapshot)? 
-- What percentage does that represent from the overall number of products sold?
SELECT count(o.product_id) as no_of_orders, count(o.product_id)*100/(SELECT count(*) FROM order_items) as percentage_of_all_sold, avg(o.price) as avg_price,
CASE
WHEN p.product_category_name IN ('audio', 'eletronicos', 'informatica_acessorios', 'pcs', 'telefonia')
	THEN 'tech'
    ELSE 'non_tech'
END tech_cat
FROM order_items as o
LEFT JOIN products as p
ON o.product_id=p.product_id
GROUP BY tech_cat;

-- What’s the average price of the products being sold?
SELECT p.product_category_name, count(o.order_id) as no_of_orders, count(o.order_id)*100/(SELECT count(*) FROM order_items) as percentage_of_all_sold, round(avg(o.price),2) as avg_price
FROM order_items as o
JOIN products as p
ON o.product_id=p.product_id
WHERE p.product_category_name IN ('audio', 'cine_foto', 'eletronicos', 'eletroportateis', 'informatica_acessorios', 'pcs', 'relogios_presentes', 'tablets_impressao_imagem', 'telefonia')
GROUP BY p.product_category_name;

-- Are expensive tech products popular
SELECT count(o.product_id) as no_of_orders,
CASE
	WHEN price > 1000 THEN "Expensive"
	WHEN price > 100 THEN "Mid-range"
	ELSE "Cheap" 
    END price_range
FROM order_items as o
LEFT JOIN products as p
ON o.product_id=p.product_id
WHERE p.product_category_name IN ('audio', 'cine_foto', 'eletronicos', 'eletroportateis', 'informatica_acessorios', 'pcs', 'relogios_presentes', 'tablets_impressao_imagem', 'telefonia')
GROUP BY price_range
ORDER BY 1 DESC;


-- sellers
-- How many months of data are included in the magist database?

SELECT TIMESTAMPDIFF(month, min(order_purchase_timestamp) ,max(order_purchase_timestamp)) as month_of_data FROM orders;

-- How many sellers are there? How many Tech sellers are there? What percentage of overall sellers are Tech sellers?
SELECT count(distinct(seller_id)) as no_of_sellers FROM sellers;

SELECT p.product_category_name, count(distinct(o.seller_id)) as no_of_sellers, count(distinct(o.order_id))*100/(SELECT distinct(count(*)) FROM order_items) as percentage_of_all_sellers
FROM order_items as o
JOIN products as p
ON o.product_id=p.product_id
WHERE p.product_category_name IN ('audio', 'cine_foto', 'eletronicos', 'eletroportateis', 'informatica_acessorios', 'pcs', 'relogios_presentes', 'tablets_impressao_imagem', 'telefonia')
GROUP BY p.product_category_name;

-- What is the total amount earned by all sellers? What is the total amount earned by all Tech sellers?
SELECT round(sum(price),2) as total_earned FROM order_items;

SELECT p.product_category_name, count(distinct(oi.seller_id)) as no_of_sellers, round(sum(oi.price),2) as earned_by_tech_sellers
FROM order_items as oi
LEFT JOIN products as p
ON oi.product_id=p.product_id
LEFT JOIN
orders o USING (order_id)
WHERE 
	p.product_category_name IN ('audio', 'cine_foto', 'eletronicos', 'eletroportateis', 'informatica_acessorios', 'pcs', 'relogios_presentes', 'tablets_impressao_imagem', 'telefonia')
	AND o.order_status NOT IN ('unavailable' , 'canceled')
GROUP BY p.product_category_name;

-- Can you work out the average monthly income of all sellers? Can you work out the average monthly income of Tech sellers?
SELECT 1666211.28 / 454 / 25;


-- delivery time
-- What’s the average time between the order being placed and the product being delivered?
SELECT avg(delivery_time) as avg_delivery 
FROM (SELECT datediff(order_delivered_customer_date, order_purchase_timestamp) as delivery_time FROM orders) AS date_diff;

-- How many orders are delivered on time vs orders delivered with a delay?
SELECT count(*) FROM orders;
SELECT 
COUNT(
CASE WHEN (SELECT date(order_delivered_customer_date) FROM orders) = (SELECT date(order_estimated_delivery_date) FROM orders) THEN 1
ELSE 0
END
) as on_time
FROM orders; 
-- Is there any pattern for delayed orders, e.g. big products being delayed more often?
SELECT
    CASE 
        WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) >= 100 THEN "> 100 day Delay"
        WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) >= 7 AND DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) < 100 THEN "1 week to 100 day delay"
        WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) > 3 AND DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) < 7 THEN "4-7 day delay"
        WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) >= 1  AND DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) <= 3 THEN "1-3 day delay"
        WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) > 0  AND DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) < 1 THEN "less than 1 day delay"
        WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) <= 0 THEN 'On time' 
    END AS "delay_range", 
    AVG(product_weight_g) AS weight_avg,
    MAX(product_weight_g) AS max_weight,
    MIN(product_weight_g) AS min_weight,
    SUM(product_weight_g) AS sum_weight,
    COUNT(DISTINCT a.order_id) AS orders_count
FROM orders a
LEFT JOIN order_items b
    USING (order_id)
LEFT JOIN products c
    USING (product_id)
WHERE order_estimated_delivery_date IS NOT NULL
AND order_delivered_customer_date IS NOT NULL
AND order_status = 'delivered'
GROUP BY delay_range;