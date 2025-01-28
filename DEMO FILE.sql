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
-- Run this to add the testuser below, add your email to see the emails regarding every user
EXEC AddNewUser 'test@test.com','testpasswordhash','TEST','USER','TEST STREET',3,'AB123','TEST CITY','TEST COUNTRY','C',1

-- Deletes the user added above
EXEC DeleteUser 25

-- Shows the last attempted login that was not successful
EXEC LastNonAuthLogon

--Use the userid of the user you want to reset the password for
EXEC ResetUserPass 25

--Disables the user
EXEC DisableUser 1

EXEC msdb.dbo.sysmail_add_account_sp
@account_name = 'Server testing mail',
@description = 'testmail',
@email_address = '**************',
@display_name = 'SQL SERVER TEST',
@mailserver_name = 'smtp.gmail.com',
@mailserver_type = 'SMTP',
@port = 587,
@username = '************',
@password = '*********',
@enable_ssl = 1


-- Test sending an email
EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'SQL SERVER MAIL', -- Mail profile to use
    @recipients = '@@@@@@', -- Recipient's email address
    @subject = 'Test Email from SQL Server', -- Email subject
    @body = 'This is a test email sent from SQL Server using Database Mail??', -- Email body
    @body_format = 'TEXT' -- Body format as plain text

-- View email sending logs
SELECT 
    mailitem_id,
    sent_status,
    subject,
    recipients,
    sent_date,
    last_mod_date
FROM msdb.dbo.sysmail_allitems
ORDER BY sent_date DESC;

-- View error logs (if the email fails to send)
SELECT 
    * 
FROM msdb.dbo.sysmail_event_log
ORDER BY log_date DESC;
