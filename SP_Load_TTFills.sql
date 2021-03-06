USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_Load_TTFills]    Script Date: 11/1/2016 10:37:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Ram>
-- Create date: <08/08/2013:1630>
-- Description:	<Load Aggregated FillHub Data to DWH>
-- =============================================
ALTER PROCEDURE [dbo].[SP_Load_TTFills]
(@CurrentYear int,@CurrentMonth int)
AS

BEGIN
SET NOCOUNT ON;


BEGIN

-----Delete and Load TTCompanies Dimension Data-------------
Delete BIDW.dbo.TTCompanies
Insert Into BIDW.dbo.TTCompanies
SELECT [CompanyId],[Name] as CompanyName,[CompanyAbbr],[isUniversity],[isTT]
FROM Chisql20.[MESS].[dbo].[Companies]


--------------Load TT Fills Data into Fills Table in BIDW---------
Create table #AggregatedFills
(Year Int, Month Int, CompanyId Int, BrokerId int, BillingAccountid varchar(20),Userid varchar(20),UserName varchar(100),
Marketid int,Axproductid int,Quantity int,Volume int,Instrumentid varchar(200),ProductTypeId int,Transactiondate datetime,
RevDestination varchar(4),ProductName varchar(50),GeneratedDate datetime,Email varchar(100),Filltype varchar(50)
)


Insert Into #AggregatedFills
Select x.Year,x.Month,Companyid,BrokerId,inv.billingaccountid as BillingAccountId,x.UserId, Username
,MarketId,x.AxProductId,Quantity,Volume,InstrumentId,ProductTypeId,Transactiondate 
,x.RevDestination,ProductName,x.GeneratedDate,Email,Filltype from 
(
SELECT distinct f.Year,f.Month,u.Companyid,f.BrokerId,c.BillingAccount as BillingAccountId,f.UserId,left(u.firstname,1)+u.lastname as Username
,f.MarketId,isnull(pm.AXItemId,80003) as AxProductId,Quantity,Volume,f.InstrumentId,ep.ProductTypeId,Transactiondate 
,case 
when f.MarketId = 0 then 'kong'
when CHARINDEX('-b',BillingAccount)>5  then 'ttbr'
when ProductTypeId = 45  then 'brdl'   ---has product type of security
else 'ttus'
end as RevDestination,Symbol as ProductName,getdate() as GeneratedDate,U.Email,Filltype
FROM (
SELECT    DATEPART(year, TransactTime) AS YEAR, DATEPART(month, TransactTime) AS MONTH,Cast(TransactTime as Date) as Transactiondate,UserId,BrokerId
,MarketId,f.InstrumentId,Filltype,SUM(LastQty) AS Quantity,sum(case when lotsize is null then lastQty else LastQty*LotSize end) as Volume FROM chisql20.ttfills.dbo.fills f  
left join 
(SELECT Distinct [InstrumentId] ,[LotSize] FROM chisql20.[MESS].[dbo].[Instruments]) I on F.InstrumentId=I.InstrumentId
WHERE YEAR(TransactTime) = @CurrentYear AND MONTH(TransactTime) = @CurrentMonth 
GROUP BY DATEPART(year, TransactTime), DATEPART(month, TransactTime), UserId, BrokerId,MarketId,f.InstrumentId,Cast(TransactTime as Date),Filltype
) as f
left JOIN chisql20.MESS.dbo.users u ON u.userid = f.userid
left JOIN chisql20.MESS.dbo.UserTradeMode utm on u.userid = utm. userid and utm.year=@CurrentYear and utm.month = @CurrentMonth--and utm.year = @year
left JOIN chisql20.MESS.dbo.CompanyMapping c ON c.CompanyId = u.companyid
left join chisql20.MESS.dbo.Instruments i on f.[InstrumentId] = i.[InstrumentId] and f.MarketId = i.marketid  
left join chisql20.MESS.dbo.ExchangeProducts ep on i.Productid = ep.Productid
left join chisql20.Mess.dbo.ProductMap pm on pm.TTTradeMode  = utm.trademodeid  and pm.BillingMode = 'Transaction'
WHERE f.YEAR = @CurrentYear AND f.MONTH = @CurrentMonth
)X
Left join chisql20.[TTFills].[dbo].[InvoiceableFills] Inv 
on x.year=inv.year and x.month=inv.month and x.userid=inv.userid and x.AxProductId=inv.AxProductId and x.RevDestination=inv.RevDestination



Delete BIDW.dbo.fills
where year=@CurrentYear and month=@CurrentMonth and platform='TTWEB'
Insert into BIDW.dbo.fills
Select isnull((select max(fillid) from chisql12.bidw.dbo.Fills),0) +row_number() over (order by year) as FillId,Year,Month,Username,BrokerId,CompanyId,ExchangeId,NetworkId, MarketId,AccountId,
AxProductId,ProductType,isnull(ProductName,'-') as ProductName,FillType,FillStatus,sum(Fills) as Fills,FixAdapterName,OpenClose,OrderFlags,LastOrderSource,FirstOrderSource,
OrderSourceHistory,FillCategoryId,Version,TransactionDate,BillingServerDate,IsBillable,count(fills) as FillsCountByDate,MDT,FunctionalityArea,DayOfMonth,
FillStatusDesc,sum(Contracts) as Contracts,DataAreaId,'TTWEB' as Platform,sum(Volume) as Volume,Userid,Getdate() as LastUpdatedDate from
(
SELECT 	Year, Month,isnull(nullif(Email,''),UserId) as UserName,BrokerId,CompanyId,0 as ExchangeId,1 as NetworkId, f.MarketId, BillingAccountid as AccountId,
AxProductId,isnull(f.ProductTypeId,0) as ProductType,ProductName,FillType,'2048' as FillStatus,
Quantity as Fills,'' as FixAdapterName,0 as OpenClose,0 as OrderFlags,0 as LastOrderSource, 0 as FirstOrderSource,
'' as OrderSourceHistory,0 as FillCategoryId,0 as Version,TransactionDate,
 --(select DATEADD(day,-1,DATEADD(month,@CurrentMonth,DATEADD(year,@CurrentYear-1900,0)))) as TransactionDate,
  '' as BillingServerDate, 'Y' as IsBillable,
0 as FillsCountByDate,'MDT' as MDT, 'TBD' as FunctionalityArea, '' as DayOfMOnth, '' as FillStatusDesc, Quantity as Contracts, '' as DataAreaId,Volume,UserId
FROM #AggregatedFills f
)Q
Group by Year,Month,Username,BrokerId,CompanyId,ExchangeId,NetworkId, MarketId,AccountId,
AxProductId,ProductType,ProductName,FillType,FillStatus,FixAdapterName,OpenClose,OrderFlags,LastOrderSource,FirstOrderSource,
OrderSourceHistory,FillCategoryId,Version,TransactionDate,BillingServerDate,IsBillable,MDT,FunctionalityArea,DayOfMOnth,
FillStatusDesc,Contracts,DataAreaId,Userid
END

-----------------------------------Load User Data --------------------------------------

Delete Bidw.[dbo].[User]
where year=@CurrentYear and month=@CurrentMonth and platform='TTWEB'
Insert Into Bidw.[dbo].[User]
select distinct (select max(Id) from chisql12.bidw.dbo.[user])+row_number() over (order by id) as Userid
--cast(ltrim(rtrim(cast(U.UserId as char(50))))+ltrim(rtrim(str(row_number() over (partition by u.userid order by A.BillingAccountId)))) as bigint) as UserId
,UserName,BillingAccountId as AccountId,NetworkId,FullName,isnull(CountryCode,'') as CountryCode,isnull(City,'') as City
,isnull(PostalCode,0) as PostalCode,X_TraderProEnabled,CustomField1,CustomField2,CustomField3
,u.Year,u.Month,State,Platform,Id as Userid,LastUpdatedDate from
(
SELECT Userid as Id,
cast(cast(@CurrentYear as char(4))+rtrim(cast(@CurrentMonth as char(2)))+rtrim(cast([UserId] as char(50))) as bigint) as userId
      ,isnull(nullif(Email,''),UserId) as UserName
      --,lower(left(firstname,1)+lastname) as [Username]
      ,'' as [AccountId]
      ,1 as [NetworkId]
      ,FirstName+' '+LastName as [FullName]
      ,[CountryCode]
      ,[City]
      ,zipcode as [PostalCode]
      ,0 as [X_TraderProEnabled]
      ,'' as[CustomField1]
      ,'' as [CustomField2]
      ,'' as [CustomField3]
      ,@CurrentYear as [Year]
      ,@CurrentMonth as [Month]
      ,statecode as [State]
      ,'TTWEB' as [Platform]
      ,getdate() as [LastUpdatedDate]
  FROM chisql20.[MESS].[dbo].[Users]) U
  left join (Select distinct Year,Month,Userid,BillingAccountId from #AggregatedFills
  where year=@CurrentYear and month=@CurrentMonth) A 
  on U.year=A.Year and u.month=A.month and U.Id=A.Userid

------------------------------------------Load User Login Data-----------------------------------------------------
Delete BIDW.[dbo].[UserLogin]
where year=@CurrentYear and month=@CurrentMonth and platform='TTWEB'
Insert into BIDW.[dbo].[UserLogin]
SELECT distinct
      H.[Year]
      ,H.[Month]
	   ,isnull(nullif(u.Email,''),u.UserId) as UserName
      --,lower(left(firstname,1)+lastname) as [Username] 
      ,nullif(BillingAccountId,'') as AccountId
      ,[AccountName]
      ,0 as [BrokerId]
      ,CompanyId as [Company]
      ,1 as [NetworkId]
      ,0 as [ProductId]
      ,'' as [ProductName]
      ,u.[FirstLogin]
      ,u.[LastLogin]
      ,[MasterAccountName]
	  , 'TTWEB' as Platform
	  , U.Userid
      ,getdate() as [LastUpdatedDate]
  FROM chisql20.[MESS].[dbo].[UserLoginhistory] H
  left join chisql20.MESS.[dbo].[Users] U
  on h.userid=u.userid
   left join (Select distinct Year,Month,Userid,BillingAccountId from #AggregatedFills
  where year=@CurrentYear and month=@CurrentMonth) F 
   on H.year=F.Year and H.month=F.month and H.userId=F.Userid
   Left join (Select AccountId,AccountName,MasterAccountName from chisql12.BIDW.dbo.Account where AccountId not like 'LGCY%') A
   on F.BillingAccountId=A.accountid
   where h.year=@CurrentYear and h.month=@CurrentMonth


------------------------Temp Code to Make Algo as Non-Billable MarketId=1001 05/03/2016-------------------

update [dbo].[Fills]
set IsBillable='N', FillStatusDesc='NoBillingAccount-AggregationException',FillStatus=5120
where year=@CurrentYear and month=@CurrentMonth and platform='TTWEB' and marketid=1001

END
