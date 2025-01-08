DELIMITER //

CREATE FUNCTION Inventory_Turnover_Ratio() RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON DEFAULT JSON_OBJECT('Timestamp', NOW());

    -- Aggregate ITR for all products into a JSON array
    SET result = JSON_SET(
        result,
        '$.InventoryTurnoverRatios',
        (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'ProductID', p.ProductID,
                    'InventoryTurnoverRatio', 
                    CASE
                        WHEN ((
                            SELECT (p.Stock + IFNULL(SUM(s.Quantity), 0))
                            FROM sales s
                            WHERE s.ProductID = p.ProductID
                        ) + p.Stock) / 2 = 0 THEN NULL
                        ELSE (
                            SELECT SUM(s.Quantity * p.Cost)
                            FROM sales s
                            WHERE s.ProductID = p.ProductID
                        ) / (
                            (p.Stock + IFNULL((
                                SELECT SUM(s.Quantity)
                                FROM sales s
                                WHERE s.ProductID = p.ProductID
                            ), 0)) / 2
                        )
                    END
                )
            )
            FROM products p
        )
    );

    RETURN result;
END //

DELIMITER ;

