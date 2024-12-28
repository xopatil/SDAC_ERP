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

    -- Get the number of rows affected
    SET feedback_id = LAST_INSERT_ID();

    IF feedback_id > 0 THEN
        SELECT 'Feedback added successfully!' AS Message;
    ELSE
        SELECT 'Error: Unable to add feedback!' AS Message;
    END IF;
END;//

-- Update Feedback Procedure
CREATE PROCEDURE EditFeedback(
    IN p_FeedbackID INT,
    IN p_Comments VARCHAR(255),
    IN p_Ratings INT
)
BEGIN
    DECLARE rows_affected INT;

    -- Update the feedback record in the FEEDBACK table
    UPDATE FEEDBACK
    SET Comments = p_Comments,
        Ratings = p_Ratings,
        Timestamp = NOW()  -- Update the timestamp to current time
    WHERE FeedbackID = p_FeedbackID;

    -- Get the number of rows affected
    SET rows_affected = ROW_COUNT();

    IF rows_affected > 0 THEN
        SELECT 'Feedback updated successfully!' AS Message;
    ELSE
        SELECT 'Error: No feedback found with the given ID or no changes made!' AS Message;
    END IF;
END;//

-- Delete Feedback Procedure
CREATE PROCEDURE DeleteFeedback(
    IN p_FeedbackID INT
)
BEGIN
    DECLARE rows_affected INT;

    -- Delete the feedback record from the FEEDBACK table
    DELETE FROM FEEDBACK
    WHERE FeedbackID = p_FeedbackID;

    -- Get the number of rows affected
    SET rows_affected = ROW_COUNT();

    IF rows_affected > 0 THEN
        SELECT 'Feedback deleted successfully!' AS Message;
    ELSE
        SELECT 'Error: No feedback found with the given ID!' AS Message;
    END IF;
END;//

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

    -- Get the number of rows affected
    SET rows_affected = ROW_COUNT();

    IF rows_affected > 0 THEN
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