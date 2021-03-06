SELECT *
  FROM [Salesforce]...[TT_Coverage__c]
  where IsDeleted='false' and cast(TT_Coverage_Role__c as char)='CSM'
  --and account__c='0011N00001XtPw7QAF'
  and Account__c+User__c in 
  (
  Select distinct s.accountid+u.id from (
Select Accountid,TTEmployee,count(distinct CoverageType) as Usercount from [Salesforce].[dbo].[TTCoverage]
where CoverageType in ('CSM','Primary Success Lead')
and AccountId is not null
Group by AccountId,TTEmployee
having count(distinct CoverageType)>1
--order by 3 desc
)s
left join (Select * from salesforce.[dbo].[User] where isactive='true') U on s.TTEmployee=u.name
where s.AccountId<>'0011N00001XtPu7QAF'
)



select * from [Salesforce]...[TT_Coverage__c]
where account__c='0011N00001XtPu7QAF' 



delete [Salesforce]...[TT_Coverage__c]
--set isdeleted='true'
 where IsDeleted='false' and cast(TT_Coverage_Role__c as char)='CSM'
   --and account__c='0011N00001XtPwEQAV'
   and Account__c+User__c in 
  (
  Select distinct s.accountid+u.id from (
Select Accountid,TTEmployee,count(distinct CoverageType) as Usercount from [Salesforce].[dbo].[TTCoverage]
where CoverageType in ('CSM','Primary Success Lead')
and AccountId is not null
Group by AccountId,TTEmployee
having count(distinct CoverageType)>1
--order by 3 desc
)s
left join (Select * from salesforce.[dbo].[User] where isactive='true') U on s.TTEmployee=u.name
where s.AccountId<>'0011N00001XtPu7QAF'
)



select * from salesforce.dbo.AccountMaster
where SalesforceId='0011N00001XtPu7QAF'