/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.2218)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2017
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/

USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_Load_TT_7x_Projections_BillingData]    Script Date: 7/23/2018 4:02:30 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[SP_Load_TT_7x_Projections_BillingData]


AS

BEGIN


------------------Temp code for TT Projections ------------------------------
Declare @prioryear int, @priormonth int
set @prioryear = case when month(getdate())=1 then year(getdate())-1 else year(getdate()) end 
set @priormonth = case when month(getdate())=1 then 12 else month(getdate())-1 End

----------------------Load Prior Month TT Projections-----------------------

IF (select COUNT(*) from chisql12.fillhub.dbo.invoicemonth   
 where YEAR=@prioryear AND MONTH =@priormonth) = 0 
 and 
 (select count(*) from MonthlyBillingData
 where YEAR=@prioryear AND MONTH =@priormonth and custgroup='ttplatform' 
 and salestype in ('AX Sales Lines','AX Invoices') and ProductSku like '8%')<=100


BEGIN

Delete MonthlyBillingData
where year=@prioryear and month=@priormonth and salestype='TT Projections'
Insert into MonthlyBillingData

Select * from
(
SELECT distinct
cast([userid] as varchar)+'-'+cast(lineid as varchar)+'-'+'-'+cast([companyid] as varchar)+'-'+ cast([billingaccount] as varchar)+'-'+cast(ProductId as char(5))+'-'+cast(Year(startdate) as varchar)+'-'+cast(Month(startdate) as varchar)+cast(startdate as varchar)+'-'+RevenueDestination as Id, Month(startdate) as Month, Year(startdate) as Year, 
CrmId, [billingaccount] as AccountId, 0 as ExchangeId, 'TTPlatform' as CustGroup, '' as PriceGroup, '' as PriceGroupDesc, ProductId as ProductSku, isnull(Salesprice,0) as BilledAmount, 
deliveryname as AdditionalInfo,  isnull(R.Region,'-') as Region, isnull(City,'') as City, isnull(isnull(statecode,'00'),'-') as State, countrycode as Country, isnull(r.branchid,0) as BranchId, '' as Action, 1 as LicenseCount, 
case when productid in (81052,81053) then 0 else 1 end as BillableLicenseCount ------ Code added to make license count=0 for Advanced Options on TT & Pro v
,case when productid in (81052,81053) then 1 else 0 end as NonBillableLicenseCount, 
'' as TTChangeType, '' as CreditReason, '' as TTLICENSEFILEID, 'TT Projections' as SalesType, '' as ConfigId, zipcode as DeliveryZipCode, description as TTNotes, startdate as TTBillStart, isnull(Enddate,'1/1/1900') as TTBillEnd, 0 as LineRecId,
'' as SalesId, 0 as Tax, 0 as Currency, 1 as TTUsage, 0 as LineAmount, 0 as TAXAMOUNT, salesprice as TotalAmount, 0 as InvoiceId, '' as CREATEDDATETIME, DELIVERYNAME, deliveryname as TTDESCRIPTION, 
'' as TTCONVERSIONDATE, '' as DataAreaId, 0 as SalesPrice, 0 as ActiveBillableToday, 0 as ActiveNonBillableToday, getdate() as LastUpdatedDate, '' as TTBillingOnBehalfOf, 
Deliveryname as  Username, 0 as TTSalesCommissionException, '' as TTUserCompany, '' as CreatedDate, '' as ModifiedDate, '' as MIC,0 as TTPassThroughPrice,B.UserId as TTUserId
,B.TTID,B.TTIDEmail,'Not-Capped' as UserCapped
FROM chisql20.[TTWebBillingProcessor].[dbo].[BillableLines] B
Left join
(
SELECT Region,[Country],isnull(nullif([State],''),'-') as State,[SalesOffice],BranchId
  FROM [BIDW].[dbo].[RegionMap] R
  left join
  (
  SELECT [BranchId],[BranchName]
  FROM [BIDW].[dbo].[Branch]
  where branchname like 'Office%'
  )B on R.SalesOffice=B.BranchName
  )R on b.countrycode=r.Country and isnull(nullif(b.statecode,''),'-')=r.state
left join bidw.dbo.Account A on b.billingaccount=a.Accountid   -------- Gives the crmid looking at Billing Account Id
where year(startdate)=@prioryear and month(startdate)=@priormonth 
--and userid in (select distinct userid from chisql20.[MESS].dbo.UserLoginHistory where year=@prioryear and month = @priormonth)
)Final 
Where Id is not null and country is not null

END


---------------------Load Current Month TT Projections-------------------------

IF (select COUNT(*) from chisql12.fillhub.dbo.invoicemonth   
 where YEAR=Year(getdate()) AND MONTH =Month(getdate())) = 0
 

BEGIN

Delete MonthlyBillingData
where year=year(getdate()) and month=month(getdate()) and salestype='TT Projections'
Insert into MonthlyBillingData

Select * from 
(
SELECT distinct
cast([userid] as varchar)+'-'+cast(lineid as varchar)+'-'+'-'+cast([companyid] as varchar)+'-'+ cast([billingaccount] as varchar)+'-'+cast(ProductId as char(5))+'-'+cast(Year(startdate) as varchar)+'-'+cast(Month(startdate) as varchar)+cast(startdate as varchar)+'-'+RevenueDestination as Id, Month(startdate) as Month, Year(startdate) as Year, 
CrmId, [billingaccount] as AccountId, 0 as ExchangeId, 'TTPlatform' as CustGroup, '' as PriceGroup, '' as PriceGroupDesc, ProductId as ProductSku, isnull(Salesprice,0) as BilledAmount, 
deliveryname as AdditionalInfo,  isnull(R.Region,'-') as Region, isnull(City,'') as City, isnull(isnull(statecode,'00'),'-') as State, countrycode as Country, isnull(r.branchid,0) as BranchId, '' as Action, 1 as LicenseCount, 
case when productid in (81052,81053) then 0 else 1 end as BillableLicenseCount ------ Code added to make license count=0 for Advanced Options on TT & Pro 
,case when productid in (81052,81053) then 1 else 0 end as NonBillableLicenseCount, 
'' as TTChangeType, '' as CreditReason, '' as TTLICENSEFILEID, 'TT Projections' as SalesType, '' as ConfigId, zipcode as DeliveryZipCode, description as TTNotes, startdate as TTBillStart, isnull(Enddate,'1/1/1900') as TTBillEnd, 0 as LineRecId,
'' as SalesId, 0 as Tax, NULL as Currency, 1 as TTUsage, 0 as LineAmount, 0 as TAXAMOUNT, salesprice as TotalAmount, 0 as InvoiceId, '' as CREATEDDATETIME, DELIVERYNAME, deliveryname as TTDESCRIPTION, 
'' as TTCONVERSIONDATE, '' as DataAreaId, 0 as SalesPrice, 0 as ActiveBillableToday, 0 as ActiveNonBillableToday, getdate() as LastUpdatedDate, '' as TTBillingOnBehalfOf, 
Deliveryname as  Username, 0 as TTSalesCommissionException, '' as TTUserCompany, '' as CreatedDate, '' as ModifiedDate, '' as MIC,0 as TTPassThroughPrice,B.UserId as TTUserId
,B.TTID,B.TTIDEmail,'Not-Capped' as UserCapped
FROM chisql20.[TTWebBillingProcessor].[dbo].[BillableLines] B
Left join
(
SELECT Region,[Country],isnull(nullif([State],''),'-') as State,[SalesOffice],BranchId
  FROM [BIDW].[dbo].[RegionMap] R
  left join
  (
  SELECT [BranchId],[BranchName]
  FROM [BIDW].[dbo].[Branch]
  where branchname like 'Office%'
  )B on R.SalesOffice=B.BranchName
  )R on b.countrycode=r.Country and isnull(nullif(b.statecode,''),'-')=r.state
left join bidw.dbo.Account A on b.billingaccount=a.Accountid   -------- Gives the crmid looking at Billing Account Id

where year(startdate)=year(getdate()) and month(startdate)=month(getdate()) 
--and userid in (select distinct userid from chisql20.[MESS].dbo.UserLoginHistory where year=year(getdate()) and month = month(getdate()))
  )Final 
Where Id is not null and final.country is not null

END



--------------------------------Temp Code for XT User Access Sales Lines----------------------------

--------------------Load for Prior Month until the month is closed-----------------

IF (select COUNT(*) from chisql12.fillhub.dbo.invoicemonth   
 where year=@prioryear and month=@priormonth) = 0 
 and 
 (select count(*) from MonthlyBillingData
 where year=@prioryear and month=@priormonth and ProductSku in (20991,20994) 
 and salestype in ('AX Invoices','AX Sales Lines'))<=100


BEGIN

Delete MonthlyBillingData
where year=@prioryear and month=@priormonth and ProductSku in (20991,20994)


Insert into [dbo].[MonthlyBillingData]
SELECT distinct
cast(Year as varchar)+'-'+cast(Month as varchar)+'-'+cast([userid] as varchar)+'-'+ cast(ic.companyid as varchar)+'-'+cast(p.sku as char(5)) as Id, Month, Year, 
CrmId, ic.companyid as AccountId, 0 as ExchangeId, 'MultiBrokr' as CustGroup, '' as PriceGroup, '' as PriceGroupDesc, p.sku as ProductSku, isnull(total,0) as BilledAmount, 
username as AdditionalInfo, isnull(R.Region,'-') as Region, isnull(City,'') as City, isnull(I.state,'-') as State, I.Country, isnull(branchid,0) as BranchId, '' as Action, 1 as LicenseCount, 1 as BillableLicenseCount, 0 as NonBillableLicenseCount, 
'' as TTChangeType, '' as CreditReason, '' as TTLICENSEFILEID, '7x Projections' as SalesType, '' as ConfigId, postalcode as DeliveryZipCode, '' as TTNotes, cast(str(month)+'/'+str(1)+'/'+str(year) as date) as TTBillStart, isnull(eomonth(cast(str(month)+'/'+str(1)+'/'+str(year) as date)),'1/1/1900') as TTBillEnd, 0 as LineRecId,
'' as SalesId, Tax, 0 as Currency, 1 as TTUsage, subtotal as LineAmount, tax as TAXAMOUNT, total as TotalAmount, 0 as InvoiceId, '' as CREATEDDATETIME, username as DELIVERYNAME, userid as TTDESCRIPTION, 
'' as TTCONVERSIONDATE, revenuedestination as DataAreaId, fillcategoryrate as SalesPrice, 1 as ActiveBillableToday, 0 as ActiveNonBillableToday, getdate() as LastUpdatedDate, '' as TTBillingOnBehalfOf, 
username as  Username, 0 as TTSalesCommissionException, '' as TTUserCompany, '' as CreatedDate, '' as ModifiedDate, '' as MIC,0 as TTPassThroughPrice,0 as TTUserId
,'' as TTID,'' as TTIDEmail,'Not-Capped' as UserCapped
FROM chisql20.[Licensing2].[dbo].[InvoiceFillDataCache] I
left join (select [InvoiceConfigId],[CompanyId] from chisql20.[Licensing2].[dbo].[InvoiceConfig]) IC on i.invoiceconfigid=ic.invoiceconfigid
left join ( select distinct ProductId,sku from chisql20.[Licensing2].[dbo].[Product]) P on I.productid=p.productid
Left join
(
SELECT Region,[Country],isnull(nullif([State],''),'-') as State,[SalesOffice],BranchId
  FROM [BIDW].[dbo].[RegionMap] R
  left join
  (
  SELECT [BranchId],[BranchName]
  FROM [BIDW].[dbo].[Branch]
  where branchname like 'Office%'
  )B on R.SalesOffice=B.BranchName
  )R on I.country=r.Country and isnull(nullif(I.state,''),'-')=r.state
left join bidw.dbo.Account A on ic.companyid=a.Accountid   -------- Gives the crmid looking at Billing Account Id
where year=@prioryear and month=@priormonth and p.sku in (20991,20994)
and total<=50

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
CrmId, ic.companyid as AccountId, 0 as ExchangeId, 'MultiBrokr' as CustGroup, '' as PriceGroup, '' as PriceGroupDesc, p.sku as ProductSku, isnull(total,0) as BilledAmount, 
username as AdditionalInfo, isnull(R.Region,'-') as Region, isnull(City,'') as City, isnull(I.state,'-') as State, I.Country, isnull(r.branchid,0) as BranchId, '' as Action, 1 as LicenseCount, 1 as BillableLicenseCount, 0 as NonBillableLicenseCount, 
'' as TTChangeType, '' as CreditReason, '' as TTLICENSEFILEID, '7x Projections' as SalesType, '' as ConfigId, postalcode as DeliveryZipCode, '' as TTNotes, cast(str(month)+'/'+str(1)+'/'+str(year) as date) as TTBillStart, isnull(eomonth(cast(str(month)+'/'+str(1)+'/'+str(year) as date)),'1/1/1900') as TTBillEnd, 0 as LineRecId,
'' as SalesId, Tax, 0 as Currency, 1 as TTUsage, subtotal as LineAmount, tax as TAXAMOUNT, total as TotalAmount, 0 as InvoiceId, '' as CREATEDDATETIME, username as DELIVERYNAME, userid as TTDESCRIPTION, 
'' as TTCONVERSIONDATE, revenuedestination as DataAreaId, fillcategoryrate as SalesPrice, 1 as ActiveBillableToday, 0 as ActiveNonBillableToday, getdate() as LastUpdatedDate, '' as TTBillingOnBehalfOf, 
username as  Username, 0 as TTSalesCommissionException, '' as TTUserCompany, '' as CreatedDate, '' as ModifiedDate, '' as MIC, 0 as TTPassThroughPrice,0 as TTUserId
,'' as TTID,'' as TTIDEmail,'Not-Capped' as UserCapped
FROM chisql20.[Licensing2].[dbo].[InvoiceFillDataCache] I
left join (select [InvoiceConfigId],[CompanyId] from chisql20.[Licensing2].[dbo].[InvoiceConfig]) IC on i.invoiceconfigid=ic.invoiceconfigid
left join ( select distinct ProductId,sku from chisql20.[Licensing2].[dbo].[Product]) P on I.productid=p.productid
Left join
(
SELECT Region,[Country],isnull(nullif([State],''),'-') as State,[SalesOffice],BranchId
  FROM [BIDW].[dbo].[RegionMap] R
  left join
  (
  SELECT [BranchId],[BranchName]
  FROM [BIDW].[dbo].[Branch]
  where branchname like 'Office%'
  )B on R.SalesOffice=B.BranchName
  )R on I.country=r.Country and isnull(nullif(I.state,''),'-')=r.state
left join bidw.dbo.Account A on ic.companyid=a.Accountid   -------- Gives the crmid looking at Billing Account Id
where year=year(getdate()) and month=month(getdate()) and p.sku in (20991,20994)
and total<=50

END

END