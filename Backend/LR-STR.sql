DELIMITER //

CREATE FUNCTION Sales_Tnd_Analysis() RETURNS JSON DETERMINISTIC
BEGIN
    DECLARE product_id INT;
    DECLARE sales_date DATE;
    DECLARE monthly_sales DECIMAL(10,2);
    DECLARE sum_x DECIMAL(10,2) DEFAULT 0;
    DECLARE sum_y DECIMAL(10,2) DEFAULT 0;
    DECLARE sum_x2 DECIMAL(10,2) DEFAULT 0;
    DECLARE sum_xy DECIMAL(10,2) DEFAULT 0;
    DECLARE n INT DEFAULT 0;
    DECLARE slope DECIMAL(10,6);
    DECLARE abs_slope DECIMAL(10,6);
    DECLARE result JSON DEFAULT JSON_OBJECT('Timestamp', NOW());
    DECLARE finished_products INT DEFAULT 0;
    DECLARE finished_sales INT DEFAULT 0;

    -- Cursor to iterate through all products
    DECLARE product_cursor CURSOR FOR
        SELECT DISTINCT ProductID FROM Sales;

    -- Handler for end of product cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished_products = 1;

    -- Open product cursor
    OPEN product_cursor;

    product_loop: LOOP
        FETCH product_cursor INTO product_id;

        IF finished_products THEN
            LEAVE product_loop;
        END IF;

        -- Reset aggregates for the new product
        SET sum_x = 0, sum_y = 0, sum_x2 = 0, sum_xy = 0, n = 0;
        SET finished_sales = 0;

        -- Declare and open monthly sales cursor in a separate block to allow a handler
        BEGIN
            -- Cursor for monthly sales data for a specific product
            DECLARE monthly_sales_cursor CURSOR FOR
                SELECT
                    DATE_FORMAT(Date, '%Y-%m-01') AS SalesMonth,
                    SUM(Total_Amount) AS MonthlySales
                FROM Sales
                WHERE ProductID = product_id
                GROUP BY SalesMonth
                ORDER BY SalesMonth;

            -- Handler for end of monthly sales cursor
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished_sales = 1;

            -- Open monthly sales cursor
            OPEN monthly_sales_cursor;

            sales_loop: LOOP
                FETCH monthly_sales_cursor INTO sales_date, monthly_sales;

                IF finished_sales THEN
                    LEAVE sales_loop;
                END IF;

                -- Update aggregates for regression
                SET n = n + 1;
                SET sum_x = sum_x + n;
                SET sum_y = sum_y + monthly_sales;
                SET sum_x2 = sum_x2 + n * n;
                SET sum_xy = sum_xy + n * monthly_sales;
            END LOOP;

            -- Close the monthly sales cursor
            CLOSE monthly_sales_cursor;
        END;

        -- Compute regression slope (m)
        IF n > 1 THEN
            SET slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x);
            SET abs_slope = ABS(slope); -- Ensure slope is non-negative for plotting
        ELSE
            SET slope = 0; -- Not enough data points for regression
            SET abs_slope = 0;
        END IF;

        -- Categorize trend and include numeric slope
        IF slope > 0 THEN
            SET result = JSON_ARRAY_APPEND(result, '$', JSON_OBJECT('PRODUCT_ID', product_id, 'TREND', 'Increasing', 'SLOPE', abs_slope));
        ELSEIF slope < 0 THEN
            SET result = JSON_ARRAY_APPEND(result, '$', JSON_OBJECT('PRODUCT_ID', product_id, 'TREND', 'Decreasing', 'SLOPE', abs_slope));
        ELSE
            SET result = JSON_ARRAY_APPEND(result, '$', JSON_OBJECT('PRODUCT_ID', product_id, 'TREND', 'Stable', 'SLOPE', abs_slope));
        END IF;
    END LOOP;

    -- Close product cursor
    CLOSE product_cursor;

    -- Return the result as JSON
    RETURN result;
END //

DELIMITER ;