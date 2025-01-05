DELIMITER //

-- Add Feedback Procedure
CREATE PROCEDURE AddFeedback(
    IN p_ProductID INT,
    IN p_CustomerID INT,
    IN p_Comments VARCHAR(255),
    IN p_Ratings INT
)
BEGIN
    DECLARE feedback_id INT;

    -- Insert new feedback into the FEEDBACK table
    INSERT INTO FEEDBACK (ProductID, CustomerID, Comments, Ratings, Timestamp)
    VALUES (p_ProductID, p_CustomerID, p_Comments, p_Ratings, NOW());

    IF LAST_INSERT_ID() > 0 THEN
        SELECT 'Feedback added successfully!' AS Message;
    ELSE
        SELECT 'Error: Unable to add feedback!' AS Message;
    END IF;
END;//
DELIMITER //

CREATE PROCEDURE EditFeedback(
    IN p_FeedbackID INT,
    IN p_Comments VARCHAR(255),
    IN p_Ratings INT
)
BEGIN
    DECLARE rows_affected INT;

    -- Update the feedback record in the FEEDBACK table only if the value is provided
    UPDATE FEEDBACK
    SET 
        Comments = IFNULL(p_Comments, Comments),  -- Only update if new comment is provided
        Ratings = IFNULL(p_Ratings, Ratings),  -- Only update if new rating is provided
        Timestamp = NOW()  -- Always update the timestamp to current time
    WHERE FeedbackID = p_FeedbackID;

    IF ROW_COUNT() > 0 THEN
        SELECT 'Feedback updated successfully!' AS Message;
    ELSE
        SELECT 'Error: No feedback found with the given ID or no changes made!' AS Message;
    END IF;
END; //

CREATE PROCEDURE DeleteFeedback(
    IN p_FeedbackID INT
)
BEGIN
    DECLARE rows_affected INT;

    -- Delete the feedback record from the FEEDBACK table
    DELETE FROM FEEDBACK
    WHERE FeedbackID = p_FeedbackID;

    IF ROW_COUNT() > 0 THEN
        SELECT 'Feedback deleted successfully!' AS Message;
    ELSE
        SELECT 'Error: No feedback found with the given ID!' AS Message;
    END IF;
END; //
DELIMITER //
-- Respond to Feedback Procedure
CREATE PROCEDURE RespondToFeedback(
    IN pFeedbackID INT,
    IN pResponse TEXT
)
BEGIN
    DECLARE rows_affected INT;

    -- Update the response for the feedback record
    UPDATE Feedback
    SET Response = pResponse
    WHERE FeedbackID = pFeedbackID;

    IF ROW_COUNT() > 0 THEN
        SELECT 'Response added successfully!' AS Message;
    ELSE
        SELECT 'Error: No feedback found with the given ID!' AS Message;
    END IF;
END;//

CREATE PROCEDURE GenerateFeedbackInsights()
BEGIN
    SELECT ProductID, AVG(Ratings) AS AverageRating, COUNT(*) AS TotalFeedbacks
    FROM Feedback
    GROUP BY ProductID;
END;//

CREATE VIEW ShowFeedback AS
SELECT FeedbackID, ProductID, CustomerID, Comments, Ratings, Timestamp, Response
FROM Feedback;

DELIMITER ;