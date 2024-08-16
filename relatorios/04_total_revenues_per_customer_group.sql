SELECT 
	c.company_name, 
	SUM(od.unit_price * od.quantity * (1.0 - od.discount)) AS total_costumer_spend,
	NTILE(5) OVER (
ORDER BY
	SUM(od.unit_price * od.quantity * (1.0 - od.discount)) as group_number 
FROM 
	orders o
	INNER JOIN
		customers c 
		ON o.customer_id = c.customer_id
	INNER JOIN
		order_details od 
		ON o.order_id = od.order_id
GROUP BY
	c.company_name
ORDER BY
	total_costumer_spend DESC;
