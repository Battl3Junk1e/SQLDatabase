# **Future Improvements**

## **In-App Hashing with Argon2**
The implementation of password hashing could be updated to use the `Argon2` algorithm, which is a modern and secure hashing function.`Argon2` is designed to resist both brute-force and GPU-based attacks, making it a more secure choice compared to traditional hashing algorithms like `SHA-256` or `SHA-512`. By using `Argon2`, we ensure that passwords are hashed in a way that is resistant to cracking attempts, enhancing the overall security of the authentication process.

---

## **Actual Verification Email**
Currently, the verification email process is not fully implemented. The goal is to send a real verification email to users upon account creation. This email will contain a `unique token or link` to confirm the user's email address. This step will improve the security of the registration process by ensuring that the email provided by the user is valid and active, preventing potential misuse of the system.


---

## **Not Storing Reset Codes in Global Temp Tables**
To improve security and avoid potential issues with session management, password reset codes should no longer be stored in global temporary tables. This change helps ensure that reset codes are kept more secure and that they aren't exposed unnecessarily to other sessions. 


---

## **Login for First-Time Users with Geolocation and MFA for Unfamiliar Locations**

Currently, users are `required` to provide an IP address during login attempts.  
However, this restriction should be removed for `first-time logins`.  
This change allows new users, who does not have an IP address associated with their account to log in and complete their registration.

### **Geolocation Check**  
If the user is logging in from an IP address that is geographically close to a previously recorded location (based on IP geolocation), the system should allow the login without additional checks. Geolocation data will be used to assess whether the user's current IP address matches the region or country of previous logins.

### **Multi-Factor Authentication (MFA) for Unfamiliar Locations**  
If the user logs in from an IP address that is not "close enough" to their previous logins (e.g., if they are using a significantly different geographic location), the system will prompt for `Multi-Factor Authentication (MFA)`. This adds an additional layer of security, ensuring that the user is indeed the account owner, even if the login attempt comes from a new or unusual location.

---

## **Multi-Factor Authentication (MFA)**
`Multi-Factor Authentication (MFA)` adds an extra layer of security to the user login process by requiring users to provide two or more verification factors. This process ensures that even if an attacker has compromised the user's password, they would still need the second factor (such as a `one-time code` sent via email or SMS) to access the account.
By requiring multiple forms of identification, MFA significantly reduces the risk of unauthorized access.


---

## **Password Complexity Enforcement**
To ensure that users create strong passwords and to protect user accounts from being easily compromised, enforcing password complexity rules is essential. This can include setting requirements for the length, character variety, and randomness of the password.  
By enforcing these rules, the system helps ensure that passwords are difficult to guess or crack, thereby improving account security.

---

## **Permissions Management (Role-Based Access Control)**
Permissions management is a critical part of securing a system and ensuring that users only have access to the data and functionality they need. 
By assigning specific roles and permissions, users are restricted to only the areas and actions they are authorized to access, thus protecting sensitive data and functionality.

