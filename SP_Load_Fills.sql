USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_Load_Fills]    Script Date: 7/27/2015 3:44:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Ram>
-- Create date: <08/08/2013:1630>
-- Description:	<Load Aggregated FillHub Data to DWH>
-- =============================================
ALTER PROCEDURE [dbo].[SP_Load_Fills]
AS

BEGIN
SET NOCOUNT ON;
declare @CurrentYear int;
declare @PriorYear int;
declare @CurrentMonth int;
declare @PriorMonth int

set @CurrentYear=YEAR(getdate())
set @CurrentMonth=MONTH(getdate())
set @PriorYear= (case when MONTH(getdate())=1 then YEAR(getdate())-1 else YEAR(getdate()) end)  -- <Ram 1/10/2014 11:35 AM> Load Only Non-Invoiced Months Data - Jira BI-80
set @PriorMonth = (case when MONTH(getdate())=1 then 12 else MONTH(getdate())-1 end)

if (select count(*) from chisql12.fillhub.dbo.fills
where year=@CurrentYear and month in (@PriorMonth,@CurrentMonth)) > 0

BEGIN

/***********************************************Delete and Load BrokerMapTable************************************************************************/
--Delete TABLE dbo.BrokerMap
--INSERT INTO dbo.BrokerMap
--select BuySideId, BrokerId, NetworkId, '' as StartDate, '' as EndDate from chisql12.fillhub.dbo.BrokerMap

Insert Into dbo.BrokerMap  ---- <Ram: 5/30/2014> Tracking the Broker n Buyside relationships with Start and End Dates
select BuySideId, BrokerId, NetworkId, GETDATE() as StartDate, '' as Enddate
from
(
select BuySideId, BrokerId, NetworkId from chisql12.fillhub.dbo.BrokerMap
except
select BuySideId, BrokerId, NetworkId from dbo.BrokerMap
)Q


Update B
set EndDate=GETDATE()
from BrokerMap B 
join
(
select BuySideId, BrokerId, NetworkId from dbo.BrokerMap
where EndDate=''
except
select BuySideId, BrokerId, NetworkId from chisql12.fillhub.dbo.BrokerMap
)C
on b.BuySideId=c.BuySideId and b.BrokerId=c.BrokerId and b.NetworkId=c.NetworkId


/*************************************************************************************************************************************************************/

/***********************************************Delete and Load Company Table************************************************************************/
Delete dbo.Company
INSERT INTO dbo.Company
select C.CompanyId, NetworkId, CompanyName,MasterAccountName as MBMasterCustomerName,IsBroker  from chisql12.fillhub.dbo.Company C
left join (SELECT  distinct MasterAccountName,[CompanyId]  
FROM [fillhub].[dbo].[BillingAccountCompanyMap] M
join (select * from bidw.dbo.Account where Accountid not like 'LGCY%')A
on m.CrmId=a.crmid) D
on c.CompanyId=d.CompanyId
where Companyname<>'<Company1>'
/*************************************************************************************************************************************************************/


/***********************************************Delete and Load Exchange Table************************************************************************/
Delete dbo.Exchange
INSERT INTO dbo.Exchange
select ExchangeId,ExchangeShortName as ExchangeFlavor,rtrim(case when charindex('-',ExchangeName)=0 then ExchangeName
when ExchangeName like 'LIFFE-Equity Options%' then 'LIFFE-Equity Options'
else replace(SUBSTRING(exchangename,1,(charindex('-',ExchangeName))),'-','') end) as ExchangeName, ExchangeActiveFlag
from
(
select ExchangeId, ExchangeShortName, 
 replace(case 
when exchangename='London International Financial Futures Exchange' then 'LIFFE'
when ExchangeName like 'Chicago Mercantile Exchange%' then 'CME'
else exchangename end,' ','-') as ExchangeName, ExchangeActiveFlag
from chisql12.fillhub.dbo.Exchanges
)E
order by 3,4

Insert into dbo.Exchange
(ExchangeId,ExchangeFlavor,ExchangeName,ExchangeActiveFlag)
Values (9999,'EEX','EEX',1)
/*************************************************************************************************************************************************************/

/***********************************************Delete and Load ExchangeProducts Table************************************************************************/
Delete dbo.ExchangeProducts
Insert Into dbo.ExchangeProducts
select row_number() over (order by Name) as Id,Name as ProductName, ProductSymbol, ProductClass, ProductType, Exchange, Gateway, AssetType, Currency, ActivationDate
 from chisql01.exchangeproducts .dbo.exchangeproducts
 
/*************************************************************************************************************************************************************/ 
 
/***********************************************Delete Load and update Market Table************************************************************************/
Delete dbo.Market
INSERT INTO dbo.Market
SELECT MarketID, MarketShortName, MarketName, CoreMarketId, MarketActiveFlag FROM chisql12.fillhub.dbo.Markets

   update M
   set M.CoreMarketId=E.CoreMarketId
  from dbo.Market M, chisql12.fillhub.dbo.Exchanges E
  where M.MarketID=E.MarketID
/*************************************************************************************************************************************************************/

/***********************************************Delete and Load Ordersource Table************************************************************************/
Delete dbo.OrderSource
INSERT INTO dbo.OrderSource
select OS.OrderSourceNumber,OSR.OrderSourceRuleId,OS.[Description],OSR.Name AS RuleName,OSR.AxProductId,OSR.Precedence,OSR.MultiBrokerAxProductId
from
chisql12.fillhub.dbo.OrderSource OS
full OUTER join chisql12.fillhub.dbo.OrderSourceRuleOrderSource OSRO
on OS.OrderSourceNumber=OSRO.OrderSourceNumber
full outer JOIN chisql12.fillhub.dbo.OrderSourceRule OSR
ON OSRO.OrderSourceRuleId=OSR.OrderSourceRuleId
/*************************************************************************************************************************************************************/

/***********************************************Delete and Load User Table************************************************************************/
DELETE dbo.[User]
where YEAR in (YEAR(getdate()))
INSERT INTO dbo.[User]
select UserId, UserName, BillingAccountId as AccountId, NetworkId, FullName, CountryCode, City, 
rtrim(case when countrycode='US' and len(PostalCode)>5 then SUBSTRING(postalcode,1,5) else postalcode end) as PostalCode,
X_TraderProEnabled,CustomField1,CustomField2,CustomField3 ,Year,Month,State, getdate() as LastUpdatedDate from chisql12.fillhub.dbo.[User]
where YEAR in (YEAR(getdate()))

update A
set A.State=B.State 
from [User] A 
left join BIDW_ODS.dbo.zipcodemapping B
on a.PostalCode=b.zipcode
where YEAR=YEAR(getdate()) 
and CountryCode='US'
and (a.State is null or a.State='<None>')
/*************************************************************************************************************************************************************/

/***********************************************Delete and Load Fill Product Type Table************************************************************************/
DELETE dbo.[FillProductType]
INSERT INTO dbo.[FillProductType]
select *,Getdate() as LastUpdatedDate from Fillhub.dbo.FillProductType

/*************************************************************************************************************************************************************/
END

/***********************************************Delete and Load Prior Month Fills Daily************************************************************************/
if (select COUNT(*) from chisql12.fillhub.dbo.invoicemonth   -- <Ram 1/10/2014 11:35 AM> Load Only Non-Invoiced Months Data - Jira BI-80
 where YEAR=@PriorYear AND MONTH =@PriorMonth) = 0
begin
create table #FillsPrior
([FillId] [bigint] NOT NULL,[Year] [int] NOT NULL,[Month] [int] NOT NULL,[UserName] [varchar](50) NOT NULL,[BrokerId] [int] NULL,[CompanyId] [int] NULL,
	[ExchangeId] [int] NOT NULL,[NetworkId] [int] NOT NULL,[MarketId] [int] NOT NULL,[AccountId] [nvarchar](50) NULL,[AxProductId] [varchar](15) NULL,
	[ProductType] [int] NOT NULL,[ProductName] [nvarchar](50) NOT NULL,[FillType] [int] NOT NULL,[FillStatus] [int] NOT NULL,[Fills] [bigint] NOT NULL,
	[FixAdapterName] [nvarchar](50) NOT NULL,[OpenClose] [int] NOT NULL,[OrderFlags] [int] NOT NULL,[LastOrderSource] [int] NOT NULL,[FirstOrderSource] [int] NOT NULL,
	[OrderSourceHistory] [nvarchar](100) NOT NULL,[FillCategoryId] [int] NULL,[Version] [int] NULL,[TransactionDate] [date] NOT NULL,
	[BillingServerDate] [date] NOT NULL,[IsBillable] [char](10) NULL,[FillsCountbydate] [int] NULL,	[MDT] [char](10) NULL,	[FunctionalityArea] [varchar](50) NULL,
	[DayofMonth] [varchar] (10) NULL,FillStatusDesc varchar(100) NULL,Contracts [bigint] NOT NULL,DataAreaId [varchar](50) NULL,[LastUpdatedDate] [datetime] NULL)
INSERT INTO #FillsPrior
select isnull((select max(fillid) from dbo.Fills),0) +row_number() over (order by f.year) as FillId, 
f.[Year], f.[Month],f.UserName, f.[broker] as [BrokerId], f.company as CompanyId, f.ExchangeId, f.NetworkId, f.MarketId,f.BillingAccountId as AccountId, f.AxProductId, f.ProductType, f.ProductName,  f.FillType, f.FillStatus, 
case when fillcategoryid=14 then sum((f.ShortQty+f.LongQty)*f.MegawattHours) else sum((f.ShortQty+f.LongQty)*f.LotSize) end as Fills, f.FixAdapterName, f.OpenClose, f.OrderFlags, f.LastOrderSource, f.FirstOrderSource, f.OrderSourceHistory,
   f.FillCategoryId, f.[Version], cast(f.TransactionDateTime as date) as TransactionDate, cast(f.BillingServerDateTime as date) as BillingServerDate, 
(case when f.fillstatus=2048 then 'Y' else 'N' end) as IsBillable, count(f.fillid) as CountsPerFillId
, '' as MDT, '' as FunctionalityArea, '' as DayofMonth, '' as FillStatusDesc,sum(f.ShortQty+f.LongQty) as Contracts,RevenueDestination as DataAreaId
,GETDATE() as lastupdateddate
from chisql12.fillhub.dbo.Fills F
WHERE YEAR=@PriorYear AND 
MONTH =@PriorMonth 
group by 
f.[Year], f.[Month],F.username, f.[broker], f.company, f.ExchangeId, f.NetworkId, f.MarketId,f.BillingAccountId, f.AxProductId, f.ProductType, f.ProductName,  f.FillType, f.FillStatus,f.FixAdapterName, f.OpenClose, f.OrderFlags, f.LastOrderSource, f.FirstOrderSource, f.OrderSourceHistory,  f.FillCategoryId, f.[Version], cast(f.TransactionDateTime as date), cast(f.BillingServerDateTime as date) 
,(case when f.fillstatus=2048 then 'Y' else 'N' end),RevenueDestination
order by cast(f.TransactionDateTime as date)

if (select COUNT(*) from #FillsPrior)>0 
begin
DELETE dbo.Fills
WHERE YEAR=@PriorYear AND 
MONTH =@PriorMonth
insert into dbo.Fills
select * from #FillsPrior
exec dbo.SP_UpdateOrderSourceHistory @PriorYear,@PriorMonth
exec dbo.SP_Load_UserLoginData @PriorYear,@PriorMonth
exec dbo.SP_Load_LastLoginData @PriorYear,@PriorMonth  -- <Ram 11/03/2014> Load Prior Month Data till the billing is closed for that Month
drop table #FillsPrior
end
end

/***********************************************Delete and Load Current Month Fills Daily************************************************************************/
if (select COUNT(*) from chisql12.fillhub.dbo.invoicemonth   -- <Ram 1/10/2014 11:35 AM> Load Only Non-Invoiced Months Data - Jira BI-80
 where YEAR=@CurrentYear AND 
MONTH =@CurrentMonth) = 0
begin
create table #FillsCurrent
([FillId] [bigint] NOT NULL,[Year] [int] NOT NULL,[Month] [int] NOT NULL,[UserName] [varchar](50) NOT NULL,[BrokerId] [int] NULL,[CompanyId] [int] NULL,
	[ExchangeId] [int] NOT NULL,[NetworkId] [int] NOT NULL,[MarketId] [int] NOT NULL,[AccountId] [nvarchar](50) NULL,[AxProductId] [varchar](15) NULL,
	[ProductType] [int] NOT NULL,[ProductName] [nvarchar](50) NOT NULL,[FillType] [int] NOT NULL,[FillStatus] [int] NOT NULL,[Fills] [bigint] NOT NULL,
	[FixAdapterName] [nvarchar](50) NOT NULL,[OpenClose] [int] NOT NULL,[OrderFlags] [int] NOT NULL,[LastOrderSource] [int] NOT NULL,[FirstOrderSource] [int] NOT NULL,
	[OrderSourceHistory] [nvarchar](100) NOT NULL,[FillCategoryId] [int] NULL,[Version] [int] NULL,[TransactionDate] [date] NOT NULL,
	[BillingServerDate] [date] NOT NULL,[IsBillable] [char](10) NULL,[FillsCountbydate] [int] NULL,	[MDT] [char](10) NULL,	[FunctionalityArea] [varchar](50) NULL,
	[DayofMonth] [varchar] (10) NULL,FillStatusDesc varchar(100) NULL,Contracts [bigint] NOT NULL,DataAreaId [varchar](50) NULL,[LastUpdatedDate] [datetime] NULL)
INSERT INTO #FillsCurrent
select isnull((select max(fillid) from dbo.Fills),0) +row_number() over (order by f.year) as FillId, 
f.[Year], f.[Month],f.UserName, f.[broker] as [BrokerId], f.company as CompanyId, f.ExchangeId, f.NetworkId, f.MarketId,f.BillingAccountId as AccountId, f.AxProductId, f.ProductType, f.ProductName,  f.FillType, f.FillStatus, 
case when fillcategoryid=14 then sum((f.ShortQty+f.LongQty)*f.MegawattHours) else sum((f.ShortQty+f.LongQty)*f.LotSize) end as Fills, f.FixAdapterName, f.OpenClose, f.OrderFlags, f.LastOrderSource, f.FirstOrderSource, f.OrderSourceHistory,
   f.FillCategoryId, f.[Version], cast(f.TransactionDateTime as date) as TransactionDate, cast(f.BillingServerDateTime as date) as BillingServerDate, 
(case when f.fillstatus=2048 then 'Y' else 'N' end) as IsBillable, count(f.fillid) as CountsPerFillId
, '' as MDT, '' as FunctionalityArea,'' as DayofMonth, '' as FillStatusDesc,sum(f.ShortQty+f.LongQty) as Contracts,RevenueDestination as DataAreaId
,GETDATE() as lastupdateddate
from chisql12.fillhub.dbo.Fills F
WHERE YEAR=@CurrentYear AND MONTH =@CurrentMonth 
group by 
f.[Year], f.[Month],F.username, f.[broker], f.company, f.ExchangeId, f.NetworkId, f.MarketId,f.BillingAccountId, f.AxProductId, f.ProductType, f.ProductName,  f.FillType, f.FillStatus,f.FixAdapterName, f.OpenClose, f.OrderFlags, f.LastOrderSource, f.FirstOrderSource, f.OrderSourceHistory,  f.FillCategoryId, f.[Version], cast(f.TransactionDateTime as date), cast(f.BillingServerDateTime as date) 
,(case when f.fillstatus=2048 then 'Y' else 'N' end),RevenueDestination
order by cast(f.TransactionDateTime as date)

if (select COUNT(*) from #FillsCurrent)>0 
begin
DELETE dbo.Fills
WHERE YEAR=@CurrentYear AND MONTH=@CurrentMonth
insert into dbo.Fills
select * from #FillsCurrent
exec dbo.SP_UpdateOrderSourceHistory @CurrentYear,@CurrentMonth
exec dbo.SP_Load_UserLoginData @CurrentYear,@CurrentMonth
exec dbo.SP_Load_LastLoginData @CurrentYear,@CurrentMonth  -- <Ram 11/03/2014> Load Prior Month Data till the billing is closed for that Month
drop table #FillsCurrent
end
end
/*************************************************************************************************************************************************************/

/******************************Update the Field Day************************************/
update Fills
set DayofMonth = (case when len(day(transactiondate))=1 then '0'+cast(day(transactiondate) as char(2)) 
else cast(day(transactiondate) as char(2)) end+'('+substring(datename(dw,TransactionDate),1,3)+')')

update F
set FillStatusDesc=FillStatusDescription
from Fills F join bidw_ods.dbo.FillStatusDesc FD
on f.FillStatus=fd.FillStatus

/*************************************************************************************************************************************************************/

/******************************Update TradeCo Fills************************************/
Update Fills
Set IsBillable='N', FillStatus=-1, FillStatusDesc='TradeCo'
where networkid=577 and IsBillable='Y'

/*************************************************************************************************************************************************************/

/**********************************************Code to Split EUREX into EEX - Added as per Jira EAS-1073**********************************************************************************/

Update F
Set F.Exchangeid=9999
from Fills F
Join dbo.Exchange E 
on F.ExchangeId=E.ExchangeID
WHERE YEAR=@PriorYear AND MONTH =@PriorMonth and fillcategoryid=14 and e.exchangename ='EUREX'

Update F
Set F.Exchangeid=9999
from Fills F
Join dbo.Exchange E 
on F.ExchangeId=E.ExchangeID
WHERE YEAR=@CurrentYear AND MONTH=@CurrentMonth and fillcategoryid=14 and e.exchangename ='EUREX'



/***************************************************************************************************************************************************************/

/************************************* Load LastLogin, Staff and License Data into BIDW***********************************************************************/

exec dbo.SP_Load_LicenseData
exec dbo.SP_Load_DailyLicenseCounts
--exec GetAlertedForNoBillingAccount -- Added as per Jira EAS -867

/*************************************************************************************************************************************************************/

END

/************************************Unused Code *********************************************/
--DELETE dbo.Fills
--WHERE YEAR=DATEPART(YYYY,GETDATE()) AND MONTH IN (DATEPART(MM,GETDATE()),DATEPART(MM,GETDATE())-1)
--INSERT INTO dbo.Fills
--select isnull((select max(fillid) from dbo.Fills),0) +row_number() over (order by f.year) as FillId, 
--f.[Year], f.[Month],f.UserName, f.[broker] as [BrokerId], f.company as CompanyId, f.ExchangeId, f.NetworkId, f.MarketId,f.BillingAccountId as AccountId, f.AxProductId, f.ProductType, f.ProductName,  f.FillType, f.FillStatus, sum((f.ShortQty+f.LongQty)*f.LotSize) as Fills, f.FixAdapterName, f.OpenClose, f.OrderFlags, f.LastOrderSource, f.FirstOrderSource, f.OrderSourceHistory,
--   f.FillCategoryId, f.[Version], cast(f.TransactionDateTime as date) as TransactionDate, cast(f.BillingServerDateTime as date) as BillingServerDate, 
--(case when f.fillstatus=2048 then 'Y' else 'N' end) as IsBillable, count(f.fillid) as CountsPerFillId
--, '' as MDT, '' as 'FunctionalityArea'
--,GETDATE() as lastupdateddate
--from chisql12.fillhub.dbo.Fills F
--WHERE YEAR=DATEPART(YYYY,GETDATE()) AND MONTH IN (DATEPART(MM,GETDATE()),DATEPART(MM,GETDATE())-1) 
--group by 
--f.[Year], f.[Month],F.username, f.[broker], f.company, f.ExchangeId, f.NetworkId, f.MarketId,f.BillingAccountId, f.AxProductId, f.ProductType, f.ProductName,  f.FillType, f.FillStatus,f.FixAdapterName, f.OpenClose, f.OrderFlags, f.LastOrderSource, f.FirstOrderSource, f.OrderSourceHistory,  f.FillCategoryId, f.[Version], cast(f.TransactionDateTime as date), cast(f.BillingServerDateTime as date) 
--,(case when f.fillstatus=2048 then 'Y' else 'N' end)
--order by cast(f.TransactionDateTime as date)



/*************************************************Insert Two Digits Formats to OrderSourceHistory********************************************************************************/
--declare @S int;
--declare @E int;
--declare @I int;
--declare @j char;
--declare @k char

--SET @s = 0
--SET @E = 9
--SET @I = @s
----set @j = 
----case 
----when @s=0 then 00 
----when @s=1 then 01
----when @s=2 then 02
----when @s=3 then 03
----end


--while 
--@I <= @E
--Begin
--select @k=@I
--select @j = (case 
--				when @I=0 then '00'
--				when @I=1 then 01
--				when @I=2 then 02
--				when @I=3 then 03
--				when @I=4 then 04 
--				when @I=5 then 05
--				when @I=6 then 06
--				when @I=7 then 07
--				when @I=8 then 08 
--				when @I=9 then 09
--				end)

----select distinct @I,@k,@j from dbo.Fills_copy

----select * from dbo.Fills_copy
----where OrderSourceHistory like 
----case when @k=0 then '0,%'
----end
-- update dbo.Fills
-- set OrderSourceHistory='0'+ OrderSourceHistory
-- where OrderSourceHistory <>''
--	and OrderSourceHistory like 
--								(case 
--								when @k=0 then '0,%'
--								when @k=1 then '1,%'
--								when @k=2 then '2,%'
--								when @k=3 then '3,%'
--								when @k=4 then '4,%'
--								when @k=5 then '5,%'
--								when @k=6 then '6,%'
--								when @k=7 then '7,%'
--								when @k=8 then '8,%'
--								when @k=9 then '9,%'
--							end)
	
--update dbo.Fills
-- set OrderSourceHistory= 
-- (case 
--	when @k=0 and @j= 00 then REPLACE(OrderSourceHistory,',0,',',00,')
--	when @k=1 and @j= 01  then REPLACE(OrderSourceHistory,',1,',',01,')
--	when @k=2 and @j= 02 then REPLACE(OrderSourceHistory,',2,',',02,')
--	when @k=3 and @j= 03 then REPLACE(OrderSourceHistory,',3,',',03,')
--	when @k=4 and @j= 04 then REPLACE(OrderSourceHistory,',4,',',04,')
--	when @k=5 and @j= 05 then REPLACE(OrderSourceHistory,',5,',',05,')
--	when @k=6 and @j= 06 then REPLACE(OrderSourceHistory,',6,',',06,')
--	when @k=7 and @j= 07 then REPLACE(OrderSourceHistory,',7,',',07,')
--	when @k=8 and @j= 08 then REPLACE(OrderSourceHistory,',8,',',08,')
--	when @k=9 and @j= 09 then REPLACE(OrderSourceHistory,',9,',',09,')
--end)
-- where OrderSourceHistory <>''
--	and OrderSourceHistory like (case 
--									when @k=0 then '%,0,%'
--									when @k=1 then '%,1,%'
--									when @k=2 then '%,2,%'
--									when @k=3 then '%,3,%'
--									when @k=4 then '%,4,%'
--									when @k=5 then '%,5,%'
--									when @k=6 then '%,6,%'
--									when @k=7 then '%,7,%'
--									when @k=8 then '%,8,%'
--									when @k=9 then '%,9,%'
--								end)
	
--	SET @I = @I+1

--end
-- update dbo.Fills
--	set OrderSourceHistory='0'+ OrderSourceHistory
--	where OrderSourceHistory <>''
--	and len(OrderSourceHistory)=1




/*************************************************************************************************************************************************************/

/*******************************************Updated MDT and Functionality Area Columns***********************************************************************/
--update dbo.Fills
--set MDT=CASE WHEN [OrderSourceHistory] like '%15%' THEN 'MDT' ELSE 'non-MDT' END
--where YEAR in (YEAR(getdate()),YEAR(getdate())-1)
----WHERE YEAR =DATEPART(YYYY,GETDATE()) AND MONTH IN (DATEPART(MM,GETDATE()),DATEPART(MM,GETDATE())-1)

--update dbo.fills
--set FunctionalityArea=(CASE 
--            WHEN [FirstOrderSource] = 9 OR ([OrderSourceHistory] like '%09%' AND ([OrderSourceHistory] like '%11%' OR [OrderSourceHistory] like '%12%' OR [OrderSourceHistory] like '%19%' OR [OrderSourceHistory] like '%21%')) THEN 'Autospreader - ServerSide'
--            WHEN [OrderSourceHistory] like '%01%' THEN 'Autospreader - Desktop' 
----            WHEN [OrderSourceHistory] like '%,1,%' OR [FirstOrderSource] = 9 OR ([OrderSourceHistory] like '%,9,%' AND ([OrderSourceHistory] like '%11%' OR [OrderSourceHistory] like '%12%' OR [OrderSourceHistory] like '%19%' OR [OrderSourceHistory] like '%21%')) THEN 'Autospreader' 
--            WHEN [OrderSourceHistory] like '%22%' or ([OrderSourceHistory] like '%12%' and [OrderSourceHistory] not like '%09%') THEN 'AlgoSE' 
--            WHEN [OrderSourceHistory] like '%02%' THEN 'Autotrader' 
--            WHEN [FirstOrderSource] IN (6,23) THEN 'FIX Adapter'
--            WHEN [OrderSourceHistory] like '%20%' OR [OrderSourceHistory] like '%24%' THEN 'SSE' 
--            WHEN [FirstOrderSource] = 3 THEN 'XTAPI'
--            WHEN [FirstOrderSource] IN (11,21) THEN 'XTAPI XT Mode'
--            WHEN OrderSourceHistory NOT LIKE '%24%'
--            AND  OrderSourceHistory NOT LIKE '%23%'
--            AND  OrderSourceHistory NOT LIKE '%22%'
--            AND  OrderSourceHistory NOT LIKE '%21%'      
--            AND  OrderSourceHistory NOT LIKE '%20%'
--            AND  OrderSourceHistory NOT LIKE '%19%'
--            AND  OrderSourceHistory NOT LIKE '%12%'
--            AND  OrderSourceHistory NOT LIKE '%11%'                                    
--            AND  OrderSourceHistory NOT LIKE '%09%'                                                                                   
--            AND  OrderSourceHistory NOT LIKE '%01%'                                                                                                                                   
--            AND  OrderSourceHistory NOT LIKE '%02%'                                     
--            AND  OrderSourceHistory NOT LIKE '%06%'                           
--			THEN 'Non-Automated' 
--			ELSE 'Needs a rule'
--		END)
--		where YEAR in (YEAR(getdate()),YEAR(getdate())-1)

/*************************************************************************************************************************************************************/
/*********************************************************************************************/




