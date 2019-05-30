select distinct churndate__C from salesforce...Churn__c
order by 1 


------------------------Delete and load churned users into SF---------------------
--delete salesforce...churn__c
--where churndate__c='2018-09-01 00:00:00.0000000'
Insert into salesforce...churn__c
([Account__c],[ChurnDate__c],[CurrencyIsoCode],[Email__c],[Name],[Office__c],[OwnerId],ReasonForLeaving__c
,[UserCompany__c],[UserGroup__c])

select  distinct am.id,Date,'USD',email,deliveryname,salesoffice,U.Id as ownerid,
reasonforleaving ,usercompany,usergroup 
from chisql12.bidw.dbo.churnedusersbymonth CM
left join
(
select * from salesforce...Account am
where name not like '%managed%'
) AM on cm.crmid=am.crm_id__c
left join 
(
select distinct Id,Name from salesforce...[user]
where isactive='true'
)U on cm.customersuccessmanager=U.Name
where year=2018 and month=10 and churntype='core' and cancels>0



select distinct churndate__c,Name,Usergroup__c from salesforce...Churn__c
where Usergroup__c is not null
order by 1,2