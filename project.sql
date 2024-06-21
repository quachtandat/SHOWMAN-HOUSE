--1. Tên Đồ Án: Showman House
--2. Học phần: Hệ quản trị CSDL - Mã học phần: IT202DV01
--3. Học kỳ: 23.2A (2333)
--   Ngày nộp: 21/06/2024
--   Ngày báo cáo: 28/06/2024
--4. Các Sinh viên thực hiện:
--            1. Lâm Văn Gia Bảo - 22102538
--            2. Quách Tấn Đạt - 22102167
--5: GVHD: Đặng Thanh Linh Phú
CREATE DATABASE PROJECT ON  PRIMARY 
	( NAME = 'Company', 
	FILENAME = 'C:\DATA\MyProject.mdf' , 
	SIZE = 4MB, 
	MAXSIZE = UNLIMITED, 
	FILEGROWTH = 1024KB )
 LOG ON 
	( NAME = 'Company_log', 
	FILENAME = 'C:\DATA\MyProject_log.ldf' , 
	SIZE = 1024KB , 
	MAXSIZE = 2048KB , 
	FILEGROWTH = 10%)

GO
--Tạo Database
CREATE DATABASE ShowmanHouse
USE ShowmanHouse
GO
--Tạo Schema
CREATE SCHEMA Management
GO
CREATE SCHEMA HumanResources
GO
CREATE SCHEMA [Event]
GO
--Tạo Table
CREATE TABLE HumanResources.Employee
(
		EmployeeID int IDENTITY(1,1) PRIMARY KEY ,
		FirstName varchar(20) NOT NULL,
		LastName varchar(22) NOT NULL,
		Address varchar(60) NOT NULL,
		Phone varchar(21) NOT NULL CONSTRAINT chkPhone 
		CHECK(Phone LIKE '[0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9]'),
		Title varchar(55) CONSTRAINT chkTitle 
		CHECK(Title IN ('Executive','Senior Executive','Management Trainee','Event Manager','Senior Event Manager'))
)
GO
INSERT INTO [HumanResources].Employee
VALUES('Bao','Lam','23TranDInhTrong','02-525-4587-364-985','Executive')
GO
INSERT INTO HumanResources.Employee
VALUES('Natasha','Stacey','1,Collins Drive','37-471-2844-974-462','Event Manager')
GO
INSERT INTO HumanResources.Employee
VALUES('Martha','Daniels','5,Whites Way','13-442-4677-374-663','Senior Event Manager')
GO
INSERT INTO HumanResources.Employee
VALUES('John','Lark','3,Major Way','11-362-4481-444-726','Senior Executive')
GO
CREATE TABLE Management.Events
(
		EventID int IDENTITY(10,1) PRIMARY KEY,
		EventName varchar(30) NOT NULL,
		EmployeeID int FOREIGN KEY References  HumanResources.Employee(EmployeeID),
		CustomerID int FOREIGN KEY  References Event.Customers(CustomerID),
		EventTypeID int CONSTRAINT fkEventTypeID FOREIGN KEY References Event.EventTypes(EventTypeID),
		StaffRequired int CONSTRAINT chkStaffRequired	
		CHECK(StaffRequired>0),
		StartDate datetime NOT NULL CONSTRAINT chkStartDate
		CHECK(StartDate>getdate()),
		EndDate datetime NOT NULL CONSTRAINT chkEndDate
		CHECK(EndDate>getdate()),
		Location varchar(40) NOT NULL,
		NoOfPeople int NOT NULL CONSTRAINT chkNoOfPeople
		CHECK(NoOfPeople>=50),
		CONSTRAINT chkStartDate2
		CHECK (StartDate<EndDate)
)
--Inser dữ liệu
GO
INSERT INTO Management.Events
VALUES('Howard Weds Martha',1,1003,500,25,'2025-04-19','2025-07-20','Civic Centre',200)
GO
INSERT INTO Management.Events
VALUES('Christines 18th Birthday',2,1001,501,20,'2024-06-18','2024-07-19','Showman Hall',90)
GO
INSERT INTO Management.Events
VALUES('Ashleys Dinner Hosting',3,1002,502,20,'2024-05-22','2025-05-02','Showman Hall',60) 
GO
INSERT INTO [Management].Events
VALUES ('GioTo',1,1001,500,3,'2024-05-18','2025-04-22','American',51)
GO
	ALTER TABLE Management.Events ADD CONSTRAINT fkEmployeeID FOREIGN KEY(EmployeeID)
	REFERENCES HumanResources.Employee(EmployeeID) ON DELETE NO ACTION ON UPDATE CASCADE 
GO
	ALTER TABLE Management.Events ADD CONSTRAINT fkCustomerID FOREIGN KEY(CustomerID)
	REFERENCES Event.Customers(CustomerID) ON DELETE NO ACTION ON UPDATE CASCADE
GO
CREATE TABLE Management.Payments 
(
		PaymentID int IDENTITY(100,1) PRIMARY KEY,
		EventID int FOREIGN KEY References Management.Events(EventID),
		EventTypeID int FOREIGN KEY References Event.EventTypes(EventTypeID) DEFAULT NULL,
		StartDate datetime,
		PaymentDate datetime,
		PaymentMethodID int FOREIGN KEY References Management.PaymentMethods(PaymentMethodID),
		PaymentStatus varchar(7) DEFAULT NULL,
		CreditCardNumber varchar(150),
		CardHoldersName varchar(30),
		CreditCardExpDate datetime CONSTRAINT chkCrdExpDate
		CHECK(CreditCardExpDate>getdate()),
		ChequeNo int,
		PaymentAmount int DEFAULT NULL,
		CONSTRAINT chkPaymentDate
		CHECK(PaymentDate<=StartDate)
)
GO
INSERT INTO Management.Payments
VALUES(13,DEFAULT,'2019-04-19','2019-04-18',1,DEFAULT,ENCRYPTBYKEY(KEY_GUID('CreditCardNo_EncryptKey'),'2343675478956478'),'Howard Christian','2025-01-01',NULL,DEFAULT)
GO
INSERT INTO Management.Payments
VALUES(23,DEFAULT,'2019-04-18','2019-04-16',1,DEFAULT,ENCRYPTBYKEY(KEY_GUID('CreditCardNo_EncryptKey'),'2434375628797458'),'Ashley Babe','2025-03-01',NULL,DEFAULT)
GO
INSERT INTO Management.Payments
VALUES(31,DEFAULT,'2019-05-01',NULL,2,NULL,DEFAULT,NULL,NULL,NULL,DEFAULT)
GO
INSERT INTO Management.Payments
VALUES(10,DEFAULT,'2019-04-19','2019-04-18',1,DEFAULT,ENCRYPTBYKEY(KEY_GUID('CreditCardNo_EncryptKey'),'2343675478956478'),'Howard Christian','2020-01-01',NULL,DEFAULT),
	  (11,DEFAULT,'2019-04-18','2019-04-16',1,DEFAULT,ENCRYPTBYKEY(KEY_GUID('CreditCardNo_EncryptKey'),'2434375628797458'),'Ashley Babe','2020-03-01',NULL,DEFAULT),
/**TO DEFINE THE PAYMENT AMOUNT COLUMN**/
GO
create TRIGGER GetPaymentAmt ON Management.Payments
AFTER INSERT AS
SET NOCOUNT ON;
BEGIN
	WITH Temp_CTE (EventID,NoOfPeople,ChargePerPerson,PaymentAmt) AS
	(select me.EventID,me.NoOfPeople,ee.ChargePerPerson,PaymentAmt=me.NoOfPeople*ee.ChargePerPerson 
	FROM Inserted ins JOIN Management.Events me ON ins.EventID=me.EventID
	JOIN Event.EventTypes ee ON me.EventTypeID=ee.EventTypeID)

	UPDATE Management.Payments
	SET [Management].[Payments].[PaymentAmount]=
	(select Temp_CTE.PaymentAmt FROM Temp_CTE WHERE Temp_CTE.EventID=Management.Payments.EventID)
END

/**TO AUTOMATICALLY SET THE EVENT TYPEID IN THE PAYMENTS TABLE**/
GO
create TRIGGER SetEventTypeID ON Management.Payments
AFTER INSERT AS
SET NOCOUNT ON;
WITH EventTypeID_CTE (EventID,EventTypeID) AS
(SELECT EventID,EventTypeID FROM Management.Events)
UPDATE Management.Payments
SET EventTypeID=(select EventTypeID FROM EventTypeID_CTE WHERE Management.Payments.EventID=EventTypeID_CTE.EventID)


--/TO AUTOMATICALLLY SET THE PAYMENT STATUS COLUMN/
GO
CREATE TRIGGER SetPaymentStatus ON Management.Payments
AFTER INSERT
AS
SET NOCOUNT ON;
BEGIN
WITH Status_CTE(PaymentID,PaymentDate,PaymentStatus) AS
(select PaymentID,PaymentDate,IIF(PaymentDate IS NULL,'Pending',IIF(PaymentDate IS NOT NULL,'Paid','')) AS PaymentStatus FROM inserted)

	UPDATE Management.Payments
	SET PaymentStatus=(select Status_CTE.PaymentStatus FROM Status_CTE WHERE Status_CTE.PaymentID=Management.Payments.PaymentID)
END


GO
CREATE TRIGGER UpdatePaymentStatus ON Management.Payments
FOR UPDATE
AS
SET NOCOUNT ON;
BEGIN
IF UPDATE(PaymentDate)
BEGIN
	WITH Status_CTE(PaymentID,PaymentDate,PaymentStatus) AS
	(select PaymentID,PaymentDate,IIF(PaymentDate IS NULL,'Pending',IIF(PaymentDate IS NOT NULL,'Paid','')) AS PaymentStatus FROM Management.Payments)

	UPDATE Management.Payments
	SET PaymentStatus=(select Status_CTE.PaymentStatus FROM Status_CTE WHERE Status_CTE.PaymentID=Management.Payments.PaymentID)
END
END


CREATE TABLE [Event].Customers
(
		CustomerID int IDENTITY(1000,1) PRIMARY KEY,
		Name varchar(30) NOT NULL,
		Address varchar(55) NOT NULL,
		City varchar(18) NOT NULL,
		State varchar(20) NOT NULL,
		Phone varchar(21) NOT NULL CONSTRAINT chkPhone 
		CHECK(PHONE LIKE '[0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9]')
)
GO
INSERT INTO [Event].Customers 
VALUES('NguyenVanA','445TranXuanSoan','HoChiMinh','Quan7','02-554-6587-957-745')
GO
INSERT INTO Event.Customers
VALUES('Howard Christian','3,Kings Way','V.I','Lagos','11-345-2534-573-458')
GO
INSERT INTO Event.Customers
VALUES('Christine Kate','3,Gbadamosi Street','Ikeja','Lagos','22-431-3355-667-458')
GO
INSERT INTO Event.Customers
VALUES('Ashley Babe','5,Collins Way','V.I','Lagos','45-543-6734-638-648')
GO
CREATE TABLE [Event].EventTypes
(
		EventTypeID int IDENTITY(500,1) PRIMARY KEY,
		Description varchar(55) NOT NULL,
		ChargePerPerson int CONSTRAINT chkChrgPerPerson
		CHECK(ChargePerPerson>0)
)
GO
INSERT INTO Event.EventTypes
VALUES('Wedding',5000)
GO
INSERT INTO Event.EventTypes
VALUES('Birthdays',4500)
GO
INSERT INTO Event.EventTypes
VALUES('Dinner Hosting',3500)
GO
INSERT INTO Event.EventTypes
VALUES('Wake Keep',3000)
GO
INSERT INTO Event.EventTypes
VALUES ('TOILADON',3)
GO
CREATE TABLE Management.PaymentMethods
(
		PaymentMethodID int IDENTITY(1,1) PRIMARY KEY,
		Description varchar(55) CONSTRAINT chkDesc 
		CHECK(Description IN('Cash','Cheque','Credit Card'))
)
GO
INSERT INTO Management.PaymentMethods
VALUES('Credit Card')
GO
INSERT INTO Management.PaymentMethods
VALUES('Cheque')
GO
INSERT INTO Management.PaymentMethods
VALUES('Cash')
GO

---
-- Thêm dữ liệu vào bảng EventTypes
INSERT INTO Event.EventTypes ( Description, ChargePerPerson)
VALUES 
('Conference', 50.00), 
('Workshop', 30.00), 
('Seminar', 20.00);

-- Thêm dữ liệu vào bảng Events
INSERT INTO Management.Events (EventName, NoOfPeople, StartDate,EndDate,Location)
VALUES 
('Tech Conference',  100, '2024-07-01','2024-07-31','vn'), 
('Business Workshop', 50, '2024-07-02','2024-07-31','vn'), 
('Health Seminar', 200, '2024-07-03','2024-07-31','vn');

-- Thêm dữ liệu vào bảng PaymentMethods
INSERT INTO Management.PaymentMethods (PaymentMethodID, PaymentMethodName)
VALUES 
(1, 'Credit Card'), 
(2, 'Cheque'), 
(3, 'Cash');

-- Thêm dữ liệu vào bảng Payments để kiểm tra các triggers
INSERT INTO Management.Payments ( EventID,EventTypeID,StartDate, PaymentDate, PaymentMethodID, CreditCardNumber, CardHoldersName, CreditCardExpDate, ChequeNo,PaymentAmount)
VALUES 
( 13,502,'2024-07-01', null, 1, '1234-5678-9012-3456', 'tandat1', '2025-07-01', 123456,8), 
( 13,502,'2024-07-01', null, 1, '1234-5678-9012-3456', 'John Doe', '2025-07-01', 123456,6), 
( 23,503,'2024-07-01', '2023-06-29', 1, '1234-5678-9012-3456', 'John ', '2025-07-01', 123456,7),  
( 31,504,'2024-07-01', '2023-06-28', 2, '1234-5678-9012-3456', 'tandat3', '2025-07-01', 123456,4); 




SELECT * FROM [Event].[Customers]
SELECT * FROM [Event].[EventTypes]
SELECT * FROM [HumanResources].[Employee]
SELECT * FROM [Management].[Events]
SELECT * FROM [Management].[PaymentMethods]
SELECT * FROM [Management].[Payments]

--Backup file TXT
--Step 1:Open cmd(commant promt with admin)
--Step 2:bcp ShowmanHouse.HumanResources.Employee out C:\Data\EmployeeData.txt -c -t, -S -Usa -P123456
--Step 3:Open link file and check (good luck hihi :>>)

-- INDEX
create UNIQUE INDEX ix_EventID ON Management.Events
(EventID)
GO
CREATE INDEX ix_CustomerEvent ON Management.Events
(CustomerID) INCLUDE (StartDate)
GO
CREATE INDEX IX_EventPayment ON Management.Payments
(EventID) INCLUDE (PaymentStatus)
GO
create INDEX IX_EventDetails ON Management.Events
(StaffRequired)
GO
--Create user
USE MASTER

CREATE LOGIN Chris WITH PASSWORD = N'123456'
EXEC sp_addsrvrolemember 'Chris','sysadmin'
CREATE USER Chris FOR LOGIN Chris

CREATE ROLE dbcreator;
ALTER ROLE dbcreator ADD MEMBER William;


CREATE LOGIN William WITH PASSWORD = N'123456'
EXEC sp_addrolemember 'William','dbcreator'
CREATE USER William for login William


CREATE LOGIN Sara WITH PASSWORD = N'123456'
EXEC sp_addrolemember 'Sara','dbcreator'
CREATE USER Sara for login Sara

CREATE LOGIN Sam WITH PASSWORD = N'123456'
EXEC sp_addrolemember 'Sam','dbcreator'
CREATE USER Sam for login Sam
--Backup data
USE ShowmanHouse
GO
BACKUP DATABASE [ShowmanHouse]
TO DISK ='C:\DATA\ShowmanHouse_Backup.bak'
WITH DESCRIPTION='FullBackupOfShowmanHouse'
GO

--Mã hóa
CREATE SYMMETRIC KEY  SK01
WITH ALGORITHM = AES_256
ENCRYPTION by PASSWORD ='HSU@sk.123'

open  symmetric key SK01 
DECRYPTION by PASSWORD = 'HSU@sk.123'

select * into [Event].[New_Customers] from [Event].[Customers]
select * from [Event].[New_Customers]
	use [ShowmanHouse]
	update [Event].[New_Customers]
	set Name=encryptbykey(key_guid('SK01'), Name)
	update [Event].[New_Customers]
	set Phone=encryptbykey(key_guid('SK01'), [Phone])

close symmetric key SK01
select * from [Event].[New_Customers]
alter table [Event].[New_Customers] 
alter column phone varchar(256) NOT NULL

alter table [Event].[New_Customers] 
alter column [name] varchar(256) NOT NULL
--Giai Mã Hóa
open symmetric key SK01
DECRYPTION by PASSWORD = 'HSU@sk.123' 
update [Event].[New_Customers]
set Phone=decryptbykey([Phone])
update [Event].[New_Customers]
set [Name]=DECRYPTBYKEY([Name])
close symmetric key SK01
select * from [Event].[New_Customers]

--Niêm phong
--Câu 10
USE ShowmanHouse
GO

-- Truy vấn thông tin cơ sở dữ liệu
SELECT DB_NAME() AS DbName,
       name AS [FileName],
       size / 128.0 AS CurrentSizeMB,
       size / 128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT) / 128.0 AS FreeSpaceMB
FROM sys.master_files
WHERE name LIKE 'ShowmanHouse%';

-- Tạo hàm kiểm tra file có tồn tại trong đường dẫn chỉ định
CREATE FUNCTION dbo.fn_FileExists(@path VARCHAR(1000))
RETURNS BIT
AS
BEGIN
    DECLARE @result INT;
    EXEC master.dbo.xp_fileexist @path, @result OUTPUT;
    RETURN CAST(@result AS BIT);
END;

-- Gọi hàm kiểm tra file có tồn tại trong đường dẫn được chỉ định
SELECT DISTINCT dbo.fn_FileExists('C:\DATA\Alert\Alert1.txt') AS IsExists
FROM [Event].[Customers];

SELECT DISTINCT dbo.fn_FileExists('C:\DATA\Alert\Alert1.txt') AS IsExists
FROM [Event].[EventTypes];

SELECT DISTINCT dbo.fn_FileExists('C:\DATA\Alert\Alert1.txt') AS IsExists
FROM [HumanResources].[Employee];

SELECT DISTINCT dbo.fn_FileExists('C:\DATA\Alert\Alert1.txt') AS IsExists
FROM [Management].[Events];

SELECT DISTINCT dbo.fn_FileExists('C:\DATA\Alert\Alert1.txt') AS IsExists
FROM [Event].[Customers];

SELECT DISTINCT dbo.fn_FileExists('C:\DATA\Alert\Alert1.txt') AS IsExists
FROM [Management].[PaymentMethods];

SELECT DISTINCT dbo.fn_FileExists('C:\DATA\Alert\Alert1.txt') AS IsExists
FROM [Management].[Payments];
-- Tạo thủ tục spWriteStringToFile để ghi chuỗi vào file
CREATE PROCEDURE spWriteStringToFile
    @String VARCHAR(MAX),
    @Path VARCHAR(255),
    @Filename VARCHAR(100)
AS
BEGIN
    DECLARE @objFileSystem INT,
            @objTextStream INT,
            @objErrorObject INT, -- Khai báo biến này
            @strErrorMessage VARCHAR(1000),
            @Command VARCHAR(1000),
            @hr INT,
            @fileAndPath VARCHAR(80);

    SET NOCOUNT ON;

    SET @strErrorMessage = 'opening the File System Object';
    EXECUTE @hr = sp_OACreate 'Scripting.FileSystemObject', @objFileSystem OUT;

    SET @fileAndPath = @Path + '\' + @Filename;

    SET @strErrorMessage = 'Creating file ''' + @fileAndPath + '''';
    EXECUTE @hr = sp_OAMethod @objFileSystem, 'CreateTextFile', @objTextStream OUT, @fileAndPath, 2, True;

    SET @strErrorMessage = 'writing to the file ''' + @fileAndPath + '''';
    EXECUTE @hr = sp_OAMethod @objTextStream, 'Write', NULL, @String;

    SET @strErrorMessage = 'closing the file ''' + @fileAndPath + '''';
    EXECUTE @hr = sp_OAMethod @objTextStream, 'Close';

    -- Optional: Handle any errors
    IF @hr <> 0
    BEGIN
        DECLARE @Source VARCHAR(255),
                @Description VARCHAR(255),
                @HelpFile VARCHAR(255),
                @HelpID INT;
        EXECUTE sp_OAGetErrorInfo @objErrorObject,
            @Source OUTPUT, @Description OUTPUT, @HelpFile OUTPUT, @HelpID OUTPUT;
        SELECT @strErrorMessage = 'Error whilst'
            + COALESCE(@strErrorMessage, 'doing something')
            + ' ' + COALESCE(@Description, '');
        RAISERROR (@strErrorMessage, 16, 1);
    END;

    EXECUTE sp_OADestroy @objTextStream;
    EXECUTE sp_OADestroy @objFileSystem;
END;
GO


-- Tạo trigger để kiểm tra dung lượng và ghi cảnh báo
CREATE TRIGGER trg_customer
ON [Event].[Customers] 
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @Space INT
    SET @Space = (SELECT size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS FreeSpaceMB 
                  FROM sys.database_files 
                  WHERE name LIKE 'ShowmanHouse') + 1824;

    IF (@Space < 10000 )
    BEGIN 
        DECLARE @fileName VARCHAR(20) 
        DECLARE @fileLink VARCHAR(70) 
        DECLARE @result INT
        DECLARE @ID INT = 1
        DECLARE @path VARCHAR(70) = 'C:\DATA\Alert'
        SET @fileName = 'Alert' + CONVERT(VARCHAR(5), @ID) + '.txt'
        SET @fileLink = @path + '\' + @fileName
        SET @result = (SELECT DISTINCT dbo.fn_FileExists(@fileLink) AS IsExists 
                       FROM [Event].[Customers])
        WHILE(@result = 1)
        BEGIN 
            SET @ID = @ID + 1 
            SET @fileName = 'Alert' + CONVERT(VARCHAR(5), @ID) + '.txt'
            SET @fileLink = @path + '\' + @fileName
            SET @result = (SELECT DISTINCT dbo.fn_FileExists(@fileLink) AS IsExists 
                           FROM [Event].[Customers])
        END 
        EXEC spWriteStringToFile 'Space fall below 10000KB', @path, @fileName 
    END
END;
GO

--IF OBJECT_ID('spWriteStringToFile', 'P') IS NOT NULL
--    DROP PROCEDURE spWriteStringToFile;
--GO
--IF OBJECT_ID('trg_alert_Customers', 'TR') IS NOT NULL
--    DROP TRIGGER trg_alert_Customers;
--GO
-- Xảy ra lỗi và cấu hình
sp_configure 'show advanced options', 1
GO
RECONFIGURE;
GO
sp_configure 'Ole Automation Procedures', 1
GO
RECONFIGURE;
GO

-- Nhập dữ liệu vào bảng để kiểm tra
select * from [Event].[Customers]
insert into[Event].[Customers]VALUES('NguyenVanb','445TranXuanSoan','HoChiMinh','Quan7','02-554-6587-957-745')
GO

-- Gọi hàm Kiểm tra file có tồn tại trong đường dẫn được chỉ định
SELECT DISTINCT dbo.fn_FileExists('C:\DATA\Alert\Alert1.txt') as IsExists
FROM[Event].[Customers]
GO

-- Tạo thủ tục spWriteStringToFile để ghi chuỗi vào file
CREATE PROCEDURE spWriteStringToFile
    @String VARCHAR(MAX),
    @Path VARCHAR(255),
    @Filename VARCHAR(100)
AS
BEGIN
    DECLARE @objFileSystem INT,
            @objTextStream INT,
            @objErrorObject INT, -- Khai báo biến này
            @strErrorMessage VARCHAR(1000),
            @Command VARCHAR(1000),
            @hr INT,
            @fileAndPath VARCHAR(80);

    SET NOCOUNT ON;

    SET @strErrorMessage = 'opening the File System Object';
    EXECUTE @hr = sp_OACreate 'Scripting.FileSystemObject', @objFileSystem OUT;

    SET @fileAndPath = @Path + '\' + @Filename;

    SET @strErrorMessage = 'Creating file ''' + @fileAndPath + '''';
    EXECUTE @hr = sp_OAMethod @objFileSystem, 'CreateTextFile', @objTextStream OUT, @fileAndPath, 2, True;

    SET @strErrorMessage = 'writing to the file ''' + @fileAndPath + '''';
    EXECUTE @hr = sp_OAMethod @objTextStream, 'Write', NULL, @String;

    SET @strErrorMessage = 'closing the file ''' + @fileAndPath + '''';
    EXECUTE @hr = sp_OAMethod @objTextStream, 'Close';

    -- Optional: Handle any errors
    IF @hr <> 0
    BEGIN
        DECLARE @Source VARCHAR(255),
                @Description VARCHAR(255),
                @HelpFile VARCHAR(255),
                @HelpID INT;
        EXECUTE sp_OAGetErrorInfo @objErrorObject,
            @Source OUTPUT, @Description OUTPUT, @HelpFile OUTPUT, @HelpID OUTPUT;
        SELECT @strErrorMessage = 'Error whilst'
            + COALESCE(@strErrorMessage, 'doing something')
            + ' ' + COALESCE(@Description, '');
        RAISERROR (@strErrorMessage, 16, 1);
    END;

    EXECUTE sp_OADestroy @objTextStream;
    EXECUTE sp_OADestroy @objFileSystem;
END;
GO


-- Tạo trigger để kiểm tra dung lượng và ghi cảnh báo
CREATE TRIGGER trg_eventtype
ON [Event].[EventTypes]
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @Space INT
    SET @Space = (SELECT size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS FreeSpaceMB 
                  FROM sys.database_files 
                  WHERE name LIKE 'ShowmanHouse') + 1824;

    IF (@Space < 10000 )
    BEGIN 
        DECLARE @fileName VARCHAR(20) 
        DECLARE @fileLink VARCHAR(70) 
        DECLARE @result INT
        DECLARE @ID INT = 1
        DECLARE @path VARCHAR(70) = 'C:\DATA\Alert'
        SET @fileName = 'Alerteventype' + CONVERT(VARCHAR(5), @ID) + '.txt'
        SET @fileLink = @path + '\' + @fileName
        SET @result = (SELECT DISTINCT dbo.fn_FileExists(@fileLink) AS IsExists 
                       FROM [Event].[EventTypes])
        WHILE(@result = 1)
        BEGIN 
            SET @ID = @ID + 1 
            SET @fileName = 'Alerteventype' + CONVERT(VARCHAR(5), @ID) + '.txt'
            SET @fileLink = @path + '\' + @fileName
            SET @result = (SELECT DISTINCT dbo.fn_FileExists(@fileLink) AS IsExists 
                           FROM [Event].[EventTypes])
        END 
        EXEC spWriteStringToFile 'Space fall below 10000KB', @path, @fileName 
    END
END;
GO
INSERT INTO Event.EventTypes ( Description, ChargePerPerson)
VALUES 
('Reference', 50.00)
SELECT DISTINCT dbo.fn_FileExists('C:\DATA\Alert\Alert1.txt') as IsExists
FROM[Event].[Customers]
GO
--
-- Tạo trigger để kiểm tra dung lượng và ghi cảnh báo
CREATE TRIGGER trg_employee
ON [HumanResources].[Employee]
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @Space INT
    SET @Space = (SELECT size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS FreeSpaceMB 
                  FROM sys.database_files 
                  WHERE name LIKE 'ShowmanHouse') + 1824;

    IF (@Space < 10000 )
    BEGIN 
        DECLARE @fileName VARCHAR(20) 
        DECLARE @fileLink VARCHAR(70) 
        DECLARE @result INT
        DECLARE @ID INT = 1
        DECLARE @path VARCHAR(70) = 'C:\DATA\Alert'
        SET @fileName = 'Alertemployee' + CONVERT(VARCHAR(5), @ID) + '.txt'
        SET @fileLink = @path + '\' + @fileName
        SET @result = (SELECT DISTINCT dbo.fn_FileExists(@fileLink) AS IsExists 
                       FROM [HumanResources].[Employee])
        WHILE(@result = 1)
        BEGIN 
            SET @ID = @ID + 1 
            SET @fileName = 'Alertemployee' + CONVERT(VARCHAR(5), @ID) + '.txt'
            SET @fileLink = @path + '\' + @fileName
            SET @result = (SELECT DISTINCT dbo.fn_FileExists(@fileLink) AS IsExists 
                           FROM [HumanResources].[Employee])
        END 
        EXEC spWriteStringToFile 'Space fall below 10000KB', @path, @fileName 
    END
END;
GO
INSERT INTO [HumanResources].Employee
VALUES('Bao','Lam','23TranDInhTrong','02-525-4587-364-985','Executive')
GO
SELECT DISTINCT dbo.fn_FileExists('C:\DATA\Alert\Alertemployee.txt') as IsExists
FROM[Event].[Customers]
GO
--

CREATE TRIGGER trg_magevents
ON [Management].[Events]
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @Space INT
    SET @Space = (SELECT size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS FreeSpaceMB 
                  FROM sys.database_files 
                  WHERE name LIKE 'ShowmanHouse') + 1824;

    IF (@Space < 10000 )
    BEGIN 
        DECLARE @fileName VARCHAR(20) 
        DECLARE @fileLink VARCHAR(70) 
        DECLARE @result INT
        DECLARE @ID INT = 1
        DECLARE @path VARCHAR(70) = 'C:\DATA\Alert'
        SET @fileName = 'Alertmagevent' + CONVERT(VARCHAR(5), @ID) + '.txt'
        SET @fileLink = @path + '\' + @fileName
        SET @result = (SELECT DISTINCT dbo.fn_FileExists(@fileLink) AS IsExists 
                       FROM [Management].[Events])
        WHILE(@result = 1)
        BEGIN 
            SET @ID = @ID + 1 
            SET @fileName = 'Alertmagevent' + CONVERT(VARCHAR(5), @ID) + '.txt'
            SET @fileLink = @path + '\' + @fileName
            SET @result = (SELECT DISTINCT dbo.fn_FileExists(@fileLink) AS IsExists 
                           FROM [Management].[Events])
        END 
        EXEC spWriteStringToFile 'Space fall below 10000KB', @path, @fileName 
    END
END;
GO
INSERT INTO Management.Events (EventName, NoOfPeople, StartDate,EndDate,Location)
VALUES 
('Tech Conference',  100, '2024-07-01','2024-07-31','vn')
SELECT DISTINCT dbo.fn_FileExists('C:\DATA\Alert\Alertemployee.txt') as IsExists
FROM[Event].[Customers]
GO
--
CREATE TRIGGER trg_magpaymethod
ON [Management].[PaymentMethods]
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @Space INT
    SET @Space = (SELECT size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS FreeSpaceMB 
                  FROM sys.database_files 
                  WHERE name LIKE 'ShowmanHouse') + 1824;

    IF (@Space < 10000 )
    BEGIN 
        DECLARE @fileName VARCHAR(20) 
        DECLARE @fileLink VARCHAR(70) 
        DECLARE @result INT
        DECLARE @ID INT = 1
        DECLARE @path VARCHAR(70) = 'C:\DATA\Alert'
        SET @fileName = 'Alertmagpaymethod' + CONVERT(VARCHAR(5), @ID) + '.txt'
        SET @fileLink = @path + '\' + @fileName
        SET @result = (SELECT DISTINCT dbo.fn_FileExists(@fileLink) AS IsExists 
                       FROM [Management].[PaymentMethods])
        WHILE(@result = 1)
        BEGIN 
            SET @ID = @ID + 1 
            SET @fileName = 'Alertmagpaymethod' + CONVERT(VARCHAR(5), @ID) + '.txt'
            SET @fileLink = @path + '\' + @fileName
            SET @result = (SELECT DISTINCT dbo.fn_FileExists(@fileLink) AS IsExists 
                           FROM [Management].[PaymentMethods])
        END 
        EXEC spWriteStringToFile 'Space fall below 10000KB', @path, @fileName 
    END
END;
GO
INSERT INTO Management.PaymentMethods
VALUES('Credit Card')
GO
--
CREATE TRIGGER trg_magpay
ON [Management].[Payments]
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @Space INT
    SET @Space = (SELECT size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS FreeSpaceMB 
                  FROM sys.database_files 
                  WHERE name LIKE 'ShowmanHouse') + 1824;

    IF (@Space < 10000 )
    BEGIN 
        DECLARE @fileName VARCHAR(20) 
        DECLARE @fileLink VARCHAR(70) 
        DECLARE @result INT
        DECLARE @ID INT = 1
        DECLARE @path VARCHAR(70) = 'C:\DATA\Alert'
        SET @fileName = 'Alertmagpay' + CONVERT(VARCHAR(5), @ID) + '.txt'
        SET @fileLink = @path + '\' + @fileName
        SET @result = (SELECT DISTINCT dbo.fn_FileExists(@fileLink) AS IsExists 
                       FROM [Management].[Payments])
        WHILE(@result = 1)
        BEGIN 
            SET @ID = @ID + 1 
            SET @fileName = 'Alertmagpay' + CONVERT(VARCHAR(5), @ID) + '.txt'
            SET @fileLink = @path + '\' + @fileName
            SET @result = (SELECT DISTINCT dbo.fn_FileExists(@fileLink) AS IsExists 
                           FROM [Management].[Payments])
        END 
        EXEC spWriteStringToFile 'Space fall below 10000KB', @path, @fileName 
    END
END;
GO
INSERT INTO Management.Payments ( EventID,EventTypeID,StartDate, PaymentDate, PaymentMethodID, CreditCardNumber, CardHoldersName, CreditCardExpDate, ChequeNo,PaymentAmount)
VALUES 
( 13,502,'2024-07-01', null, 1, '1234-5678-9012-3456', 'tandat1', '2025-07-01', 123456,8)