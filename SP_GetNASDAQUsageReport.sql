USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetNASDAQUsageReport_Old]    Script Date: 04/03/2014 09:40:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[GetNASDAQUsageReport]
     
AS
BEGIN

Create table #tempCSV
(CustomerAccountNumber varchar(50),EffectiveDateOfInventoryChange varchar(50),Productcode varchar(50),ProductQuantityChanged float(50),NewProductQuantity float (50)
,CompanyName varchar(100),CompanyAddress varchar(200),City varchar(50),State varchar(20),PostalCode varchar(20),Country char(10) )

insert into #tempCSV
select A.AccountId as CustomerAccountNumber,(SELECT convert(char(10),DATEADD(mm, DATEDIFF(mm, 0, GETDATE()), 0),112)) as EffectiveDateOfInventoryChange,'NDTV' as ProductCode,A.NewProductQuantity-B.NewProductQuantity as ProductQuantityChanged,A.NewProductQuantity,a.CompanyName,a.address as CompanyAddress,a.city as City,a.state as [State],a.postcode as PostalCode,a.Country from 
(
select F.AccountId, '' as EffectiveDateOfInventoryChange,ProductSku as ProductCode,'' as ProductQuantityChanged,
count(ProductSku) as NewProductQuantity,AccountName as CompanyName,d.[Address],d.city,d.[state],d.zipcode as PostCode,
d.countryregionid as Country,d.contactpersonid,d.phone
from MonthlyBillingData F join Exchange E
on f.ExchangeId=e.ExchangeId
join Account A
on F.AccountId=A.Accountid
join (select accountnum,[address],city,[state],zipcode,countryregionid, contactpersonid,phone from chiaxsql01.TT_DYANX09_PRD.dbo.CUSTTABLE) D
on f.AccountId=d.accountnum
where ProductSku=10392
--where E.ExchangeName like 'NYSE%'
and YEAR=YEAR(getdate()) and MONTH=MONTH(getdate())
group by F.AccountId,ProductSku
,AccountName,d.[Address],d.city,d.[state],d.zipcode,d.countryregionid,d.contactpersonid,d.phone
)A
join 
(
select F.AccountId, '' as EffectiveDateOfInventoryChange,ProductSku as ProductCode,'' as ProductQuantityChanged,
count(ProductSku) as NewProductQuantity,AccountName as CompanyName,d.[Address],d.city,d.[state],d.zipcode as PostCode,
d.countryregionid as Country,d.contactpersonid,d.phone
from MonthlyBillingData F join Exchange E
on f.ExchangeId=e.ExchangeId
join Account A
on F.AccountId=A.Accountid
join (select accountnum,[address],city,[state],zipcode,countryregionid, contactpersonid,phone from chiaxsql01.TT_DYANX09_PRD.dbo.CUSTTABLE) D
on f.AccountId=d.accountnum
where ProductSku=10392
--where E.ExchangeName like 'NYSE%'
and YEAR=YEAR(getdate()) and MONTH=MONTH(getdate())-1
group by F.AccountId,ProductSku
,AccountName,d.[Address],d.city,d.[state],d.zipcode,d.countryregionid,d.contactpersonid,d.phone
)B
on A.AccountId=B.AccountId and A.ProductCode=B.ProductCode

select '' as VendorID,'T' as Report,convert(char(10),GETDATE(),112) as DateFileCreated,replace(CONVERT(VARCHAR(8),GETDATE(),108),':','') as TimeFileCreated,
(SELECT convert(char(10),DATEADD(mm, DATEDIFF(mm, 0, GETDATE()), 0),112)) as FirstDayOfReportPeriod,
(SELECT convert(char(10),DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE())+1,0)),112)) as LastDayOfReportPeriod,
(select COUNT(*) from #tempCSV)+1 as TotalNumberOfRows

select * from #tempCSV

drop table #tempCSV

end





