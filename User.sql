DELIMITER //

CREATE PROCEDURE EditUserDetails(
    IN pUserID INT,
    IN pName VARCHAR(255),
    IN pMailID VARCHAR(255),
    IN pRole ENUM('Admin', 'Regular')
)
BEGIN
    UPDATE Users
    SET Name = pName, MailID = pMailID, Role = pRole
    WHERE UserID = pUserID;
END;//

DELIMITER ;