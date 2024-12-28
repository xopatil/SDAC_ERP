DELIMITER //

CREATE FUNCTION ForecastDemand(days INT) 
RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE product_id INT;
    DECLARE product_name VARCHAR(100);
    DECLARE avg_sales DECIMAL(10, 2);
    DECLARE total_sales INT;
    DECLARE result JSON DEFAULT JSON_ARRAY();
    DECLARE done INT DEFAULT 0;

    -- Cursor declaration
    DECLARE product_cursor CURSOR FOR
    SELECT ProductID, Name
    FROM Products;

    -- Handler for end of cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Open the cursor
    OPEN product_cursor;

    -- Iterate through all products
    product_loop: LOOP
        FETCH product_cursor INTO product_id, product_name;

        IF done THEN
            LEAVE product_loop;
        END IF;

        SELECT IFNULL(AVG(Quantity), 0) INTO avg_sales
        FROM Sales
        WHERE ProductID = product_id
          AND Date >= CURDATE() - INTERVAL days DAY;

        SET total_sales = CEIL(avg_sales * days);

        SET result = JSON_ARRAY_APPEND(result, '$', JSON_OBJECT(
            'ProductID', product_id,
            'ProductName', product_name,
            'PredictedDemand', total_sales
        ));
    END LOOP;

    CLOSE product_cursor;

    RETURN result;
END;
//

DELIMITER ;