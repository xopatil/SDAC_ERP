DELIMITER $$

CREATE PROCEDURE Execute_ABC_Classification()
BEGIN
    -- Classifying products based on sales data
    FOR rec IN (SELECT ProductID, Name, SUM(Total_Amount) AS SalesValue
                FROM sales s
                JOIN products p ON s.ProductID = p.ProductID
                GROUP BY ProductID, Name
                ORDER BY SalesValue DESC) LOOP
        -- Assign 'A', 'B', or 'C' based on sales value
        IF rec.SalesValue > 10000 THEN
            UPDATE products
            SET Category = 'A'
            WHERE ProductID = rec.ProductID;
        ELSIF rec.SalesValue BETWEEN 5000 AND 10000 THEN
            UPDATE products
            SET Category = 'B'
            WHERE ProductID = rec.ProductID;
        ELSE
            UPDATE products
            SET Category = 'C'
            WHERE ProductID = rec.ProductID;
        END IF;
    END LOOP;

    -- Log the results of the classification
    INSERT INTO Logs (Algorithm_Name, Timestamp, Results)
    VALUES ('ABC Classification', SYSDATE, 'Products classified into A, B, C');
END$$

DELIMITER ;
