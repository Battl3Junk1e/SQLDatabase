# **Database Tables**
This page is formatted as: 

* Column name `Column attribute` Additional information

## **Users**

* UserID `INT`,`PRIMARY KEY`,`IDENTITY(1,1)` ID given to the user when signing up
* Email `NVARCHAR(255)`, `UNIQUE`, `NOT NULL` 
* PwdHash `NVARCHAR(128)`, `NOT NULL` Users password hash, using SHA2_512
* FirstName `NVARCHAR(255)`, `NOT NULL` NVARCHAR to accommodate international use. 
* LastName `NVARCHAR(255)`, `NOT NULL` 
* StreetName `NVARCHAR(255)`, `NOT NULL` Has a character limit of 255 to accommodate corner cases.
* StreetNumber `SMALLINT`, `NOT NULL` Stored separately for normalization of the database and for easier filtering.
* PostalCode  `VARCHAR(30)`, `NOT NULL` VARCHAR for flexibility and better international use.
* City `NVARCHAR(255)`, `NOT NULL`
* Country  `NVARCHAR(60)`, `NOT NULL`
* UserType `CHAR(1)`, `NOT NULL` CHAR(1) represents the role with either A or C for performance and efficiency 
* IsActive `BIT`, `DEFAULT 1` Shows if the user is active to log in

## **SysLog**

* SysLogID `INT`, `PRIMARY KEY` ID for the login attempt
* UserID  `INT`, `FOREIGN KEY` User ID of the login attempt FOREIGN KEY (UserID) REFERENCES Users(UserID)
* IPAddress  `NVARCHAR(128)`
* Email  `NVARCHAR(255)`, `NOT NULL` Shows the email address trying to login.
* DateTime `DATETIME`, `NOT NULL` Fetches the date and time when the login attempt was made.
* IsAuthenticated `BIT`, `NOT NULL` Indicates authentication success: 1 for success, 0 for failure.


## **Orders**

* OrderID `INT`,`PRIMARY KEY`
* TotalAmount `INT` Total amount for the products in the order.
* DeliveryOption `INT`,`FOREIGN KEY` 
* OrderDate `DATETIME`,`NOT NULL`
* Fullfillment `BIT`,`NOT NULL` Set to 1 if the order is filled.
* Paymentmethod `INT`,`FOREGIN KEY` 

## **OrderLines**

* OrderLineID `INT`, `PRIMARY KEY`
* OrderID `INT`, `FOREIGN KEY`, `NOT NULL`
* ProductID  `INT`, `NOT NULL`
* ProductName `NVARCHAR(255)`, `NOT NULL`
* Quantity `INT`, `NOT NULL`
* UnitPrice `DECIMAL(10, 2)`, `NOT NULL`
* ShippedDate `DATE`
* WarehouseID `INT`, `FOREIGN KEY`
* Notes  `NVARCHAR(MAX)` Custom notes put on the order.

## **Products**

* ProductID `INT`, `PRIMARY KEY`
* ProductName `NVARCHAR(255)`, `NOT NULL` 
* SupplierID `INT`, `FOREIGN KEY`, `NOT NULL`
* Color `INT`, `FOREIGN KEY`
* ProductWeight `INT` 
* UnitPrice `DECIMAL (10, 2)`, `NOT NULL` 
* TaxAmt `TINYINT`
* IsActive `BIT`, `NOT NULL`
* CreatedDate `DATETIME`, `NOT NULL`
* LastEdited `DATETIME`, `NOT NULL`

## **Suppliers**

* SupplierID `INT`, `PRIMARY KEY`
* OrgName `NVARCHAR(255)`, `NOT NULL`
* Country `NVARCHAR(255)`


## **Warehouse**

* WarehouseID `INT`, `PRIMARY KEY`
* WarehouseName `NVARCHAR(50)`, `NOT NULL`
* StreetName `NVARCHAR(255)`, `NOT NULL`
* StreetNumber `INT`, `NOT NULL`
* Postalcode `VARCHAR(30)`, `NOT NULL` VARCHAR for flexibility and better international use.
* City `NVARCHAR(255)`
* Country `NVARCHAR(255)`
* Phone `INT`, `NOT NULL`
* Email `NVARCHAR(100)`

## **PaymentMethods**

* PaymentID `INT`, `PRIMARY KEY`
* PaymentType `VARCHAR(25)`

## **DeliveryOptions**

* DeliveryID `INT`, `PRIMARY KEY`
* DeliveryPrice `SMALLINT`
* DeliveryType `VARCHAR(100)`

## **Colors**

* ColorID `INT`, `PRIMARY KEY`
* ColorName `VARCHAR(15)`

