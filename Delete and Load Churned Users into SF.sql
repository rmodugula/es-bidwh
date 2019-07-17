--select * from salesforce...Churn__c
--order by systemmodstamp desc


--select * from salesforce...[user]
--where id in ('0051N000006mY35QAE','0051N000006mY4MQAU')

--select id,* from salesforce...Account
--where crm_id__c='b6ca5f95-2a2c-48f2-a57a-b49f1f80b783'



------------------------Delete and load churned users into SF---------------------
--delete salesforce...churn__c
Insert into salesforce...churn__c
([Account__c],[ChurnDate__c],[CurrencyIsoCode],[Email__c],[Name],[Office__c],[OwnerId],ReasonForLeaving__c
,[UserCompany__c],[UserGroup__c])

select distinct am.id,DATEADD(DAY,1,EOMONTH(Date,-1)) as Date,'USD',email,deliveryname,salesoffice,U.Id as ownerid,
reasonforleaving ,usercompany,usergroup 
from chisql12.bidw.dbo.churnedusersbymonth CM
left join
(
select * from salesforce...Account am
where name not like '%managed%'
) AM on cm.crmid=am.crm_id__c
left join 
(
select distinct Id,Name from salesforce...[user] where isactive='true'
)U on cm.customersuccessmanager=U.Name
where year=2019 and month=6 and churntype='core' and cancels>0
and am.id is not null
order by deliveryname



delete salesforce...churn__c
--select * from  salesforce...churn__c
where [ChurnDate__c]='06/01/2019'
