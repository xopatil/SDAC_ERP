
DELIMITER //

CREATE PROCEDURE log_sales_trend()
BEGIN
    DECLARE trend_result JSON;
    DECLARE execution_time DATETIME;

    -- Capture the execution timestamp
    SET execution_time = CURRENT_TIMESTAMP;

    -- Call the function to compute the trends
    SET trend_result = analyze_sales_trend_generalized();

    -- Insert the result into the Logs table
    INSERT INTO Logs (Algorithm_Name, Timestamp, Results)
    VALUES ('Sales Trend Analysis', execution_time, trend_result);
END;
//

DELIMITER ;



CREATE VIEW ShowLogs AS
SELECT LogID, Algorithm_Name, Timestamp, Results
FROM Logs;
















