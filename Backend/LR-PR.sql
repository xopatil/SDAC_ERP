DELIMITER $$

CREATE FUNCTION GetProfitabilityRegressionWithProducts() 
RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON;

    -- Variables for linear regression
    DECLARE n INT;
    DECLARE sumX DECIMAL(10, 2) DEFAULT 0;
    DECLARE sumY DECIMAL(10, 2) DEFAULT 0;
    DECLARE sumXY DECIMAL(10, 2) DEFAULT 0;
    DECLARE sumX2 DECIMAL(10, 2) DEFAULT 0;
    DECLARE slope DECIMAL(10, 4) DEFAULT 0;
    DECLARE intercept DECIMAL(10, 4) DEFAULT 0;

    -- Temporary table to store product-wise profitability
    DROP TEMPORARY TABLE IF EXISTS ProfitData;
    CREATE TEMPORARY TABLE ProfitData AS
    SELECT 
        MONTH(S.Date) AS X,  -- Month as X (independent variable)
        SUM((S.Total_Amount / S.Quantity - P.Cost) * S.Quantity) AS Y,  -- Profit as Y (dependent variable)
        P.ProductID,
        P.Name AS ProductName
    FROM 
        Products P
    JOIN 
        Sales S ON P.ProductID = S.ProductID
    GROUP BY 
        YEAR(S.Date), MONTH(S.Date), P.ProductID;

    -- Step 2: Calculate the necessary sums for linear regression (overall profitability)
    SELECT 
        COUNT(*) AS n,
        SUM(X) AS sumX,
        SUM(Y) AS sumY,
        SUM(X * Y) AS sumXY,
        SUM(X * X) AS sumX2
    INTO 
        n, sumX, sumY, sumXY, sumX2
    FROM 
        ProfitData;

    -- Step 3: Calculate slope (m) and intercept (b) for overall profitability
    SET slope = (n * sumXY - sumX * sumY) / (n * sumX2 - POW(sumX, 2));
    SET intercept = (sumY - slope * sumX) / n;

    -- Step 4: Prepare the individual product profitability data
    -- Create a temporary table to store product profit data
    DROP TEMPORARY TABLE IF EXISTS ProductProfit;
    CREATE TEMPORARY TABLE ProductProfit AS
    SELECT 
        P.ProductID,
        P.Name AS ProductName,
        SUM((S.Total_Amount / S.Quantity - P.Cost) * S.Quantity) AS TotalProfit,
        AVG(S.Total_Amount / S.Quantity - P.Cost) AS AverageProfitPerUnit
    FROM 
        Products P
    JOIN 
        Sales S ON P.ProductID = S.ProductID
    GROUP BY 
        P.ProductID;

    -- Step 5: Generate JSON result for overall profitability trend and individual product profitabilities
    SET result = JSON_OBJECT(
        'OverallTrend', JSON_OBJECT(
            'Slope', slope,
            'Intercept', intercept,
            'TrendLineEquation', CONCAT('y = ', slope, 'x + ', intercept)
        ),
        'ProductProfitabilities', (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'ProductID', ProductID,
                    'ProductName', ProductName,
                    'TotalProfit', TotalProfit,
                    'AverageProfitPerUnit', AverageProfitPerUnit
                )
            )
            FROM ProductProfit
        )
    );

    -- Return the result as JSON
    RETURN result;
END$$

DELIMITER ;