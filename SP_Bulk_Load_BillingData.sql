USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_Bulk_Load_BillingData]    Script Date: 7/29/2014 2:31:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Ram>
-- Create date: <08/08/2013:1630>
-- Description:	<Load Apollo Data to DWH>
-- =============================================
ALTER PROCEDURE [dbo].[SP_Bulk_Load_BillingData]

AS


BEGIN

	SET NOCOUNT ON;
	
--truncate table dbo.MonthlyBillingData
delete from dbo.MonthlyBillingData
where year in (2013,2014)

insert into dbo.MonthlyBillingData
select Id, Month, Year, CrmId, AccountId,isnull(d.exchangeid,0) as ExchangeId, CustGroup,PriceGroup,C.ProductSku, BilledAmount, AdditionalInfo, Region, City, State, Country, BranchId, Action, LicenseCount, BillableLicenseCount, NonBillableLicenseCount, TTChangeType, CreditReason, TTLICENSEFILEID, SalesType, ConfigId, DeliveryZipCode, TTNotes, TTBillStart, TTBillEnd, LineRecId, SalesId, Tax, TaxRate, TTUsage, LineAmount, TAXAMOUNT, TotalAmount, InvoiceId, CREATEDDATETIME, DELIVERYNAME, TTDESCRIPTION, DataAreaId, SalesPrice, ActiveBillableToday, ActiveNonBillableToday,GETDATE() as LastUpdatedDate
from
(
select MonthlyBillingData.*,p.ProductName from chiaxsql01.apollo.dbo.MonthlyBillingData MonthlyBillingData
left join Product P on MonthlyBillingData.ProductSku = P.ProductSku
where YEAR in (2013,2014)
) c
left join
(
select a.*, b.* from
(
select ProductSku, rtrim(replace(ProductName,'Gateway',''))as Productname, ProductCategoryId, ProductCategoryName from dbo.Product
--where ProductName like 'CME%'
)a
join
(
select * from fillhublink.fillhub.dbo.Exchanges
--where exchangeshortname ='CME'
)b 
on a.Productname=b.exchangeshortname
)d
on c.ProductSku=d.ProductSku and rtrim(replace(c.ProductName,'Gateway',''))=d.Productname






-------------------------------------------------------Region Map Table--------------------------------------------------------------
truncate table dbo.RegionMap
insert into dbo.RegionMap
select Region,Country,[State],City,ISNULL(Salesoffice,City) as SalesOffice from
(
select case when B.SalesRegion is null then A.Region else B.SalesRegion end as Region,A.COUNTRY,A.STATE,isnull(A.CITY,'Unassigned')as City,B.SalesOffice
FROM
( 
  SELECT distinct Region,City,Country,isnull(nullif(State,''),'Unassigned') as State
  FROM chiaxsql01.[Apollo].[dbo].[MonthlyBillingData]
  )A
  LEFT OUTER JOIN
  (
  SELECT [Country]
      ,isnull(nullif([State],''),'Unassigned') as State
      ,[SalesOffice]
      ,[SalesRegion]
  FROM chiaxsql01.[Apollo].[dbo].[RegionMap]
  )B
  ON A.Country=B.Country AND A.State=B.State
)Q
where q.region NOT IN ('None','Unassigned')


 --------------------------------------------------------------------------------------------------------------------------------------------



-------------------------------------------------------Account Table--------------------------------------------------------------
/*select A.Accountid,A.AccountName,isnull(A.MasterAccountName,A.AccountName) as MasterAccountName ,A.CrmId,BA.MultiBrokerNetworkId,BA.CustomerGroup
from
(
select A.ACCOUNTNUM as Accountid,  A.NAME as AccountName ,  A.NAME as Legalname, 1 as IsActive , 1 as AccountSatusId , A.TTCRMID as CrmId , NULL as CustomerType
, B.Name as MasterAccountName
from TT_DYANX09_PRD.dbo.CUSTTABLE A
left  join chisql19.Trading_Technologies_MSCRM.dbo.AccountBase B on A.TTCRMID = cast(B.AccountId as varchar(50))
) A
left join
fillhublink.fillhub.dbo.BillingAccounts BA
on A.Accountid=BA.BillingAccountId*/
 --------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------Temp Account Table--------------------------------------------------------------
truncate table dbo.Account
insert into Account
select Accountid, AccountName, MasterAccountName, A.CrmId, MultiBrokerNetworkId, CustomerGroup from chiaxsql01.apollo.dbo.account A
left join fillhublink.fillhub.dbo.BillingAccounts BA
on A.Accountid=BA.BillingAccountId
 --------------------------------------------------------------------------------------------------------------------------------------------
 
 -------------------------------------------------------Load  Product Table--------------------------------------------------------------
truncate table dbo.Product
insert into dbo.Product
select ProductSku, ProductName, ProductCategoryId, ProductCategoryName  from chiaxsql01.apollo.dbo.Product 

 --------------------------------------------------------------------------------------------------------------------------------------------

END
