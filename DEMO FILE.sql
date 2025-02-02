USE HarrysCarsDB
/*
Demo file, this file displays most/all views, SP, Indexes
*/

/*VIEWS*/

--User login shows the latest successful and not successful login per user
SELECT *
FROM Userlogin

--More detailed version that shows total attempts and attempt breakdown
SELECT *
FROM AmountofLogins

/*
STORED PROCEDURES
*/
-- Run this to add the testuser below, add your email if you want to try out the email functionality
EXEC AddNewUser 'test@test.com','testpassword','TEST','USER','TEST STREET',3,'AB123','TEST CITY','TEST COUNTRY','C',1
GO

--Run this to test the login for the new user IMPORTANT run the insert statement for it to work.
INSERT INTO SysLog (UserID, IPAddress, Email, DateTime, IsAuthenticated)
VALUES (25, '192.168.9.1' , 'test@test.com', '2025-01-12 13:25:00', 1)

EXEC trylogin 'test@test.com','testpassword', '192.168.9.1'
GO

--Use the userid of the user you want to reset the password for, testuser is 25.
EXEC forgotpassword 25

--Set a new password with the resetcode generated in SP_forgotpassword, run the select statement to see the resetcode.
SELECT *
FROM ##resetpass
EXEC setforgottenpassword 'test@test.com', 'hello','0E652580-F684-4C60-AD8F-5C2DB0DD47E6'

--Disables the user, which WOULD make it unable to login, not implemented yet
EXEC DisableUser 25

-- Deletes the user added above
EXEC DeleteUser 25

-- Shows the last attempted login that was not successful
EXEC LastNonAuthLogon


