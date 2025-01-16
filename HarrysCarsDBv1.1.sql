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

CREATE TABLE Users (
UserID INT PRIMARY KEY IDENTITY(1,1),
Email NVARCHAR(255) UNIQUE NOT NULL,
PwdHash VARCHAR(MAX) NOT NULL,
FirstName NVARCHAR(255) NOT NULL,
LastName NVARCHAR(255) NOT NULL,
StreetName NVARCHAR(255) NOT NULL,
StreetNumber SMALLINT NOT NULL,
PostalCode VARCHAR(30) NOT NULL,
City NVARCHAR(255) NOT NULL,
Country NVARCHAR(60) NOT NULL,
UserType CHAR(1) CHECK (UserType IN ('A', 'C')) NOT NULL,
)
GO
CREATE PROCEDURE AddNewUser 
    @Email NVARCHAR(255),
    @PwdHash VARCHAR(MAX),
    @FirstName NVARCHAR(255),
    @LastName NVARCHAR(255),
    @StreetName NVARCHAR(255),
    @StreetNumber SMALLINT,
    @PostalCode VARCHAR(30),
    @City NVARCHAR(255),
    @Country NVARCHAR(60),
    @UserType CHAR(1)
AS
BEGIN
	BEGIN TRY
	INSERT INTO Users ( Email, PwdHash, FirstName, LastName, StreetName, StreetNumber, PostalCode, City, Country, UserType)
	VALUES (@Email, @PwdHash, @FirstName, @LastName, @StreetName, @StreetNumber, @PostalCode, @City, @Country, @UserType)
	END TRY
	BEGIN CATCH 
	DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE()
	DECLARE @ErrorSeverity INT = ERROR_SEVERITY()
    DECLARE @ErrorState INT = ERROR_STATE()
    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
	END CATCH
END
GO
CREATE INDEX LastName 
ON Users (LastName)
CREATE INDEX StreetName
ON Users (StreetName)
CREATE INDEX PostalCode
ON Users (PostalCode)

GO
INSERT INTO Users (Email, PwdHash, FirstName, LastName, StreetName, StreetNumber, PostalCode, City, Country, UserType)
VALUES
('john.doe@example.com', '$argon2i$v=19$m=65536,t=3,p=4$OmtFQKXk8g9vHtAXM1QpUQ$zX6XTZh4jlqjH7zFtNjwI+msUOXzB92FVTx3MkmqlJk', 'John', 'Doe', '123 Elm St', '10', '12345', 'New York', 'USA', 'A'),
('jane.smith@example.com', '$argon2i$v=19$m=65536,t=3,p=4$ZtnPqaF8S5cchdyHiB87XA$kHgZT+Uw11Xm3hoyrt+RHq46X0IV6W/5t3tbZ8XZ6Jw', 'Jane', 'Smith', '456 Oak Ave', '15', '54321', 'Los Angeles', 'USA', 'C'),
('alice.johnson@example.com', '$argon2i$v=19$m=65536,t=3,p=4$8WQ8Kqu29IMvZEKbhU8uQA$Bf1z44u8LvqDhgBzQxlhREtYoXGOfK6o8lI6r6kIbhk', 'Alice', 'Johnson', '789 Pine Blvd', '20', '67890', 'Chicago', 'USA', 'A'),
('bob.white@example.com', '$argon2i$v=19$m=65536,t=3,p=4$BhYav4wCVnQkg9MZLrM7jw$lkL5s5KKppsl9LgVZnzwAGVVyI57lSMXgkpZQeTlt/g', 'Bob', 'White', '101 Maple Rd', '25', '23456', 'Houston', 'USA', 'C'),
('charlie.brown@example.com', '$argon2i$v=19$m=65536,t=3,p=4$Dgy0lGgf1XsD1V4MreJwOw$D/ZmZk9fScEdq0vv7FjqwWhd0t1oZ8AB79u48cmG0y0', 'Charlie', 'Brown', '202 Birch Ln', '30', '34567', 'San Francisco', 'USA', 'A')

GO
CREATE TABLE SysLog (
SysLogID INT PRIMARY KEY IDENTITY(1,1),
UserID INT NOT NULL,
FOREIGN KEY (UserID) REFERENCES Users(UserID),
IPAddress VARBINARY(16),
Email NVARCHAR(255) NOT NULL,
DateTime DATETIME NOT NULL,
IsAuthenticated BIT NOT NULL
)

CREATE INDEX SysLogEmail
ON SysLog (Email)

INSERT INTO SysLog (UserID, IPAddress, Email, DateTime, IsAuthenticated)
VALUES (3,4532,'testspauth',GETDATE(),0)

SELECT *
FROM SysLog

CREATE PROCEDURE LastNonAuthLogon
@NotAuthenticated 