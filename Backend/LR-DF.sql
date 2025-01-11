DELIMITER //

CREATE FUNCTION Demand_Forecasting_Months(months INT)
RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE product_id INT;
    DECLARE product_name VARCHAR(100);
    DECLARE slope DECIMAL(10, 5);
    DECLARE intercept DECIMAL(10, 5);
    DECLARE predicted_demand DECIMAL(10, 2);
    DECLARE result JSON DEFAULT JSON_OBJECT('Timestamp', NOW());
    DECLARE done INT DEFAULT 0;

        -- Step 1: Calculate regression parameters for the last 12 months (1 year)
        DECLARE sum_x INT DEFAULT 0;
        DECLARE sum_y INT DEFAULT 0;
        DECLARE sum_x2 INT DEFAULT 0;
        DECLARE sum_xy INT DEFAULT 0;
        DECLARE count_data INT DEFAULT 0;
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

        SELECT COUNT(*), 
               SUM(PERIOD_DIFF(DATE_FORMAT(CURDATE(), '%Y%m'), DATE_FORMAT(Date, '%Y%m'))), 
               SUM(Quantity), 
               SUM(POW(PERIOD_DIFF(DATE_FORMAT(CURDATE(), '%Y%m'), DATE_FORMAT(Date, '%Y%m')), 2)), 
               SUM(PERIOD_DIFF(DATE_FORMAT(CURDATE(), '%Y%m'), DATE_FORMAT(Date, '%Y%m')) * Quantity)
        INTO count_data, sum_x, sum_y, sum_x2, sum_xy
        FROM Sales
        WHERE ProductID = product_id
          AND Date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH);

        -- Prevent division by zero in case of no data
        IF count_data = 0 OR (count_data * sum_x2 - POW(sum_x, 2)) = 0 THEN
            SET slope = 0;
            SET intercept = 0;
        ELSE
            SET slope = (count_data * sum_xy - sum_x * sum_y) / (count_data * sum_x2 - POW(sum_x, 2));
            SET intercept = (sum_y - slope * sum_x) / count_data;
        END IF;

        -- Step 2: Predict total demand for the next 'months'
        SET predicted_demand = slope * months + intercept;

        -- Step 3: Add result to JSON object
        SET result = JSON_ARRAY_APPEND(result, '$', JSON_OBJECT(
            'ProductID', product_id,
            'ProductName', product_name,
            'PredictedDemandForNextPeriod', GREATEST(CEIL(predicted_demand), 0) -- Ensure non-negative demand
        ));
    END LOOP;

    CLOSE product_cursor;

    RETURN result;
END //

DELIMITER ;