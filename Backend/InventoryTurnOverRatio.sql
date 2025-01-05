DELIMITER //

CREATE FUNCTION Inventory_Turnover_Ratio(
    p_ProductID INT
) RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
    -- Variables to store intermediate results
    DECLARE result DECIMAL(10, 2);
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

	SET result = v_COGS / v_Average_Inventory;
    
	INSERT INTO Logs (Algorithm_Name, Timestamp, Results)
    VALUES ('Inventory Turnover Ratio', NOW(), result);
    -- Calculate and return Inventory Turnover Ratio
    RETURN result;
END //

DELIMITER ;
