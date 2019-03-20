----------Update already existing masteruser into Masteruser table for subscription to subscription username changes--------------
Insert into MasterUser
Select distinct mu.MasterUserId,t.Deliveryname,t.NetworkName,ttuserid,t.personid
--t.*,mu.masteruserid,u.alias
from (
SELECT [MasterUserId],[MasterAccountName],[Username],[Deliveryname],[TTUserId],[Personid],[TTIDEmail]
,[NetworkName],[PreviousUserName],[PreviousDeliveryName],[PreviousNetworkName],[PreviousNetworkShortName]
FROM [BIDW].[Temporary].[novNewUsers]
where PreviousUserName not in ('none')  and NetworkName='Subscribe'  and PreviousDeliveryName='All'
)T left join masteruser MU on PreviousUserName=mu.username
Left join chisql20.mess.dbo.users U on t.ttuserid=u.userid
--where mu.MasterUserId<>'01934185-79A1-4A5C-80D7-2A36E296A1E1'

----------Update already existing masteruser into Masteruser table for subscription to Other network username changes--------------
Insert into MasterUser
Select distinct mu.MasterUserId,t.Deliveryname,PreviousNetworkShortName,ttuserid,t.personid
--t.*,mu.masteruserid,u.alias
from (
SELECT [MasterUserId],[MasterAccountName],[Username],[Deliveryname],[TTUserId],[Personid],[TTIDEmail]
,[NetworkName],[PreviousUserName],[PreviousDeliveryName],[PreviousNetworkName],[PreviousNetworkShortName]
FROM [BIDW].[Temporary].[novNewUsers]
where PreviousUserName not in ('none')  and NetworkName='Subscribe'  and PreviousDeliveryName<>'All'
)T left join masteruser MU on PreviousDeliveryName=mu.username
Left join chisql20.mess.dbo.users U on t.ttuserid=u.userid

----------Update already existing/ masterusers into Masteruser table for unibroker network to Other/same network username changes--------------
Insert into MasterUser
Select distinct mu.MasterUserId,t.Username,PreviousNetworkShortName,ttuserid,t.personid
--t.*,mu.masteruserid,u.alias
from (
SELECT [MasterUserId],[MasterAccountName],[Username],[Deliveryname],[TTUserId],[Personid],[TTIDEmail]
,[NetworkName],[PreviousUserName],[PreviousDeliveryName],[PreviousNetworkName],[PreviousNetworkShortName]
FROM [BIDW].[Temporary].[novNewUsers]
where PreviousUserName not in ('none')  and NetworkName not in ('Subscribe','7xASP','TTWEB')  
)T left join masteruser MU on PreviousUserName=mu.username
Left join chisql20.mess.dbo.users U on t.ttuserid=u.userid
where mu.MasterUserId is not null

----------Add new masterusers into Masteruser table for unibroker network to Other/same network username changes--------------
drop table #NewMUUni
Select newid() as MasterUserId,t.Username,NetworkName,previoususername,PreviousNetworkShortName,ttuserid,t.personid
Into #NewMUUni
from (
SELECT [MasterUserId],[MasterAccountName],[Username],[Deliveryname],[TTUserId],[Personid],[TTIDEmail]
,[NetworkName],[PreviousUserName],[PreviousDeliveryName],[PreviousNetworkName],[PreviousNetworkShortName]
FROM [BIDW].[Temporary].[novNewUsers]
where PreviousUserName not in ('none')  and NetworkName not in ('Subscribe','7xASP','TTWEB')  
)T left join masteruser MU on PreviousUserName=mu.username
Left join chisql20.mess.dbo.users U on t.ttuserid=u.userid
where mu.MasterUserId is null

Insert into MasterUser
Select MasterUserId,Username,NetworkName,TTUserId,Personid from #NewMUUni
UNION
Select MasterUserId,PreviousUserName,NetworkName,TTUserId,Personid from #NewMUUni


----------Update already existing/ masterusers into Masteruser table for multibroker network to Other/same network username changes--------------
Insert into MasterUser
Select distinct mu.MasterUserId,t.Username,PreviousNetworkShortName,ttuserid,t.personid
--t.*,mu.masteruserid,u.alias
from (
SELECT [MasterUserId],[MasterAccountName],[Username],[Deliveryname],[TTUserId],[Personid],[TTIDEmail]
,[NetworkName],[PreviousUserName],[PreviousDeliveryName],[PreviousNetworkName],[PreviousNetworkShortName]
FROM [BIDW].[Temporary].[novNewUsers]
where PreviousUserName not in ('none')  and NetworkName in ('7xASP')  
)T left join masteruser MU on PreviousDeliveryName=mu.username
Left join chisql20.mess.dbo.users U on t.ttuserid=u.userid
--where PreviousDeliveryName='SQUARESB'

----------Update already existing masterusers into Masteruser table for TTWEB network to Other/same network username changes--------------
Insert into MasterUser
Select distinct mu.MasterUserId,alias,isnull(NetworkName,'TTWEB') as NetworkName,ttuserid,t.personid
--t.*,mu.masteruserid,u.alias
from (
SELECT [MasterUserId],[MasterAccountName],[Username],[Deliveryname],[TTUserId],[Personid],[TTIDEmail]
,[NetworkName],[PreviousUserName],[PreviousDeliveryName],[PreviousNetworkName],[PreviousNetworkShortName]
FROM [BIDW].[Temporary].[novNewUsers]
where PreviousUserName not in ('none')  and NetworkName in ('TTWEB')  
)T left join masteruser MU on t.PreviousUserName=mu.username or t.PreviousDeliveryName=mu.username 
Left join chisql20.mess.dbo.users U on t.ttuserid=u.userid
where mu.MasterUserId is not null


----------Add New masterusers into Masteruser table for TTWEB network to Other/same network username changes--------------
Insert into MasterUser
Select newid() as MasterUserId,alias,isnull(NetworkName,'TTWEB') as NetworkName,ttuserid,t.personid
--t.*,mu.masteruserid,u.alias
from (
SELECT [MasterUserId],[MasterAccountName],[Username],[Deliveryname],[TTUserId],[Personid],[TTIDEmail]
,[NetworkName],[PreviousUserName],[PreviousDeliveryName],[PreviousNetworkName],[PreviousNetworkShortName]
FROM [BIDW].[Temporary].[novNewUsers]
where PreviousUserName not in ('none')  and NetworkName in ('TTWEB')  
)T left join masteruser MU on t.PreviousUserName=mu.username or t.PreviousDeliveryName=mu.username
Left join chisql20.mess.dbo.users U on t.ttuserid=u.userid
where mu.MasterUserId is null and NetworkName='TTWEB' and PreviousNetworkName='TTWEB'


--------------Insert new masteruserid for new users----------------
Insert into MasterUser
SELECT  Newid(),case when networkname='Subscribe' then deliveryname else username end as Username
,case when NetworkName='NULL' then 'Subscribe' else NetworkName end as Network,TTUserId,o.Personid
FROM [BIDW].[Temporary].[novNewUsers] O
Left join chisql20.mess.dbo.users U on o.ttuserid=u.userid
where PreviousUserName in ('none') and NetworkName<>'TTWEB'
UNION
SELECT Newid(),alias,case when NetworkName='NULL' then 'Subscribe' else NetworkName end as Network,TTUserId,o.Personid
FROM [BIDW].[Temporary].[novNewUsers] O
Left join chisql20.mess.dbo.users U on o.ttuserid=u.userid
where PreviousUserName in ('none') and NetworkName='TTWEB'


--------------------Queries to check quality of the data------

Select userid,count(distinct masteruserid) from masteruser
group by userid
order by 2 desc

Select username,count(distinct masteruserid) from masteruser
group by username
order by 2 desc