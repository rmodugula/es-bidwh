Select Revenue,(Revenue*cast(CommissionPercent as numeric))/100 as FinalRevenue,q.* from 
(
SELECT  year(CommissionStart) as CommissionYear,Month(CommissionStart) as CommissionMonth,O.[Id] as OpportunityId,[Name] as OpportunityName,Author,Title,Regarding,DeliveryName
,TTPlatformUserId,SevenXUsername,isnull(SevenXUsername,TTPlatformUserId) as Username,RejectionReason,CommissionPercent,CommissionStart,CommissionEnd,[TargetLiveDate],[ExpectedMonthlyRevenue],[OrganizationId],OrganizationName
,[SalesRep],[CurrentStage]
--,[Description]
,[NextSteps],[Region],[NumberOfScreens],[Priority]
,[Broker],[Top10],[ChanceOfClosing],[OpportunityType],[Source],[TrueNorth],[Products],[ClientType]
  FROM [Synap].[dbo].[Opportunity] O
  INNER JOIN 
  (
  SELECT Distinct [Author],[Title],[Regarding],[RegardingIds]
   FROM [Synap].[dbo].[Note]
  where regardingids is not null
  and title ='True North Timestamp'
  and (Author ='BizOps Synap Api' or Author like '%mcclowry%')  and RegardingIds<>''
  )N on o.id=N.RegardingIds
	  left join
	  (
	  SELECT [Id],[Name] as OrganizationName      
	  FROM [Synap].[dbo].[Organization]
	  )R on O.OrganizationId=R.Id
  inner Join 
  (
    SELECT Distinct [Name] as DeliveryName,[OpportunityId],[TTPlatformUserId],[SevenXUsername],[RejectionReason],[CommissionPercent],[CommissionStart],[CommissionEnd],[AccountingStage]
     FROM [Synap].[dbo].[PlatformUser]
      where AccountingStage='Verified' and CommissionPercent>0 and CommissionStart is not null
	  )P on o.Id=P.OpportunityId
  where CurrentStage='Closed - Won' and TrueNorth=1
  --and SevenXUsername like '%ffhsha%'
  )Q
  left join 
  (
  Select Year,Month,TTdescription,sum(billedamount) as Revenue from bidw.dbo.MonthlyBillingDataAggregate
  where year=2017  
   Group by Year,Month,TTdescription
   UNION 
   Select Year,Month,AdditionalInfo,sum(billedamount) as Revenue from bidw.dbo.MonthlyBillingDataAggregate
  where year=2017  
   Group by Year,Month,AdditionalInfo
   	  UNION 
   Select Year,Month,TTUserId,sum(billedamount) as Revenue from bidw.dbo.MonthlyBillingDataAggregate
  where year=2017  
     Group by Year,Month,TTUserId
   )w
   on q.CommissionYear=w.year and q.CommissionMonth=w.month and q.Username=w.TTdescription