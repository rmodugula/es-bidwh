drop table #Billing
Select * 
INto #Billing
from MonthlyBillingDataAggregate_domo
where year>=2016 and ismonthbilled='Y'and screens like 'screens%'


drop table #NewMasterUsers
SELECT [MasterUserId]
      ,mu.[UserName]
      ,[NetworkShortName]
	  ,isnull(isnull(isnull(u.LastTradedDate,ut.LastTradedDate),s.LastBilledDate),isnull(sl.LastBilledDate,tl.LastBilledDate)) as LastTradedDate
	  Into #NewMasterUsers
  FROM [BIDW].[dbo].[MasterUser] MU 
  left join 
  (
  select username,max(transactiondate) as LastTradedDate from fills
  where year>=2016 and IsBillable='Y'
  group by username
  )U on mu.username=u.username
  left join 
  (
  select cast(UserId as varchar(50)) as UserId,max(transactiondate) as LastTradedDate from fills
  where year>=2016 and IsBillable='Y'
  group by UserId
  )Ut on mu.username=ut.UserId
  left join 
  (
  select AdditionalInfo,max(date) as LastBilledDate from #Billing
   group by AdditionalInfo
  )S on mu.UserName=s.AdditionalInfo
   left join 
  (
   select TTdescription,max(date) as LastBilledDate from #Billing
  group by TTdescription
  )SL on mu.UserName=sL.TTdescription
  left join 
  (
   select TTUserId,max(date) as LastBilledDate from #Billing
  group by TTUserId
  )TL on mu.UserName=TL.TTUserId
  order by 1


drop table #data
select * 
into #data
from 
(
Select *,row_number() over (partition by masteruserid order by lasttradeddate desc) as rowid from #NewMasterUsers
)w
order by 1

drop table #final
select *,isnull(lead(NetworkShortName) over (partition by masteruserid order by masteruserid,lasttradeddate desc),'-') as LeadNetworkName
Into #final
from #data
--where MasterUserId='4ADFD42A-8FF1-4AFD-9B6E-0001F0AF4B94'

drop table #WithMigrations
Select MasterUserId,UserName,NetworkShortName,LastTradedDate,case when NetworkShortName in ('TTWEB','7xASP') 
and LeadNetworkName not in ('TTWEB','-') and NetworkShortName<>LeadNetworkName
and rowid=1 
then 'Migration' end as Reason 
into #WithMigrations
from 
(
select * from #final
--where MasterUserId='1F5EC653-6F85-4D7E-844F-0E0A13573509'
)H

--select * from #WithMigrations

drop table #withTransfers
Select MasterUserId,UserName,NetworkShortName,LastTradedDate
,case when NetworkShortName not in ('TTWEB','7xASP','-') and LeadNetworkName not in ('TTWEB','7xASP','-')
and NetworkShortName<>LeadNetworkName and rowid=1
then 'Transfer' End as Reason 
Into #withTransfers
from #final
where MasterUserId not in 
(select distinct MasterUserId from #WithMigrations
where reason='Migration')


-------------Final data with trade dates and migration/transfer assignments------
delete [dbo].[MasterUserWithReasons]
insert into [dbo].[MasterUserWithReasons]
Select * 
--Into MasterUser_Updated
from 
(
select MasterUserId,UserName,NetworkShortName,LastTradedDate,case when rowid=1 then 
'Other' END as Reason from #final
where MasterUserId not in 
(select distinct MasterUserId from #WithMigrations
where reason='Migration')
and MasterUserId not in 
(select distinct MasterUserId from #withTransfers
where reason='Transfer')
UNION
select MasterUserId,UserName,NetworkShortName,LastTradedDate,case when rowid=1 then 
'Migration' END as Reason from #final
where MasterUserId in 
(select distinct MasterUserId from #WithMigrations
where reason='Migration')
UNION
select MasterUserId,UserName,NetworkShortName,LastTradedDate,case when rowid=1 then 
'Transfer' END as Reason from #final
where MasterUserId in 
(select distinct MasterUserId from #withTransfers
where reason='Transfer')
)FinalData