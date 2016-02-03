------------------------------Append New Accounts Information into TT Master Customer Table----------------- 
Insert into chiaxsql01.[TT_DYANX09_PRD].[dbo].[TTMASTERCUSTOMER]
select 1 as Recversion, (select max(recid) from chiaxsql01.[TT_DYANX09_PRD].[dbo].[TTMASTERCUSTOMER])+row_number() over (order by Accountid) as Recid
,substring(Name,1,100) as CustomerName,Accountid as CRMguid from chisql12.crmonlinebi.dbo.account
where accountid in
(
SELECT distinct [accountid] FROM chisql12.[CRMOnlineBI].[dbo].[TTAccountContracts]
where accountid not in 
(
SELECT distinct crmguid  FROM chiaxsql01.[TT_DYANX09_PRD].[dbo].[TTMASTERCUSTOMER]
  )
)


---------------------------Update Customer Names to that of Master Account Names in CRM----------------
Update T
Set t.customername=substring(a.Name,1,100)
from chiaxsql01.[TT_DYANX09_PRD].[dbo].[TTMASTERCUSTOMER] T
left join chisql12.crmonlinebi.dbo.account A on t.crmguid=a.accountid
where crmguid in 
(
select Distinct crmguid from
(
SELECT distinct crmguid,customername FROM chiaxsql01.[TT_DYANX09_PRD].[dbo].[TTMASTERCUSTOMER]
Except 
SELECT distinct [accountid],Name FROM chisql12.crmonlinebi.dbo.account
)Q
) 
and a.name is not null

