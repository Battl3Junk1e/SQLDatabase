# **Indexes**

The following indexes have been created for the tables `Users` and `SysLog` to optimize query performance:

## **Users Table**
* **LastName Index**: `CREATE INDEX LastName ON Users (LastName)`
  - This index improves the performance of queries filtering or sorting by the `LastName` column.
  
* **StreetName Index**: `CREATE INDEX StreetName ON Users (StreetName)`
  - This index improves the performance of queries filtering or sorting by the `StreetName` column.
  
* **PostalCode Index**: `CREATE INDEX PostalCode ON Users (PostalCode)`
  - This index improves the performance of queries filtering or sorting by the `PostalCode` column.
---
## **SysLog Table**
* **SysLogEmail Index**: `CREATE INDEX SysLogEmail ON SysLog (Email)`
  - This index improves the performance of queries filtering or sorting by the `Email` column in the `SysLog` table.
