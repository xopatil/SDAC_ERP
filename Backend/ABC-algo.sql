
DELIMITER $$

CREATE FUNCTION ABC_Classification()
RETURNS JSON -- Return results in JSON format
DETERMINISTIC
BEGIN
    DECLARE total_sales DECIMAL(10,2);
    DECLARE cumulative_sales DECIMAL(10,2) DEFAULT 0;
    DECLARE threshold_a DECIMAL(10,2);
    DECLARE threshold_b DECIMAL(10,2);
    DECLARE finished INT DEFAULT 0;
    DECLARE product_id INT;
    DECLARE product_sales DECIMAL(10,2);
    DECLARE result JSON DEFAULT JSON_ARRAY();
    
    -- Cursor for product sales
    DECLARE sales_cursor CURSOR FOR
        SELECT ProductID, SUM(TOTAL_AMOUNT) AS PRODUCT_SALES
        FROM Sales
        GROUP BY ProductID
        ORDER BY PRODUCT_SALES DESC;

    -- Handler for end of data
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;

    -- Calculate total sales
    SELECT SUM(TOTAL_AMOUNT) INTO total_sales FROM Sales;

    -- Define thresholds
    SET threshold_a = total_sales * 0.80;
    SET threshold_b = total_sales * 0.95;

    -- Open the cursor
    OPEN sales_cursor;

    -- Process each product
    fetch_loop: LOOP
        FETCH sales_cursor INTO product_id, product_sales;
        IF finished THEN
            LEAVE fetch_loop;
        END IF;

        -- Accumulate sales
        SET cumulative_sales = cumulative_sales + product_sales;

        -- Categorize products and append to result
        IF cumulative_sales <= threshold_a THEN
            SET result = JSON_ARRAY_APPEND(result, '$', JSON_OBJECT('PRODUCT_ID', product_id, 'CATEGORY', 'A'));
        ELSEIF cumulative_sales <= threshold_b THEN
            SET result = JSON_ARRAY_APPEND(result, '$', JSON_OBJECT('PRODUCT_ID', product_id, 'CATEGORY', 'B'));
        ELSE
            SET result = JSON_ARRAY_APPEND(result, '$', JSON_OBJECT('PRODUCT_ID', product_id, 'CATEGORY', 'C'));
        END IF;
    END LOOP;

    -- Close the cursor
    CLOSE sales_cursor;
    
	INSERT INTO Logs (Algorithm_Name, Timestamp, Results)
	VALUES ('ABC Classification', NOW(), result);

    -- Return the JSON result
    RETURN result;
END$$

DELIMITER ;