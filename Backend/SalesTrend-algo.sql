DELIMITER //

CREATE FUNCTION Sales_Trend_Analysis() RETURNS JSON DETERMINISTIC
BEGIN
    DECLARE product_id INT;
    DECLARE sales_date DATE;
    DECLARE monthly_sales DECIMAL(10,2);
    DECLARE prev_month_sales DECIMAL(10,2) DEFAULT NULL;
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

        -- Reset previous month's sales for the new product
        SET prev_month_sales = NULL;
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

                -- Extract year and month from sales_date
                SET @month = MONTH(sales_date);
                SET @year = YEAR(sales_date);

                -- Compare with previous month's sales
                IF prev_month_sales IS NOT NULL THEN
                    IF monthly_sales > prev_month_sales THEN
                        SET result = JSON_ARRAY_APPEND(result, '$', JSON_OBJECT('PRODUCT_ID', product_id, 'YEAR', @year, 'MONTH', @month, 'TREND', 'Increasing'));
                    ELSEIF monthly_sales < prev_month_sales THEN
                        SET result = JSON_ARRAY_APPEND(result, '$', JSON_OBJECT('PRODUCT_ID', product_id, 'YEAR', @year, 'MONTH', @month, 'TREND', 'Decreasing'));
                    ELSE
                        SET result = JSON_ARRAY_APPEND(result, '$', JSON_OBJECT('PRODUCT_ID', product_id, 'YEAR', @year, 'MONTH', @month, 'TREND', 'Stable'));
                    END IF;
                END IF;

                -- Update previous month's sales
                SET prev_month_sales = monthly_sales;
            END LOOP;

            -- Close the monthly sales cursor
            CLOSE monthly_sales_cursor;
        END;
    END LOOP;

    -- Close product cursor
    CLOSE product_cursor;


    -- Return the result as JSON
    RETURN result;
END; //

DELIMITER ;