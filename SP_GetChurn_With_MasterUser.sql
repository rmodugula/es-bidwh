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
/****** Object:  StoredProcedure [dbo].[GetChurn_With_MasterUser]    Script Date: 7/9/2018 10:50:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[GetChurn_With_MasterUser] 
  
	 
AS

Declare @StartDate Date,@Year int,@Month int,@EndDate Date,@RunDate Date
Set @StartDate=DATEADD(month, DATEDIFF(month, 0, getdate()), 0)
Set @Enddate='2016-12-01 00:00:00.000'
--DATEADD(month,-7,@StartDate)
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
Cancels int,Adds int
,AvgRevenue float,MonthsTradedinLast12Months int
,LastMonthTraded varchar(20),UserFluctuation varchar(20))


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

Select MasterAccountName, MasterUserId,count(distinct startdate) as MonthsTradedinLast12Months,sum(billedamount)/count(distinct startdate) as AvgRevenue
Into #MonthsTraded
from
(
select MasterAccountName,rtrim(cast(MasterUserId as varchar(50))) as MasterUserId
,StartDate,sum(BilledAmount) as Billedamount
from #BillingData M
left join (select * from MasterUser where NetworkShortName='Subscribe') MU on M.AdditionalInfo=MU.UserName
left join TimeInterval T on m.year=t.year and m.month=t.month
where StartDate>=DATEADD(month,-11,@RunDate) and StartDate<=cast(DATEADD(month, DATEDIFF(month, 0, @RunDate), 0) as date)
and screens in ('screens','Screens Login Only')
and CustGroup='Subscribe' 
and BilledAmount>0 
--and LicenseCount>0
group by MasterAccountName, rtrim(cast(MasterUserId as varchar(50))),StartDate
UNION ALL
select MasterAccountName,rtrim(cast(MasterUserId as varchar(50))) as MasterUserId,StartDate,sum(BilledAmount) as Billedamount
from #BillingData M
left join (select * from MasterUser where NetworkShortName='TTWEB') MU on M.TTDESCRIPTION=MU.UserName
left join TimeInterval T on m.year=t.year and m.month=t.month
where StartDate>=DATEADD(month,-11,@RunDate) and StartDate<=cast(DATEADD(month, DATEDIFF(month, 0, @RunDate), 0) as date)
and screens in ('screens','Screens Login Only')
and CustGroup='TTPlatform' 
group by MasterAccountName, rtrim(cast(MasterUserId as varchar(50))),StartDate
UNION ALL
select MasterAccountName,rtrim(cast(MasterUserId as varchar(50))) as MasterUserId,StartDate,sum(BilledAmount) as Billedamount
from #BillingData M
left join (select * from MasterUser where NetworkShortName in ('7xASP')) MU on M.TTDESCRIPTION=MU.UserName
left join TimeInterval T on m.year=t.year and m.month=t.month
where StartDate>=DATEADD(month,-11,@RunDate) and StartDate<=cast(DATEADD(month, DATEDIFF(month, 0, @RunDate), 0) as date)
and screens in ('screens','Screens Login Only')
and CustGroup in ('MultiBrokr') 
group by MasterAccountName, rtrim(cast(MasterUserId as varchar(50))),StartDate
UNION ALL
select MasterAccountName,rtrim(cast(MasterUserId as varchar(50))) as MasterUserId,StartDate,sum(BilledAmount) as Billedamount
from #BillingData M
left join (select * from MasterUser where NetworkShortName not in ('7xASP','Subscribe','TTWEB')) MU
 on M.TTDESCRIPTION=MU.UserName and M.NetworkShortName=MU.NetworkShortName
left join TimeInterval T on m.year=t.year and m.month=t.month
where StartDate>=DATEADD(month,-11,@RunDate) and StartDate<=cast(DATEADD(month, DATEDIFF(month, 0, @RunDate), 0) as date)
and screens in ('screens','Screens Login Only')
and CustGroup in ('Trnx SW') 
group by MasterAccountName, rtrim(cast(MasterUserId as varchar(50))),StartDate
)Y
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
select m.Year,m.Month,MasterAccountName,rtrim(cast(MasterUserId as varchar(50))) as MasterUserId
from #BillingData M
left join (select * from MasterUser where NetworkShortName='Subscribe') MU on M.AdditionalInfo=MU.UserName
left join TimeInterval T on m.year=t.year and m.month=t.month
where StartDate>=DATEADD(month,-11,@Rundate) and StartDate<=cast(DATEADD(month, DATEDIFF(month, 0, @Rundate), 0) as date)
and screens in ('screens','Screens Login Only')
and CustGroup='Subscribe' 
and BilledAmount>0 
--and LicenseCount>0
group by m.Year,m.Month,MasterAccountName, rtrim(cast(MasterUserId as varchar(50))),m.year, m.Month
UNION ALL
select m.Year,m.Month,MasterAccountName, rtrim(cast(MasterUserId as varchar(50))) as MasterUserId
from #BillingData M
left join (select * from MasterUser where NetworkShortName='TTWEB') MU on M.TTDESCRIPTION=MU.UserName
left join TimeInterval T on m.year=t.year and m.month=t.month
where StartDate>=DATEADD(month,-11,@Rundate) and StartDate<=cast(DATEADD(month, DATEDIFF(month, 0, @Rundate), 0) as date)
and screens in ('screens','Screens Login Only')
and CustGroup='TTPlatform' 
group by m.Year,m.Month,MasterAccountName, rtrim(cast(MasterUserId as varchar(50))),m.year, m.Month
UNION ALL
select m.Year,m.Month,MasterAccountName, rtrim(cast(MasterUserId as varchar(50))) as MasterUserId
from #BillingData M
left join (select * from MasterUser where NetworkShortName in ('7xASP')) MU on M.TTDESCRIPTION=MU.UserName
left join TimeInterval T on m.year=t.year and m.month=t.month
where StartDate>=DATEADD(month,-11,@Rundate) and StartDate<=cast(DATEADD(month, DATEDIFF(month, 0, @Rundate), 0) as date)
and screens in ('screens','Screens Login Only')
and CustGroup in ('MultiBrokr') 
group by m.Year,m.Month,MasterAccountName, rtrim(cast(MasterUserId as varchar(50))),m.year, m.Month
UNION ALL
select m.Year,m.Month,MasterAccountName, rtrim(cast(MasterUserId as varchar(50))) as MasterUserId
from #BillingData M
left join (select * from MasterUser where NetworkShortName not in ('7xASP','Subscribe','TTWEB')) MU 
on M.TTDESCRIPTION=MU.UserName and M.NetworkShortName=MU.NetworkShortName
left join TimeInterval T on m.year=t.year and m.month=t.month
where StartDate>=DATEADD(month,-11,@Rundate) and StartDate<=cast(DATEADD(month, DATEDIFF(month, 0, @Rundate), 0) as date)
and screens in ('screens','Screens Login Only')
and CustGroup in ('Trnx SW') 
group by m.Year,m.Month,MasterAccountName, rtrim(cast(MasterUserId as varchar(50))),m.year, m.Month
)Q
)T where rowid=1

---------------------Base Query----------------------------------------------------------------------------
Select * 
Into #Base
from
(
select Year,Month,MasterAccountName,rtrim(cast(MasterUserId as varchar(50))) as MasterUserId,Crmid,AdditionalInfo as DeliveryName
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,isnull(TTUserCompany,MasterAccountName) as UserCompany
from #BillingData M
left join (select * from MasterUser where NetworkShortName='Subscribe') MU on M.AdditionalInfo=MU.UserName
where YEAR =@Baseyear 
and MONTH=@Basemonth
and screens in ('screens','screens login only')
and CustGroup='Subscribe' 
and BilledAmount>0 and LicenseCount>0
UNION ALL
Select Year,Month,MasterAccountName,MasterUserId,Crmid,DeliveryName
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,UserCompany from 
(
select Year,Month,MasterAccountName,rtrim(cast(MasterUserId as varchar(50))) as MasterUserId,Crmid,AdditionalInfo as DeliveryName
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,isnull(TTUserCompany,MasterAccountName) as UserCompany
,case when year=2018 and MasterAccountName like 'Mercury Derivatives%' then 1 else sum(billedamount) end as Billedamount
,sum(licensecount) as licensecount
from #BillingData M
left join (select * from MasterUser where NetworkShortName='TTWEB') MU on M.TTdescription=MU.UserName
where YEAR =@Baseyear 
and MONTH=@Basemonth
and screens in ('screens','screens login only')
and CustGroup='TTPlatform' 
Group by Year,Month,MasterAccountName,rtrim(cast(MasterUserId as varchar(50))),Crmid,AdditionalInfo
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,isnull(TTUserCompany,MasterAccountName)
)Y
where Billedamount>0 
--and licensecount>0
UNION ALL
select Year,Month,MasterAccountName,rtrim(cast(MasterUserId as varchar(50))) as MasterUserId,Crmid,AdditionalInfo as DeliveryName
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,isnull(TTUserCompany,MasterAccountName) as UserCompany
from #BillingData M
left join (select * from MasterUser where NetworkShortName in ('7xASP')) MU on M.TTdescription=MU.UserName
where YEAR =@Baseyear 
and MONTH=@Basemonth
and screens in ('screens','screens login only')
and CustGroup in ('MultiBrokr') 
and BilledAmount>0 
UNION ALL
select Year,Month,MasterAccountName,rtrim(cast(MasterUserId as varchar(50))) as MasterUserId,Crmid,AdditionalInfo as DeliveryName
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,isnull(TTUserCompany,MasterAccountName) as UserCompany
from #BillingData M
left join (select * from MasterUser where NetworkShortName not in ('7xASP','TTWEB','Subscribe')) MU 
on M.TTdescription=MU.UserName and M.NetworkShortName=MU.NetworkShortName
where YEAR =@Baseyear 
and MONTH=@Basemonth
and screens in ('screens','screens login only')
and CustGroup in ('Trnx SW') 
and BilledAmount>0
)Base 
--where MasterUserId is not null

---------------------Current Query------------------------------------------------------------

Select * 
Into #Current
from
(
select Year,Month,MasterAccountName,rtrim(cast(MasterUserId as varchar(50))) as MasterUserId,Crmid
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
select Year,Month,MasterAccountName,rtrim(cast(MasterUserId as varchar(50))) as MasterUserId,Crmid,AdditionalInfo as DeliveryName
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
Group by Year,Month,MasterAccountName,rtrim(cast(MasterUserId as varchar(50))),Crmid,AdditionalInfo
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,isnull(TTUserCompany,MasterAccountName)
)Y
where Billedamount>0 
--and licensecount>0
UNION ALL
select Year,Month,MasterAccountName,rtrim(cast(MasterUserId as varchar(50))) as MasterUserId,Crmid,AdditionalInfo as DeliveryName
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
select Year,Month,MasterAccountName,rtrim(cast(MasterUserId as varchar(50))) as MasterUserId,Crmid,AdditionalInfo as DeliveryName
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

-------------------------------Cancels-----------------------------------------------

Insert into #LicenseImpact
Select @Currentyear as Year,@Currentmonth as Month
,ltrim(rtrim(Final.MasterAccountName)) as MasterAccountName,rtrim(cast(final.MasterUserId as varchar(50))) as MasterUserId
,Crmid,ltrim(rtrim(Final.DeliveryName)) as DeliveryName
,CustGroup,SalesOffice,Region,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager,UserCompany,Cancels,Adds
,AvgRevenue as AvgRevInLast12Months,MonthsTradedinLast12Months,YearMonth as LastMonthTraded
from
(
Select * from 
( 
Select *,1 as cancels,0 as Adds from #base
where isnull(masteruserid,deliveryname)
--+masteraccountname 
in
(
Select isnull(masteruserid,deliveryname)
--+masteraccountname 
from #base
except
Select isnull(masteruserid,deliveryname)
--+masteraccountname 
from #Current
)
)r
where DeliveryName
--+masteraccountname
not in 
(Select DeliveryName
--+masteraccountname 
from #Current)


-----------------------------Adds---------------------------
UNION ALL
Select * from 
( 
Select *,0 as cancels,1 as Adds from #Current
where isnull(masteruserid,deliveryname)
--+masteraccountname 
in
(
Select isnull(masteruserid,deliveryname)
--+masteraccountname 
from #Current
except
Select isnull(masteruserid,deliveryname)
--+masteraccountname 
from #Base
)
)s
where DeliveryName
--+masteraccountname
not in 
(Select DeliveryName
--+masteraccountname 
from #base)
)Final
left join #MonthsTraded MT
on final.MasterAccountName=MT.MasterAccountName and final.MasterUserId=MT.MasterUserId
left join #LastMonthTraded lt on Final.MasterAccountName=LT.MasterAccountName and final.MasterUserId=LT.MasterUserId




-----------------------------------------------------------------Drop Temp Tables Created--------------------------------------------------------------------
drop table #Base
drop table #Current
drop table #MonthsTraded
drop table #LastMonthTraded

SET @Rundate=dateadd(month,-1,@RunDate)

END


----------------------------------------Delete and reload churned users data for current year---------------------------------------------------------------
Delete ChurnedUsersByMonth
where year>=year(getdate())

Insert Into ChurnedUsersByMonth
Select Year(date) as Year,Month(date) as Month,d.*,CurrentMonthLicenseCount,PriorMonthLicenseCount
,Case when IsClosed=1 then 'Billed' else 'Not-Billed' END as MonthBilled,getdate() as LastUpdatedDate,UserGroup
from 
(
Select case when CustomerGroup <>'Subscribe' and cancels>0 
and CSMUpdated is null then dateadd(month,-1,[Date])  else 
date end as Date,MasterAccountName,MasterUserId,CRMId,Deliveryname,CustomerGroup
,SalesOffice,SalesRegion,ProductName,ProductCategoryName,CustomerSuccessManager
,SalesManager,UserCompany,Cancels,Adds,AvgRevInLast12Months,MonthsTradedinLast12Months
,LastMonthTraded,ChurnType,Email
,ltrim(rtrim(case when masteruserid='F1D1DA56-AE6B-4A2B-BA07-85B69DCD038E' then 'Unknown' 
else ReasonForLeaving end)) as ReasonForLeaving
from 
(
Select Distinct cast(concat(l.month,'-','01','-',l.year) as date) as Date,
L.Year,L.Month,L.MasterAccountName,MasterUserId
,Crmid,L.DeliveryName
,L.CustomerGroup,SalesOffice,L.SalesRegion,ProductName,ProductCategoryName
,CustomerSuccessManager,SalesManager
,ltrim(rtrim(replace(replace(UserCompany,'(Managed)',''),'(managed)',''))) as UserCompany,Cancels,Adds
,AvgRevenue as AvgRevInLast12Months,MonthsTradedinLast12Months,LastMonthTraded
,Case when ProductName like '%pro%' and MonthsTradedinLast12Months>=7 and AvgRevenue>400 then 'Core' 
     when ProductName not like '%pro%' and MonthsTradedinLast12Months>=7 and AvgRevenue>50 then 'Core' 
else 'Non-Core' END ChurnType,
case when CustomerGroup='TTPlatform' then TEM.email else EM.Email END as Email
,case when UserFluctuation='Userfluctuated' then 'Stop and Go' else ReasonForLeaving
 End as ReasonForLeaving,CSMUpdated
from #LicenseImpact L
Left Join 
(
Select Distinct DeliveryName,Email from
(
select DeliveryName,Email,row_number() over (partition by deliveryname order by email) as rowid from lastlogin 
where year>=2017  and email <>''
)w
where rowid=1
)EM on L.Deliveryname=EM.DeliveryName
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

Left join 
(
select Distinct [churnedYear],[ChurnedMonth],ltrim(rtrim([MasterAccountName])) as MasterAccountName,ltrim(rtrim(UserName)) as UserName
,case when [ReasonForLeaving]='Returned User' then 'Stop and Go'
else Reasonforleaving end as Reasonforleaving,CSMUpdated
from [dbo].[CoreUsersChurn]
where ReasonForLeaving  not like '%active%'
and ReasonForLeaving is not null and ReasonForLeaving<>'' and CSMUpdated is null
)CC on l.Deliveryname=cc.UserName and l.MasterAccountName=cc.MasterAccountName
)F
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
where year(d.date)>=year(getdate())

