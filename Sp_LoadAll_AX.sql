USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[Sp_LoadAll_AX]    Script Date: 3/20/2017 4:12:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[Sp_LoadAll_AX] 
as


declare @StartDate datetime;
declare @EndDate datetime;
declare @IndexDate datetime;
declare @year int;
declare @month int;

SET @StartDate = DATEADD(m,-1,GETDATE())
SET @EndDate = DATEADD(m,+6,GETDATE())
SET @IndexDate = @StartDate 


--------------------------------------Refresh monthly billing info--------------------------------------------------------------

while @IndexDate <= @EndDate
begin
	print '>' + convert(varchar(30),year(@IndexDate)) + '-' + convert(varchar(30),month(@IndexDate))
	select @year = year(@IndexDate)
	select @month = month(@IndexDate)
	exec SP_Load_AXBillingData @month ,@year
	exec SP_Load_RevenueImpactData @year,@month -- Refresh RevenueImpactReporting Data
	SET @IndexDate = DATEADD(m,1,@IndexDate)
end

-------------------------------------------------Truncate and Load Account Table---------------------------------------------------------------------------------
Create Table #Account (AccountId varchar(50),AccountName varchar(100),MasterAccountName varchar(100),CRMId varchar(100),MultiBrokerNetworkId int,CustomerGroup varchar(50), CustomerType varchar(50),
StatusType varchar(50))

Insert into #Account
select A.Accountid, A.AccountName, A.MasterAccountName,
Case when len(a.crmid)<>36 then substring(a.crmid,1,8)+'-'+substring(a.crmid,9,4)+'-'+substring(a.crmid,13,4)+'-'+substring(a.crmid,17,4)+'-'+substring(a.crmid,21,12)
else a.crmid end as CrmId
--, A.CrmId
, '' as MultiBrokerNetworkId, CustomerGroup,A.CustomerTypeCodeName as CustomerType
,A.StatusCodeName as StatusType  from 
(select A.ACCOUNTNUM as Accountid,  A.NAME as AccountName ,  A.NAME as Legalname, 1 as IsActive , 1 as AccountSatusId , A.TTCRMID as CrmId , NULL as CustomerType
, isnull(B.Name,A.NAME) as MasterAccountName, CustomerTypeCodeName,StatusCodeName
from CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.CUSTTABLE A
left  join chisql12.bidw_ods.dbo.CRMOnlineAccountTable B on A.TTCRMID = cast(B.AccountId as varchar(50))
) A
left join chisql12.fillhub.dbo.BillingAccounts BA
on A.Accountid=BA.BillingAccountId   ---------------------<Ram 09/08/2014> Updated to get data from CRM Online-------------

--------------------Old Code----------------------------------------------------------------------------
--select A.Accountid, A.AccountName, A.MasterAccountName, A.CrmId, '' as MultiBrokerNetworkId,A.custgroup as CustomerGroup,A.CustomerTypeCode as CustomerType
--,A.StatusType  from 
--(select A.ACCOUNTNUM as Accountid,  A.NAME as AccountName ,  A.NAME as Legalname, 1 as IsActive , 1 as AccountSatusId , A.TTCRMID as CrmId , NULL as CustomerType
--, isnull(B.Name,A.NAME) as MasterAccountName, SMC.Value as CustomerTypeCode,SMS.Value as StatusType,A.custgroup
--from CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.CUSTTABLE A
--left  join chicrmsql01.Trading_Technologies_MSCRM.dbo.AccountBase B on A.TTCRMID = cast(B.AccountId as varchar(50))
--left join (SELECT  AttributeValue,Value,AttributeName FROM chicrmsql01.[Trading_Technologies_MSCRM].[dbo].[StringMap] 
--  where objecttypecode=1 and AttributeName ='customertypecode')SMC -- Ram<10/11/2013:14:45:00> Added CustomerType and StatusType Columns
--  on B.CustomerTypeCode=SMC.AttributeValue
--left join (SELECT  AttributeValue,Value,AttributeName FROM chicrmsql01.[Trading_Technologies_MSCRM].[dbo].[StringMap] 
--  where objecttypecode=1 and AttributeName ='StatusCode')SMS
--  on B.StatusCode=SMS.AttributeValue
--) A
--left join chisql12.fillhub.dbo.BillingAccounts BA
--on A.Accountid=BA.BillingAccountId
-------------------------------------------------------------------------------------------------------------

if (select COUNT(*) from #Account)<>0  
Begin
Delete Account
where Accountid not like 'LGCY%' -- <Ram 10/16/2014> Brought Legacy Account Information from Athena DB
insert into Account
Select * from #Account
END



-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------Truncate and Load Product Table---------------------------------------------------------------------------------
-- from AX

Create Table #Product 
(Productsku int, ProductName varchar(100),ProductCategoryId varchar(50), ProductCategoryName varchar(50),ProductSubGroup varchar(50),ProductSubGroupId varchar(50),ReportingGroup varchar(50),Screens varchar(50))

Insert into #Product
select ProductSku, ProductName, ProductCategoryId, ProductCategoryName, ProductSubGroup, ProductSubGroupId, ReportingGroup, Screens from
(
select distinct B.ITEMID as ProductSku, B.ITEMNAME as ProductName 
, A.ITEMGROUPID as ProductCategoryId, A.NAME as ProductCategoryName,C.Name as ProductSubGroup,c.PackagingGroupId as ProductSubGroupId,d.Description as ReportingGroup
,TTScreen as Screens,a.dataareaid,row_number() over (partition by B.itemid order by a.dataareaid desc) as row
--, 1 as IsSupported, 1 as IsActive
from CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.INVENTITEMGROUP A
inner join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.INVENTTABLE B
Left join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.INVENTBUYERGROUP D on B.Itembuyergroupid=D.Group_ and B.dataareaid=D.dataareaid
left join (select * from 
(
select *,row_number() over (partition by packaginggroupid order by recid desc) as row
from CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.InventPackagingGroup
)Q
where row=1) C
on b.PackagingGroupId =c.PackagingGroupId 
on A.ITEMGROUPID = B.ITEMGROUPID and A.DATAAREAID = B.DATAAREAID
where A.itemgroupid ='ContraExMB' or (A.ITEMGROUPID like 'Rev%' or A.ITEMGROUPID IN ('Credits','Write-Off','Obsolete','Collection','CE','PrePay')) -- <Ram 08/09/2013:1545> Included Write-Off and Obsolete
and A.DATAAREAID in ('ttus','bkdl')
)Q
where row=1 and len(productsku)=5

If (select COUNT(*) from #Product)<>0  
Begin
Delete Product
Insert into Product
Select * from #Product
END



-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------Truncate and Load Branch Table---------------------------------------------------------------------------------
Create Table #Branch (BranchId Int, BranchName varchar(50), Active int)

Insert Into #Branch
select LOCATIONNUM as BranchId, DESCRIPTION as BranchName , 1 as Active
   from CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.TTLOCATIONSALESREGIONMAPPING 

If (select COUNT(*) from #Branch)<>0  
Begin
Delete Branch
Insert into Branch
Select * from #Branch
END

   
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------Truncate and Load RegionMap--------------------------------------------------------------------------------------
Create Table #RegionMap
(Region varchar(50), Country char(50), State varchar(50),City varchar(50),SalesOffice Varchar(50),Countryname varchar(255))

Insert Into #RegionMap
select distinct case ttsalesregion when 1 then 'Asia Pacific' when 2 then 'Europe' when 3 then 'North America' when 4  then 'South America' End as Region,
lm.Country, State, '' as City, Description as SalesOffice, c.Country as CountryName
  from CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.TTLocationSalesRegionMapping L
 join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.[TT_ADDRESSLOCATIONMAPPING] LM
on locationnum=location
left join bidw_ods.dbo.countries c
on lm.Country=c.CountryCode
where Description like '%Office%'
UNION All
Select 'North America' as Region,'US' as Country,'AE' as State,'' as City,'Office-Chicago' as SalesOffice,'United States' as CountryName
UNION All
Select 'North America' as Region,'US' as Country,'AP' as State,'' as City,'Office-Chicago' as SalesOffice,'United States' as CountryName

--Select x.*,c.country as CountryName from 
--(
--select Region,Country,[State],City,ISNULL(Salesoffice,City) as SalesOffice from
--(
--select case when B.SalesRegion is null then A.Region else B.SalesRegion end as Region,A.COUNTRY,A.STATE,isnull(A.CITY,'Unassigned')as City,B.SalesOffice
--FROM
--( 
--  SELECT distinct Region,City,Country,isnull(nullif(State,''),'Unassigned') as State
--  FROM [dbo].[MonthlyBillingData]
--  where len(country)<3
--  )A
--  LEFT OUTER JOIN
--  (
--  SELECT [Country]
--      ,isnull(nullif([State],''),'Unassigned') as State
--      ,[SalesOffice]
--      ,[SalesRegion]
--  FROM chisql12.bidw_ods.[dbo].[RegionMap_old]
--  )B
--  ON A.Country=B.Country AND A.State=B.State
--)Q
--where q.region NOT IN ('None','Unassigned')
--)x
--left Join bidw_ods.dbo.countries c
--on x.Country=c.CountryCode

--Delete #RegionMap
--where region='europe' and country='us'

If (select COUNT(*) from #RegionMap)<>0  
Begin
Delete RegionMap
Insert into RegionMap
Select * from #RegionMap
END

-------------------------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------Truncate and Load Inteval Data---------------------------------------------------------------------------------------------- 
--Create Table #TimeInterval
--(Year Int, Month Int, MonthName varchar(10),YearMonth int, Quarter int,Startdate datetime, EndDate DateTime)

--Insert Into #TimeInterval
--select distinct Year,Month
--	, Case 
--	      when Month=1 then 'Jan'
--	      when Month=2 then 'Feb'
--	      when Month=3 then 'Mar'
--	      when Month=4 then 'Apr'
--	      when Month=5 then 'May'
--	      when Month=6 then 'Jun'
--	      when Month=7 then 'Jul'
--	      when Month=8 then 'Aug'
--	      when Month=9 then 'Sep'
--	      when Month=10 then 'Oct'
--	      when Month=11 then 'Nov'
--	      when Month=12 then 'Dec'
--	    end as MonthName
--, cast(case when len(month)=1 then cast(year as char(4))+('0'+cast(month as char)) else cast(year as char(4))+cast(month as char(2)) end as int)  as YearMonth
--,case when month in (1,2,3) then 1 when month in (4,5,6) then 2 when month in (7,8,9) then 3 when month in (10,11,12) then 4 End as Quarter
--,DATEADD(month,MONTH-1,DATEADD(year,YEAR-1900,0)) as StartDate,
--DATEADD(day,-1,dateadd(month,+1, CONVERT(datetime, convert(char(4),year) + '/' + convert(char(2),MONTH) + '/1'))) as EndDate
--from dbo.MonthlyBillingData  
--order by Year,Month

--If (select COUNT(*) from #TimeInterval)<>0  
--Begin
--Delete TimeInterval
--Insert into TimeInterval
--Select * from #TimeInterval
--END


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Drop Table #Account
Drop Table #Product
Drop Table #Branch
Drop Table #RegionMap
--Drop Table #TimeInterval



------------------Temp code for TT Projections ------------------------------
Declare @prioryear int, @priormonth int
set @prioryear = case when month(getdate())=1 then year(getdate())-1 else year(getdate()) end 
set @priormonth = case when month(getdate())=1 then 12 else month(getdate())-1 End

----------------------Load Prior Month TT Projections-----------------------

IF (select COUNT(*) from chisql12.fillhub.dbo.invoicemonth   
 where YEAR=@prioryear AND MONTH =@priormonth) = 0 
 and 
 (select count(*) from MonthlyBillingData
 where YEAR=@prioryear AND MONTH =@priormonth and custgroup='ttplatform' and salestype in ('AX Sales Lines','AX Invoices'))<=100
 --and
 --(select count(*) from MonthlyBillingData
 --where YEAR=Year(getdate()) AND MONTH =Month(getdate())-1 and custgroup='ttplatform')<=
 --(Select count(*) from monthlybillingdata where year=case when month(getdate())=2 then year(getdate())-1 else year(getdate()) end 
 -- and month=case when month(getdate())=2 then 12 else month(getdate())-2 end
 -- and custgroup='ttplatform')

BEGIN

Delete MonthlyBillingData
where year=@prioryear and month=@priormonth and salestype='TT Projections'
Insert into MonthlyBillingData

Select * from
(
SELECT distinct
cast([userid] as varchar)+'-'+cast([companyid] as varchar)+'-'+ cast([billingaccount] as varchar)+'-'+cast(ProductId as char(5))+'-'+cast(Year(startdate) as varchar)+'-'+cast(Month(startdate) as varchar)+cast(startdate as varchar)+'-'+RevenueDestination as Id, Month(startdate) as Month, Year(startdate) as Year, 
'' as CrmId, [billingaccount] as AccountId, 0 as ExchangeId, 'TTPlatform' as CustGroup, '' as PriceGroup, '' as PriceGroupDesc, ProductId as ProductSku, isnull(Salesprice,0) as BilledAmount, 
deliveryname as AdditionalInfo,  isnull(R.Region,'-') as Region, isnull(City,'') as City, isnull(isnull(statecode,'00'),'') as State, countrycode as Country, '' as BranchId, '' as Action, 1 as LicenseCount, 1 as BillableLicenseCount, 0 as NonBillableLicenseCount, 
'' as TTChangeType, '' as CreditReason, '' as TTLICENSEFILEID, 'TT Projections' as SalesType, '' as ConfigId, zipcode as DeliveryZipCode, description as TTNotes, startdate as TTBillStart, isnull(Enddate,'1/1/1900') as TTBillEnd, 0 as LineRecId,
'' as SalesId, 0 as Tax, 0 as Currency, 1 as TTUsage, 0 as LineAmount, 0 as TAXAMOUNT, salesprice as TotalAmount, 0 as InvoiceId, '' as CREATEDDATETIME, DELIVERYNAME, deliveryname as TTDESCRIPTION, 
'' as TTCONVERSIONDATE, '' as DataAreaId, 0 as SalesPrice, 0 as ActiveBillableToday, 0 as ActiveNonBillableToday, getdate() as LastUpdatedDate, '' as TTBillingOnBehalfOf, 
Deliveryname as  Username, 0 as TTSalesCommissionException, '' as TTUserCompany, '' as CreatedDate, '' as ModifiedDate, '' as MIC,0 as TTPassThroughPrice,B.UserId as TTUserId
,B.TTID,B.TTIDEmail
FROM chisql20.[TTWebBillingProcessor].[dbo].[BillableLines] B
Left Join (SELECT distinct [Country],[CountryName],Region FROM [BIDW].[dbo].[RegionMap]
                 where CountryName is not null)R
			  on B.Countrycode=R.Country
where year(startdate)=@prioryear and month(startdate)=@priormonth 
--and companyid=10 
--and environment='Live'
--year(startdate)=(case when @month=12 then @Year+1 else @year end) and month(startdate)=(case when @Month=12 then 1 else @Month+1 end) and companyid=10
and userid in (select distinct userid from chisql20.[MESS].dbo.UserLoginHistory where year=@prioryear and month = @priormonth)
)Final 
Where Id is not null and country is not null

END


---------------------Load Current Month TT Projections-------------------------

IF (select COUNT(*) from chisql12.fillhub.dbo.invoicemonth   
 where YEAR=Year(getdate()) AND MONTH =Month(getdate())) = 0
 --and
 --(select count(*) from MonthlyBillingData
 --where YEAR=Year(getdate()) AND MONTH =Month(getdate()) and productsku=80001 and CustGroup='TTPlatform')=0


BEGIN

Delete MonthlyBillingData
where year=year(getdate()) and month=month(getdate()) and salestype='TT Projections'
Insert into MonthlyBillingData

Select * from 
(
SELECT distinct
cast([userid] as varchar)+'-'+cast([companyid] as varchar)+'-'+ cast([billingaccount] as varchar)+'-'+cast(ProductId as char(5))+'-'+cast(Year(startdate) as varchar)+'-'+cast(Month(startdate) as varchar)+cast(startdate as varchar)+'-'+RevenueDestination as Id, Month(startdate) as Month, Year(startdate) as Year, 
'' as CrmId, [billingaccount] as AccountId, 0 as ExchangeId, 'TTPlatform' as CustGroup, '' as PriceGroup, '' as PriceGroupDesc, ProductId as ProductSku, isnull(Salesprice,0) as BilledAmount, 
deliveryname as AdditionalInfo,  isnull(R.Region,'-') as Region, isnull(City,'') as City, isnull(isnull(statecode,'00'),'') as State, countrycode as Country, '' as BranchId, '' as Action, 1 as LicenseCount, 1 as BillableLicenseCount, 0 as NonBillableLicenseCount, 
'' as TTChangeType, '' as CreditReason, '' as TTLICENSEFILEID, 'TT Projections' as SalesType, '' as ConfigId, zipcode as DeliveryZipCode, description as TTNotes, startdate as TTBillStart, isnull(Enddate,'1/1/1900') as TTBillEnd, 0 as LineRecId,
'' as SalesId, 0 as Tax, NULL as Currency, 1 as TTUsage, 0 as LineAmount, 0 as TAXAMOUNT, salesprice as TotalAmount, 0 as InvoiceId, '' as CREATEDDATETIME, DELIVERYNAME, deliveryname as TTDESCRIPTION, 
'' as TTCONVERSIONDATE, '' as DataAreaId, 0 as SalesPrice, 0 as ActiveBillableToday, 0 as ActiveNonBillableToday, getdate() as LastUpdatedDate, '' as TTBillingOnBehalfOf, 
Deliveryname as  Username, 0 as TTSalesCommissionException, '' as TTUserCompany, '' as CreatedDate, '' as ModifiedDate, '' as MIC,0 as TTPassThroughPrice,B.UserId as TTUserId
,B.TTID,B.TTIDEmail
FROM chisql20.[TTWebBillingProcessor].[dbo].[BillableLines] B
Left Join (SELECT distinct [Country],[CountryName],Region FROM [BIDW].[dbo].[RegionMap]
                 where CountryName is not null)R
			  on B.Countrycode=R.Country
where year(startdate)=year(getdate()) and month(startdate)=month(getdate()) 
--and companyid=10 
--and environment='Live'
--year(startdate)=(case when @month=12 then @Year+1 else @year end) and month(startdate)=(case when @Month=12 then 1 else @Month+1 end) and companyid=10
and userid in (select distinct userid from chisql20.[MESS].dbo.UserLoginHistory where year=year(getdate()) and month = month(getdate()))
)Final 
Where Id is not null and country is not null

END



--------------------------------Temp Code for XT User Access Sales Lines----------------------------

--------------------Load for Prior Month until the month is closed-----------------

IF (select COUNT(*) from chisql12.fillhub.dbo.invoicemonth   
 where year=@prioryear and month=@priormonth) = 0 
 and 
 (select count(*) from MonthlyBillingData
 where year=@prioryear and month=@priormonth and ProductSku in (20991,20994) and salestype in ('AX Invoices','AX Sales Lines'))<=100


BEGIN

Delete MonthlyBillingData
where year=@prioryear and month=@priormonth and ProductSku in (20991,20994)


Insert into [dbo].[MonthlyBillingData]
SELECT distinct
cast(Year as varchar)+'-'+cast(Month as varchar)+'-'+cast([userid] as varchar)+'-'+ cast(ic.companyid as varchar)+'-'+cast(p.sku as char(5)) as Id, Month, Year, 
'' as CrmId, ic.companyid as AccountId, 0 as ExchangeId, 'MultiBrokr' as CustGroup, '' as PriceGroup, '' as PriceGroupDesc, p.sku as ProductSku, isnull(total,0) as BilledAmount, 
username as AdditionalInfo, isnull(R.Region,'-') as Region, isnull(City,'') as City, isnull(state,'') as State, I.Country, '' as BranchId, '' as Action, 1 as LicenseCount, 1 as BillableLicenseCount, 0 as NonBillableLicenseCount, 
'' as TTChangeType, '' as CreditReason, '' as TTLICENSEFILEID, '7x Projections' as SalesType, '' as ConfigId, postalcode as DeliveryZipCode, '' as TTNotes, cast(str(month)+'/'+str(1)+'/'+str(year) as date) as TTBillStart, isnull(eomonth(cast(str(month)+'/'+str(1)+'/'+str(year) as date)),'1/1/1900') as TTBillEnd, 0 as LineRecId,
'' as SalesId, Tax, 0 as Currency, 1 as TTUsage, subtotal as LineAmount, tax as TAXAMOUNT, total as TotalAmount, 0 as InvoiceId, '' as CREATEDDATETIME, username as DELIVERYNAME, userid as TTDESCRIPTION, 
'' as TTCONVERSIONDATE, revenuedestination as DataAreaId, fillcategoryrate as SalesPrice, 1 as ActiveBillableToday, 0 as ActiveNonBillableToday, getdate() as LastUpdatedDate, '' as TTBillingOnBehalfOf, 
username as  Username, 0 as TTSalesCommissionException, '' as TTUserCompany, '' as CreatedDate, '' as ModifiedDate, '' as MIC,0 as TTPassThroughPrice,0 as TTUserId
,'' as TTID,'' as TTIDEmail
FROM chisql20.[Licensing2].[dbo].[InvoiceFillDataCache] I
left join (select [InvoiceConfigId],[CompanyId] from chisql20.[Licensing2].[dbo].[InvoiceConfig]) IC on i.invoiceconfigid=ic.invoiceconfigid
left join ( select distinct ProductId,sku from chisql20.[Licensing2].[dbo].[Product]) P on I.productid=p.productid
Left Join (SELECT distinct [Country],[CountryName],Region FROM [BIDW].[dbo].[RegionMap]
                 where CountryName is not null)R
			  on I.Country=R.Country
where year=@prioryear and month=@priormonth and p.sku in (20991,20994)

END


--------------------------------Load for current month until the month is closed-----------------------

IF (select COUNT(*) from chisql12.fillhub.dbo.invoicemonth   
 where YEAR=Year(getdate()) AND MONTH =Month(getdate())) = 0

BEGIN

Delete MonthlyBillingData
where year=year(getdate()) and month=month(getdate()) and ProductSku in (20991,20994)


Insert into [dbo].[MonthlyBillingData]
SELECT distinct
cast(Year as varchar)+'-'+cast(Month as varchar)+'-'+cast([userid] as varchar)+'-'+ cast(ic.companyid as varchar)+'-'+cast(p.sku as char(5)) as Id, Month, Year, 
'' as CrmId, ic.companyid as AccountId, 0 as ExchangeId, 'MultiBrokr' as CustGroup, '' as PriceGroup, '' as PriceGroupDesc, p.sku as ProductSku, isnull(total,0) as BilledAmount, 
username as AdditionalInfo, isnull(R.Region,'-') as Region, isnull(City,'') as City, isnull(state,'') as State, I.Country, '' as BranchId, '' as Action, 1 as LicenseCount, 1 as BillableLicenseCount, 0 as NonBillableLicenseCount, 
'' as TTChangeType, '' as CreditReason, '' as TTLICENSEFILEID, '7x Projections' as SalesType, '' as ConfigId, postalcode as DeliveryZipCode, '' as TTNotes, cast(str(month)+'/'+str(1)+'/'+str(year) as date) as TTBillStart, isnull(eomonth(cast(str(month)+'/'+str(1)+'/'+str(year) as date)),'1/1/1900') as TTBillEnd, 0 as LineRecId,
'' as SalesId, Tax, 0 as Currency, 1 as TTUsage, subtotal as LineAmount, tax as TAXAMOUNT, total as TotalAmount, 0 as InvoiceId, '' as CREATEDDATETIME, username as DELIVERYNAME, userid as TTDESCRIPTION, 
'' as TTCONVERSIONDATE, revenuedestination as DataAreaId, fillcategoryrate as SalesPrice, 1 as ActiveBillableToday, 0 as ActiveNonBillableToday, getdate() as LastUpdatedDate, '' as TTBillingOnBehalfOf, 
username as  Username, 0 as TTSalesCommissionException, '' as TTUserCompany, '' as CreatedDate, '' as ModifiedDate, '' as MIC, 0 as TTPassThroughPrice,0 as TTUserId
,'' as TTID,'' as TTIDEmail
FROM chisql20.[Licensing2].[dbo].[InvoiceFillDataCache] I
left join (select [InvoiceConfigId],[CompanyId] from chisql20.[Licensing2].[dbo].[InvoiceConfig]) IC on i.invoiceconfigid=ic.invoiceconfigid
left join ( select distinct ProductId,sku from chisql20.[Licensing2].[dbo].[Product]) P on I.productid=p.productid
Left Join (SELECT distinct [Country],[CountryName],Region FROM [BIDW].[dbo].[RegionMap]
                 where CountryName is not null)R
			  on I.Country=R.Country
where year=year(getdate()) and month=month(getdate()) and p.sku in (20991,20994)

END




--------------------------------------------------------------------------------

-------------------------------------------------Unused Code -----------------------------------------------------------------------------------------------

--------------------------------------refresh Account info
/* -- from ABS
Delete Account
insert into Account
select  
	 Accountid
	,AccountName
	,Legalname
	,IsActive
	,AccountStatusId
	,CrmId
	,CustomerType
from tt_internal.dbo.account
*/

-- from AX
/*
Delete Account
insert into Account
select ACCOUNTNUM as Accountid,  NAME as AccountName ,  NAME as Legalname, 1 as IsActive , 1 as AccountSatusId , TTCRMID as CrmId , NULL as CustomerType
from TT_DYANX09_PRD.dbo.CUSTTABLE 
*/



--------------------------------------refresh Product info
/* -- from ABS
Delete Product
insert into Product
select 
 ProductId as ProductSku
,p.Name as ProductName
,pc.ProductCategoryId
,pc.[Description] as ProductCategoryName
,p.IsSupported
,p.IsActive
from chisql01.products.dbo.products p
inner join chisql01.products.dbo.productcategories pc 
		on p.ProductCategoryId = pc.ProductCategoryId
-- add some phantom products to add a touch of complexity -- intoduced when statring billing on AX
insert into Product values ( 20999
,'X_TRADER® Pro Transaction'
,1
,'Trading Products'
,1
,1)

insert into Product values ( 20998
,'Fix Adapter Transaction'
,2
,'API Products'
,1
,1)
*/


--------------------------------------refresh branch info
/* -- from ABS
Delete Branch
insert into Branch
select
  ttBranchId as BranchId
  ,ttBranchName as BranchName
  ,isactive1 as Active 
from tt_internal.dbo.ttbranch
*/

--from AX

--------------------------------------refresh ticket info 
/*
Delete [Ticket]
insert into [Ticket]
select [TicketID]
	  ,DATEPART(month,[CreatedDate]) as [month]	
	  ,DATEPART(year,[CreatedDate]) as [year] 	
      ,[CreatedDate]
      ,[Summary]
      ,ts.Name as [TicketStatus]
      ,tor.Name as [TicketOrigin]
	  ,tl.name as [TicketLocation]
	  ,[ContactId] as [CrmContactId]
	  ,[AccountID] as [CrmAccountId]
      ,ProductSku as [ProductID]
      ,[ProductVersionID]
      ,[PCR]
      ,tes.[Name] as [EarStatus]
      ,tept.[Name] as EarProductTeam
      ,t.LocationId as [TTBranchID]
      ,it.[name] as [IssueType]
      ,it.[Category] as [IssueTypeCategory]
      ,rc.[name] as [RootCause]
      ,tp.[name] Priority
	  ,tt.[Name] as Team
	  ,ClosedDate
	  ,case when (t.StatusId in (9,7)) then (select min(CreatedDate) from chisql01.supportnet.dbo.[Action] where ticketid = t.ticketId and t.StatusId in (9,7)) else null end as PendingDate
	  ,(select count(*) from chisql01.supportnet.dbo.[Action] where ticketid = t.ticketId and ActionTypeEnum in ('Note','Notification')) as SupportActions
FROM chisql01.supportnet.dbo.[Ticket] t  with (NOLOCK)
inner join chisql01.supportnet.dbo.TicketStatus ts on t.StatusId = ts.StatusId
inner join chisql01.supportnet.dbo.TicketOrigin tor on t.OriginId = tor.OriginId
left join chisql01.supportnet.dbo.RootCauseType rc on rc.RootCauseTypeId = t.RootCauseTypeId
left join chisql01.supportnet.dbo.IssueType it on it.IssueTypeId = t.IssueTypeId
left join chisql01.supportnet.dbo.TicketPriority tp on tp.PriorityId = t.PriorityId
left join chisql01.supportnet.dbo.Location tl on tl.LocationId = t.LocationId
left join chisql01.supportnet.dbo.Team tt on tt.TeamId = t.TeamId 
left join chisql01.supportnet.dbo.EarStatus tes on tes.EarStatusId = t.EarStatusId
left join chisql01.supportnet.dbo.EarProductTeam tept on tept.EarProductTeamId = t.EarProductTeamId
where t.[CreatedDate] > dateadd(month,-18, getdate())
*/

-----------------------------------------------------------------------------------------------------------------------------------------------------------