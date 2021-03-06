USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_Load_LicenseData]    Script Date: 10/22/2015 1:12:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_Load_LicenseData]
  
AS
BEGIN

----------------------------Load Network Table from LicenseFile Table in FillHub-------------------------
Truncate table Network
Insert Into Network
select NetworkId,NetworkShortName,NetworkName,B.AccountId,A.AccountName,StaffId,StaffName,IsActive,BillingMode,Location,TTAPIEnabled,B.CrmId,GETDATE() as LastUpdatedDate
from
(
select LicenseFileID as NetworkId,ShortName as NetworkShortName,Name as NetworkName,BillingAccountId as AccountId,BillingAccountName as AccountName,staff.StaffId,staff.lastname + ' ' + staff.Firstname as StaffName,licensefile.IsActive,BillingMode,Location,TTAPIEnabled,AccountId as CrmId from chisql12.fillhub.dbo.LicenseFile 
left join chisql12.fillhub.dbo.staff
on licensefile.DefaultTamID=staff.staffid
)B left join Account A on A.Accountid=B.AccountId
UNION ALL 
Select 1 as NetworkId,'TTWEB' as NetworkShortName,'TTWEB' as NetworkName,Null as AccountId,Null as AccountName,Null as StaffId,Null as StaffName,0 as IsActive
,'TT' as BillingMode,'' as Location,0 as TTAPIEnabled,Null as CrmId,GETDATE() as LastUpdatedDate
order by 1
------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------Load License Table from Licenses Table in FillHub---------------------------------------
Truncate table License
Insert Into License
select row_number() over (order by ActivationDate, expirationdate Asc) as LicenseId,LicenseFileID as NetworkId,ExchangeID,ProductID, ProductTypeAbbr,   
sum(Quantity) as Quantity, case when MarketQty=0 then 'All' else Null end as MarketQty, ActivationDate, ExpirationDate,ServerIPAddress, SimulationFlag, Notes, 
TamID, Location as StaffLocation,GETDATE() as LastUpdatedDate
from chisql12.fillhub.dbo.Licenses
--where licensefileid=799
group by  ProductID, ProductTypeAbbr, LicenseFileID, ExchangeID, ServerIPAddress, ActivationDate, ExpirationDate, SimulationFlag, Notes, 
case when MarketQty=0 then 'All' else Null end, TamID, Location

-----------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------Load License Data from Licenses and LicenseFile Table in FillHub----------------------------------------------------------------------------
--Truncate Table License
--Insert Into license
--select row_number() over (order by A.ActivationDate, A.expirationdate Asc) as LicenseId , 
--A.LicenseFileId,A.ProductId,A.ProductTypeAbbr,A.ExchangeId,B.ShortName,B.Name,B.BillingAccountId,B.BillingAccountName,B.BillingMode,A.Quantity,A.ActivationDate,A.ExpirationDate,A.ServerIPAddress,A.SimulationFlag,A.Notes,A.MarketQty,
--A.TamId,A.Location as StaffLocation,B.StaffId,B.StaffName,B.IsActive,B.Location,B.TTAPIEnabled,B.CrmId, getdate() as LastUpdatedDate
--from
--(
--select ProductID, ProductTypeAbbr, LicenseFileID, ExchangeID, sum(Quantity) as Quantity, ServerIPAddress, ActivationDate, ExpirationDate, SimulationFlag, Notes, case when MarketQty=0 then 'All' else Null end as MarketQty, TamID, Location
--from chisql12.fillhub.dbo.Licenses
----where licensefileid=799
--group by  ProductID, ProductTypeAbbr, LicenseFileID, ExchangeID, ServerIPAddress, ActivationDate, ExpirationDate, SimulationFlag, Notes, case when MarketQty=0 then 'All' else Null end, TamID, Location
--)A
--join
--(
--select LicenseFileID,ShortName,Name,staff.StaffId,staff.lastname + ' ' + staff.Firstname as StaffName,licensefile.IsActive,BillingAccountId,BillingAccountName,BillingMode,Location,TTAPIEnabled,AccountId as CrmId from chisql12.fillhub.dbo.LicenseFile 
--left join chisql12.fillhub.dbo.staff
--on licensefile.DefaultTamID=staff.staffid
----where licensefileid=799
--)B
--on A.licensefileid=b.licensefileid

------------------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------Load Staff Data from FillHub-------------------------------------------------------------------------------------
-- <Ram 3/10/2014 1500> Re-modified with active staff from Staff Management Data
Truncate Table dbo.staff
Insert into dbo.Staff
select  TTStaffID as StaffId, AuthName as UserName,FirstName, LastName,FirstName+''+LastName as FullName, Email,TTBranchName as City,Region, 
CostCenterCode1 as CostCenter,Title,case when IsActive =1 then 'Y' else 'N' end as IsActive, GETDATE() as LastUpdatedDate
from chisql01.tt_internal.dbo.ttstaff S left join chisql01.tt_internal.dbo.ttbranch B
on s.ttbranchid=b.ttbranchid
left join (select distinct salesoffice,region from RegionMap)M
on b.ttbranchname=m.SalesOffice
where TTStaffID>=0



--Truncate Table Staff
--Insert Into Staff
--select S.StaffId,S.UserName,S.FirstName,s.LastName,Q.FullName,S.Email,Q.City,Q.Country,Q.Region,Q.SalesOffice,Q.Company,S.CostCenter,S.IsTam,S.IsActive,S.IsLokiUser,S.LastUpdatedDate 
--from (Select StaffId, Domainuser as UserName, FirstName, LastName, Email,
-- CostCenter, IsTam, IsActive, IsLokiUser,GETDATE() as LastUpdatedDate 
-- from chisql12.fillhub.dbo.staff
--where staffid>=0) S left join 
--(
--select * from 
--(
--SELECT 
--replace(domainname,'INTAD\','') as Username
--,firstname as FirstName
--,lastname as LastName
--,[fullname] as FullName
--,[address1_city] as City
--,[address1_country] as Country
--,tt_continentname as Region
--,[tt_salesofficename] as SalesOffice
--,[tt_ttcompanyname] as Company
--,modifiedon as ModifiedDate
--, ROW_NUMBER() over (partition by domainname Order by modifiedon desc) as Rownum
--FROM [Trading_Technologies_MSCRM].[dbo].[FilteredSystemUser]
----chicrmsql01.
--) Z
--where Z.Rownum=1
--)Q
--on S.UserName COLLATE DATABASE_DEFAULT=Q.Username COLLATE DATABASE_DEFAULT
----where S.UserName=(select replace(suser_sname(),'INTAD\',''))

--update A
--set A.Salesoffice=B.SalesOffice
--from Staff A 
--join
--(
--select ttstaffid as StaffId,A.TTBranchID,ttbranchname as SalesOffice from
--(
--SELECT TTStaffID,TTBranchID
--FROM chisql01.[tt_internal].[dbo].[TTStaff]
--)A join
--( 
--SELECT  [TTBranchID]
--,[TTBranchName]
--FROM chisql01.[tt_internal].[dbo].[TTbranch]
--)B
--on A.TTBranchID=B.TTBranchID
--)B
--on A.StaffId=B.StaffId
 
--update A
--set a.Region=b.region
--from Staff A join RegionMap B
--on A.SalesOffice=B.SalesOffice
------------------------------------------------------------------------------------------------------------------------------------------------------------------
end



