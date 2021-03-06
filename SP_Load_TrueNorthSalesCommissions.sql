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
/****** Object:  StoredProcedure [dbo].[SP_Load_TrueNorthSalesCommissions]    Script Date: 10/26/2018 9:15:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


Alter PROCEDURE [dbo].[SP_Load_TrueNorthSalesCommissions]
@Year Int = Null,
@Month Int = Null


AS

BEGIN
-------------------Refresh Salesforce Data in Saslesforce DB for to be used for Commission calculations---------------
EXEC MSDB.dbo.sp_start_job N'Salesforce Refresh 20min'


Declare @RunDate date
Set @RunDate= case when @year is null and @month is null 
then dateadd(month,0,DATEADD(month, DATEDIFF(month, 0, getdate()), 0))
else
cast(concat(cast(@month as char(2)),'-','01','-',cast(@year as char(4))) as date)
END


-------------------------Temp table loading all the billing data from 2017---------------------------------------------------------
Select * Into #BillingData
from bidw.dbo.MonthlyBillingDataAggregate
where year>=Year(getdate())-1



-------------------------------------------All users and their revenue by month--------------------------
select * 
into #TempUsers7x from 
(
Select Year,Month,TTdescription,SalesType as RevenueSource,NetworkShortName,sum(billedamount) as Revenue from #BillingData
where year>=Year(getdate())-1  and Screens in ('screens','Screens Login Only')
Group by Year,Month,TTdescription,SalesType,NetworkShortName
UNION 
Select Year,Month,AdditionalInfo,SalesType as RevenueSource,NetworkShortName,sum(billedamount) as Revenue from #BillingData
where year>=Year(getdate())-1  and Screens in ('screens','Screens Login Only')
Group by Year,Month,AdditionalInfo,SalesType,NetworkShortName
UNION 
Select Year,Month,AdditionalInfo,SalesType as RevenueSource,NetworkShortName,sum(billedamount) as Revenue from #BillingData
where year>=Year(getdate())-1  and ProductSku in (20996,20998,10140)
Group by Year,Month,AdditionalInfo,SalesType,NetworkShortName
UNION 
Select Year,Month,TTdescription,SalesType as RevenueSource,NetworkShortName,sum(billedamount) as Revenue from #BillingData
where year>=Year(getdate())-1  and ProductSku in (20996,20998,10140)
Group by Year,Month,TTdescription,SalesType,NetworkShortName
UNION 
Select Year,Month,TTUserId,SalesType as RevenueSource,NetworkShortName,sum(billedamount) as Revenue from #BillingData
where year>=Year(getdate())-1  and Screens in ('screens','Screens Login Only')
Group by Year,Month,TTUserId,SalesType,NetworkShortName
)l

select * 
into #TempUserstt from 
(
Select Year,Month,case when TTUserId='' then isnull(nullif(TTdescription,''),AdditionalInfo) else TTUserId end as TTUserId,SalesType as RevenueSource,NetworkShortName,sum(billedamount) as Revenue from #BillingData
where year>=Year(getdate())-1  and Screens in ('screens','Screens Login Only')
Group by Year,Month,TTUserId,SalesType,TTdescription,AdditionalInfo,NetworkShortName
UNION
Select Year,Month,case when TTUserId='' then isnull(nullif(TTdescription,''),AdditionalInfo) else TTUserId end as TTUserId,SalesType as RevenueSource,NetworkShortName,sum(billedamount) as Revenue from #BillingData
where year>=Year(getdate())-1  and ProductName like '%Fix%'
--and Screens in ('screens','Screens Login Only')
Group by Year,Month,TTUserId,SalesType,TTdescription,AdditionalInfo,NetworkShortName
UNION
Select Year,Month,isnull(nullif(TTdescription,''),AdditionalInfo)  as TTUserId,SalesType as RevenueSource,NetworkShortName,sum(billedamount) as Revenue from #BillingData
where year>=Year(getdate())-1  and Screens in ('screens','Screens Login Only')
Group by Year,Month,TTUserId,SalesType,TTdescription,AdditionalInfo,NetworkShortName
UNION
Select Year,Month,isnull(nullif(AdditionalInfo,''),TTdescription)  as TTUserId,SalesType as RevenueSource,NetworkShortName,sum(billedamount) as Revenue from #BillingData
where year>=Year(getdate())-1  and Screens in ('screens','Screens Login Only')
Group by Year,Month,TTUserId,SalesType,TTdescription,AdditionalInfo,NetworkShortName
UNION
Select Year,Month,TTIDEmail,SalesType as RevenueSource,NetworkShortName,sum(billedamount) as Revenue from #BillingData
where year>=Year(getdate())-1  and Screens in ('screens','Screens Login Only')
Group by Year,Month,TTIDEmail,SalesType,NetworkShortName
)m


select * 
into #TempUsersttnonscreen from 
(
Select Year,Month,TTdescription,SalesType as RevenueSource,NetworkShortName,sum(billedamount) as Revenue from #BillingData
where year>=Year(getdate())-1 and Screens not in ('screens','Screens Login Only') and CustGroup in ('TTPlatform','TTPHost')
Group by Year,Month,TTdescription,SalesType,NetworkShortName
UNION
Select Year,Month,ttuserid,SalesType as RevenueSource,NetworkShortName,sum(billedamount) as Revenue from #BillingData
where year>=Year(getdate())-1 and Screens not in ('screens','Screens Login Only') and CustGroup in ('TTPlatform','TTPHost')
Group by Year,Month,ttuserid,SalesType,NetworkShortName
)m




----------------------------------------Calculating commissions by platform user-----------------------------

Select  cast(CommissionStart as date) as CommissionDate
,year(Case when revenue is null then null else cast(CommissionStart as date) END) as CommissionStartYear
,month(Case when revenue is null then null else cast(CommissionStart as date) END) as CommissionStartMonth
,[Revenue], [Commission],  [OpportunityId]
, [OpportunityName], '' as [Author], '' as [Title], '' as [Regarding], [DeliveryName], [TTPlatformUserId], [SevenXUsername]
, [Username], [RejectionReason], [CommissionPercent], [CommissionStart], [CommissionEnd], [TargetLiveDate]
, [ExpectedMonthlyRevenue], [OrganizationId], [OrganizationName], [SalesRep], [CurrentStage], [NextSteps]
, [Region], [NumberOfScreens], [Priority], [Broker], [Top10], [ChanceOfClosing], [OpportunityType]
, [Source], [TrueNorth], [Products], [ClientType], [IsMonthBilled],RevenueSource,getdate() as CommissionSnapshotDate
Into #TrueNorthSalesCommissions
from
(
-------------------- Query to get commissions by 7x username without Network Limiter-------------------------
Select Revenue,(Revenue*cast(isnull(isnull(CommissionPercent,CommissionOverride),7.5) as numeric(26,12)))/100 as Commission,RevenueSource,q.*,
case when IsClosed=1 then 'Y' else 'N' End as IsMonthBilled from 
(
SELECT  year(CommissionStart) as CommissionYear,Month(CommissionStart) as CommissionMonth,O.[Id] as OpportunityId,[Name] as OpportunityName,'' as Author,'' as Title,'' as Regarding,DeliveryName
,TTPlatformUserId,SevenXUsername,isnull(SevenXUsername,TTPlatformUserId) as Username,RejectionReason
,isnull(CommissionPercent,CommissionOverride) as CommissionPercent,CommissionStart,CommissionEnd,[TargetLiveDate]
,[ExpectedMonthlyRevenue],AccountId as [OrganizationId],OrganizationName
,[SalesRep],[CurrentStage]
--,[Description]
,NextStep as [NextSteps],[Region],[NumberOfScreens],[Priority]
,[Broker],[Top10],[ChanceOfClosing],[OpportunityType],[Source],[TrueNorth],[Products],[ClientType],CommissionOverride,NetworkLimiter
  FROM [Salesforce].[dbo].[Opportunities] O
	  left join
	  (
	  SELECT [SalesforceId],[Name] as OrganizationName      
	  FROM [Salesforce].[dbo].[AccountMaster]
	  where isdeleted='False'
	  )R on O.Accountid=R.SalesforceId
  inner Join 
  (
				Select * from 
			(
			Select *,row_number() over (partition by opportunityid,deliveryname order by commissionstart asc) as CommissionAppliedMonthNumber from 
			(
			Select Year,Month,Quarter,case when EndDate<CommissionStart then null else EndDate end as CommissionStart
			,CommissionEnd,DeliveryName,OpportunityId,TTPlatformUserId,SevenXUsername,RejectionReason,CommissionPercent,AccountingStage,NetworkLimiter
			from 
			(
			Select T.*,P.* from chisql12.bidw.[dbo].[TimeInterval] T
			left join 
			(
			SELECT Distinct [Name] as DeliveryName,[OpportunityId],[TTPlatformUserId],[SevenXUsername],[RejectionReason],[CommissionPercent],case when [CommissionStart] is null then w.date else CommissionStart end as CommissionStart,[CommissionEnd],[AccountingStage],NetworkLimiter
			FROM (select * from [SalesForce].[dbo].[PlatformUser] where NetworkLimiter is null) P
			left join
			(select Distinct TTdescription,Date from
				(
				select TTdescription,CAST(CAST(Year AS VARCHAR(4)) +RIGHT('0' + CAST(Month AS VARCHAR(2)), 2) +RIGHT('0' + CAST(1 AS VARCHAR(2)), 2) AS DATE) as Date,row_number() over (partition by ttdescription order by year,month) as row from #TempUsers7x
				where TTdescription is not null and TTdescription<>''
				)S where row=1)w on p.SevenXUsername=w.TTdescription
			where AccountingStage='Verified' 
			and isdeleted='False'
			)P on 1=1
			where t.year>=Year(getdate())-1
			)z
			)g
			where CommissionStart is not null
			)x
			where CommissionAppliedMonthNumber<=24 and CommissionStart<=isnull(CommissionEnd,'2500-12-31')
	)P on o.Id=P.OpportunityId
  where TrueNorth='Yes'
  --CurrentStage='Closed - Won' and
  )Q
  left join 
  (
  select * from #TempUsers7x
   )w
   on q.CommissionYear=w.year and q.CommissionMonth=w.month and q.Username=w.TTdescription
   Left Join 
   (
   SELECT Year,Month,IsClosed FROM [fillhub].[dbo].[InvoiceMonth]
   )I on q.CommissionYear=I.year and q.CommissionMonth=I.month
   where TTPlatformUserId is null
----------------------------------------------------------------------------------------------------------------

UNION ALL

-------------------- Query to get commissions by 7x username with Network Limiter-------------------------
Select Revenue,(Revenue*cast(isnull(isnull(CommissionPercent,CommissionOverride),7.5) as numeric(26,12)))/100 as Commission,RevenueSource,q.*,
case when IsClosed=1 then 'Y' else 'N' End as IsMonthBilled from 
(
SELECT  year(CommissionStart) as CommissionYear,Month(CommissionStart) as CommissionMonth,O.[Id] as OpportunityId,[Name] as OpportunityName,'' as Author,'' as Title,'' as Regarding,DeliveryName
,TTPlatformUserId,SevenXUsername,isnull(SevenXUsername,TTPlatformUserId) as Username,RejectionReason
,isnull(CommissionPercent,CommissionOverride) as CommissionPercent,CommissionStart,CommissionEnd,[TargetLiveDate]
,[ExpectedMonthlyRevenue],AccountId as [OrganizationId],OrganizationName
,[SalesRep],[CurrentStage]
--,[Description]
,NextStep as [NextSteps],[Region],[NumberOfScreens],NUll as [Priority]
,[Broker],[Top10],[ChanceOfClosing],[OpportunityType],[Source],[TrueNorth],[Products],[ClientType],CommissionOverride,NetworkLimiter
  FROM [SalesForce].[dbo].[Opportunities] O
	  left join
	  (
	  SELECT [SalesforceId],[Name] as OrganizationName      
	  FROM [SalesForce].[dbo].[AccountMaster]
	  where isdeleted='False'
	  )R on O.AccountId=R.salesforceid
  inner Join 
  (
				Select * from 
			(
			Select *,row_number() over (partition by opportunityid,deliveryname order by commissionstart asc) as CommissionAppliedMonthNumber from 
			(
			Select Year,Month,Quarter,case when EndDate<CommissionStart then null else EndDate end as CommissionStart
			,CommissionEnd,DeliveryName,OpportunityId,TTPlatformUserId,SevenXUsername,RejectionReason,CommissionPercent,AccountingStage,NetworkLimiter
			from 
			(
			Select T.*,P.* from chisql12.bidw.[dbo].[TimeInterval] T
			left join 
			(
			SELECT Distinct [Name] as DeliveryName,[OpportunityId],[TTPlatformUserId],[SevenXUsername],[RejectionReason],[CommissionPercent],case when [CommissionStart] is null then w.date else CommissionStart end as CommissionStart,[CommissionEnd],[AccountingStage],NetworkLimiter
			FROM (select * from [SalesForce].[dbo].[PlatformUser] where NetworkLimiter is not null) P
			left join
			(select Distinct TTdescription,NetworkShortName,Date from
				(
				select TTdescription,NetworkShortName,CAST(CAST(Year AS VARCHAR(4)) +RIGHT('0' + CAST(Month AS VARCHAR(2)), 2) +RIGHT('0' + CAST(1 AS VARCHAR(2)), 2) AS DATE) as Date,row_number() over (partition by ttdescription,networkshortname order by year,month) as row from #TempUsers7x
				where TTdescription is not null and TTdescription<>''
				)S where row=1)w on p.SevenXUsername=w.TTdescription and p.NetworkLimiter=w.networkshortname
			where AccountingStage='Verified' 
			and isdeleted='False'
			)P on 1=1
			where t.year>=Year(getdate())-1
			)z
			)g
			where CommissionStart is not null
			)x
			where CommissionAppliedMonthNumber<=24 and CommissionStart<=isnull(CommissionEnd,'2500-12-31')
	)P on o.Id=P.OpportunityId
  where TrueNorth='Yes'
  --CurrentStage='Closed - Won' and
  )Q
  left join 
  (
  select * from #TempUsers7x
   )w
   on q.CommissionYear=w.year and q.CommissionMonth=w.month and q.Username=w.TTdescription and q.NetworkLimiter=w.NetworkShortName
   Left Join 
   (
   SELECT Year,Month,IsClosed FROM [fillhub].[dbo].[InvoiceMonth]
   )I on q.CommissionYear=I.year and q.CommissionMonth=I.month
   where TTPlatformUserId is null
----------------------------------------------------------------------------------------------------------------

UNION ALL

---------------------Query to get sales commission by TTUserid/TDescription/TTIDEMail trading screen products-------------------------------------
Select Revenue,(Revenue*cast(isnull(isnull(CommissionPercent,CommissionOverride),7.5) as numeric(26,12)))/100 as Commission,RevenueSource,q.*
,case when IsClosed=1 then 'Y' else 'N' End as IsMonthBilled from 
(
SELECT  year(CommissionStart) as CommissionYear,Month(CommissionStart) as CommissionMonth,O.[Id] as OpportunityId,[Name] as OpportunityName,'' as Author,'' as Title,'' as Regarding,DeliveryName
,TTPlatformUserId,SevenXUsername,isnull(SevenXUsername,TTPlatformUserId) as Username,RejectionReason,isnull(CommissionPercent,CommissionOverride) as CommissionPercent,CommissionStart,CommissionEnd,[TargetLiveDate],[ExpectedMonthlyRevenue],AccountId as [OrganizationId],OrganizationName
,[SalesRep],[CurrentStage]
--,[Description]
,NextStep as [NextSteps],[Region],[NumberOfScreens],[Priority]
,[Broker],[Top10],[ChanceOfClosing],[OpportunityType],[Source],[TrueNorth],[Products],[ClientType],CommissionOverride,NetworkLimiter
  FROM [SalesForce].[dbo].[Opportunities] O
	  left join
	  (
	  SELECT [SalesForceId],[Name] as OrganizationName      
	  FROM [SalesForce].[dbo].[AccountMaster]
	  where isdeleted='False'
	  )R on O.AccountId=R.SalesforceId
  inner Join 
  (
				Select * from 
			(
			Select *,row_number() over (partition by opportunityid,deliveryname order by commissionstart asc) as CommissionAppliedMonthNumber from 
			(
			Select Year,Month,Quarter, case when EndDate<CommissionStart then null else EndDate end as CommissionStart,CommissionEnd,DeliveryName,OpportunityId,TTPlatformUserId,SevenXUsername,RejectionReason,CommissionPercent,AccountingStage,NetworkLimiter from 
			(
			Select T.*,P.* from chisql12.bidw.[dbo].[TimeInterval] T
			left join 
			(
			SELECT Distinct [Name] as DeliveryName,[OpportunityId],[TTPlatformUserId],[SevenXUsername],[RejectionReason],[CommissionPercent],case when [CommissionStart] is null then w.date else CommissionStart end as CommissionStart,[CommissionEnd],[AccountingStage],NetworkLimiter
			FROM (select * from [SalesForce].[dbo].[PlatformUser] where NetworkLimiter is null) P
			left join
			(select Distinct TTUserId,Date from
				(
				select TTUserId,CAST(CAST(Year AS VARCHAR(4)) +RIGHT('0' + CAST(Month AS VARCHAR(2)), 2) +RIGHT('0' + CAST(1 AS VARCHAR(2)), 2) AS DATE) as Date,row_number() over (partition by TTUserId order by year,month) as row from #TempUserstt
				where TTUserId is not null and TTUserId<>''
				)S where row=1)w on p.TTPlatformUserId=w.TTUserId
			where AccountingStage='Verified' 
			--and CommissionPercent>0 
			and isdeleted='False'
			)P on 1=1
			where t.year>=Year(getdate())-1
			)z
			)g
			where CommissionStart is not null
			)x
			where CommissionAppliedMonthNumber<=24 and CommissionStart<=isnull(CommissionEnd,'2500-12-31')
	)P on o.Id=P.OpportunityId
  where TrueNorth='Yes'
  --CurrentStage='Closed - Won' and
  )Q
  left join 
  (
  select * from #TempUserstt
   )w
   on q.CommissionYear=w.year and q.CommissionMonth=w.month and q.Username=w.TTUserId
   Left Join 
   (
   SELECT Year,Month,IsClosed FROM [fillhub].[dbo].[InvoiceMonth]
   )I on q.CommissionYear=I.year and q.CommissionMonth=I.month
   where SevenXUsername is null and (TTPlatformUserId like '%@%' or isnumeric(TTPlatformUserId)=1)
----------------------------------------------------------------------------------------------------------------


UNION ALL

---------------------Query to get sales commission by  TTUserid/TDescription/TTIDEMail trading non-screen products-------------------------------------
Select Revenue,(Revenue*cast(isnull(isnull(CommissionPercent,CommissionOverride),7.5) as numeric(26,12)))/100 as Commission,RevenueSource,q.*
,case when IsClosed=1 then 'Y' else 'N' End as IsMonthBilled from 
(
SELECT  year(CommissionStart) as CommissionYear,Month(CommissionStart) as CommissionMonth,O.[Id] as OpportunityId,[Name] as OpportunityName,'' as Author,'' as Title,'' as Regarding,DeliveryName
,TTPlatformUserId,SevenXUsername,isnull(SevenXUsername,TTPlatformUserId) as Username,RejectionReason,isnull(CommissionPercent,CommissionOverride) as CommissionPercent,CommissionStart,CommissionEnd,[TargetLiveDate],[ExpectedMonthlyRevenue],Accountid as [OrganizationId],OrganizationName
,[SalesRep],[CurrentStage]
--,[Description]
,NextStep as [NextSteps],[Region],[NumberOfScreens],[Priority]
,[Broker],[Top10],[ChanceOfClosing],[OpportunityType],[Source],[TrueNorth],[Products],[ClientType],CommissionOverride,NetworkLimiter
  FROM [SalesForce].[dbo].[Opportunities] O
	  left join
	  (
	  SELECT [SalesForceId],[Name] as OrganizationName      
	  FROM [SalesForce].[dbo].[AccountMaster]
	  where isdeleted='False'
	  )R on O.AccountId=R.SalesforceId
  inner Join 
  (
				Select * from 
			(
			Select *,row_number() over (partition by opportunityid,deliveryname order by commissionstart asc) as CommissionAppliedMonthNumber from 
			(
			Select Year,Month,Quarter, case when EndDate<CommissionStart then null else EndDate end as CommissionStart,CommissionEnd,DeliveryName,OpportunityId,TTPlatformUserId,SevenXUsername,RejectionReason,CommissionPercent,AccountingStage,NetworkLimiter from 
			(
			Select T.*,P.* from chisql12.bidw.[dbo].[TimeInterval] T
			left join 
			(
			SELECT Distinct [Name] as DeliveryName,[OpportunityId],[TTPlatformUserId],[SevenXUsername],[RejectionReason],[CommissionPercent],case when [CommissionStart] is null then w.date else CommissionStart end as CommissionStart,[CommissionEnd],[AccountingStage],NetworkLimiter
			FROM (select * from [SalesForce].[dbo].[PlatformUser] where NetworkLimiter is null) P
			left join
			(select Distinct TTdescription,Date from
				(
				select TTdescription,CAST(CAST(Year AS VARCHAR(4)) +RIGHT('0' + CAST(Month AS VARCHAR(2)), 2) +RIGHT('0' + CAST(1 AS VARCHAR(2)), 2) AS DATE) as Date,row_number() over (partition by ttdescription order by year,month) as row from #TempUsersttnonscreen
				where TTdescription is not null and TTdescription<>''
				)S where row=1)w on p.[SevenXUsername]=w.TTdescription
			where AccountingStage='Verified' 
			--and CommissionPercent>0 
			and isdeleted='False'
			)P on 1=1
			where t.year>=Year(getdate())-1
			)z
			)g
			where CommissionStart is not null
			)x
			where CommissionAppliedMonthNumber<=24 and CommissionStart<=isnull(CommissionEnd,'2500-12-31')
	)P on o.Id=P.OpportunityId
  where TrueNorth='Yes'
  --CurrentStage='Closed - Won' and
  )Q
  left join 
  (
  select * from #TempUsersttnonscreen
   )w
   on q.CommissionYear=w.year and q.CommissionMonth=w.month and q.Username=w.TTdescription
   Left Join 
   (
   SELECT Year,Month,IsClosed FROM [fillhub].[dbo].[InvoiceMonth]
   )I on q.CommissionYear=I.year and q.CommissionMonth=I.month
   where SevenXUsername is null and TTPlatformUserId not like '%@%' and isnumeric(TTPlatformUserId)=0
----------------------------------------------------------------------------------------------------------------

)Final




----------------------------------------Processed Commissions----------------------------------------------
Select 
[CommissionDate], year(PU.[CommissionStart]) as [CommissionStartYear],month(PU.[CommissionStart]) as [CommissionStartMonth], [Revenue]
,case when 
T.username in ('Markus Grob','malcolm.wong@cimb.com','sueann.lee@cimb.com'
,'yewjin.huang@cimb.com','SAP0011P','SAP0011Q','zmandel','tim.marchant@newerainvestments.com'
,'ddacosta@danix.co.uk','mike.carney@newerainvestments.com','raphael.daune@newerainvestments.com'
,'RWALKER','Michela Franceschini','Liliane Riad','Wolfgang Kitzing','Mark T Lee'
,'Simon Bourqui','Eric Bourgeois','Antoine Bonnot','Sszkudlarek','Greg Davidoff','NHFNHFUORPR') 
then commission else
case when t.CommissionDate>=st.CommissionStartMin then commission else 0 end end as Commission
, [OpportunityId]
, [OpportunityName], [Author], [Title], [Regarding], [DeliveryName], [TTPlatformUserId], [SevenXUsername]
, T.[Username], [RejectionReason], [CommissionPercent], PU.[CommissionStart], PU.[CommissionEnd], [TargetLiveDate]
, [ExpectedMonthlyRevenue], [OrganizationId], [OrganizationName], [SalesRep], [CurrentStage], [NextSteps]
, [Region], [NumberOfScreens], [Priority], [Broker], [Top10], [ChanceOfClosing], [OpportunityType], [Source]
, [TrueNorth], [Products], [ClientType], [IsMonthBilled], [RevenueSource], [CommissionSnapshotDate], [MonthsRemaining]
Into #ProcessedData
from #TrueNorthSalesCommissions T
Left Join 
(
-------------Logic to get Months Ramaining for TN Commission to be paid out---------------
SELECT UserName,12-count(distinct case when  Commission>0
and RevenueSource='AX Invoices' 
then [CommissionDate] END) as MonthsRemaining
  FROM #TrueNorthSalesCommissions
  where username is not null
  group by username
  )M on T.Username=M.Username
Left Join 
(
SELECT Distinct isnull([SevenXUsername],[TTPlatformUserId]) as UserName,[CommissionStart],CommissionEnd FROM [SalesForce].[dbo].[PlatformUser]
where (SevenXUsername is not null or TTPlatformUserId is not null)
and AccountingStage='Verified' 
--and CommissionPercent>0 
and isdeleted='False'
)PU on T.Username=PU.UserName
left join 
( 
select Distinct UserName,min(CommissionStart) as CommissionStartMin from 
(
select distinct username, CommissionStart,Revenue
,row_number() over (partition by username order by CommissionStart) as RowId
, case when revenue>50 then 1 else 0 end as Revenue50orMore
from #TrueNorthSalesCommissions
where username is not null and revenue is not null
)r where Revenue50orMore=1
group by username
)St on t.Username=st.Username
where Revenue is not null and Commission is not null




-------------------------------------Delete the TrueNorthSalesCommissions--------------------------------------------------------

Select * 
Into #FinalData
from
(
-------------------------------------------------With zero commissions--------------------------------------------------
Select [CommissionDate],[CommissionStartYear],[CommissionStartMonth],[Revenue],[Commission],[OpportunityId],[OpportunityName],[Author],[Title],[Regarding],[DeliveryName],[TTPlatformUserId],[SevenXUsername],final.[Username]
,[RejectionReason],[CommissionPercent],[CommissionStart],[CommissionEnd],[TargetLiveDate],[ExpectedMonthlyRevenue],[OrganizationId],[OrganizationName],salesrep as [SalesManager],[CurrentStage],[NextSteps],[Region],[NumberOfScreens]
,[Priority],[Broker],[Top10],[ChanceOfClosing],[OpportunityType],[Source],[TrueNorth],[Products],[ClientType],[IsMonthBilled],[RevenueSource]
,[CommissionSnapshotDate],case when m.[MonthsRemaining]<0 then 0 else m.[MonthsRemaining] End as MonthsRemaining  from 
(
Select *,0 as Record from
(
select * from #ProcessedData
)With0
where commission=0

UNION

--------------------------------With non-zero commissions----------------------------------------------------------------
Select *,case when commission>0 or commission is null then row_number() over (partition by username order by commissiondate) end as row from
(
select * from #ProcessedData
)Alldata
where commission>0 or commission is null
)Final
Left Join 
(
-------------Logic to get Months Ramaining for TN Commission to be paid---------------
SELECT UserName,12-count(distinct case when  Commission>0
and RevenueSource='AX Invoices' 
then [CommissionDate] END) as MonthsRemaining
  FROM (Select * from #ProcessedData where commission>0 or commission is null)Q
  where username is not null
  group by username
  )M on final.Username=M.Username
where Record<=12
)QQ


Delete BIDW.dbo.TrueNorthSalesCommissions
where CommissionDate>=@RunDate
Insert Into BIDW.dbo.TrueNorthSalesCommissions
Select [CommissionDate],year(CommissionStartDate) as [CommissionStartYear],month(CommissionStartDate) as [CommissionStartMonth]
,[Revenue],[Commission],[OpportunityId],[OpportunityName]
,[Author],[Title],[Regarding],[DeliveryName],[TTPlatformUserId],[SevenXUsername],FD.[Username]
,[RejectionReason],[CommissionPercent],CommissionStartDate as [CommissionStart],[CommissionEnd],[TargetLiveDate],[ExpectedMonthlyRevenue]
,[OrganizationId],[OrganizationName]
,[SalesManager],[CurrentStage],[NextSteps],[Region],[NumberOfScreens]
,[Priority],[Broker],[Top10],[ChanceOfClosing],[OpportunityType],[Source],[TrueNorth],[Products],[ClientType]
,[IsMonthBilled],[RevenueSource]
,[CommissionSnapshotDate],MonthsRemaining,FirstInvoiceDate
,case when s.screens is null then 'Nonscreen' else s.screens end as Screens
,'Automation' as DataSource from #FinalData FD
left join
(
select username,min(commissiondate) as FirstInvoiceDate,min(case when commission>0 then commissiondate end) as CommissionStartDate
from #FinalData
group by username
)ID on fd.Username=Id.Username
left join 
(select distinct eomonth(date) as EndDate,TTdescription as UserName,'Screen' as Screens 
from #BillingData
where year>=2017 
and screens like '%screens%'
UNION
select distinct eomonth(date) as EndDate,ttuserid as UserName,'Screen' as Screens 
from #BillingData
where year>=2017 
and screens like '%screens%'
UNION
select distinct eomonth(date) as EndDate,AdditionalInfo as UserName,'Screen' as Screens 
from #BillingData
where year>=2017 
and screens like '%screens%'
UNION
select distinct eomonth(date) as EndDate,TTIDEmail as UserName,'Screen' as Screens 
from #BillingData
where year>=2017 
and screens like '%screens%'
)S on fd.CommissionDate=s.EndDate and fd.Username=s.UserName
where CommissionDate>=@RunDate


Drop table #TrueNorthSalesCommissions
Drop table #ProcessedData
Drop table #FinalData
Drop table #BillingData

 END
