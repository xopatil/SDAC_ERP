CREATE VIEW MonthlyBeginningInventoryView AS
SELECT
    p.ProductID,
    p.Name AS ProductName,
    p.Cost AS UnitCost,
    rm.MonthStart,
    CASE
        WHEN rm.MonthStart = '2023-01-01' THEN 100
        ELSE 100 - COALESCE(
            (
                SELECT SUM(s.Quantity)
                FROM sales s
                WHERE s.ProductID = p.ProductID
                AND s.Date < rm.MonthStart
            ), 0
        )
    END AS BeginningInventory
FROM
    products p
CROSS JOIN
    (
        -- Generate months as a derived table
        WITH RECURSIVE RecursiveMonths AS (
            SELECT DATE('2023-01-01') AS MonthStart
            UNION ALL
            SELECT DATE_ADD(MonthStart, INTERVAL 1 MONTH)
            FROM RecursiveMonths
            WHERE MonthStart < '2025-01-01'
        )
        SELECT MonthStart FROM RecursiveMonths
    ) AS rm -- Ensure the derived table has an alias
ORDER BY
    p.ProductID, rm.MonthStart;

DELIMITER //

CREATE FUNCTION Inventory_Turnover_Ratio()
RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON DEFAULT JSON_OBJECT('Timestamp', NOW());
    DECLARE current_month_start DATE;
    DECLARE current_month_end DATE;
    
    -- Get the start and end date of the current month
    SET current_month_start = DATE_FORMAT(CURDATE(), '%Y-%m-01');
    SET current_month_end = LAST_DAY(CURDATE());
    
    SET result = JSON_SET(
        result,
        '$.InventoryTurnoverRatios',
        (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'ProductID', p.ProductID,
                    'ProductName', p.Name,
                    'BeginningInventory', mbiv.BeginningInventory,
                    'EndingInventory', p.Stock,
                    'COGS', (
                        SELECT COALESCE(SUM(s.Quantity), 0) * p.Cost
                        FROM sales s
                        WHERE s.ProductID = p.ProductID
                        AND s.Date >= current_month_start
                        AND s.Date <= current_month_end
                    ),
                    'AverageInventory', ((mbiv.BeginningInventory + p.Stock) / 2) * p.Cost,
                    'InventoryTurnoverRatio',
                    CASE
                        WHEN ((mbiv.BeginningInventory + p.Stock) / 2) = 0 THEN 0
                        ELSE (
                            SELECT COALESCE(SUM(s.Quantity), 0) * p.Cost
                            FROM sales s
                            WHERE s.ProductID = p.ProductID
                            AND s.Date >= current_month_start
                            AND s.Date <= current_month_end
                        ) / (((mbiv.BeginningInventory + p.Stock) / 2) * p.Cost)
                    END
                )
            )
            FROM products p
            JOIN MonthlyBeginningInventoryView mbiv ON mbiv.ProductID = p.ProductID
            WHERE mbiv.MonthStart = current_month_start
        )
    );
    
    RETURN result;
END //

DELIMITER ;

