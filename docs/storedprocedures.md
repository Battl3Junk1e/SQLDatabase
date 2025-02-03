# **Stored Procedures**

## **AddNewUser**
* `@AddNewUser`
    * Email
    * PwdHash
    * FirstName
    * LastName
    * StreetName
    * StreetNumber
    * PostalCode
    * City
    * Country
    * UserType `A`, `C` or blank for `C`
    * IsActive 

> This stored procedure adds a new user to the system.  
It hashes the user's plaintext password using the `fn_HASHPASSWORD` function with the `SHA2_512` algorithm and the user's salt. Additionally, the procedure sends a verification email to the user to confirm their account.  
When using this procedure without an `INSERT` statement,  
make sure the strings are provided in the correct order within the 'text' parameter.

## **DeleteUser**
* `@DeleteUser`
    * UserID

> Deletes user with `UserID`

## **LastNonAuthLogon**
* `@LastNonAuthLogon`

> Shows the latest logon that was not authenticated.

## **DisableUser**
* `@DisableUser`
    * UserID

> Changes the users `IsActive` to 0

## **ForgotPassword**
* `@ForgotPassword`
    * UserID or Email

> Takes `UserID` or `Email` and creates a reset code in a global temporary table and emails the user the reset code

## **setforgottenpassword**
* `@setforgottenpassword`
    * Email
    * Password
    * Token 

> Enter the `Email`, `new password` and the `reset token`, the new password is automatically hashed.

## **trylogin**
* `@trylogin`
    * Email
    * Password
    * IPAddress

> The `trylogin` procedure verifies the user's `email`, `password`, and `IP address` against the database records.  
It also checks whether the user's `IsActive` status is set to 1. If an incorrect password is entered three times within a 15-minute period  
or the IP address does not match the one stored in the database, the user's `IsActive` status is set to 0 for 15 minutes, starting from the first failed login attempt. If additional failed login attempts occur during the lockout period, the 15-minute countdown is reset.  
Once the lockout period expires, the user's `IsActive` status is restored to 1 if the correct login is entered.