USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_Load_UserLoginData]    Script Date: 10/22/2015 1:04:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_Load_UserLoginData]
 @Year int,
 @Month int
AS
Declare @FirstDayOfMOnth smalldatetime
set @FirstDayOfMOnth= CONVERT(varchar,@Month) + '/1/' + CONVERT(varchar,@Year)

BEGIN

create Table #TempUserLogin
(UserLoginId int, Login nvarchar(50), LastLogin datetime, BrokerId int , NetworkId int , TradingProductId int)

Insert into #TempUserLogin
select * from chisql12.fillhub.dbo.UserLogin
where Year(LastLogin)=@year and Month(LastLogin)=@month


Create Table #TempUser
(UserId int, BillingAccountId nvarchar(200), NetworkId int, UserName nvarchar(200), FullName nvarchar(200), CountryCode varchar(20), City nvarchar(200), PostalCode nvarchar(20), 
CustomField1 nvarchar(200), CustomField2 nvarchar(200), CustomField3 nvarchar(200), LastUpdatedDate datetime, FileUploadId uniqueidentifier, BrokerId int, 
Month int, Year int, X_TraderProEnabled bit,State nvarchar(50))

Insert into #TempUser
select UserId,BillingAccountId,NetworkId,UserName,FullName,CountryCode,City,PostalCode, 
CustomField1,CustomField2,CustomField3,LastUpdatedDate,FileUploadId,BrokerId, 
Month,Year,X_TraderProEnabled,State from chisql12.fillhub.dbo.[user]
where year=@year and month=@month


create table #TempCompany
(CompanyId int, CompanyName nvarchar(500), NetworkId int)

insert into #TempCompany
select CompanyId, CompanyName, NetworkId from chisql12.fillhub.dbo.company


Create Table #TempProducts
(ProductID smallint, ProductTypeAbbr char(1), ProductActiveFlag bit, ProductName varchar(30), ProductStatic bit, ParentFlag bit)

insert into #TempProducts
select * from chisql12.fillhub.dbo.Products


Create Table #Current
(Year int, Month int,Username varchar(50), Accountid varchar(50),AccountName varchar(100),BrokerID int,Company varchar(200),NetworkId int,ProductId int, ProductName varchar(50),
firstlogin datetime, LastLogin datetime,Masteraccountname varchar(100),Platform varchar(50),LastUpdatedDate datetime)

Insert into #current
select A.Year, A.Month,A.UserName,BillingAccountId as AccountId, AccountName,A.BrokerId, Company,A.NetworkId, ProductId,ProductName,
 LastLogin as FirstLogin,LastLogin,MasterAccountName,
 case when A.networkid=1104 then '7xASP' when A.networkid<>1104 then '7xUniBroker' End as Platform, GETDATE() as LastUpdatedDate
from
(
select distinct Year(LastLogin) as Year, Month(LastLogin) as Month,Login as username,ul.NetworkId, Tradingproductid as ProductId,ProductName,
Null as FirstLogin, LastLogin,Null as Customer, BrokerId, CompanyName as Company  from #TempUserLogin UL
left join (select * from #TempCompany) C
on ul.brokerid=c.companyid and ul.networkid=c.networkid
left join (select * from #TempProducts
where ProductTypeAbbr='C')P
on ul.tradingproductid=productid
where Year(LastLogin)=@year and Month(LastLogin)=@month
--and login ='TTOFARI'
)A
left join 
(
select distinct Year,Month,Username,billingaccountid,AccountName,MasterAccountName,Networkid,Brokerid from #TempUser U
left join Account A
on u.billingaccountid=A.Accountid
where year=@year and month=@month
--and username ='TTOFARI'
) B
on A.Year=b.year and a.Month=b.month and a.Username =b.username and a.networkid=b.networkid and a.brokerid=b.brokerid
where cast(Productid as char(2))+cast(A.username as char)+cast(A.NetworkId as char) in 
(
select cast(Productid as char(2))+cast(username as char)+cast(networkid as char) from
(
select distinct Login as Username,TradingProductId as Productid,NetworkId,BrokerId from #TempUserLogin
except
select distinct username, productid,NetworkId,BrokerId from UserLogin 
where year=@year and month=@month
)q
)


--Delete dbo.UserLogin
--where YEAR=@year and Month=@month
Insert into dbo.UserLogin
select * from #Current



update U
set U.lastlogin=T.lastlogin
from UserLogin U
left join #TempUserLogin T
on U.username=T.login and u.ProductId=t.TradingProductId and u.NetworkId=t.NetworkId
where u.year=@year and u.month=@month
and cast(u.Productid as char(2))+cast(u.username as char)+cast(U.NetworkId as char) in 
(
select cast(Productid as char(2))+cast(username as char)+cast(networkid as char) from
(
select distinct Login as Username,TradingProductId as Productid,NetworkId,BrokerId,lastlogin from #TempUserLogin
except
select distinct username, productid,NetworkId,BrokerId,lastlogin from UserLogin 
where year=@year and month=@month
)q
)

drop table #TempUserLogin
drop table #TempUser
drop table #TempProducts
drop table #TempCompany
drop table #Current

END