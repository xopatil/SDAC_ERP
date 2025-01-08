DELIMITER //

CREATE PROCEDURE AddLog(
    IN p_Algorithm_Name VARCHAR(255),
    IN p_New_Result JSON
)
BEGIN
    DECLARE existing_results JSON;

    -- Step 1: Check if there's an existing result for the given algorithm
    SET existing_results = (
        SELECT Results
        FROM erp.Logs
        WHERE Algorithm_Name = p_Algorithm_Name
        LIMIT 1
    );

    -- Step 2: If no existing results, initialize the result as an empty JSON array
    IF existing_results IS NULL THEN
        SET existing_results = JSON_ARRAY();
    END IF;

    -- Step 3: Append the new result to the existing result array
    SET existing_results = JSON_ARRAY_APPEND(existing_results, '$', p_New_Result);

    -- Step 4: Update the existing record or insert a new one if not found
    IF EXISTS (SELECT 1 FROM erp.Logs WHERE Algorithm_Name = p_Algorithm_Name) THEN
        UPDATE erp.Logs
        SET Results = existing_results, Timestamp = NOW()
        WHERE Algorithm_Name = p_Algorithm_Name;
    ELSE
        INSERT INTO erp.Logs (Algorithm_Name, Results, Timestamp)
        VALUES (p_Algorithm_Name, existing_results, NOW());
    END IF;

END; //

DELIMITER ;


CREATE VIEW ShowLogs AS
SELECT LogID, Algorithm_Name, Timestamp, Results
FROM Logs;


-- Execution of algorithms and inserting into logs
SET SQL_SAFE_UPDATES = 0;

-- Step 1: Declare a local variable to store the result
SET @results = erp.Inventory_Turnover_Ratio();

-- Step 2: Call the log procedure with the results
CALL erp.AddLog('Inventory Turnover Ratio', @results);

SET SQL_SAFE_UPDATES = 1;
















