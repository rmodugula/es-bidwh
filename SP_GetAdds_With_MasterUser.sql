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
/****** Object:  StoredProcedure [dbo].[GetAdds_With_MasterUser_06272018]    Script Date: 7/17/2018 2:28:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[GetAdds_With_MasterUser] 
  
	 
AS

Declare @StartDate Date,@Year int,@Month int,@EndDate Date,@RunDate Date
Set @StartDate=DATEADD(month, DATEDIFF(month, 0, getdate()), 0)
Set @Enddate='2016-12-01 00:00:00.000'
Set @RunDate=@StartDate

Select * 
into #BillingData 
from MonthlyBillingDataAggregate_Domo
where date>='2016-01-01' and date<=cast(getdate() as date)
and screens in ('screens','Screens Login Only') 

Create table #LicenseImpact
(Year int,Month int,MasterAccountName varchar(200),MasterUserId varchar(50),CRMId varchar(100),Deliveryname nvarchar(200)
,CustomerGroup nvarchar(100),SalesOffice nvarchar(50),SalesRegion nvarchar(50),ProductName varchar(50)
,ProductCategoryName varchar(100),CustomerSuccessManager varchar(50),SalesManager varchar(50),UserCompany varchar(50),
Adds int,AddsResurrected Int,[Transfer/Migrated] int
,AvgRevenue float,MonthsTradedinLast12Months int
,LastMonthTraded varchar(20))


While @RunDate>@Enddate
BEGIN
SET NOCOUNT ON;


declare @LastdayBaseMonth date , @LastdayCurrentMonth date, @Baseyear Int,@Basemonth Int,@Currentyear Int,@Currentmonth Int

SET @Baseyear=Year(DATEADD(month,-1,@RunDate))
SET @Basemonth=Month(DATEADD(month,-1,@RunDate))
SET @Currentyear=Year(DATEADD(month,0,@RunDate))
SET @Currentmonth=Month(DATEADD(month,0,@RunDate))
SET @LastdayBaseMonth = (select CAST(EndDate as date) from TimeInterval where YEAR=@Baseyear and Month=@Basemonth)
SET @LastdayCurrentMonth = (select CAST(EndDate as date) from TimeInterval where YEAR=@Currentyear and Month=@Currentmonth)


--------------------------------Query to get the Last 12 months Traded by User-------------------------------------------

Select MasterAccountName, MasterUserId,count(distinct startdate) as MonthsTradedinLast12Months
,sum(billedamount)/(case when count(distinct startdate)>=12 then 12 else count(distinct startdate) End)  as AvgRevenue
 Into #MonthsTraded
 from
(
Select MasterAccountName,MasterUserId,StartDate,sum(billedamount) as billedamount
,row_number() over (partition by MasterAccountName, MasterUserId order by startdate desc) as rowid from 
(
select MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)) as MasterUserId
,StartDate,sum(BilledAmount) as Billedamount
from #BillingData M
left join (select * from MasterUser where NetworkShortName='Subscribe') MU on M.AdditionalInfo=MU.UserName
left join TimeInterval T on m.year=t.year and m.month=t.month
where StartDate>=DATEADD(month,0,@RunDate) and StartDate<=cast(DATEADD(month, DATEDIFF(month, 0, getdate()), 0) as date)
and screens in ('screens','Screens Login Only')
and CustGroup='Subscribe' 
and BilledAmount>0 and LicenseCount>0
group by MasterAccountName, rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)),StartDate
UNION ALL
select MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)) as MasterUserId,StartDate,sum(BilledAmount) as Billedamount
from #BillingData M
left join (select * from MasterUser where NetworkShortName='TTWEB') MU on M.TTDESCRIPTION=MU.UserName
left join TimeInterval T on m.year=t.year and m.month=t.month
where StartDate>=DATEADD(month,0,@RunDate) and StartDate<=cast(DATEADD(month, DATEDIFF(month, 0, getdate()), 0) as date)
and screens in ('screens','Screens Login Only')
and CustGroup='TTPlatform' 
group by MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)),StartDate
UNION ALL
select MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)) as MasterUserId,StartDate,sum(BilledAmount) as Billedamount
from #BillingData M
left join (select * from MasterUser where NetworkShortName in ('7xASP')) MU on M.TTDESCRIPTION=MU.UserName
left join TimeInterval T on m.year=t.year and m.month=t.month
where StartDate>=DATEADD(month,0,@RunDate) and StartDate<=cast(DATEADD(month, DATEDIFF(month, 0, getdate()), 0) as date)
and screens in ('screens','Screens Login Only')
and CustGroup in ('MultiBrokr') 
group by MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)),StartDate
UNION ALL
select MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)) as MasterUserId,StartDate,sum(BilledAmount) as Billedamount
from #BillingData M
left join (select * from MasterUser where NetworkShortName not in ('7xASP','Subscribe','TTWEB')) MU
 on M.TTDESCRIPTION=MU.UserName and M.NetworkShortName=MU.NetworkShortName
left join TimeInterval T on m.year=t.year and m.month=t.month
where StartDate>=DATEADD(month,0,@RunDate) and StartDate<=cast(DATEADD(month, DATEDIFF(month, 0, getdate()), 0) as date)
and screens in ('screens','Screens Login Only')
and CustGroup in ('Trnx SW') 
group by MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)),StartDate
)Y
Group by MasterAccountName, MasterUserId,StartDate
)G where rowid<=12
Group by MasterAccountName, MasterUserId

-------------------------------------Temp Table to get the Last YearMonth Traded by the user------------------------------------------
Select MasterAccountName,MasterUserId,YearMonth  
Into #LastMonthTraded
from 
(
Select MasterAccountName,rtrim(cast(MasterUserId as varchar(50))) as MasterUserId
,cast(cast(year as char(4))+(case when len(month)=1 then '0'+cast(month as char(2)) 
else cast(month as char(2)) END) as int) as YearMonth
,row_number() over (partition by MasterAccountName,rtrim(cast(MasterUserId as varchar(50))) 
order by cast(cast(year as char(4))+(case when len(month)=1 then '0'+cast(month as char(2)) 
else cast(month as char(2)) END) as int) desc) as Rowid
from
(
select m.Year,m.Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)) as MasterUserId
from #BillingData M
left join (select * from MasterUser where NetworkShortName='Subscribe') MU on M.AdditionalInfo=MU.UserName
left join TimeInterval T on m.year=t.year and m.month=t.month
where StartDate>=DATEADD(month,0,@RunDate) and StartDate<=cast(DATEADD(month, DATEDIFF(month, 0, getdate()), 0) as date)
and screens in ('screens','Screens Login Only')
and CustGroup='Subscribe' 
and BilledAmount>0 and LicenseCount>0
group by m.Year,m.Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)),m.year, m.Month
UNION ALL
select m.Year,m.Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)) as MasterUserId
from #BillingData M
left join (select * from MasterUser where NetworkShortName='TTWEB') MU on M.TTDESCRIPTION=MU.UserName
left join TimeInterval T on m.year=t.year and m.month=t.month
where StartDate>=DATEADD(month,0,@RunDate) and StartDate<=cast(DATEADD(month, DATEDIFF(month, 0, getdate()), 0) as date)
and screens in ('screens','Screens Login Only')
and CustGroup='TTPlatform' 
group by m.Year,m.Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)),m.year, m.Month
UNION ALL
select m.Year,m.Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)) as MasterUserId
from #BillingData M
left join (select * from MasterUser where NetworkShortName in ('7xASP')) MU on M.TTDESCRIPTION=MU.UserName
left join TimeInterval T on m.year=t.year and m.month=t.month
where StartDate>=DATEADD(month,0,@RunDate) and StartDate<=cast(DATEADD(month, DATEDIFF(month, 0, getdate()), 0) as date)
and screens in ('screens','Screens Login Only')
and CustGroup in ('MultiBrokr') 
group by m.Year,m.Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)),m.year, m.Month
UNION ALL
select m.Year,m.Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)) as MasterUserId
from #BillingData M
left join (select * from MasterUser where NetworkShortName not in ('7xASP','Subscribe','TTWEB')) MU 
on M.TTDESCRIPTION=MU.UserName and M.NetworkShortName=MU.NetworkShortName
left join TimeInterval T on m.year=t.year and m.month=t.month
where StartDate>=DATEADD(month,0,@RunDate) and StartDate<=cast(DATEADD(month, DATEDIFF(month, 0, getdate()), 0) as date)
and screens in ('screens','Screens Login Only')
and CustGroup in ('Trnx SW') 
group by m.Year,m.Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)),m.year, m.Month
)Q
)T where rowid=1

---------------------Base Query Resurrected----------------------------------------------------------------------------
Select * 
Into #Base
from
(
select m.Year,m.Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)) as MasterUserId
,Crmid,AdditionalInfo as DeliveryName
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,isnull(TTUserCompany,MasterAccountName) as UserCompany
from #BillingData M
left join TimeInterval T on m.year=t.year and m.month=t.month
left join (select * from MasterUser where NetworkShortName='Subscribe') MU on M.AdditionalInfo=MU.UserName
where StartDate>=DATEADD(month,-6,@RunDate) and StartDate<DATEADD(month,0,@RunDate)
and screens in ('screens','screens login only')
and CustGroup='Subscribe' 
and BilledAmount>0 and LicenseCount>0
UNION ALL
Select Year,Month,MasterAccountName,MasterUserId,Crmid,DeliveryName
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,UserCompany from 
(
select m.Year,m.Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)) as MasterUserId,Crmid,AdditionalInfo as DeliveryName
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,isnull(TTUserCompany,MasterAccountName) as UserCompany
,case when m.year=2018 and MasterAccountName like 'Mercury Derivatives%' then 1 else sum(billedamount) end as Billedamount
,sum(licensecount) as licensecount
from #BillingData M
left join TimeInterval T on m.year=t.year and m.month=t.month
left join (select * from MasterUser where NetworkShortName='TTWEB') MU on M.TTdescription=MU.UserName
where StartDate>=DATEADD(month,-6,@RunDate) and StartDate<DATEADD(month,0,@RunDate)
and screens in ('screens','screens login only')
and CustGroup='TTPlatform' 
Group by m.Year,m.Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)),Crmid,AdditionalInfo
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,isnull(TTUserCompany,MasterAccountName)
)Y
where Billedamount>0 
--and licensecount>0
UNION ALL
select m.Year,m.Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)) as MasterUserId,Crmid,AdditionalInfo as DeliveryName
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,isnull(TTUserCompany,MasterAccountName) as UserCompany
from #BillingData M
left join TimeInterval T on m.year=t.year and m.month=t.month
left join (select * from MasterUser where NetworkShortName in ('7xASP')) MU on M.TTdescription=MU.UserName
where StartDate>=DATEADD(month,-6,@RunDate) and StartDate<DATEADD(month,0,@RunDate)
and screens in ('screens','screens login only')
and CustGroup in ('MultiBrokr') 
and BilledAmount>0 
UNION ALL
select m.Year,m.Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)) as MasterUserId,Crmid,AdditionalInfo as DeliveryName
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,isnull(TTUserCompany,MasterAccountName) as UserCompany
from #BillingData M
left join TimeInterval T on m.year=t.year and m.month=t.month
left join (select * from MasterUser where NetworkShortName not in ('7xASP','TTWEB','Subscribe')) MU 
on M.TTdescription=MU.UserName and M.NetworkShortName=MU.NetworkShortName
where StartDate>=DATEADD(month,-6,@RunDate) and StartDate<DATEADD(month,0,@RunDate)
and screens in ('screens','screens login only')
and CustGroup in ('Trnx SW') 
and BilledAmount>0
)Base 

---------------------Base Query for New users ever----------------------------------------------------------------------------
Select * 
Into #BaseNew
from
(
select m.Year,m.Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)) as MasterUserId,Crmid,AdditionalInfo as DeliveryName
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,isnull(TTUserCompany,MasterAccountName) as UserCompany
from #BillingData M
left join TimeInterval T on m.year=t.year and m.month=t.month
left join (select * from MasterUser where NetworkShortName='Subscribe') MU on M.AdditionalInfo=MU.UserName
where StartDate<DATEADD(month,0,@RunDate)
and screens in ('screens','screens login only')
and CustGroup='Subscribe' 
and BilledAmount>0 and LicenseCount>0
UNION ALL
Select Year,Month,MasterAccountName,MasterUserId,Crmid,DeliveryName
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,UserCompany from 
(
select m.Year,m.Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)) as MasterUserId,Crmid,AdditionalInfo as DeliveryName
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,isnull(TTUserCompany,MasterAccountName) as UserCompany
,case when m.year=2018 and MasterAccountName like 'Mercury Derivatives%' then 1 else sum(billedamount) end as Billedamount
,sum(licensecount) as licensecount
from #BillingData M
left join TimeInterval T on m.year=t.year and m.month=t.month
left join (select * from MasterUser where NetworkShortName='TTWEB') MU on M.TTdescription=MU.UserName
where StartDate<DATEADD(month,0,@RunDate)
and screens in ('screens','screens login only')
and CustGroup='TTPlatform' 
Group by m.Year,m.Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)),Crmid,AdditionalInfo
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,isnull(TTUserCompany,MasterAccountName)
)Y
where Billedamount>0 
--and licensecount>0
UNION ALL
select m.Year,m.Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)) as MasterUserId,Crmid,AdditionalInfo as DeliveryName
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,isnull(TTUserCompany,MasterAccountName) as UserCompany
from #BillingData M
left join TimeInterval T on m.year=t.year and m.month=t.month
left join (select * from MasterUser where NetworkShortName in ('7xASP')) MU on M.TTdescription=MU.UserName
where StartDate<DATEADD(month,0,@RunDate)
and screens in ('screens','screens login only')
and CustGroup in ('MultiBrokr') 
and BilledAmount>0 
UNION ALL
select m.Year,m.Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)) as MasterUserId,Crmid,AdditionalInfo as DeliveryName
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,isnull(TTUserCompany,MasterAccountName) as UserCompany
from #BillingData M
left join TimeInterval T on m.year=t.year and m.month=t.month
left join (select * from MasterUser where NetworkShortName not in ('7xASP','TTWEB','Subscribe')) MU 
on M.TTdescription=MU.UserName and M.NetworkShortName=MU.NetworkShortName
where StartDate<DATEADD(month,0,@RunDate)
and screens in ('screens','screens login only')
and CustGroup in ('Trnx SW') 
and BilledAmount>0
)Base 

---------------------Current Query------------------------------------------------------------

Select * 
Into #Current
from
(
select Year,Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)) as MasterUserId,Crmid
,AdditionalInfo as DeliveryName
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,isnull(TTUserCompany,MasterAccountName) as UserCompany
from #BillingData M
left join (select * from MasterUser where NetworkShortName='Subscribe') MU on M.AdditionalInfo=MU.UserName
where YEAR =@Currentyear 
and MONTH=@Currentmonth
and screens in ('screens','screens login only')
and CustGroup='Subscribe' 
and BilledAmount>0 and LicenseCount>0
UNION ALL
Select Year,Month,MasterAccountName,MasterUserId,Crmid,DeliveryName
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,UserCompany from 
(
select Year,Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)) as MasterUserId,Crmid,AdditionalInfo as DeliveryName
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,isnull(TTUserCompany,MasterAccountName) as UserCompany
,case when year=2018 and MasterAccountName like 'Mercury Derivatives%' then 1 else sum(billedamount) end as Billedamount
,sum(licensecount) as licensecount
from #BillingData M
left join (select * from MasterUser where NetworkShortName='TTWEB') MU on M.TTdescription=MU.UserName
where YEAR =@Currentyear 
and MONTH=@Currentmonth
and screens in ('screens','screens login only')
and CustGroup='TTPlatform' 
Group by Year,Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)),Crmid,AdditionalInfo
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,isnull(TTUserCompany,MasterAccountName)
)Y
where Billedamount>0 
--and licensecount>0
UNION ALL
select Year,Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)) as MasterUserId,Crmid,AdditionalInfo as DeliveryName
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,isnull(TTUserCompany,MasterAccountName) as UserCompany
from #BillingData M
left join (select * from MasterUser where NetworkShortName in ('7xASP')) MU on M.TTdescription=MU.UserName
where YEAR =@Currentyear 
and MONTH=@Currentmonth
and screens in ('screens','screens login only')
and CustGroup in ('MultiBrokr') 
and BilledAmount>0
UNION ALL
select Year,Month,MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)) as MasterUserId,Crmid,AdditionalInfo as DeliveryName
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,isnull(TTUserCompany,MasterAccountName) as UserCompany
from #BillingData M
left join (select * from MasterUser where NetworkShortName not in ('7xASP','TTWEB','Subscribe')) MU 
on M.TTdescription=MU.UserName and M.NetworkShortName=MU.NetworkShortName
where YEAR =@Currentyear 
and MONTH=@Currentmonth
and screens in ('screens','screens login only')
and CustGroup in ('Trnx SW') 
and BilledAmount>0
)Cur 
--where MasterUserId is not null

-------------------------------Adds-----------------------------------------------

Insert into #LicenseImpact
Select @Currentyear as Year,@Currentmonth as Month
,ltrim(rtrim(Final.MasterAccountName)) as MasterAccountName,rtrim(cast(final.MasterUserId as varchar(50))) as MasterUserId
,Crmid,ltrim(rtrim(Final.DeliveryName)) as DeliveryName
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,UserCompany,
Adds,AddsResurrected,[Transfer/Migrated]
,AvgRevenue as AvgRevInLast12Months,MonthsTradedinLast12Months,YearMonth as LastMonthTraded
from
(
--------------------Adds Resurrected---------------------------
Select * from 
( 
Select *,0 as Adds,1 as AddsResurrected,0 as [Transfer/Migrated] from #Current
where rtrim(isnull(cast(MasterUserId as varchar(50)),DeliveryName))
in
(
Select rtrim(isnull(cast(MasterUserId as varchar(50)),DeliveryName))
from #Current
except
Select rtrim(isnull(cast(MasterUserId as varchar(50)),DeliveryName))
from #Base
)
)s
where DeliveryName 
not in 
(Select DeliveryName from #base)

UNION ALL
--------------------Adds New Ever---------------------------
Select * from 
( 
Select *,1 as Adds,0 as AddsResurrected,0 as [Transfer/Migrated] from #Current
where rtrim(isnull(cast(MasterUserId as varchar(50)),DeliveryName))
in
(
Select rtrim(isnull(cast(MasterUserId as varchar(50)),DeliveryName))
from #Current
except
Select rtrim(isnull(cast(MasterUserId as varchar(50)),DeliveryName))
from #BaseNew
)
)s
where DeliveryName 
not in 
(Select DeliveryName from #base)

UNION ALL
--------------------Adds New Ever MIgrated/Transferred---------------------------
Select * from 
( 
Select *,0 as Adds,0 as AddsResurrected,1 as [Transfer/Migrated] from #Current
where DeliveryName
in
(
Select DeliveryName
from #Current
except
Select DeliveryName
from #BaseNew
)
)s
--where MasterUserId 
-- in 
--( select distinct masteruserid from 
--  (
--  SELECT Distinct [Year],[Month],[Date],[MasterAccountName],[MasterUserId],[CRMId],[Deliveryname],[CustomerGroup]
--,[SalesOffice],[SalesRegion],[CustomerSuccessManager],[SalesManager]
--,[UserCompany],[Cancels]*-1 as ChangeQuantity,'Cancels' as ChangeType,AvgRevInLast12Months*-1 as [AvgRevInLast12Months],[MonthsTradedinLast12Months]
--,[LastMonthTraded],[ChurnType] as CoreVsNonCore,[Email],[CurrentMonthLicenseCount],[PriorMonthLicenseCount],[MonthBilled]
--,[LastUpdatedDate],[UserGroup]
--FROM [BIDW].[dbo].[ChurnedUsersByMonth]
--where cancels>0 and isnull(ReasonForLeaving,'-') in ('Transfer','Migration')
--and ProductName not like '%user access%'
--)q)
)Final
left join #MonthsTraded MT
on final.MasterAccountName=MT.MasterAccountName and final.MasterUserId=MT.MasterUserId
left join #LastMonthTraded lt on Final.MasterAccountName=LT.MasterAccountName and final.MasterUserId=LT.MasterUserId




-----------------------------------------------------------------Drop Temp Tables Created--------------------------------------------------------------------
drop table #Base
drop table #BaseNew
drop table #Current
drop table #MonthsTraded
drop table #LastMonthTraded


SET @Rundate=dateadd(month,-1,@RunDate)

END


----------------------------------------Delete and reload churned users data for current year---------------------------------------------------------------
Delete UserAddsByMonth

Insert into UserAddsByMonth
Select Date,MasterAccountName,MasterUserId,CRMId,d.Deliveryname,CustomerGroup
,SalesOffice,SalesRegion,CustomerSuccessManager
,SalesManager,UserCompany,Adds,AddsResurrected,[Transfer/Migrated],AvgRevInLast12Months,MonthsTradedinLast12Months
,LastMonthTraded,CoreVsNonCore,Email,UserGroup,CurrentMonthLicenseCount,PriorMonthLicenseCount
,Case when IsClosed=1 then 'Billed' else 'Not-Billed' END as MonthBilled,getdate() as LastUpdatedDate
from 
(
Select Distinct cast(concat(l.month,'-','01','-',l.year) as date) as Date,
L.Year,L.Month,L.MasterAccountName,MasterUserId
,Crmid,L.DeliveryName
,L.CustomerGroup,SalesOffice,L.SalesRegion
,CustomerSuccessManager,SalesManager
,ltrim(rtrim(replace(replace(UserCompany,'(Managed)',''),'(managed)',''))) as UserCompany,Adds,AddsResurrected
,[Transfer/Migrated],AvgRevenue as AvgRevInLast12Months
,case when MonthsTradedinLast12Months>12 then 12 else MonthsTradedinLast12Months end as MonthsTradedinLast12Months
,LastMonthTraded
,Case when ProductName like '%pro%' and MonthsTradedinLast12Months>=2 and AvgRevenue>400 then 'Core' 
     when ProductName not like '%pro%' and MonthsTradedinLast12Months>=2 and AvgRevenue>50 then 'Core' 
else 'Non-Core' END CoreVsNonCore
,case when CustomerGroup='TTPlatform' then TEM.email else EM.Email END as Email
from #LicenseImpact L
Left Join 
(
Select Distinct DeliveryName,Email from
(
select DeliveryName,Email,row_number() over (partition by deliveryname order by email) as rowid from lastlogin 
where year>=2017  and email <>''
)w
where rowid=1
)EM on  L.Deliveryname=EM.DeliveryName
left join
(
Select distinct DeliveryName,Email from 
(
select *,row_number() over (partition by deliveryname order by email) as rowid from
(
SELECT distinct firstname+' '+lastname as DeliveryName, Email
  FROM chisql20.[MESS].[dbo].[Users]
  where email is not null and email<>'' 
  )q
  )w
  where rowid=1
)TEM on L.Deliveryname=TEM.DeliveryName
)D
left join 
(
Select *,LAG(CurrentMonthLicenseCount, 1,0) OVER (ORDER BY YEAR,month) as PriorMonthLicenseCount from 
(
select Year,Month
,sum(BilledAmount) as CurrentMonthRevenue,sum(licensecount) as CurrentMonthLicenseCount
from #BillingData
where year>=2016
and screens in ('screens','screens login only')
group by Year,Month
)t
)screens on year(d.date)=screens.Year and month(d.date)=screens.month 
Left Join chisql12.fillhub.dbo.InvoiceMonth I 
on year(d.date) = I.Year and month(d.date)=I.Month
Left Join 
(
select * from 
(
select distinct DeliveryName,UserGroup,row_number() over (partition by deliveryname order by usergroup) as rowid from 
(
Select Distinct DeliveryName,replace(replace(UserGroup,'(Managed)',''),'(managed)','')  as UserGroup from
(
select distinct UserGroup,DeliveryName from lastlogin 
)w
)Y 
)t where rowid=1 
)UG on d.Deliveryname=ug.DeliveryName

