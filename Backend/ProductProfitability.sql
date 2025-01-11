DELIMITER //

CREATE FUNCTION Product_Profitability() RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON DEFAULT JSON_OBJECT('Timestamp', NOW());

    -- Calculate and aggregate product profitability into a JSON array
    SET result = (
        SELECT JSON_OBJECT(
            'Timestamp', NOW(),
            'ProfitabilityData', JSON_ARRAYAGG(profitability_data)
        )
        FROM (
            SELECT 
                JSON_OBJECT(
                    'ProductID', p.ProductID,
                    'TotalProfit', COALESCE(SUM((s.Total_Amount / s.Quantity - p.Cost) * s.Quantity), 0)
                ) AS profitability_data
            FROM Products p
            LEFT JOIN Sales s ON p.ProductID = s.ProductID
            GROUP BY p.ProductID
        ) AS aggregated_data
    );

    RETURN result;
END;
//
DELIMITER ;


