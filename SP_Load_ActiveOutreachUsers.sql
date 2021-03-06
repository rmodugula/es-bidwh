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
/****** Object:  StoredProcedure [dbo].[SP_Load_ActiveOutreachUsers]    Script Date: 8/15/2018 10:02:36 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[SP_Load_ActiveOutreachUsers] 
  
	 
AS

Declare @StartDate Date,@EndDate Date,@RunDate Date
Set @StartDate=cast(getdate() as date)
Set @Enddate=dateadd(week, datediff(week, 0, getdate()), -1)
Set @RunDate=@StartDate

------------------Creating temp table for billing data----------------------
Select * 
into #BillingData 
from MonthlyBillingDataAggregate_Domo
where date>='2017-01-01' and date<=cast(@RunDate as date)
and screens in ('screens') 

-----------------Creating temp table for fills-------------------------------
Select *  
Into #Fills
from Fills
where IsBillable='Y' and username<>''
and transactiondate>=dateadd(month,-12,cast(@RunDate as date))
and TransactionDate not between '2017-12-15' and '2018-01-15' -------------Grace Period for Active OutReach
and MarketId not in (100,102) ------Not Including EEX and NFX Users as Per Jira BI-240

------------Table to store final results--------------------
Create table #Final
([Date] date,MasterAccountName varchar(200),MasterUserId varchar(50),Deliveryname nvarchar(200)
,UserName varchar(100),CustomerGroup nvarchar(100),SalesOffice nvarchar(50),SalesRegion nvarchar(50),ProductName varchar(50)
,[Pro/NonPro] varchar(10),CustomerSuccessManager varchar(50),UserCompany varchar(50),
TTIDEmail varchar(100),Domain varchar(50),UserGroup varchar(100),LastTradedDate date,NetworkShortName varchar(100),TTUserId varchar(50)
,MonthsTradedinLast12Months int,AvgRevInLast12Months float
)


--While @RunDate>@Enddate
BEGIN
SET NOCOUNT ON;


declare @WeekStartDate date,@MonthStartDate date,@Date180Before date

SET @WeekStartDate=dateadd(week, datediff(week, 0, @RunDate), -1)
SET @MonthStartDate =DATEADD(month, DATEDIFF(month, 0, @RunDate), 0)
SET @Date180Before=dateadd(day,-180,cast(@RunDate as date))



--------------------------------Query to get the Last 12 months Traded by User-------------------------------------------
Select MasterAccountName, MasterUserId,count(distinct startdate) as MonthsTradedinLast12Months,sum(billedamount)/count(distinct startdate) as AvgRevenue
Into #MonthsTraded
from
(
select MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)) as MasterUserId
,StartDate,sum(BilledAmount) as Billedamount
from #BillingData M
left join (select * from MasterUser where NetworkShortName='Subscribe') MU on M.AdditionalInfo=MU.UserName
left join TimeInterval T on m.year=t.year and m.month=t.month
where StartDate>=DATEADD(month,-11,@MonthStartDate) and StartDate<=cast(DATEADD(month, DATEDIFF(month, 0, @MonthStartDate), 0) as date)
and screens in ('screens','Screens Login Only')
and CustGroup='Subscribe' 
and BilledAmount>0 
--and LicenseCount>0
group by MasterAccountName, rtrim(isnull(cast(MasterUserId as varchar(50)),AdditionalInfo)),StartDate
UNION ALL
select MasterAccountName,rtrim(isnull(isnull(cast(MasterUserId as varchar(50)),TTIDEmail),TTUserId)) as MasterUserId,StartDate,sum(BilledAmount) as Billedamount
from #BillingData M
left join (select * from MasterUser where NetworkShortName='TTWEB') MU on M.TTDESCRIPTION=MU.UserName
left join TimeInterval T on m.year=t.year and m.month=t.month
where StartDate>=DATEADD(month,-11,@MonthStartDate) and StartDate<=cast(DATEADD(month, DATEDIFF(month, 0, @MonthStartDate), 0) as date)
and screens in ('screens','Screens Login Only')
and CustGroup='TTPlatform' 
group by MasterAccountName,rtrim(isnull(isnull(cast(MasterUserId as varchar(50)),TTIDEmail),TTUserId)),StartDate
UNION ALL
select MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),TTdescription)) as MasterUserId,StartDate,sum(BilledAmount) as Billedamount
from #BillingData M
left join (select * from MasterUser where NetworkShortName in ('7xASP')) MU on M.TTDESCRIPTION=MU.UserName
left join TimeInterval T on m.year=t.year and m.month=t.month
where StartDate>=DATEADD(month,-11,@MonthStartDate) and StartDate<=cast(DATEADD(month, DATEDIFF(month, 0, @MonthStartDate), 0) as date)
and screens in ('screens','Screens Login Only')
and CustGroup in ('MultiBrokr') 
group by MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),TTdescription)),StartDate
UNION ALL
select MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),TTdescription)) as MasterUserId,StartDate,sum(BilledAmount) as Billedamount
from #BillingData M
left join (select * from MasterUser where NetworkShortName not in ('7xASP','Subscribe','TTWEB')) MU
 on M.TTDESCRIPTION=MU.UserName and M.NetworkShortName=MU.NetworkShortName
left join TimeInterval T on m.year=t.year and m.month=t.month
where StartDate>=DATEADD(month,-11,@MonthStartDate) and StartDate<=cast(DATEADD(month, DATEDIFF(month, 0, @MonthStartDate), 0) as date)
and screens in ('screens','Screens Login Only')
and CustGroup in ('Trnx SW') 
group by MasterAccountName,rtrim(isnull(cast(MasterUserId as varchar(50)),TTdescription)),StartDate
)Y
Group by MasterAccountName, MasterUserId



---------------------User Trades by MasterUser for last 180 Days------------------------------
SELECT distinct isnull(cast(isnull(mu.MasterUserId,mu1.masteruserid) as varchar(36)),f.username) as MasterUserId
,TransactionDate,row_number() over (partition by isnull(cast(isnull(mu.MasterUserId,mu1.masteruserid) as varchar(36)),f.username) 
order by TransactionDate) as RowId
Into #UserTrades
FROM #Fills F
left join MasterUser MU on F.username=MU.UserName
left join GetmasterUserEmails MU1 on f.username=mu1.email
where IsBillable='Y' and transactiondate>=cast(@Date180Before as date) and TransactionDate<=cast(@WeekStartDate as date)
and f.username <>'' 
group by isnull(cast(isnull(mu.MasterUserId,mu1.masteruserid) as varchar(36)),f.username),TransactionDate,f.username
order by 1,2,3

---------------------------------Query to calculate gap-------------------------------

Select MasterUserId,TransactionDate,lead(transactiondate) over(order by MasterUserId,rowId) as NextTransactionDate
Into #UserNextTrades
from #UserTrades
order by 1,2,3
  
--------------------------query to show gap in days >15 for last 180 days---------------------------

Select *,row_number() over (partition by masteruserid order by masteruserid) as RowId 
Into #UserGap
from 
(
select *,datediff(day,TransactionDate,NextTransactionDate) as GapINDays from
( 
Select UT.MasterUserId,TransactionDate,case when TransactionDate=MaxTransactionDate 
then null else NextTransactionDate end as NextTransactionDate,MaxTransactionDate,DaysTradedinLast90Days
from #UserNextTrades UT
left join
(
Select MasterUserId,max(transactiondate) as MaxTransactionDate,count(distinct transactiondate) as DaysTradedinLast90Days
from #UserNextTrades
Group by MasterUserId 
)UTM on UT.MasterUserId=UTM.MasterUserId
)Z
)ZZ
where GapINDays>15 


--------------------Users with max last traded date between 16 to 23 days compared to current date-------------------

select distinct MasteruserId,MaxDate as LastTransactionDate
into #UsersWithGap
from 
(
SELECT isnull(cast(isnull(mu.MasterUserId,mu1.masteruserid) as varchar(36)),f.username) as MasteruserId
,max(transactiondate) as MaxDate,cast(@WeekStartDate as date) as Date,datediff(day,max(transactiondate),cast(@WeekStartDate as date)) as Diff
FROM #Fills F
left join MasterUser MU on F.username=MU.UserName
left join GetmasterUserEmails MU1 on f.username=mu1.email
Left join Account A on f.AccountId=A.Accountid
Left Join Product P on f.AxProductId=p.ProductSku
where IsBillable='Y' and
transactiondate>=cast(@Date180Before as date) and TransactionDate<=cast(@WeekStartDate as date)
and f.username <>'' 
group by isnull(cast(isnull(mu.MasterUserId,mu1.masteruserid) as varchar(36)),f.username)
)Q where diff>15 and diff<24
and MasteruserId not in
(
select distinct masteruserid from #UserGap
)


------------------------Users with Gap and billing data fields-----------------------------------------
Insert into #Final
Select D.*,isnull(MonthsTradedinLast12Months,0) as MonthsTradedinLast12Months,isnull(AvgRevenue,0) as AvgRevInLast12Months
 from 
(
Select @WeekStartDate as Date,MasterAccountName,p.MasterUserId,DeliveryName,UserName,CustomerGroup,SalesOffice,SalesRegion
,ProductName,[Pro/NonPro],CustomerSuccessManager,UserCompany,TTIDEmail,Domain,UserGroup,LastTransactionDate,NetworkShortName,TTUserId from 
(
Select distinct m.*,isnull(cast(isnull(mu.MasterUserId,mu1.MasterUserId) as varchar(36)),m.username) as MasterUserId from 
(
Select Distinct MasterAccountName,CustGroup as CustomerGroup,AdditionalInfo as DeliveryName,TTdescription,case when CustGroup='TTplatform' 
then TTIDEmail else TTdescription end as UserName,isnull(TTUserCompany,MasterAccountName) as UserCompany 
,SalesOffice,Region as SalesRegion,ProductName,TTIDEmail,Usergroup
,case when ProductName like '%Pro%' then 'Pro' else 'Non-Pro' End as [Pro/NonPro]
,CustomerSuccessManager,Domain,NetworkShortName,TTUserId
from #BillingData
where date>=cast(@Date180Before as date) and date<=cast(@WeekStartDate as date) and screens = 'Screens' and CustGroup<>'subscribe' 
and ProductName not like '%Advanced Options%' and IsMonthBilled='Y'
Group by CustGroup,TTdescription,case when CustGroup='TTplatform' then TTIDEmail else  TTdescription end
,SalesOffice,Region,ProductName,TTIDEmail,Usergroup,TTUserCompany,MasterAccountName
,CustomerSuccessManager,Domain,AdditionalInfo,NetworkShortName,TTUserId
)M left join MasterUser MU on M.username=MU.UserName
left join MasterUser MU1 on M.TTdescription=MU1.UserName
)p
left join #UsersWithGap G on p.MasterUserId=g.MasteruserId
where p.MasterUserId in (select distinct MasterUserId from #UsersWithGap)
)D
left join #MonthsTraded M on d.MasterUserId=M.MasterUserId





-----------------------------------------------------------------Drop Temp Tables Created--------------------------------------------------------------------
drop table #UserGap
drop table #UserNextTrades
drop table #MonthsTraded
drop table #UserTrades
drop table #UsersWithGap

--SET @Rundate=dateadd(day,-6,@WeekStartDate)

END


Delete ActiveOutreachUsers
where datepart(week,date)=datepart(week,@RunDate)
Insert into ActiveOutreachUsers
Select  [Date], [MasterAccountName], [MasterUserId], [Deliveryname], [UserName], [CustomerGroup], [SalesOffice], [SalesRegion],
[ProductName], [Pro/NonPro], [CustomerSuccessManager], [UserCompany], [TTIDEmail], [Domain], [UserGroup], [LastTradedDate],
[NetworkShortName],TTUserId, [MonthsTradedinLast12Months], [AvgRevInLast12Months]
,ltrim(rtrim(NetworkShortName))+'_'+UserName as OutreachKey,getdate() as LastUpdatedDate
from 
(
Select *,row_number() over (partition by date,masteruserid order by avgrevinlast12months desc) as rowid from #Final
)Q
where rowid=1
and MasterUserId not in 
(
select distinct masteruserid from [BIDW].[dbo].[ActiveOutreachUsers]
where datepart(week,date)<datepart(week,@RunDate)
)
