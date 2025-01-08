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

CREATE VIEW HistoricalSellingPrices AS
SELECT 
    s.SaleID,
    s.ProductID,
    s.Quantity,
    s.Date AS SaleDate,
    s.Total_Amount / s.Quantity AS Selling_Price_At_Sale,
    p.Cost
FROM 
    Sales s
JOIN 
    Products p ON s.ProductID = p.ProductID;


CREATE VIEW ProductProfitabilityView AS
SELECT 
    h.ProductID,
    SUM((h.Selling_Price_At_Sale - h.Cost) * h.Quantity) AS TotalProfit
FROM 
    HistoricalSellingPrices h
GROUP BY 
    h.ProductID;
    
    
    


