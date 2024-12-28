DELIMITER //

CREATE FUNCTION ResetPassword(
    pMailID VARCHAR(255),
    pNewPassword VARCHAR(255),
    pConfirmPassword VARCHAR(255)
) RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE resultMessage VARCHAR(255);

    -- Check if the user exists
    IF NOT EXISTS (SELECT 1 FROM Users WHERE MailID = pMailID) THEN
        SET resultMessage = 'User does not exist.';
    -- Validate that the new password and confirm password match
    ELSEIF pNewPassword <> pConfirmPassword THEN
        SET resultMessage = 'Passwords do not match.';
    ELSE
        -- Update the password with a hashed version
        UPDATE Users 
        SET Password = SHA2(pNewPassword, 256)
        WHERE MailID = pMailID;

        SET resultMessage = 'Password reset successful.';
    END IF;

    RETURN resultMessage;
END;

//
DELIMITER ;