USE HarrysCarsDB

/*
Demo file, this file displays most/all views, SP, Indexes
*/

/*VIEWS*/


--User login shows the latest successful and not successful login per user
SELECT *
FROM Userlogin


/*
STORED PROCEDURES
*/
-- Run this to add the testuser below
EXEC AddNewUser 'testuser@testemail.com','testpasswordhash','TEST','USER','TEST STREET','3','AB123','TEST CITY','TEST COUNTRY','C'

-- Deletes the user added above
EXEC DeleteUser 25

-- Shows the last attempted login that was not successful
EXEC LastNonAuthLogon

--Use the userid of the user you want to reset the password for
EXEC ResetUserPass 1