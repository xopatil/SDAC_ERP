DELIMITER //

CREATE FUNCTION Product_Profitability() RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON DEFAULT JSON_OBJECT('Timestamp', NOW());
    DECLARE totalProfit DECIMAL(10, 2);
    DECLARE product_id INT;
    DECLARE done INT DEFAULT 0;

    -- Cursor declaration to iterate through all products in the Sales and Products tables
    DECLARE product_cursor CURSOR FOR
        SELECT 
            s.ProductID, 
            SUM((IFNULL(s.Total_Amount / s.Quantity, 0) - IFNULL(p.Cost, 0)) * s.Quantity) AS TotalProfit
        FROM 
            Sales s
        JOIN 
            Products p ON s.ProductID = p.ProductID
        GROUP BY 
            s.ProductID;

    -- Handler for end of cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Open the cursor
    OPEN product_cursor;

    -- Iterate through all products and append their profitability to the result JSON
    product_loop: LOOP
        FETCH product_cursor INTO product_id, totalProfit;

        IF done THEN
            LEAVE product_loop;
        END IF;

        -- If no sales data exists, set profit to 0
        IF totalProfit IS NULL THEN
            SET totalProfit = 0;
        END IF;

        -- Append the product's profitability to the JSON array
        SET result = JSON_ARRAY_APPEND(
            result,
            '$',
            JSON_OBJECT('ProductID', product_id, 'Profit', totalProfit)
        );
    END LOOP;

    -- Close the cursor
    CLOSE product_cursor;

    -- Return the result JSON object
    RETURN result;
END //

DELIMITER ;


DELIMITER //

CREATE FUNCTION Inventory_Turnover_Ratio(
    p_ProductID INT
) RETURNS JSON 
DETERMINISTIC
BEGIN
    -- Variables to store intermediate results
	DECLARE result JSON DEFAULT JSON_OBJECT('Timestamp', NOW());
    DECLARE v_COGS DECIMAL(10, 2);
    DECLARE v_Current_Stock INT;
    DECLARE v_Beginning_Stock INT;
    DECLARE v_Average_Inventory DECIMAL(10, 2);

    -- Calculate Cost of Goods Sold (COGS)
    SET v_COGS = (
        SELECT SUM(s.Quantity * p.Cost)
        FROM sales s
        JOIN products p ON s.ProductID = p.ProductID
        WHERE p.ProductID = p_ProductID
    );

    -- Get the current stock
    SET v_Current_Stock = (
        SELECT Stock
        FROM products
        WHERE ProductID = p_ProductID
    );

    -- Calculate beginning stock
    SET v_Beginning_Stock = (
        SELECT (v_Current_Stock + IFNULL(SUM(s.Quantity), 0))
        FROM sales s
        WHERE s.ProductID = p_ProductID
    );

    -- Calculate Average Inventory
    SET v_Average_Inventory = (v_Beginning_Stock + v_Current_Stock) / 2;

    -- Handle division by zero
    IF v_Average_Inventory = 0 THEN
        RETURN NULL; -- Return NULL if Average Inventory is zero
    END IF;

-- 	SET result = v_COGS / v_Average_Inventory;
    
    SET result = JSON_SET(result, '$.InventoryTurnoverRatio', v_COGS / v_Average_Inventory);

    -- Calculate and return Inventory Turnover Ratio
    RETURN result;
END //

DELIMITER ;
