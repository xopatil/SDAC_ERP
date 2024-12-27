DELIMITER //

CREATE PROCEDURE add_feedback(
    IN p_ProductID INT,
    IN p_CustomerID INT,
    IN p_Comments VARCHAR(255),
    IN p_Ratings INT
)
BEGIN
    -- Insert new feedback into the FEEDBACK table
    INSERT INTO FEEDBACK (ProductID, CustomerID, Comments, Ratings, Timestamp)
    VALUES (p_ProductID, p_CustomerID, p_Comments, p_Ratings, NOW());
END;//

CREATE PROCEDURE update_feedback(
    IN p_FeedbackID INT,
    IN p_Comments VARCHAR(255),
    IN p_Ratings INT
)
BEGIN
    -- Update the feedback record in the FEEDBACK table
    UPDATE FEEDBACK
    SET Comments = p_Comments,
        Ratings = p_Ratings,
        Timestamp = NOW()  -- Update the timestamp to current time
    WHERE FeedbackID = p_FeedbackID;
END;//

CREATE PROCEDURE delete_feedback(
    IN p_FeedbackID INT
)
BEGIN
    -- Delete the feedback record from the FEEDBACK table
    DELETE FROM FEEDBACK
    WHERE FeedbackID = p_FeedbackID;
END;//

CREATE PROCEDURE ReviewFeedback()
BEGIN
    SELECT FeedbackID, ProductID, CustomerID, Comments, Ratings, Timestamp, Response FROM Feedback;
END;//

CREATE PROCEDURE RespondToFeedback(
    IN pFeedbackID INT,
    IN pResponse TEXT
)
BEGIN
    UPDATE Feedback
    SET Response = pResponse
    WHERE FeedbackID = pFeedbackID;
END;//

CREATE PROCEDURE GenerateFeedbackInsights()
BEGIN
    SELECT ProductID, AVG(Ratings) AS AverageRating, COUNT(*) AS TotalFeedbacks
    FROM Feedback
    GROUP BY ProductID;
END;//

DELIMITER ;