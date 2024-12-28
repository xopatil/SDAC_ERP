Delimiter //
CREATE FUNCTION CalculateInventoryTurnover(
    p_ProductID INT
) RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
    -- Variables to store intermediate results
    SET @v_COGS = (
        SELECT SUM(s.Quantity * p.Cost)
        FROM sales s
        JOIN products p ON s.ProductID = p.ProductID
        WHERE p.ProductID = p_ProductID
    );

    SET @v_Current_Stock = (
        SELECT Stock
        FROM products
        WHERE ProductID = p_ProductID
    );

    SET @v_Beginning_Stock = (
        SELECT (@v_Current_Stock + IFNULL(SUM(s.Quantity), 0))
        FROM sales s
        WHERE s.ProductID = p_ProductID
    );

    -- Calculate Average Inventory
    SET @v_Average_Inventory = (@v_Beginning_Stock + @v_Current_Stock) / 2;

    -- Handle division by zero
    IF @v_Average_Inventory = 0 THEN
        RETURN NULL; -- Return NULL if Average Inventory is zero
    END IF;

    -- Calculate and return Inventory Turnover Ratio
    RETURN @v_COGS / @v_Average_Inventory;
END;//