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
/****** Object:  StoredProcedure [dbo].[Sp_Load_BillingData_Hourly]    Script Date: 7/16/2018 2:41:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER Procedure [dbo].[Sp_Load_BillingData_Hourly] 
as


declare @StartDate datetime;
declare @EndDate datetime;
declare @IndexDate datetime;
declare @year int;
declare @month int;

SET @StartDate = DATEADD(m,-1,GETDATE())
SET @EndDate = DATEADD(m,+1,GETDATE())
SET @IndexDate = @StartDate 



-------------------------------------------------Truncate and Load Account Table---------------------------------------------------------------------------------
Create Table #Account (AccountId varchar(50),AccountName varchar(100),MasterAccountName varchar(100),CRMId varchar(100),MultiBrokerNetworkId int,CustomerGroup varchar(50), CustomerType varchar(50),
StatusType varchar(50))

Insert into #Account
select distinct  A.Accountid, A.AccountName, A.MasterAccountName,
Case when len(a.crmid)<>36 then substring(a.crmid,1,8)+'-'+substring(a.crmid,9,4)+'-'+substring(a.crmid,13,4)+'-'+substring(a.crmid,17,4)+'-'+substring(a.crmid,21,12)
else a.crmid end as CrmId
--, A.CrmId
, '' as MultiBrokerNetworkId, CustomerGroup,A.CustomerTypeCodeName as CustomerType
,A.StatusCodeName as StatusType  from 
(select A.ACCOUNTNUM as Accountid,  A.NAME as AccountName ,  A.NAME as Legalname, 1 as IsActive ,
 1 as AccountSatusId , A.TTCRMID as CrmId , NULL as CustomerType
, isnull(B.Name,o.NAME) as MasterAccountName, CustomerTypeCodeName,StatusCodeName
from CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.CUSTTABLE A
left  join chisql12.bidw_ods.dbo.CRMOnlineAccountTable B on A.TTCRMID = cast(B.AccountId as varchar(50))
left join [Synap].[dbo].[OrganizationMaster] O on a.ttcrmid=o.crmid ------Added to get the latest MasterAccountName from Synap
) A
left join chisql12.fillhub.dbo.BillingAccounts BA
on A.Accountid=BA.BillingAccountId    ---------------------<Ram 09/08/2014> Updated to get data from CRM Online-------------


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
select ProductSku, ProductName, ProductCategoryId, ProductCategoryName, ProductSubGroup, ProductSubGroupId, ReportingGroup, 
case when Screens='Screens Exc Login' then 'Screens' else screens end as Screens from
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
(Region varchar(50), Country char(50), State varchar(50),City varchar(50),SalesOffice Varchar(50),Countryname varchar(255),CSMOffice varchar(50))

Insert Into #RegionMap
select D.*,isnull(C.SalesOffice,d.SalesOffice) as CSMOffice from 
(
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
)D
left join [dbo].[CSMSalesOffice] C on d.Country=c.country

If (select COUNT(*) from #RegionMap)<>0  
Begin
Delete RegionMap
Insert into RegionMap
Select * from #RegionMap
END

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--------------------------------------Refresh monthly billing info--------------------------------------------------------------

while @IndexDate <= @EndDate
begin
	print '>' + convert(varchar(30),year(@IndexDate)) + '-' + convert(varchar(30),month(@IndexDate))
	select @year = year(@IndexDate)
	select @month = month(@IndexDate)
	exec SP_Load_AXBillingData @month ,@year
	--exec SP_Load_RevenueImpactData @year,@month -- Refresh RevenueImpactReporting Data
	SET @IndexDate = DATEADD(m,1,@IndexDate)
end



Drop Table #Account
Drop Table #Product
Drop Table #Branch
Drop Table #RegionMap




