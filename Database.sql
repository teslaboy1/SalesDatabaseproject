
-- 1)   Creating Table for Product

-- Create the table in the specified schema
CREATE TABLE [dbo].[Product]
(
    [P_ID] INT IDENTITY(100,1) NOT NULL PRIMARY KEY, -- Primary Key column
    [Product_Name] NVARCHAR(50) NOT NULL,
    [Quantity_Available] INT NOT NULL,
    [Price] FLOAT NOT NULL,
    [Expiry_Date] DATE NOT NULL,
    [Manufacture_Date] DATE NOT NULL
    -- Specify more columns here
);
GO

ALTER TABLE Product
ADD CONSTRAINT UQ_Product_Product_Name UNIQUE(Product_Name)

-- 2)   Creating Table for Customer

-- Create the table in the specified schema
CREATE TABLE [dbo].[Customer]
(
    [Id] INT IDENTITY(100,1) NOT NULL PRIMARY KEY, -- Primary Key column
    [Customer_Name] NVARCHAR(50) NOT NULL,
    [Age] INT NOT NULL,
    [Gender] NVARCHAR(50) NOT NULL,
    [Contact_Number] VARCHAR(50) NOT NULL,
    [Email_Address] NVARCHAR(50) NOT NULL
    
    -- Specify more columns here
);
GO

ALTER TABLE Customer
ADD CONSTRAINT UQ_Customer_Contact_Number UNIQUE(Contact_Number)

ALTER TABLE Customer
ADD CONSTRAINT UQ_Customer_Email_Address UNIQUE(Email_Address)


-- 3). Creating Table for Sales_Transaction

CREATE TABLE [dbo].[Sales_Transaction]
(
    [Transaction_Id] INT IDENTITY(100,1) NOT NULL PRIMARY KEY, -- Primary Key column
    [ID_Customer] INT NOT NULL,
    [ID_Product] INT NOT NULL,
    [Quantity] INT NOT NULL,
    [Purchase_Date] DATE NOT NULL
    -- Specify more columns here
);
GO

ALTER TABLE Sales_Transaction
ADD CONSTRAINT FK_SalesT_ID_Customer
FOREIGN KEY(ID_Customer) REFERENCES Customer(Id)

ALTER TABLE Sales_Transaction
ADD CONSTRAINT FK_SalesT_ID_Product
FOREIGN KEY(ID_Product) REFERENCES Product(P_Id)

-- 4). Creating Table for Invoice

CREATE TABLE [dbo].[Invoice]
(
    [Invoice_Id] INT IDENTITY(100,1) NOT NULL PRIMARY KEY, -- Primary Key column
    [ID_transaction] INT NOT NULL,
    [Customer_ID] INT NOT NULL,
    [Product_ID] INT NOT NULL,
    [Net_Amount] FLOAT NULL
    
);
GO

-- 1. Adding Store Procedures for Product

    -- 1a. Store Procedure for product Insert

go
CREATE PROC spInsertProduct
@Product_Name NVARCHAR(50),
@Quantity_Available INT,
@Price FLOAT,
@Expiry_Date DATE,
@Manufacture_Date DATE
AS
BEGIN
    INSERT INTO Product
                (Product_Name,
                Quantity_Available,
                Price,
                Expiry_Date,
                Manufacture_Date)
    VALUES      (@Product_Name,
                @Quantity_Available,
                @Price,
                @Expiry_Date,
                @Manufacture_Date)
END

EXEC spInsertProduct @Product_Name = 'KitKat' , @Quantity_Available = 56, @Price = 60 ,@Expiry_Date = '2022-5-7' , @Manufacture_Date = '2020-5-2'
    
    -- 1b. Store Procedure for product Update

go
CREATE PROC spUpdateProduct
@P_ID INT,
@Product_Name NVARCHAR(50),
@Quantity_Available INT,
@Price FLOAT,
@Expiry_Date DATE,
@Manufacture_Date DATE
AS
BEGIN
    UPDATE Product
    SET Product_Name = @Product_Name,
        Quantity_Available = @Quantity_Available,
        Price = @Price,
        Expiry_Date = @Expiry_Date,
        Manufacture_Date = @Manufacture_Date
    WHERE P_ID = @P_ID
END

    -- 1c. Store Procedure for product Select

go
CREATE PROC spSelectProduct
AS
BEGIN
    SELECT * FROM Product
END

-- 2. Adding Store Procedures for Cutomer

    -- 2a). Store Procedure for Insert customer

GO
CREATE PROC spInsertCustomer
@Customer_Name NVARCHAR(50),
@Age INT,
@Gender NVARCHAR(50),
@Contact_Number VARCHAR(50),
@Email_Address NVARCHAR(50)
AS
BEGIN
    INSERT INTO Customer
                (Customer_Name,
                Age,
                Gender,
                Contact_Number,
                Email_Address)
    VALUES      (@Customer_Name,
                @Age,
                @Gender,
                @Contact_Number,
                @Email_Address)
END

    -- 2b). Store Procedure for Update customer

GO
CREATE PROC spUpdateCustomer
@ID INT,
@Customer_Name NVARCHAR(50),
@Age INT,
@Gender NVARCHAR(50),
@Contact_Number VARCHAR(50),
@Email_Address NVARCHAR(50)
AS
BEGIN
    UPDATE Customer
    SET Customer_Name = @Customer_Name,
        Age = @Age,
        Gender = @Gender,
        Contact_Number = @Contact_Number,
        Email_Address = @Email_Address
    WHERE ID = @ID
END

    -- 2c). Store Procedure for Select customer

GO
CREATE PROC spSelectCustomer
AS
BEGIN
    SELECT * FROM Customer
END

-- 3. Adding Store Procedure for Sales Transaction 

    -- 3a). Store Procedure for Insert Sales Transaction

GO
CREATE PROC spInsertTrans
@ID_Customer INT,
@ID_Product INT,
@Quantity INT,
@Purchase_Date DATE
AS
BEGIN
    INSERT INTO Sales_Transaction
                (ID_Customer,
                ID_Product,            
                Quantity,
                Purchase_Date)
    VALUES      (@ID_Customer,
                @ID_Product,
                @Quantity,
                @Purchase_Date)  
END

-- CREATING trigger for inserting
GO
CREATE TRIGGER tr_Sales_Transaction_ForInsert
ON Sales_Transaction
FOR INSERT
AS
BEGIN
Select * from Invoice
    DECLARE @Transaction_Id INT,@ID_Customer INT,@ID_Product INT,@Purchase_Date DATE,@Net_Amount FLOAT    
    SELECT @Transaction_Id = Transaction_Id, @ID_Customer = ID_Customer, @ID_Product = ID_Product,@Purchase_Date = Purchase_Date,@Net_Amount = null FROM inserted
    INSERT INTO Invoice 
    VALUES(@Transaction_Id , @ID_Customer, @ID_Product,@Net_Amount)
    SELECT * FROM Invoice
    UPDATE Product
    SET Product.Quantity_Available = Product.Quantity_Available - Sales_Transaction.Quantity
    FROM Product
    INNER JOIN Sales_Transaction
    ON Product.P_ID = Sales_Transaction.ID_Product

    UPDATE Invoice
    SET Invoice.Net_Amount = Product.Price * Sales_Transaction.Quantity
    FROM Invoice
    INNER JOIN Sales_Transaction ON Invoice.ID_transaction = Sales_Transaction.Transaction_Id
    INNER JOIN Product ON Invoice.Product_ID = Product.P_ID

END

    -- 3b). Store Procedure for Update Sales Transaction 

GO
CREATE PROC spUpdateTrans
@Transaction_Id INT,
@ID_Customer INT,
@ID_Product INT,
@Quantity INT,
@Purchase_Date DATE
AS
BEGIN
    UPDATE Sales_Transaction
    SET ID_Customer = @ID_Customer,
        ID_Product = @ID_Product,
        Quantity = @Quantity,
        Purchase_Date = @Purchase_Date
    WHERE Transaction_Id = @Transaction_Id
END

    -- 3c). Store Procedure for Select Sales Transaction 

go
CREATE PROC spSelectTrans
AS
BEGIN
    SELECT Transaction_Id, Customer_Name, Product_Name,Quantity, (Quantity * Price) as [Net_Amount], Purchase_Date
    FROM Sales_Transaction
    JOIN Customer ON Sales_Transaction.ID_Customer = Customer.Id
    JOIN Product ON Sales_Transaction.ID_Product = Product.P_ID  
END

-- Generating Bill for the Customers 
go
CREATE PROC spInvoiceGenerate
AS
BEGIN
    SELECT Customer_Name,SUM(Net_Amount)AS [Total Amount],
    CASE WHEN SUM(Net_Amount)<=500
        THEN SUM(Net_Amount)-(0.05*SUM(Net_Amount))
        ELSE SUM(Net_Amount)-(0.1*SUM(Net_Amount))
    END AS [Discounted Price]--Invoice.Purchase_Date
    --IFF([Total Amount]<=500,[Total Amount]-(0.05*[Total Amount]), [Total Amount]-(0.1*[Total Amount]))AS Discounted
    FROM Invoice
    JOIN Customer ON Invoice.Customer_ID = Customer.Id
    JOIN Product ON Invoice.Product_ID = Product.P_ID  
    JOIN Sales_Transaction ON Invoice.ID_transaction = Sales_Transaction.Transaction_Id
    GROUP BY Customer_Name
   -- GROUP BY Invoice.Purchase_Date,Customer_Name
END












