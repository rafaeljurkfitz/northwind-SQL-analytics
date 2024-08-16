SELECT 
	c.contact_name, SUM((od.unit_price * od.quantity * (1.0 - od.discount))) AS sales
FROM 
	customers c
INNER JOIN 
	orders o
	on o.customer_id = c.customer_id
INNER JOIN
	order_details od
	on o.order_id = od.order_id
WHERE 
	LOWER(c.country) = 'uk'
GROUP BY
	c.contact_name
HAVING 
	SUM((od.unit_price * od.quantity * (1.0 - od.discount))) >= 1000
ORDER BY
	sales DESC
