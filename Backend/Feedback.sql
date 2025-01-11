DELIMITER //

-- Add Feedback Procedure
CREATE PROCEDURE AddFeedback(
    IN p_ProductID INT,
    IN p_CustomerID INT,
    IN p_Comments VARCHAR(255),
    IN p_Ratings INT
)
BEGIN
    -- Insert new feedback into the FEEDBACK table
    INSERT INTO FEEDBACK (ProductID, CustomerID, Comments, Ratings, Timestamp)
    VALUES (p_ProductID, p_CustomerID, p_Comments, p_Ratings, NOW());

    IF LAST_INSERT_ID() > 0 THEN
        SELECT 'Feedback added successfully!' AS Message;
    ELSE
        SELECT 'Error: Unable to add feedback!' AS Message;
    END IF;
END;//

CREATE PROCEDURE EditFeedback(
    IN p_FeedbackID INT,
    IN p_Comments VARCHAR(255),
    IN p_Ratings INT
)
BEGIN
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
    IN pFeedbackID INT
)
BEGIN
    DECLARE pFeedbackText TEXT;
    DECLARE sentimentTone VARCHAR(50);
    DECLARE positiveKeywords TEXT DEFAULT 'good,excellent,amazing,awesome,positive,happy,satisfied';
    DECLARE negativeKeywords TEXT DEFAULT 'bad,poor,terrible,horrible,negative,angry,unsatisfied';
    DECLARE positiveCount INT DEFAULT 0;
    DECLARE negativeCount INT DEFAULT 0;
    DECLARE autoResponse TEXT;
    DECLARE keyword TEXT;
    DECLARE keywordList TEXT;

    -- Fetch the feedback text for the given FeedbackID
    SELECT Comments INTO pFeedbackText
    FROM Feedback
    WHERE FeedbackID = pFeedbackID;

    -- Check if feedback text was found
    IF pFeedbackText IS NOT NULL THEN

        -- Count Positive Keywords
        SET keywordList = positiveKeywords;
        WHILE LOCATE(',', keywordList) > 0 DO
            SET keyword = TRIM(SUBSTRING_INDEX(keywordList, ',', 1));
            SET positiveCount = positiveCount + 
                (LENGTH(LOWER(pFeedbackText)) - LENGTH(REPLACE(LOWER(pFeedbackText), LOWER(keyword), ''))) / LENGTH(keyword);
            SET keywordList = SUBSTRING(keywordList FROM LOCATE(',', keywordList) + 1);
        END WHILE;

        -- Last positive keyword
        SET keyword = TRIM(keywordList);
        IF keyword IS NOT NULL AND keyword != '' THEN
            SET positiveCount = positiveCount + 
                (LENGTH(LOWER(pFeedbackText)) - LENGTH(REPLACE(LOWER(pFeedbackText), LOWER(keyword), ''))) / LENGTH(keyword);
        END IF;

        -- Count Negative Keywords
        SET keywordList = negativeKeywords;
        WHILE LOCATE(',', keywordList) > 0 DO
            SET keyword = TRIM(SUBSTRING_INDEX(keywordList, ',', 1));
            SET negativeCount = negativeCount + 
                (LENGTH(LOWER(pFeedbackText)) - LENGTH(REPLACE(LOWER(pFeedbackText), LOWER(keyword), ''))) / LENGTH(keyword);
            SET keywordList = SUBSTRING(keywordList FROM LOCATE(',', keywordList) + 1);
        END WHILE;

        -- Last negative keyword
        SET keyword = TRIM(keywordList);
        IF keyword IS NOT NULL AND keyword != '' THEN
            SET negativeCount = negativeCount + 
                (LENGTH(LOWER(pFeedbackText)) - LENGTH(REPLACE(LOWER(pFeedbackText), LOWER(keyword), ''))) / LENGTH(keyword);
        END IF;

        -- Determine Sentiment Tone
        IF positiveCount > negativeCount THEN
            SET sentimentTone = 'Positive';
        ELSEIF negativeCount > positiveCount THEN
            SET sentimentTone = 'Negative';
        ELSE
            SET sentimentTone = 'Neutral';
        END IF;

        -- Generate Auto-Response Based on Sentiment
        IF sentimentTone = 'Positive' THEN
            SET autoResponse = 'Thank you for your positive feedback! We are thrilled you had a great experience.';
        ELSEIF sentimentTone = 'Negative' THEN
            SET autoResponse = 'We are sorry to hear about your experience. Your feedback is important, and we will work to improve.';
        ELSE
            SET autoResponse = 'Thank you for your feedback! We appreciate your input.';
        END IF;

        -- Update the Response for the Feedback Record
        UPDATE Feedback
        SET Response = autoResponse
        WHERE FeedbackID = pFeedbackID;

        -- Provide Feedback on Success or Failure
        IF ROW_COUNT() > 0 THEN
            SELECT CONCAT('Response added successfully! Detected sentiment: ', sentimentTone) AS Message;
        ELSE
            SELECT 'Error: Could not update the response!' AS Message;
        END IF;

    ELSE
        -- Feedback not found message
        SELECT 'Error: No feedback found with the given ID!' AS Message;
    END IF;
END //

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