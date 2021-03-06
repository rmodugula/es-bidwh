USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetTTMigrationProjections]    Script Date: 3/3/2017 12:03:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[GetTTMigrationProjections]
     
     
AS

Declare @StartDate Date,@Year int,@Month int,@EndDate Date,@RunDate Date
Set @StartDate=DATEADD(month, DATEDIFF(month, 0, getdate()), 0)
Set @Enddate=DATEADD(month,-12,@StartDate)
Set @RunDate=@StartDate

Create Table #Final
(Month int, Year Int,Date Date,CrmId varchar(50), Accountid varchar(50),AccountName varchar(200),CustGroup varchar(50),ProductSku varchar(50),ProductName varchar(100),ReportingGroup varchar(50)
,Screens varchar(50),ProductCategoryId varchar(50),ProductCategoryName varchar(100), ProductSubGroup varchar(50),Revenue Numeric(28,2), UserCount int,
additionalinfo varchar(100), Region varchar(50), city varchar(50), State varchar(50), Country varchar(50), CountryName varchar(50), Branch varchar(50)
, Action varchar(50), LicenseCount int, Quantity int ,NonBillableLicenseCount int, MasterAccountName varchar(200), TTChangeType varchar(50)
, CreditReason varchar(50), TTLICENSEFILEID varchar(50), DataAreaId varchar(50), ActiveBillableToday int
,ActiveNonBillableToday int, PriceGroup varchar(50), TTBillingOnBehalfOf varchar(50), salestype varchar(50), NetworkShortName varchar(50), TTUserCompany varchar(50),
 MIC varchar(50), UserName varchar(100), TTPassThroughPrice numeric(28,12)
, SalesOffice varchar(50), InvoiceId varchar(50),TypeOfInvoice varchar(50))

While @RunDate>@Enddate
BEGIN

Set @Year=year(@Rundate)
Set @Month=month(@Rundate)

BEGIN
SET NOCOUNT ON;

Insert into #Final

Select * from
(
select Month, Year, Date, CrmId, Accountid, AccountName, CustGroup, ProductSku, ProductName
, ReportingGroup, Screens, ProductCategoryId,ProductCategoryName,ProductSubGroup
, case 
when productsku ='80000' then (select sum(BilledAmount)/count(*) from MonthlyBillingDataAggregate where year=@Year and month=@Month and ProductSku in ('20000'))
when productsku ='80001' then (select sum(BilledAmount)/count(*) from MonthlyBillingDataAggregate where year=@Year and month=@Month and ProductSku in ('20200'))
else sum(BilledAmount) END
as Revenue,sum(UserCount) as UserCount
, additionalinfo, Region, city, State, Country, CountryName, Branch
, Action, LicenseCount, Fills as Quantity ,NonBillableLicenseCount, MasterAccountName, TTChangeType, CreditReason, TTLICENSEFILEID, DataAreaId, ActiveBillableToday
, ActiveNonBillableToday, PriceGroup, TTBillingOnBehalfOf, salestype, NetworkShortName, TTUserCompany, MIC, UserName, TTPassThroughPrice
, SalesOffice, InvoiceId,'Migration Subscription Projection' as TypeOfInvoice from 
(
select Month, Year, Date, CrmId, Accountid, AccountName,'TTPlatform' as CustGroup
,case when productsku in ('20993','20997','20999') then '80003'
      when productsku in ('20005','20992','20995') then '80002'
	 when ProductSku in ('20996','20998') then '80099'
	 when ProductSku in ('20991') then '80005'
	 when ProductSku in ('20994') then '80006'
	 when ProductSku='20000' then '80000'
	 when ProductSku='20200' then '80001' END as ProductSku
,case when productsku in ('20993','20997','20999') then 'TT Pro - Transaction'
      when productsku in ('20005','20992','20995') then 'TT - Transaction'
	  when ProductSku in ('20996','20998') then 'TT FIX Transaction'
	 when ProductSku in ('20991') then 'TT User Access'
	 when ProductSku in ('20994') then 'TT Pro User Access'
	 when ProductSku='20000' then 'TT - Subscription'
	 when ProductSku='20200' then 'TT Pro - Subscription' END as ProductName
, ReportingGroup, Screens
,'RevTTTrade' as ProductCategoryId
, 'TT Trading Products' as ProductCategoryName
,'TT' as ProductSubGroup
, case 
when productsku in ('20993','20997','20999') then LicenseCount*1400 
when productsku in ('20005','20992','20995') then LicenseCount*700  
when ProductSku in ('20996','20998') then LicenseCount*700
when ProductSku in ('20991','20994') then LicenseCount*700
when ProductSku='20000' then BilledAmount
when ProductSku='20200' then BilledAmount
else 0 END 
as BilledAmount,LicenseCount as UserCount
, additionalinfo, Region, city, State, Country, CountryName, Branch
, Action, LicenseCount, Fills,NonBillableLicenseCount, MasterAccountName, TTChangeType, CreditReason, TTLICENSEFILEID, DataAreaId, ActiveBillableToday
, ActiveNonBillableToday, PriceGroup, TTBillingOnBehalfOf, salestype, NetworkShortName, TTUserCompany, MIC, UserName, TTPassThroughPrice
, SalesOffice, InvoiceId from MonthlyBillingDataAggregate
where year=@Year and month=@Month 
and ProductSku in ('20000','20005','20200','20991','20992','20993','20994','20995','20997','20999','20996','20998')

UNION ALL

----------------- Includes Telco Charges-----------------------------------
select Month, Year, Date, CrmId, Accountid, AccountName,CustGroup, ProductSku, ProductName, ReportingGroup, Screens
,ProductCategoryId
,  ProductCategoryName, ProductSubGroup, BilledAmount,LicenseCount as UserCount, additionalinfo, Region, city, State, Country, CountryName, Branch
, Action, LicenseCount, Fills,NonBillableLicenseCount, MasterAccountName, TTChangeType, CreditReason, TTLICENSEFILEID, DataAreaId, ActiveBillableToday
, ActiveNonBillableToday, PriceGroup, TTBillingOnBehalfOf, salestype, NetworkShortName, TTUserCompany, MIC, UserName, TTPassThroughPrice
, SalesOffice, InvoiceId from MonthlyBillingDataAggregate
where year=@Year and month=@Month 
and ProductSku not in ('20000','20005','20200','20991','20992','20993','20994','20995','20997','20999','20996','20998')
and productsubgroup like '%Telco%'
--and CustGroup not in ('TTNETHost','Trnx SW','Subscribe')

UNION ALL
----------------- Includes Royalties and MarketData Charges-----------------------------------
select Month, Year, Date, CrmId, Accountid, AccountName,CustGroup, ProductSku, ProductName, ReportingGroup, Screens
,ProductCategoryId
,  ProductCategoryName, ProductSubGroup, BilledAmount,LicenseCount as UserCount, additionalinfo, Region, city, State, Country, CountryName, Branch
, Action, LicenseCount, Fills,NonBillableLicenseCount, MasterAccountName, TTChangeType, CreditReason, TTLICENSEFILEID, DataAreaId, ActiveBillableToday
, ActiveNonBillableToday, PriceGroup, TTBillingOnBehalfOf, salestype, NetworkShortName, TTUserCompany, MIC, UserName, TTPassThroughPrice
, SalesOffice, InvoiceId from MonthlyBillingDataAggregate
where year=@Year and month=@Month 
and CustGroup in ('Royalty','MarketData')

UNION ALL

------------------------------------------Adjusted MAP fees when migrated to TT Platform---------------------

select distinct Month, Year, @Rundate as TransactionDate, '' as CrmId, '' as AccountId, '' as AccountName,'MultiBrokr' as CustGroup, '' as ProductSku,
'Market Access Provider'+'-'+MarketName as ProductName, 'Software Revenue' as ReportingGroup, Screens
,'RevMktAcc' as ProductCategoryId, 'Market Access Provider Fees' as ProductCategoryName,'Market Access Provider Fees' as ProductSubGroup
,case when count(distinct username)*250 >5000 then 5000 else count(distinct username)*250 End as BilledAmount,count(distinct username) as UserCount
--count(distinct username) as Users
, '' as additionalinfo, '' as Region, '' as city, '' as State, '' as Country, '' as CountryName, '' as Branch
, '' as Action, count(distinct username) as LicenseCount, sum(Fills) as Fills,0 as NonBillableLicenseCount, T.MasterAccountName, '' as TTChangeType
, '' as CreditReason, '' as TTLICENSEFILEID, '' as DataAreaId, 0 as ActiveBillableToday
, 0 as ActiveNonBillableToday,'' as PriceGroup, '' as TTBillingOnBehalfOf, '' as salestype, '' as NetworkShortName, '' as  TTUserCompany, '' as  MIC,'' as UserName,
  0 as TTPassThroughPrice,'' as  SalesOffice,'' as  InvoiceId
from VW_TransactionsMatrixForMigrationProjections T
left join Product P on T.AXProductName=P.ProductName
Left Join Account A on T.Accountid=A.Accountid
where year=@Year and month=@Month and IsBillable='Y' and AXProductName not like '%FIX%' 
Group by Month, Year,MarketName, ReportingGroup, Screens, T.MasterAccountName

UNION ALL
select Month, Year, Date, CrmId, Accountid, AccountName,CustGroup, ProductSku, ProductName, ReportingGroup, Screens
,ProductCategoryId,  ProductCategoryName, ProductSubGroup, BilledAmount,LicenseCount as UserCount
, additionalinfo, Region, city, State, Country, CountryName, Branch
, Action, LicenseCount, Fills,NonBillableLicenseCount, MasterAccountName, TTChangeType, CreditReason, TTLICENSEFILEID, DataAreaId, ActiveBillableToday
, ActiveNonBillableToday, PriceGroup, TTBillingOnBehalfOf, salestype, NetworkShortName, TTUserCompany, MIC, UserName, TTPassThroughPrice
, SalesOffice, InvoiceId 
from MonthlyBillingDataAggregate
where year=@Year and month=@Month 
and custgroup='TTPlatform'
and ProductCategoryName<>'Market Access Provider Fees'

)Q
group by 
Month, Year, Date, CrmId, Accountid, AccountName, CustGroup, ProductSku, ProductName
, ReportingGroup, Screens, ProductCategoryId,ProductCategoryName,ProductSubGroup
, additionalinfo, Region, city, State, Country, CountryName, Branch
, Action, LicenseCount, Fills,NonBillableLicenseCount, MasterAccountName, TTChangeType, CreditReason, TTLICENSEFILEID, DataAreaId, ActiveBillableToday
, ActiveNonBillableToday, PriceGroup, TTBillingOnBehalfOf, salestype, NetworkShortName, TTUserCompany, MIC, UserName, TTPassThroughPrice
, SalesOffice, InvoiceId 


UNION ALL

--------------------TT Migration Transaction Projections--------------------------
select Month, Year, Date, CrmId, Accountid, AccountName, CustGroup, ProductSku, ProductName
, ReportingGroup, Screens, ProductCategoryId,ProductCategoryName,ProductSubGroup
, case 
when productsku ='80000' then (select sum(BilledAmount)/count(*) from MonthlyBillingDataAggregate where year=@Year and month=@Month and ProductSku in ('20000'))
when productsku ='80001' then (select sum(BilledAmount)/count(*) from MonthlyBillingDataAggregate where year=@Year and month=@Month and ProductSku in ('20200'))
when ProductSku =80003 and sum(BilledAmount)>1800 then 1800 
when ProductSku =80003 and sum(BilledAmount)<1800 then 400
when ProductSku =80002 and sum(BilledAmount)>1000 then 1000 
when ProductSku =80002 and sum(BilledAmount)<1000 then 200
when ProductSku =80099 and sum(BilledAmount)>1000 then 1000 
when ProductSku =80099 and sum(BilledAmount)<1000 then 200
else sum(BilledAmount) END
as Revenue,sum(UserCount) as UserCount
, additionalinfo, Region, city, State, Country, CountryName, Branch
, Action, LicenseCount, Fills,NonBillableLicenseCount, MasterAccountName, TTChangeType, CreditReason, TTLICENSEFILEID, DataAreaId, ActiveBillableToday
, ActiveNonBillableToday, PriceGroup, TTBillingOnBehalfOf, salestype, NetworkShortName, TTUserCompany, MIC, UserName, TTPassThroughPrice
, SalesOffice, InvoiceId,'Migration Transaction Projection' as TypeOfInvoice from 
(
select Month, Year, Date, CrmId, Accountid, AccountName,'TTPlatform' as CustGroup
,case when productsku in ('20993','20997','20999') then '80003'
      when productsku in ('20005','20992','20995') then '80002'
	 when ProductSku in ('20996','20998') then '80099'
	 when ProductSku in ('20991') then '80005'
	 when ProductSku in ('20994') then '80006'
	 when ProductSku='20000' then '80000'
	 when ProductSku='20200' then '80001' END as ProductSku
,case when productsku in ('20993','20997','20999') then 'TT Pro - Transaction'
      when productsku in ('20005','20992','20995') then 'TT - Transaction'
	  when ProductSku in ('20996','20998') then 'TT FIX Transaction'
	 when ProductSku in ('20991') then 'TT User Access'
	 when ProductSku in ('20994') then 'TT Pro User Access'
	 when ProductSku='20000' then 'TT - Subscription'
	 when ProductSku='20200' then 'TT Pro - Subscription' END as ProductName
, ReportingGroup, Screens
,'RevTTTrade' as ProductCategoryId
, 'TT Trading Products' as ProductCategoryName
,'TT' as ProductSubGroup
, case 
when productsku in ('20993','20997','20999') then fills*0.3 
when productsku in ('20005','20992','20995') then fills*0.3 
when ProductSku in ('20996','20998') then fills*0.3
when ProductSku in (20991,20994) then LicenseCount*50
when ProductSku='20000' then BilledAmount
when ProductSku='20200' then BilledAmount
else 0 END 
as BilledAmount,LicenseCount as UserCount
, additionalinfo, Region, city, State, Country, CountryName, Branch
, Action, LicenseCount, Fills,NonBillableLicenseCount, MasterAccountName, TTChangeType, CreditReason, TTLICENSEFILEID, DataAreaId, ActiveBillableToday
, ActiveNonBillableToday, PriceGroup, TTBillingOnBehalfOf, salestype, NetworkShortName, TTUserCompany, MIC, UserName, TTPassThroughPrice
, SalesOffice, InvoiceId from MonthlyBillingDataAggregate
where year=@Year and month=@Month 
and ProductSku in ('20000','20005','20200','20991','20992','20993','20994','20995','20997','20999','20996','20998')

UNION ALL

select Month, Year, Date, CrmId, Accountid, AccountName,CustGroup, ProductSku, ProductName, ReportingGroup, Screens
,ProductCategoryId
,  ProductCategoryName, ProductSubGroup, BilledAmount,LicenseCount as UserCount, additionalinfo, Region, city, State, Country, CountryName, Branch
, Action, LicenseCount, Fills,NonBillableLicenseCount, MasterAccountName, TTChangeType, CreditReason, TTLICENSEFILEID, DataAreaId, ActiveBillableToday
, ActiveNonBillableToday, PriceGroup, TTBillingOnBehalfOf, salestype, NetworkShortName, TTUserCompany, MIC, UserName, TTPassThroughPrice
, SalesOffice, InvoiceId from MonthlyBillingDataAggregate
where year=@Year and month=@Month 
and ProductSku not in ('20000','20005','20200','20991','20992','20993','20994','20995','20997','20999','20996','20998')
and productsubgroup like '%Telco%'
--and CustGroup not in ('TTNETHost','Trnx SW','Subscribe')

UNION ALL
----------------- Includes Royalties and MarketData Charges-----------------------------------
select Month, Year, Date, CrmId, Accountid, AccountName,CustGroup, ProductSku, ProductName, ReportingGroup, Screens
,ProductCategoryId
,  ProductCategoryName, ProductSubGroup, BilledAmount,LicenseCount as UserCount, additionalinfo, Region, city, State, Country, CountryName, Branch
, Action, LicenseCount, Fills,NonBillableLicenseCount, MasterAccountName, TTChangeType, CreditReason, TTLICENSEFILEID, DataAreaId, ActiveBillableToday
, ActiveNonBillableToday, PriceGroup, TTBillingOnBehalfOf, salestype, NetworkShortName, TTUserCompany, MIC, UserName, TTPassThroughPrice
, SalesOffice, InvoiceId from MonthlyBillingDataAggregate
where year=@Year and month=@Month 
and CustGroup in ('Royalty','MarketData')

UNION ALL

------------------------------------------Adjusted MAP fees when migrated to TT Platform---------------------
select distinct Month, Year, @Rundate as TransactionDate, '' as CrmId, '' as AccountId, '' as AccountName,'MultiBrokr' as CustGroup, '' as ProductSku,
'Market Access Provider'+'-'+MarketName as ProductName, 'Software Revenue' as ReportingGroup, Screens
,'RevMktAcc' as ProductCategoryId, 'Market Access Provider Fees' as ProductCategoryName,'Market Access Provider Fees' as ProductSubGroup
,case when count(distinct username)*250 >5000 then 5000 else count(distinct username)*250 End as BilledAmount,count(distinct username) as UserCount
--count(distinct username) as Users
, '' as additionalinfo, '' as Region, '' as city, '' as State, '' as Country, '' as CountryName, '' as Branch
, '' as Action, count(distinct username) as LicenseCount, sum(Fills) as Fills,0 as NonBillableLicenseCount, T.MasterAccountName, '' as TTChangeType
, '' as CreditReason, '' as TTLICENSEFILEID, '' as DataAreaId, 0 as ActiveBillableToday
, 0 as ActiveNonBillableToday,'' as PriceGroup, '' as TTBillingOnBehalfOf, '' as salestype, '' as NetworkShortName, '' as  TTUserCompany, '' as  MIC,'' as UserName,
  0 as TTPassThroughPrice,'' as  SalesOffice,'' as  InvoiceId
from VW_TransactionsMatrixForMigrationProjections T
left join Product P on T.AXProductName=P.ProductName
Left Join Account A on T.Accountid=A.Accountid
where year=@Year and month=@Month and IsBillable='Y' and AXProductName not like '%FIX%' 
Group by Month, Year,MarketName, ReportingGroup, Screens, T.MasterAccountName

UNION ALL
select Month, Year, Date, CrmId, Accountid, AccountName,CustGroup, ProductSku, ProductName, ReportingGroup, Screens
,ProductCategoryId,  ProductCategoryName, ProductSubGroup, BilledAmount,LicenseCount as UserCount
, additionalinfo, Region, city, State, Country, CountryName, Branch
, Action, LicenseCount, Fills,NonBillableLicenseCount, MasterAccountName, TTChangeType, CreditReason, TTLICENSEFILEID, DataAreaId, ActiveBillableToday
, ActiveNonBillableToday, PriceGroup, TTBillingOnBehalfOf, salestype, NetworkShortName, TTUserCompany, MIC, UserName, TTPassThroughPrice
, SalesOffice, InvoiceId 
from MonthlyBillingDataAggregate
where year=@Year and month=@Month 
and custgroup='TTPlatform'
and ProductCategoryName<>'Market Access Provider Fees'
)Q
group by 
Month, Year, Date, CrmId, Accountid, AccountName, CustGroup, ProductSku, ProductName
, ReportingGroup, Screens, ProductCategoryId,ProductCategoryName,ProductSubGroup
, additionalinfo, Region, city, State, Country, CountryName, Branch
, Action, LicenseCount, Fills,NonBillableLicenseCount, MasterAccountName, TTChangeType, CreditReason, TTLICENSEFILEID, DataAreaId, ActiveBillableToday
, ActiveNonBillableToday, PriceGroup, TTBillingOnBehalfOf, salestype, NetworkShortName, TTUserCompany, MIC, UserName, TTPassThroughPrice
, SalesOffice, InvoiceId 



UNION ALL

------------------------------------------Current Invoicing---------------------------------------------

select Month, Year, Date, CrmId, Accountid, AccountName,CustGroup, ProductSku, ProductName, ReportingGroup, Screens
,ProductCategoryId
,  ProductCategoryName, ProductSubGroup, BilledAmount,LicenseCount as UserCount, additionalinfo, Region, city, State, Country, CountryName, Branch
, Action, LicenseCount, Fills,NonBillableLicenseCount, MasterAccountName, TTChangeType, CreditReason, TTLICENSEFILEID, DataAreaId, ActiveBillableToday
, ActiveNonBillableToday, PriceGroup, TTBillingOnBehalfOf, salestype, NetworkShortName, TTUserCompany, MIC, UserName, TTPassThroughPrice
, SalesOffice, InvoiceId,'Current Invoicing' as TypeOfInvoice from MonthlyBillingDataAggregate
where year=@Year and month=@Month 
)Q


--Select * 
--into #Final
--from #temp

--Drop table #temp

SET @Rundate=dateadd(month,-1,@RunDate)

END

END

Select * from #Final