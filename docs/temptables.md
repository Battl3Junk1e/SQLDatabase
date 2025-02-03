# **Temporary Tables**

## **##activecheck**

* email `NVARCHAR(255)` Email address of the user attempting to log in.
* failedattempt `TINYINT` Number of failed login attempts by the user.
* date `DATETIME`, `DEFAULT GETDATE()` Date and time of the last failed login attempt.

## **##resetpass**

* resetcode `NVARCHAR(50)` The unique reset code for password recovery.
* Validfrom `DATETIME` The start date and time from which the reset code is valid.
* Validto `DATETIME` The expiration date and time of the reset code