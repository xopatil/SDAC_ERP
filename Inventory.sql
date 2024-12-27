DELIMITER $$

CREATE PROCEDURE Calculate_Inventory_Turnover()
BEGIN
    -- Declare variables
    DECLARE total_sales DECIMAL(10, 2);
    DECLARE avg_inventory DECIMAL(10, 2);
    DECLARE turnover_ratio DECIMAL(10, 2);

    -- Fetch total sales in the past year
    SELECT SUM(Total_Amount) INTO total_sales
    FROM Sales
    WHERE Date BETWEEN DATE_SUB(NOW(), INTERVAL 1 YEAR) AND NOW();

    -- Fetch average inventory
    SELECT AVG(Stock) INTO avg_inventory
    FROM Products;

    -- Calculate the inventory turnover ratio
    SET turnover_ratio = total_sales / avg_inventory;

    -- Log the turnover ratio
    INSERT INTO Logs (Algorithm_Name, Timestamp, Results)
    VALUES ('Inventory Turnover Ratio', NOW(), CONCAT('Turnover Ratio: ', turnover_ratio));
END$$

DELIMITER ;
