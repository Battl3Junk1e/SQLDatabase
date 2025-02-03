# **Functions**

## **fn_HASHPASSWORD**
This function takes a user's password (in plain text) and their unique salt, concatenates them,  
and then hashes the combined string using the `SHA2_512` algorithm.  
The function returns the resulting password hash as a `VARCHAR(128)`.
```SQL
CREATE FUNCTION fn_HASHPASSWORD
(
 @PASSWORD NVARCHAR(128),
 @SALT UNIQUEIDENTIFIER 

)
RETURNS VARCHAR(128)
AS
BEGIN
	DECLARE @hashedPassword VARCHAR(128)
	DECLARE @PwdAndSalt NVARCHAR(128)

	SET @PwdAndSalt = CONCAT(@PASSWORD, CAST(@SALT AS VARCHAR(36)))
	SET @hashedPassword = CONVERT(VARCHAR(128),HASHBYTES('SHA2_512', @PwdAndSalt),2)

	RETURN @hashedPassword
END
```