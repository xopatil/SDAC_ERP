DELIMITER //

CREATE PROCEDURE ResetPassword(
    IN pMailID VARCHAR(255),
    IN pNewPassword VARCHAR(255),
    IN pConfirmPassword VARCHAR(255)
)
BEGIN
    -- Check if the user exists
    IF NOT EXISTS (SELECT 1 FROM Users WHERE MailID = pMailID) THEN
        SELECT 'User does not exist.' AS Message;
    -- Validate that the new password and confirm password match
    ELSEIF pNewPassword <> pConfirmPassword THEN
        SELECT 'Passwords do not match.' AS Message;
    ELSE
        -- Update the password with a hashed version
        UPDATE Users 
        SET Password = SHA2(pNewPassword, 256)
        WHERE MailID = pMailID;

        SELECT 'Password reset successful.' AS Message;
    END IF;
END;

//
DELIMITER ;
