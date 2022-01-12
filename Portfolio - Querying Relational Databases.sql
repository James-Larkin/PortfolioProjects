--Querying the pcshop database in MySQL (phpMyAdmin)

---------------------------------------> JOINS <----------------------------------------

#1. List the makers that make at least two different models of PC.
SELECT maker FROM products
JOIN pcs 
ON products.model = pcs.model
GROUP BY maker 
HAVING COUNT(maker) >= 2;

#2. List the maker(s) of the laptop(s) with the highest available speed.
SELECT maker
FROM products NATURAL JOIN laptops
WHERE speed >= ALL (SELECT speed FROM laptops);

#3. List the cities with customers who bought a printer.
SELECT DISTINCT city FROM customers 
JOIN sales ON customers.customer_id = sales.customer_id
JOIN products ON sales.model = products.model
WHERE products.type = 'printer';

#4. List the makers of PCs that don't make any laptop or printer.
#JOIN
SELECT DISTINCT a.maker
FROM products a JOIN pcs b ON a.model = b.model
AND a.type = 'pc' 
AND maker NOT IN (SELECT maker FROM products WHERE type <> 'pc')

#SUBQUERY
SELECT DISTINCT maker FROM products
WHERE type = 'pc' AND maker NOT IN
    (SELECT maker FROM products
     WHERE type = 'laptop'
     OR type = 'printer');

#5. List all laptop models and only for models made by makers A and B list also their price. The prices of laptops not made by either A or B should be NULL.
SELECT laptops.model, products.maker,
IF(maker = 'A' OR maker = 'B', price, NULL) AS priceAandB
FROM products JOIN laptops ON products.model = laptops.model;

#6. List the names (first name and last name) of customers who haven't bought any product.
SELECT firstname, lastname FROM customers
LEFT JOIN sales ON customers.customer_id = sales.customer_id 
WHERE sales.customer_id IS NULL

#7. Find the makers who make exactly three different PC models. List all such makers, and for each of them, list also the average speed of the three PC models they make.
SELECT maker, AVG(speed)
FROM products JOIN pcs USING(model)
GROUP BY maker
HAVING COUNT(*) = 3

#8. List the makers who make at least two different computers (PCs or laptops) with speed of at least 2.80.
SELECT maker FROM pcs
RIGHT JOIN products ON pcs.model = products.model
LEFT JOIN laptops ON products.model = laptops.model
WHERE type != 'printer' 
AND pcs.speed >= 2.80 OR laptops.speed >= 2.8
GROUP BY maker
HAVING COUNT(maker) >= 2;

#9. Find the dates on which the shop made total sales (money paid for all products sold on the date) of at least 1000 euro. List these dates and for each date list also the total quantity of products sold.
SELECT day, SUM(quantity)
FROM sales
GROUP BY day
HAVING SUM(paid) >= 1000


----------------------------------> MODIFYING SCHEMA <----------------------------------

#10. Modifying the pcshop schema
CREATE TABLE price_changes(
    model CHAR(4) NOT NULL,
    updated_price DOUBLE NOT NULL,
    updated_datetime DATETIME NOT NULL,
    PRIMARY KEY(model, updated_datetime), 
    FOREIGN KEY (model)
    REFERENCES products(model)
    ON UPDATE CASCADE
);


----------------------------------> EXPRESSING FKS <------------------------------------

#11. Sales - Customer_ID
ALTER TABLE sales
ADD CONSTRAINT fk_sales_cust_id
FOREIGN KEY (customer_id)
REFERENCES customers (customer_id);

#12. Sales - Model 
ALTER TABLE sales
ADD CONSTRAINT fk_sales_model
FOREIGN KEY (model)
REFERENCES products (model);

#13. Printers - Model
ALTER TABLE printers
ADD CONSTRAINT fk_printers
FOREIGN KEY (model) 
REFERENCES products(model);

#14. Laptops - Model
ALTER TABLE laptops
ADD CONSTRAINT fk_laptops
FOREIGN KEY (model) 
REFERENCES products(model);

#15. PCs - Model
ALTER TABLE pcs
ADD CONSTRAINT fk_pcs
FOREIGN KEY (model) 
REFERENCES products(model);


----------------------------------> ADDING TRIGGERS <-----------------------------------

#16. PCs
DELIMITER // 
CREATE TRIGGER price_changes_pc
BEFORE UPDATE ON pcs 
FOR EACH ROW BEGIN
	IF (NEW.price <> OLD.price) THEN
	INSERT INTO price_changes
	VALUES (OLD.model, OLD.price, NOW()); 
END IF;
END;//

#17. Laptops
DELIMITER // 
CREATE TRIGGER price_changes_laptops
BEFORE UPDATE ON laptops 
FOR EACH ROW BEGIN
	IF (NEW.price <> OLD.price) THEN
	INSERT INTO price_changes
	VALUES (OLD.model, OLD.price, NOW()); 
END IF;
END;//

#18. Printers
DELIMITER // 
CREATE TRIGGER price_changes_printers
BEFORE UPDATE ON printers 
FOR EACH ROW BEGIN
	IF (NEW.price <> OLD.price) THEN
	INSERT INTO price_changes
	VALUES (OLD.model, OLD.price, NOW()); 
END IF;
END;//


-------------------------> CREATING TABLES & ADDING COLUMNS <---------------------------

#19. New Ratings Table
CREATE TABLE ratings(
    customer_id CHAR(10),
    model CHAR(4), 
    rating INTEGER CHECK (rating IN (1,2,3,4,5,'')),
    rating_time TIMESTAMP,
    PRIMARY KEY (model, customer_id, rating_time),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (model) REFERENCES products(model)
);

#20. Adding Discount Column
ALTER TABLE customers ADD COLUMN(
    discount FLOAT NOT NULL DEFAULT 0)
);


-------------------------------> CREATING FUNCTIONS <-----------------------------------

#21. Creating Get Current Rating Function
delimiter //
CREATE FUNCTION GetCurrentRating(cid CHAR(10), m CHAR(4))
RETURNS CHAR
READS SQL DATA
BEGIN 
DECLARE latest_rating CHAR DEFAULT NULL;
    SELECT rating INTO latest_rating FROM ratings
    WHERE ratings.customer_id = cid 
    AND ratings.model = m 
    AND ratings.rating_time =(
        SELECT MAX(rating_time) FROM ratings 
        WHERE customer_id = cid AND model = m
) ; RETURN latest_rating ;
END;
//

#22. Creating Get Number of Ratings Function
delimiter // 
CREATE FUNCTION GetNumberOfRatings(cid CHAR(10))
RETURNS INTEGER (10)
READS SQL DATA
BEGIN 
DECLARE rating_count INTEGER DEFAULT 0;
    SELECT COUNT(rating) INTO rating_count
    FROM ratings WHERE rating >= 1 AND customer_id = cid;
RETURN rating_count ;
END;
//


------------------------------> CREATING PROCEDURES <-----------------------------------

#23. Creating a Stored Procedure to insert new ratings into table ratings
delimiter //
CREATE PROCEDURE RateModel(
    cid CHAR(10), m CHAR(4), r INT) 
BEGIN
    DECLARE discount FLOAT;
    IF ((r = 0) AND (GetCurrentRating(cid, m) IS NOT NULL)) THEN
        INSERT INTO ratings(customer_id, rating, model, rating_time) 
        VALUES(cid, NULL, m, NOW());
    ELSEIF r != 0 THEN
        INSERT INTO ratings(customer_id, rating, model, rating_time) 
        VALUES(cid, m, r, NOW());
    END IF;

    SELECT customers.discount INTO discount
    FROM customers 
    WHERE customers.customer_id = cid;

    IF ((GetNumberOfRatings(cid)>4) AND (discount<10)) THEN
        UPDATE customers SET customers.discount = 10 
        WHERE customers.customer_id = cid;
    END IF;
END;
//