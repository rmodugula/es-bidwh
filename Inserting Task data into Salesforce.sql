select id,* from salesforce...[user]
where name like '%kara%' or 
name like '%intelligence%'
  

--select top 10 * FROM [SALESFORCE]...[contact]
--where email like '%peterzhang@globalsigmagroup.com%'
--  order by systemmodstamp desc



select top 100 * FROM [SALESFORCE]...[Task]
where cast(Task_Topic__c as char)='Active Outreach'
and cast(createddate as date)='2018-11-18'
  order by systemmodstamp desc



Select *  
Into #ActiveOutReachData
from
[dbo].[GetActiveOutReachWithLastTradedDate]
 where date=cast(DATEADD(dd, -(DATEPART(dw, getdate())-1), getdate()) as date)




Insert into [SALESFORCE]...[Task]
(ActivityDate,Task_Topic__c,[OwnerId],[ReminderDateTime],[Status],[Subject],Description,Type,WhoId)


Select distinct getdate(),'Active Outreach',isnull(u.id,'0051N000006mY2yQAE') as Id
,cast(Getdate() as date) as Date,'Open' as Status,'Active Outreach:'+' '+isnull(nullif(TTIDemail,''),deliveryname),
'OutreachKey: '+au.Outreachkey+CHAR(13)+CHAR(13)+'Date: '+rtrim(cast(date as char))+CHAR(13)+'Account Name: '+MasterAccountName
+CHAR(13)
+'User Company: '+UserCompany+CHAR(13)+'DeliveryName: '+DeliveryName+CHAR(13)
+'UserGroup: '+isnull(UserGroup,'-')+CHAR(13)
+'CustomerGroup: '+isnull(CustomerGroup,'-')+CHAR(13)
+'SalesOffice: '+isnull(SalesOffice,'-')+CHAR(13)
+'Pro/NonPro: '+isnull([Pro/NonPro],'-')+CHAR(13)
+'TTIDEmail: '+isnull(TTIDEmail,'-')+CHAR(13)
+'Domain: '+isnull(Domain,'-')+CHAR(13) 
+'Last Trade Prior To Gap: '+cast(LastTradePriorToGap as varchar(10))+CHAR(13) 
+'Last Login Date: '+cast(AU.LastLoginDate as varchar(10))+CHAR(13) 
+'AvgRev In Last 12 Months: '+cast(AvgRevInLast12Months  as varchar(10))+CHAR(13) 
+'Months Traded in Last 12 Months: '+cast(MonthsTradedinLast12Months  as varchar(2))+CHAR(13) 
+'Last Transaction Date: '+cast(LastTransactionDate  as varchar(10))+CHAR(13) as Description
,'Task',SC.Id as WhoId
from (select * from [dbo].[GetActiveOutReachWithLastTradedDate] 
where date=cast(DATEADD(dd, -(DATEPART(dw, getdate())-1), getdate()) as date)
and OutreachResult is null)Au
left join chisql12.[Salesforce].[dbo].[AccountMaster] AM on Au.masteraccountname=AM.Name
left join (select * from salesforce...[user] where isactive='true') u on au.customersuccessmanager=u.name
Left join [SALESFORCE]...[contact] SC on au.ttidemail=SC.Email


 





