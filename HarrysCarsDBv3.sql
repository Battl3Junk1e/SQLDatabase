SET NOCOUNT ON

USE master
GO

IF EXISTS (SELECT * FROM sysdatabases WHERE name = 'HarrysCarsDB')
	BEGIN
	ALTER DATABASE HarrysCarsDB
	SET SINGLE_USER
	WITH ROLLBACK IMMEDIATE

	DROP DATABASE HarrysCarsDB
	PRINT 'Database dropped successfully'
	END
	ELSE 
	BEGIN
	PRINT 'Database does not exist'
END
GO

CREATE DATABASE HarrysCarsDB
GO

USE HarrysCarsDB

--Activate email settings
EXEC sp_configure 'show advanced options', 1
RECONFIGURE
EXEC sp_configure 'Database Mail XPs', 1
RECONFIGURE
/* --Email profile setup
EXEC msdb.dbo.sysmail_add_account_sp
@account_name = 'Server testing mail',
@description = 'testmail',
@email_address = 'YOURMAIL',
@display_name = 'SQL SERVER TEST',
@mailserver_name = 'smtp.gmail.com',
@mailserver_type = 'SMTP',
@port = 587,
@username = 'YOUREMAIL',
@password = 'YOURPASSWORD',
@enable_ssl = 1
*/



CREATE TABLE Users
(
	UserID INT PRIMARY KEY IDENTITY(1,1),
	Email NVARCHAR(255) UNIQUE NOT NULL,
	PwdHash VARCHAR(128) NOT NULL,
	Salt UNIQUEIDENTIFIER DEFAULT NEWID(),
	FirstName NVARCHAR(255) NOT NULL,
	LastName NVARCHAR(255) NOT NULL,
	StreetName NVARCHAR(255) NOT NULL,
	StreetNumber SMALLINT NOT NULL,
	PostalCode VARCHAR(30) NOT NULL,
	City NVARCHAR(255) NOT NULL,
	Country NVARCHAR(60) NOT NULL,
	UserType CHAR(1) CHECK (UserType IN ('A', 'C')) DEFAULT 'C' NOT NULL,
	IsActive BIT DEFAULT 1
)
GO

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




GO
CREATE PROCEDURE AddNewUser 
    @Email NVARCHAR(255),
    @PwdHash NVARCHAR(128),
    @FirstName NVARCHAR(255),
    @LastName NVARCHAR(255),
    @StreetName NVARCHAR(255),
    @StreetNumber SMALLINT,
    @PostalCode VARCHAR(30),
    @City NVARCHAR(255),
    @Country NVARCHAR(60),
    @UserType CHAR(1),
	@IsActive BIT
AS
BEGIN
	BEGIN TRY
	DECLARE @Salt UNIQUEIDENTIFIER = NEWID()
	INSERT INTO Users ( Email, PwdHash, Salt, FirstName, LastName, StreetName, StreetNumber, PostalCode, City, Country, UserType, IsActive)
	VALUES (@Email, DBO.fn_HASHPASSWORD(@PwdHash, @Salt),@Salt, @FirstName, @LastName, @StreetName, @StreetNumber, @PostalCode, @City, @Country, @UserType, @IsActive)
		EXEC msdb.dbo.sp_send_dbmail
		@profile_name = 'SQL SERVER MAIL',
		@recipients = @Email,
		@subject = 'VERIFY your account',
		@body = '0',
		@body_format = 'TEXT'
	END TRY
	BEGIN CATCH 
	DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE()
	DECLARE @ErrorSeverity INT = ERROR_SEVERITY()
    DECLARE @ErrorState INT = ERROR_STATE()
    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
	END CATCH
END
GO

CREATE PROCEDURE DeleteUser 
	@userid INT
AS
	 DELETE FROM Users
	 WHERE UserID = @userid
GO
CREATE PROCEDURE DisableUser 
	@userid INT
AS
	UPDATE Users
	SET IsActive = 0
	WHERE UserID = @userid

GO
CREATE PROCEDURE ForgotPassword 
	@userid INT = NULL, 
	@UserEmail NVARCHAR(255)= NULL
AS
BEGIN
	BEGIN TRY
		DECLARE @currentuseremail NVARCHAR(255)
		DECLARE @Resetcode NVARCHAR(50)
		SELECT @Resetcode = CONVERT(NVARCHAR(50),NEWID())
		CREATE TABLE ##resetpass
		(
		resetcode NVARCHAR(50),
		Validfrom DATETIME,
		Validto DATETIME
		)
		INSERT INTO ##resetpass (resetcode, Validfrom, Validto)
		VALUES(@Resetcode,GETDATE(),DATEADD(DAY,1,GETDATE()))
		IF @userid IS NOT NULL
			BEGIN

			SELECT @currentuseremail = email
			FROM Users
			WHERE UserID = @userid

			UPDATE Users
			SET PwdHash = @Resetcode
			WHERE UserID = @userid
		END
		ELSE IF @UserEmail IS NOT NULL
			BEGIN

			SELECT @currentuseremail = email
			FROM Users
			WHERE @UserEmail = Email

			UPDATE Users
			SET
			PwdHash = 'RESETCODE'
			WHERE @UserEmail = Email
		END
			EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'SQL SERVER MAIL',
			@recipients = @currentuseremail,
			@subject = 'Password reset',
			@body = 'Password reset token: ',
			@body_format = 'TEXT'
		PRINT ('An email has been sent to ' + @currentuseremail + ' with instructions on how to reset their password' )
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE()
		DECLARE @ErrorSeverity INT = ERROR_SEVERITY()
		DECLARE @ErrorState INT = ERROR_STATE()
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
	END CATCH
END
	/*
	WAITFOR DELAY '24:00:00'
	DROP ##resetpass
	*/
GO
CREATE PROCEDURE trylogin 
	@email NVARCHAR(255),
	@password NVARCHAR(128),
	@ipaddress NVARCHAR(128)
AS
BEGIN
	IF OBJECT_ID('tempdb..##activecheck') IS NULL
	BEGIN
		CREATE TABLE ##activecheck (email NVARCHAR(255),failedattempt TINYINT,date DATETIME DEFAULT GETDATE())
	END

	BEGIN TRY
		
		DECLARE @useremail NVARCHAR(255)
		DECLARE @userpassword VARCHAR(128)
		DECLARE @usersalt UNIQUEIDENTIFIER
		DECLARE @userip NVARCHAR(128)
		DECLARE @validlogin BIT = 0
		DECLARE @userid INT
		DECLARE @isactive BIT
		SELECT @userpassword = u.PwdHash, @useremail = u.Email, @userip = sl.IPAddress, @usersalt = u.Salt, @userid = u.UserID, @isactive = u.IsActive
		FROM Users u
		LEFT JOIN SysLog sl ON u.UserID = sl.UserID
		WHERE u.Email = @email AND sl.IPAddress = @ipaddress

		SELECT @validlogin = CASE WHEN @userpassword = dbo.fn_HASHPASSWORD(@password,@usersalt) THEN 1 ELSE 0
		END

		IF @validlogin = 1 AND @isactive = 1
		BEGIN
			PRINT('Valid Login')
			INSERT INTO SysLog(UserID, IPAddress, Email, DateTime, IsAuthenticated)
			VALUES(@userid,@ipaddress,@email,GETDATE(),1)
			SELECT *
			FROM Users u
			LEFT JOIN SysLog sl ON u.UserID = sl.UserID
			WHERE u.Email = @email
			RETURN
		END
		ELSE 
			PRINT('Not a valid login or user is locked out')
			INSERT INTO SysLog(UserID, IPAddress, Email, DateTime, IsAuthenticated)
			VALUES(@userid,@ipaddress,@email,GETDATE(),0)
			INSERT INTO ##activecheck(email, failedattempt)
			VALUES(@email, 1)
			DECLARE @failedattempts INT
			SELECT @failedattempts = COUNT(*)
			FROM ##activecheck
			WHERE @email = Email
			AND date >= DATEADD(MINUTE,-15,GETDATE())
		IF @failedattempts = 3
		BEGIN
			UPDATE Users
			SET IsActive = 0
			WHERE Email = @email
			PRINT('USER IS LOCKED OUT FOR 15MIN')
		END
		ELSE
		BEGIN
			UPDATE Users
			SET IsActive = 1
			WHERE Email = @email
		END
	END TRY
	BEGIN CATCH
		PRINT 'Error occurred during login process'
		DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE()
		DECLARE @ErrorSeverity INT = ERROR_SEVERITY()
		DECLARE @ErrorState INT = ERROR_STATE()
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
	END CATCH
END
GO

CREATE INDEX IX_LastNameFirstName 
ON Users (LastName, FirstName)
CREATE INDEX IX_PostalCodeCity
ON Users (PostalCode, City)

GO



INSERT INTO Users (Email, PwdHash, FirstName, LastName, StreetName, StreetNumber, PostalCode, City, Country, UserType)
VALUES
('john.doe@example.com', 'b5c0b187fe309af0f4d35982fd961d7e', 'John', 'Doe', 'Elm St', '10', '12345', 'New York', 'USA', 'A'),
('jane.smith@example.com', 'e99a18c428cb38d5f260853678922e03', 'Jane', 'Smith', 'Oak Ave', '15', '54321', 'Los Angeles', 'USA', 'C'),
('alice.johnson@example.com', '3f79bb7b435b05321651daefd374cd21', 'Alice', 'Johnson', 'Pine Blvd', '20', '67890', 'Chicago', 'USA', 'A'),
('bob.white@example.com', 'aab3238922bcc25a6f606eb525ffdc56', 'Bob', 'White', 'Maple Rd', '25', '23456', 'Houston', 'USA', 'C'),
('charlie.brown@example.com', '9bf31c7ff062936a96d3c8bd1f8f2ff3', 'Charlie', 'Brown', 'Birch Ln', '30', '34567', 'San Francisco', 'USA', 'A'),
('alice.williams@yahoo.com', 'c74d97b01eae257e44aa9d5bade97baf', 'Alice', 'Williams', 'Pine Road', '12', '12345', 'Chicago', 'USA', 'C'),
('bob.johnson@msn.com', '70efdf2ec9b086079795c442636b55fb', 'Bob', 'Johnson', 'Maple Avenue', '30', '98765', 'New York', 'USA', 'C'),
('clara.evans@aol.com', '6f4922f45568161a8cdf4ad2299f6d23', 'Clara', 'Evans', 'Birch Boulevard', '18', '54321', 'Austin', 'USA', 'C'),
('david.brown@outlook.com', 'd1fe173d08e959397adf34b1d77e88d7', 'David', 'Brown', 'Cedar Lane', '45', '11223', 'Miami', 'USA', 'C'),
('emily.clark@hotmail.com', 'c20ad4d76fe97759aa27a0c99bff6710','Emily', 'Clark', 'Willow Way', '27', '65432', 'Seattle', 'USA', 'C'),
('frank.martin@gmail.com', 'ec8956637a99787bd197eacd77acce5e','Frank', 'Martin', 'Chestnut Court', '31', '45678', 'Boston', 'USA', 'C'),
('george.white@protonmail.com', '45c48cce2e2d7fbdea1afc51c7c6ad26', 'George', 'White', 'Poplar Drive', '38', '98789', 'Denver', 'USA', 'C'),
('hannah.thomas@yahoo.com', '6512bd43d9caa6e02c990b0a82652dca', 'Hannah', 'Thomas', 'Aspen Way', '22', '21345', 'Atlanta', 'USA', 'C'),
('isabella.moore@msn.com', 'a87ff679a2f3e71d9181a67b7542122c', 'Isabella', 'Moore', 'Oakwood Avenue', '19', '34567', 'Phoenix', 'USA', 'C'),
('sophie.turner@gmail.com', 'e4da3b7fbbce2345d7772b0674a318d5', 'Sophie', 'Turner', 'Maple Lane', '28', '98745', 'London', 'UK', 'C'),
('li.wei@outlook.com', '1679091c5a880faf6fb5e6087eb1b2dc', 'Li', 'Wei', 'Cherry Street', '35', '100010', 'Beijing', 'China', 'C'),
('miguel.garcia@yahoo.com', '8f14e45fceea167a5a36dedd4bea2543', 'Miguel', 'Garcia', 'Palm Avenue', '24', '28013', 'Madrid', 'Spain', 'C'),
('emma.johnson@msn.com', 'c9f0f895fb98ab9159f51fd0297e236d', 'Emma', 'Johnson', 'Cypress Drive', '29', 'T5K0L4', 'Toronto', 'Canada', 'C'),
('noah.davies@protonmail.com', '45c48cce2e2d7fbdea1afc51c7c6ad26', 'Noah', 'Davies', 'Willow Street', '33', '3000', 'Melbourne', 'Australia', 'C'),
('amelie.duval@orange.fr', 'd3d9446802a44259755d38e6d163e820', 'Amelie', 'Duval', 'Hawthorn Road', '27', '75001', 'Paris', 'France', 'C'),
('lukas.müller@yahoo.de', '6512bd43d9caa6e02c990b0a82652dca', 'Lukas', 'Müller', 'Beech Lane', '21', '10115', 'Berlin', 'Germany', 'C'),
('hiroshi.tanaka@gmail.com', 'aab3238922bcc25a6f606eb525ffdc56', 'Hiroshi', 'Tanaka', 'Cedar Path', '32', '150-0001', 'Tokyo', 'Japan', 'C'),
('fatima.al-farsi@msn.com', '9bf31c7ff062936a96d3c8bd1f8f2ff3', 'Fatima', 'Al-Farsi', 'Palm Grove', '26', '113', 'Muscat', 'Oman', 'C'),
('peter.nielsen@gmail.com', '70efdf2ec9b086079795c442636b55fb', 'Peter', 'Nielsen', 'Birch Close', '40', '8000', 'Aarhus', 'Denmark', 'C')

GO
CREATE TABLE SysLog
(
	SysLogID INT PRIMARY KEY IDENTITY(1,1),
	UserID INT,
	FOREIGN KEY (UserID) REFERENCES Users(UserID)
	ON DELETE SET NULL,
	IPAddress NVARCHAR(128),
	Email NVARCHAR(255) NOT NULL,
	DateTime DATETIME NOT NULL,
	IsAuthenticated BIT NOT NULL
)
INSERT INTO SysLog (UserID, IPAddress, Email, DateTime, IsAuthenticated)
VALUES
(1, '192.168.0.1', 'john.doe@example.com', '2024-05-12 13:20:00', 1),
(1, '192.168.0.1', 'john.doe@example.com', '2024-03-01 08:45:30', 1),
(1, '192.168.0.1', 'john.doe@example.com', '2024-04-19 09:53:42', 1),
(1, '192.168.0.1', 'john.doe@example.com', '2024-08-07 15:22:28', 0),
(2, '192.168.0.2', 'jane.smith@example.com', '2024-07-21 14:55:17', 1),
(3, '192.168.0.3', 'alice.johnson@example.com', '2024-09-05 10:35:25', 1),
(4, '168.192.168.1', 'bob.white@example.com', '2024-04-15 16:50:42', 1),
(5, '192.168.0.4', 'charlie.brown@example.com', '2024-10-30 11:27:11', 1),
(6, '168.192.168.2', 'alice.williams@yahoo.com', '2024-06-03 09:12:33', 1),
(7, '192.168.0.5', 'bob.johnson@msn.com', '2024-12-09 18:11:58', 1),
(8, '168.192.168.3', 'clara.evans@aol.com', '2024-01-15 07:48:11', 1),
(9, '192.168.0.6', 'david.brown@outlook.com', '2024-11-02 14:26:59', 1),
(10, '168.192.168.4', 'emily.clark@hotmail.com', '2024-05-19 13:44:52', 1),
(11, '192.168.0.7', 'frank.martin@gmail.com', '2024-08-27 16:15:06', 1),
(12, '168.192.168.5', 'george.white@protonmail.com', '2024-02-23 22:51:21', 1),
(13, '192.168.0.8', 'hannah.thomas@yahoo.com', '2024-07-29 17:09:45', 1),
(14, '168.192.168.6', 'isabella.moore@msn.com', '2024-09-16 20:13:59', 1),
(15, '192.168.0.9', 'sophie.turner@gmail.com', '2024-03-08 12:42:37', 1),
(16, '168.192.168.7', 'li.wei@outlook.com', '2024-06-18 11:54:11', 1),
(17, '192.168.0.10', 'miguel.garcia@yahoo.com', '2024-10-01 09:22:48', 1),
(18, '168.192.168.8', 'emma.johnson@msn.com', '2024-12-13 06:37:15', 1),
(19, '192.168.0.11', 'noah.davies@protonmail.com', '2024-02-01 16:04:29', 1),
(20, '168.192.168.9', 'amelie.duval@orange.fr', '2024-04-10 14:39:08', 1),
(21, '192.168.0.12', 'lukas.müller@yahoo.de', '2024-11-23 10:01:30', 1),
(22, '168.192.168.10', 'hiroshi.tanaka@gmail.com', '2024-03-17 18:43:19', 1),
(23, '192.168.0.13', 'fatima.al-farsi@msn.com', '2024-07-09 20:25:54', 1),
(NULL, '168.192.168.11', 'no.authenticated.email@domain.com', '2024-09-25 17:34:51', 0),
(NULL, '192.168.0.14', 'no.authenticated.email@domain.com', '2024-10-12 14:22:43', 0),
(NULL, '168.192.168.12', 'no.authenticated.email@domain.com', '2024-12-06 13:17:55', 0),
(2, '192.168.0.2', 'jane.smith@example.com', '2024-06-17 12:08:14', 1),
(3, '192.168.0.3', 'alice.johnson@example.com', '2024-02-03 11:16:56', 1),
(4, '168.192.168.1', 'bob.white@example.com', '2024-10-28 14:42:33', 1),
(5, '192.168.0.4', 'charlie.brown@example.com', '2024-05-23 07:59:07', 1),
(6, '168.192.168.2', 'alice.williams@yahoo.com', '2024-03-14 17:11:53', 1),
(7, '192.168.0.5', 'bob.johnson@msn.com', '2024-07-01 16:29:22', 1),
(8, '168.192.168.3', 'clara.evans@aol.com', '2024-09-09 09:44:56', 1),
(9, '192.168.0.6', 'david.brown@outlook.com', '2024-04-25 13:58:39', 1),
(10, '168.192.168.4', 'emily.clark@hotmail.com', '2024-01-22 20:02:44', 1),
(11, '192.168.0.7', 'frank.martin@gmail.com', '2024-05-11 10:21:55', 1),
(12, '168.192.168.5', 'george.white@protonmail.com', '2024-08-18 13:34:25', 1),
(13, '192.168.0.8', 'hannah.thomas@yahoo.com', '2024-07-06 06:56:12', 1),
(14, '168.192.168.6', 'isabella.moore@msn.com', '2024-09-20 19:39:29', 1),
(15, '192.168.0.9', 'sophie.turner@gmail.com', '2024-11-16 21:17:40', 1),
(16, '168.192.168.7', 'li.wei@outlook.com', '2024-05-02 16:44:57', 1),
(17, '192.168.0.10', 'miguel.garcia@yahoo.com', '2024-06-30 07:22:13', 1),
(18, '168.192.168.8', 'emma.johnson@msn.com', '2024-04-05 15:59:44', 1),
(19, '192.168.0.11', 'noah.davies@protonmail.com', '2024-10-23 08:14:35', 1),
(20, '168.192.168.9', 'amelie.duval@orange.fr', '2024-07-17 12:50:59', 1),
(21, '192.168.0.12', 'lukas.müller@yahoo.de', '2024-08-01 14:04:39', 1),
(22, '168.192.168.10', 'hiroshi.tanaka@gmail.com', '2024-02-13 22:47:26', 1),
(23, '192.168.0.13', 'fatima.al-farsi@msn.com', '2024-12-03 13:11:08', 1)



CREATE INDEX IXUserIDSysLog
ON SysLog(UserID)
CREATE INDEX IXDateTimeSysLog
ON SysLog(DateTime)

GO

CREATE PROCEDURE LastNonAuthLogon
	AS
		BEGIN
		SELECT TOP(1) *
		FROM SysLog
		WHERE IsAuthenticated = 0
		ORDER BY SYSLOG.DateTime DESC
	END
GO


CREATE TABLE PaymentMethods
(
	PaymentID INT PRIMARY KEY IDENTITY(1,1),
	PaymentType VARCHAR(25)
)
INSERT INTO PaymentMethods (PaymentType)
VALUES
('Credit Card'),
('Debit Card'),
('PayPal'),
('Bank Transfer'),
('Cash')

CREATE TABLE DeliveryOptions
(
	DeliveryID INT PRIMARY KEY IDENTITY(1,1),
	DeliveryPrice SMALLINT,
	DeliveryType VARCHAR(100)
)
INSERT INTO DeliveryOptions (DeliveryPrice, DeliveryType)
VALUES
(10, 'Standard Shipping'),
(20, 'Express Shipping'),
(50, 'Overnight Shipping')

CREATE TABLE Orders
(
	OrderID INT PRIMARY KEY IDENTITY(1,1),
	UserID INT,
	TotalAmount INT,
	DeliveryOption INT,
	OrderDate DATETIME NOT NULL,
	Fullfillment BIT NOT NULL,
	PaymentMethod INT NOT NULL,
	FOREIGN KEY (UserID) REFERENCES Users(UserID)
	ON DELETE SET NULL,
	FOREIGN KEY (DeliveryOption) REFERENCES DeliveryOptions(DeliveryID),
	FOREIGN KEY (PaymentMethod) REFERENCES PaymentMethods(PaymentID)
)
INSERT INTO Orders (UserID, TotalAmount, DeliveryOption, OrderDate, Fullfillment, PaymentMethod)
VALUES
(3, 1270.5, 1, '2024-06-23', 1, 1),
(7, 5833.7, 1, '2024-12-31', 1, 1),
(2, 9470.8, 1, '2024-09-18', 1, 3),
(20, 10787.1, 2, '2024-05-20', 1, 5),
(14, 11390.5, 1, '2024-07-13', 1, 2),
(17, 1064.6, 2, '2024-02-23', 1, 3),
(12, 17181.0, 1, '2024-04-26', 1, 1),
(1, 518.8, 1, '2024-03-09', 1, 5),
(6, 11950.4, 1, '2024-08-17', 0, 5),
(21, 1738.9, 3, '2024-11-15', 1, 1),
(14, 5744.2, 2, '2024-10-25', 1, 5),
(18, 3740.8, 3, '2024-10-01', 1, 4),
(7, 10681.7, 3, '2025-01-06', 1, 2),
(16, 13008.9, 2, '2024-07-04', 1, 1),
(5, 7049.5, 1, '2024-02-25', 1, 1),
(10, 7097.9, 1, '2024-11-20', 1, 2),
(21, 11373.7, 2, '2024-04-29', 1, 5),
(2, 4788.5, 1, '2024-10-23', 1, 4),
(16, 8525.5, 2, '2024-04-30', 1, 4),
(3, 1930.5, 3, '2024-12-23', 1, 3),
(24, 7748.9, 3, '2024-08-30', 1, 4),
(24, 17480.6, 3, '2024-05-15', 1, 3),
(24, 15886.2, 3, '2024-04-18', 1, 5),
(13, 17899.9, 2, '2024-02-10', 1, 5),
(6, 9901.9, 1, '2024-05-29', 1, 5),
(5, 2285.1, 1, '2024-11-30', 1, 5),
(8, 5697.1, 2, '2024-09-02', 0, 1),
(8, 501.7, 2, '2024-02-26', 1, 4),
(22, 7683.4, 3, '2024-11-18', 1, 3),
(12, 13983.0, 3, '2024-05-19', 1, 5),
(24, 6445.5, 2, '2024-12-17', 1, 2),
(1, 5666.4, 2, '2024-04-01', 1, 4),
(3, 19845.9, 3, '2024-09-13', 1, 5),
(16, 4940.8, 1, '2024-05-24', 1, 5),
(23, 16378.5, 2, '2024-11-19', 1, 4),
(13, 11838.5, 3, '2024-07-15', 1, 4),
(11, 16379.9, 2, '2024-11-23', 1, 4),
(21, 8413.6, 3, '2024-11-13', 1, 4),
(10, 10762.6, 2, '2024-07-08', 1, 1),
(21, 17586.0, 2, '2024-09-19', 1, 2),
(19, 19256.8, 3, '2024-01-31', 1, 5),
(19, 18137.1, 1, '2024-12-22', 1, 4),
(7, 11750.6, 1, '2024-03-21', 1, 2),
(2, 17909.9, 1, '2024-03-04', 1, 4),
(19, 9499.2, 3, '2024-06-29', 1, 4),
(19, 693.2, 1, '2024-08-06', 1, 2),
(21, 13351.2, 2, '2024-07-06', 1, 5),
(14, 14306.1, 3, '2024-11-27', 1, 4),
(23, 15438.2, 2, '2024-11-05', 1, 2),
(15, 1401.4, 3, '2024-10-29', 0, 1),
(7, 8382.9, 1, '2024-01-29', 1, 3),
(3, 16919.1, 1, '2024-02-22', 1, 5),
(4, 7315.9, 2, '2024-10-01', 1, 5),
(19, 2634.1, 2, '2024-12-31', 1, 2),
(20, 16382.3, 1, '2024-11-06', 1, 3),
(11, 7123.6, 1, '2024-10-22', 1, 4)

CREATE INDEX IX_OrderDateOrders 
ON Orders(OrderDate)

CREATE TABLE Warehouse
(
	WarehouseID INT PRIMARY KEY IDENTITY(1,1),
	WarehouseName NVARCHAR(50) NOT NULL,
	StreetName NVARCHAR(255) NOT NULL,
	StreetNumber INT NOT NULL,
	Postalcode VARCHAR(30) NOT NULL,
	City NVARCHAR(255),
	Country NVARCHAR(255),
	Phone INT NOT NULL,
	Email NVARCHAR(100)
)
INSERT INTO Warehouse (WarehouseName, StreetName, StreetNumber, Postalcode, City, Country, Phone, Email)
VALUES
('Central Warehouse', 'Industrial Avenue', 25, '12345', 'Los Angeles', 'USA', 1234567890, 'central.warehouse@example.com'),
('East Storage Facility', 'Harbor Road', 12, '54321', 'New York', 'USA', 1876543210, 'east.storage@example.com'),
('Global Distribution Center', 'Logistics Lane', 7, '98765', 'Berlin', 'Germany', 1239876543, 'global.dc@example.com')

CREATE TABLE OrderLines
(
	OrderLineID INT PRIMARY KEY IDENTITY(1,1),
	OrderID INT NOT NULL,
	ProductID INT NOT NULL,
	ProductName NVARCHAR(255) NOT NULL,
	Quantity INT NOT NULL,
	UnitPrice DECIMAL(10, 2) NOT NULL,
	ShippedDate DATE,
	WarehouseID INT,
	Notes NVARCHAR(MAX)
	FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
	FOREIGN KEY (WarehouseID) REFERENCES Warehouse(WarehouseID)
)
CREATE INDEX IXOrderIDOrderLines 
ON OrderLines(OrderID)
CREATE INDEX IXProductIDOrderLines 
ON OrderLines(ProductID)


CREATE TABLE Suppliers
(
	SupplierID INT PRIMARY KEY IDENTITY(1,1),
	OrgName NVARCHAR(255) NOT NULL,
	Country NVARCHAR(255)
)
INSERT INTO Suppliers (OrgName, Country)
VALUES
    ('Global Trade Co.', 'United States'),
    ('Euro Supply Ltd.', 'Germany'),
    ('Pacific Imports Inc.', 'Japan'),
    ('Continental Resources', 'Canada'),
    ('Horizon Wholesale', 'Australia')

CREATE TABLE Colors
(
	ColorID INT PRIMARY KEY IDENTITY(1,1),
	ColorName VARCHAR(15)
)
INSERT INTO Colors (ColorName)
VALUES
    ('Red'),
    ('Blue'),
    ('Green'),
    ('Yellow'),
    ('Orange'),
    ('Purple'),
    ('Pink'),
    ('Brown'),
    ('Black'),
    ('White'),
    ('Gray'),
    ('Cyan'),
    ('Magenta'),
    ('Teal'),
    ('Lavender'),
    ('Maroon'),
    ('Navy'),
    ('Olive'),
    ('Gold'),
    ('Silver')

CREATE TABLE Products
(
	ProductID INT PRIMARY KEY IDENTITY(1,1),
	ProductName NVARCHAR(255) NOT NULL,
	SupplierID INT NOT NULL,
	Color INT,
	ProductWeight INT,
	UnitPrice DECIMAL (10, 2) NOT NULL,
	TaxAmt TINYINT,
	IsActive BIT NOT NULL,
	CreatedDate DATETIME NOT NULL,
	LastEdited DATETIME NOT NULL,
	FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID),
	FOREIGN KEY (Color) REFERENCES Colors(ColorID)
)

INSERT INTO Products (ProductName, SupplierID, Color, ProductWeight, UnitPrice, TaxAmt, IsActive, CreatedDate, LastEdited)
VALUES
    ('Wireless Mouse', 1, 3, 12, 15.50, 5, 1, '2025-01-17', '2025-01-17'),
    ('Gaming Keyboard', 2, 7, 8, 25.00, 8, 1, '2025-01-17', '2025-01-17'),
    ('Noise Cancelling Headphones', 3, 15, 20, 89.99, 10, 1, '2025-01-17', '2025-01-17'),
    ('Portable Charger', 4, 10, 5, 50.00, 5, 1, '2025-01-17', '2025-01-17'),
    ('Smartphone Case', 5, 2, 25, 19.99, 4, 1, '2025-01-17', '2025-01-17'),
    ('Bluetooth Speaker', 1, 8, 18, 30.49, 6, 1, '2025-01-17', '2025-01-17'),
    ('LED Desk Lamp', 2, 19, 7, 19.99, 3, 1, '2025-01-17', '2025-01-17'),
    ('USB-C Cable', 3, 4, 16, 9.99, 1, 1, '2025-01-17', '2025-01-17'),
    ('Laptop Cooling Pad', 4, 13, 9, 22.50, 7, 1, '2025-01-17', '2025-01-17'),
    ('Adjustable Monitor Stand', 5, 6, 11, 27.89, 6, 1, '2025-01-17', '2025-01-17'),
    ('Wireless Earbuds', 1, 20, 10, 15.75, 4, 1, '2025-01-17', '2025-01-17'),
    ('Fitness Tracker', 2, 17, 14, 35.25, 6, 1, '2025-01-17', '2025-01-17'),
    ('Gaming Mouse Pad', 3, 5, 21, 12.99, 2, 1, '2025-01-17', '2025-01-17'),
    ('Smart Light Bulb', 4, 9, 12, 49.99, 8, 1, '2025-01-17', '2025-01-17'),
    ('Ergonomic Office Chair', 5, 12, 22, 199.99, 15, 1, '2025-01-17', '2025-01-17'),
    ('Adjustable Standing Desk', 1, 14, 35, 329.99, 20, 0, '2025-01-17', '2025-01-17'),
    ('Action Camera', 2, 3, 18, 199.00, 10, 1, '2025-01-17', '2025-01-17'),
    ('Electric Scooter', 3, 7, 55, 499.99, 25, 1, '2025-01-17', '2025-01-17'),
    ('Waterproof Phone Pouch', 4, 5, 1, 9.99, 1, 1, '2025-01-17', '2025-01-17'),
    ('Camping Lantern', 5, 18, 12, 29.99, 3, 1, '2025-01-17', '2025-01-17'),
    ('Smart Coffee Maker', 1, 11, 20, 129.99, 8, 1, '2025-01-17', '2025-01-17'),
    ('Outdoor Security Camera', 2, 8, 28, 89.99, 6, 1, '2025-01-17', '2025-01-17'),
    ('Robot Vacuum', 3, 6, 35, 299.99, 18, 1, '2025-01-17', '2025-01-17'),
    ('Instant Photo Printer', 4, 13, 10, 99.99, 5, 1, '2025-01-17', '2025-01-17'),
    ('Electric Kettle', 5, 2, 15, 39.99, 7, 1, '2025-01-17', '2025-01-17'),
	('Wireless Charger', 1, 5, 12, 25.99, 5, 1, '2025-01-17', '2025-01-17'),
    ('4K HDMI Cable', 2, 8, 3, 15.49, 3, 1, '2025-01-17', '2025-01-17'),
    ('Cordless Drill', 3, 15, 25, 79.99, 10, 1, '2025-01-17', '2025-01-17'),
    ('Electric Toothbrush', 4, 3, 2, 49.99, 8, 1, '2025-01-17', '2025-01-17'),
    ('Smart Thermostat', 5, 18, 1, 149.00, 6, 1, '2025-01-17', '2025-01-17'),
    ('Mini Projector', 1, 2, 5, 199.99, 12, 1, '2025-01-17', '2025-01-17'),
    ('Noise-Isolating Earbuds', 2, 10, 0.5, 29.99, 4, 1, '2025-01-17', '2025-01-17'),
    ('Digital Picture Frame', 3, 6, 3, 89.50, 9, 1, '2025-01-17', '2025-01-17'),
    ('Wireless Security System', 4, 12, 15, 299.00, 15, 1, '2025-01-17', '2025-01-17'),
    ('Portable Air Conditioner', 5, 14, 55, 399.99, 20, 0, '2025-01-17', '2025-01-17'),
    ('Dash Cam', 1, 7, 1.2, 99.99, 6, 1, '2025-01-17', '2025-01-17'),
    ('Infrared Thermometer', 2, 9, 0.8, 24.99, 5, 1, '2025-01-17', '2025-01-17'),
    ('Self-Cleaning Water Bottle', 3, 4, 1, 45.00, 3, 1, '2025-01-17', '2025-01-17'),
    ('Cordless Hair Clipper', 4, 19, 2, 69.99, 7, 1, '2025-01-17', '2025-01-17'),
    ('Electric Scooter Helmet', 5, 1, 1.5, 59.99, 4, 1, '2025-01-17', '2025-01-17'),
    ('Car Vacuum Cleaner', 1, 11, 2.8, 39.49, 6, 1, '2025-01-17', '2025-01-17'),
    ('UV Phone Sanitizer', 2, 13, 1, 29.99, 3, 1, '2025-01-17', '2025-01-17'),
    ('Electric Blanket', 3, 16, 4, 79.99, 9, 1, '2025-01-17', '2025-01-17'),
    ('Smart Door Lock', 4, 20, 3.5, 199.00, 15, 1, '2025-01-17', '2025-01-17'),
    ('Portable Bluetooth Receiver', 5, 17, 0.3, 12.49, 2, 1, '2025-01-17', '2025-01-17')

GO
CREATE VIEW UserLogin AS

	WITH LastAuthenticLogon AS
	(
		SELECT userid, MAX(DateTime) AS [Successful logon]
		FROM SysLog
		WHERE IsAuthenticated = 1
		GROUP BY UserID
		),
	LastNonAuthenticLogon AS
	(
		SELECT userid, MAX(Datetime) AS [Not Successful logon]
		FROM SysLog
		WHERE IsAuthenticated = 0
		GROUP BY UserID
	)

	SELECT u.Email, u.FirstName, u.LastName, [Successful logon], [Not Successful logon]
	FROM Users u
	LEFT JOIN SysLog sl ON u.UserID = sl.UserID
	LEFT JOIN LastAuthenticLogon lal ON u.UserID = lal.UserID
	LEFT JOIN LastNonAuthenticLogon lnal ON u.UserID = lnal.UserID
	GROUP BY u.Email, FirstName, LastName, [Successful logon], [Not Successful logon]
GO

CREATE VIEW AmountofLogins AS

	SELECT Email, IPAddress,
		COUNT(*) OVER(PARTITION BY Email, IPAddress ORDER BY DateTime) AS [Total Attempts],
		COUNT(CASE WHEN IsAuthenticated = 1 THEN 1 END) OVER(PARTITION BY Email, IPAddress ORDER BY DateTime) AS [Successful Attempts],
		COUNT(CASE WHEN IsAuthenticated = 0 THEN 1 END) OVER(PARTITION BY Email, IPAddress ORDER BY DateTime) AS [Not Successful Attempts],
		AVG(CAST(IsAuthenticated AS FLOAT)) OVER(PARTITION BY Email, IPAddress ORDER BY DateTime) AS [Average Success Rate],
		DateTime AS Date
	FROM SysLog

GO

CREATE PROCEDURE setforgottenpassword 
    @email NVARCHAR(255), 
    @password NVARCHAR(128), 
    @token NVARCHAR(50)
AS
BEGIN
    BEGIN TRY

        DECLARE @resetcode NVARCHAR(50), @validto DATETIME

        SELECT @resetcode = resetcode, @validto = validto
        FROM ##resetpass
        WHERE resetcode = @token

        IF @token = @resetcode AND GETDATE() < @validto
        BEGIN
            UPDATE Users
            SET PwdHash = dbo.fn_HASHPASSWORD(@password, salt)
            WHERE email = @email
        END
        ELSE
        BEGIN
            THROW 50001, 'Invalid or expired token.', 1
        END
    END TRY
    BEGIN CATCH
       	DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE()
		DECLARE @ErrorSeverity INT = ERROR_SEVERITY()
		DECLARE @ErrorState INT = ERROR_STATE()
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
    END CATCH
END
GO

