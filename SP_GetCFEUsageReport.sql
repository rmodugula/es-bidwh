USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetCFEUsageReport]    Script Date: 02/21/2014 15:27:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[GetCFEUsageReport]
     
AS
BEGIN

--Create table #tempCSV
--(CustomerAccountNumber varchar(50),EffectiveDateOfInventoryChange varchar(50),Productcode varchar(50),ProductQuantityChanged float(50),NewProductQuantity float (50)
--,CompanyName varchar(100),CompanyAddress varchar(200),City varchar(50),State varchar(20),PostalCode varchar(20),Country char(10) )

--insert into #tempCSV

select A.AccountId as CustomerAccountNumber,(SELECT convert(char(10),DATEADD(mm, DATEDIFF(mm, 0, GETDATE()), 0),112)) as EffectiveDateOfInventoryChange,
'CFE' as ProductCode,isnull(A.NewProductQuantity-B.NewProductQuantity,0) as ProductQuantityChanged,A.NewProductQuantity,a.CompanyName,a.address as CompanyAddress,a.city as City,a.state as [State],a.postcode as PostalCode,a.Country from 
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
where ProductSku=10155
--where E.ExchangeName like 'NYSE%'
and YEAR=case when month(getdate())=1 then YEAR(getdate())-1 else YEAR(getdate()) end
and MONTH=case when month(getdate())=1 then 12 else MONTH(getdate())-1 end
group by F.AccountId,ProductSku
,AccountName,d.[Address],d.city,d.[state],d.zipcode,d.countryregionid,d.contactpersonid,d.phone
)A
left join 
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
where ProductSku=10155
--where E.ExchangeName like 'NYSE%'
and YEAR= case when month(getdate())in (1,2) then YEAR(getdate())-1 else YEAR(getdate()) end 
and MONTH=case when month(getdate())=2  then 12  
               when month(getdate())=1  then 11 else month(getdate())-2 end 
group by F.AccountId,ProductSku
,AccountName,d.[Address],d.city,d.[state],d.zipcode,d.countryregionid,d.contactpersonid,d.phone
)B
on A.AccountId=B.AccountId and A.ProductCode=B.ProductCode

--select * from #tempCSV

--drop table #tempCSV

end





