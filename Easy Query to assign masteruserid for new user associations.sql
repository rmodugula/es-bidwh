---------------------Back up tables----------------------------
--select * 
--Into MasterUser_20190318
--from masteruser


--SELECT  *
--into [dbo].[ChurnedUsersByMonth_20190318]
--  FROM [BIDW].[dbo].[ChurnedUsersByMonth]

--  SELECT  *
--into [dbo].[UserAddsByMonth_20190318]
--  FROM [dbo].[UserAddsByMonth]

-------------------------------------------------------------------------------


----------Update already existing masteruser into Masteruser table for subscription to subscription username changes--------------
Insert into MasterUser
Select distinct mu.MasterUserId,t.Deliveryname,t.NetworkName,ttuserid,t.personid
--t.*,mu.masteruserid,u.alias
from (
SELECT [MasterUserId],[MasterAccountName],[Username],[Deliveryname],[TTUserId],[Personid]
,[NetworkName],[PreviousUserName],[PreviousDeliveryName],[PreviousNetworkName],[PreviousNetworkShortName]
FROM [BIDW].[Temporary].[FebNewUsers2019]
where PreviousUserName not in ('none')  and NetworkName='Subscribe'  and PreviousDeliveryName='All'
)T left join masteruser MU on PreviousUserName=mu.username
Left join chisql20.mess.dbo.users U on t.ttuserid=u.userid
--where mu.MasterUserId<>'01934185-79A1-4A5C-80D7-2A36E296A1E1'

----------Update already existing masteruser into Masteruser table for subscription to Other network username changes--------------
Insert into MasterUser
Select distinct mu.MasterUserId,t.Deliveryname,PreviousNetworkShortName,ttuserid,t.personid
--t.*,mu.masteruserid,u.alias
from (
SELECT [MasterUserId],[MasterAccountName],[Username],[Deliveryname],[TTUserId],[Personid]
,[NetworkName],[PreviousUserName],[PreviousDeliveryName],[PreviousNetworkName],[PreviousNetworkShortName]
FROM [BIDW].[Temporary].[FebNewUsers2019]
where PreviousUserName not in ('none')  and NetworkName='Subscribe'  and PreviousDeliveryName<>'All'
)T left join masteruser MU on PreviousDeliveryName=mu.username
Left join chisql20.mess.dbo.users U on t.ttuserid=u.userid
where mu.MasterUserId is not null

----------Update already existing/ masterusers into Masteruser table for unibroker network to Other/same network username changes--------------
Insert into MasterUser
Select distinct mu.MasterUserId,t.Username,PreviousNetworkShortName,ttuserid,t.personid
--t.*,mu.masteruserid,u.alias
from (
SELECT [MasterUserId],[MasterAccountName],[Username],[Deliveryname],[TTUserId],[Personid]
,[NetworkName],[PreviousUserName],[PreviousDeliveryName],[PreviousNetworkName],[PreviousNetworkShortName]
FROM [BIDW].[Temporary].[FebNewUsers2019]
where PreviousUserName not in ('none')  and NetworkName not in ('Subscribe','7xASP','TTWEB')  
)T left join masteruser MU on PreviousUserName=mu.username
Left join chisql20.mess.dbo.users U on t.ttuserid=u.userid
where mu.MasterUserId is not null and t.username<>'All'
--and mu.masteruserid not in ('581F5734-C27F-4A5C-B4D5-2D6CA2E14AAF','ACEC605C-D8BE-479A-AA5C-A08027934CF4')

----------Add new masterusers into Masteruser table for unibroker network to Other/same network username changes--------------
drop table #NewMUUni
Select newid() as MasterUserId,t.Username,NetworkName,previoususername,PreviousNetworkShortName,ttuserid,t.personid
Into #NewMUUni
from (
SELECT [MasterUserId],[MasterAccountName],[Username],[Deliveryname],[TTUserId],[Personid]
,[NetworkName],[PreviousUserName],[PreviousDeliveryName],[PreviousNetworkName],[PreviousNetworkShortName]
FROM [BIDW].[Temporary].[FebNewUsers2019]
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
SELECT [MasterUserId],[MasterAccountName],[Username],[Deliveryname],[TTUserId],[Personid]
,[NetworkName],[PreviousUserName],[PreviousDeliveryName],[PreviousNetworkName],[PreviousNetworkShortName]
FROM [BIDW].[Temporary].[FebNewUsers2019]
where PreviousUserName not in ('none')  and NetworkName in ('7xASP')  
)T left join masteruser MU on PreviousDeliveryName=mu.username
Left join chisql20.mess.dbo.users U on t.ttuserid=u.userid
--where PreviousDeliveryName='SQUARESB'


--drop table #temp
--Select * Into #Temp from masteruser
----------Update already existing masterusers into Masteruser table for TTWEB network to Other/same network username changes--------------
Insert into MasterUser
--Insert Into #Temp
Select distinct mu.MasterUserId,alias,isnull(NetworkName,'TTWEB') as NetworkName,ttuserid,t.personid
--t.*,mu.masteruserid,u.alias
from (
SELECT [MasterUserId],[MasterAccountName],[Username],[Deliveryname],[TTUserId],[Personid]
,[NetworkName],[PreviousUserName],[PreviousDeliveryName],[PreviousNetworkName],[PreviousNetworkShortName]
FROM [BIDW].[Temporary].[FebNewUsers2019]
where PreviousUserName not in ('none')  and NetworkName in ('TTWEB')  
)T left join masteruser MU on t.PreviousUserName=mu.username or t.PreviousDeliveryName=mu.username 
Left join chisql20.mess.dbo.users U on t.ttuserid=u.userid
where mu.MasterUserId is not null 


--select * from #Temp
--where username='dbanks'

----------Add New masterusers into Masteruser table for TTWEB network to Other/same network username changes--------------
Insert into MasterUser
--Insert Into #Temp
Select newid() as MasterUserId,alias,isnull(NetworkName,'TTWEB') as NetworkName,ttuserid,t.personid
--t.*,mu.masteruserid,u.alias
from (
SELECT [MasterUserId],[MasterAccountName],[Username],[Deliveryname],[TTUserId],[Personid]
,[NetworkName],[PreviousUserName],[PreviousDeliveryName],[PreviousNetworkName],[PreviousNetworkShortName]
FROM [BIDW].[Temporary].[FebNewUsers2019]
where PreviousUserName not in ('none')  and NetworkName in ('TTWEB')  
)T left join masteruser MU on t.PreviousUserName=mu.username or t.PreviousDeliveryName=mu.username
Left join chisql20.mess.dbo.users U on t.ttuserid=u.userid
where mu.MasterUserId is null and NetworkName='TTWEB' and PreviousNetworkName='TTWEB'


--------------Insert new masteruserid for new users Non -TTWEB----------------
Insert into MasterUser
--Insert Into #Temp
SELECT  Newid() as MasterUserId,case when networkname='Subscribe' then deliveryname else username end as Username
,case when NetworkName='NULL' then 'Subscribe' else NetworkName end as Network,TTUserId,o.Personid
FROM [BIDW].[Temporary].[FebNewUsers2019] O
Left join chisql20.mess.dbo.users U on o.ttuserid=u.userid
where PreviousUserName in ('none') and NetworkName<>'TTWEB'




--------------Insert new masteruserid for new users TTWEB----------------
Insert into MasterUser
--Insert Into #Temp
Select distinct isnull(MU.MasterUserId,N.MasterUserId) as MasterUserid,alias,Network,ttuserid,N.PersonId from 
(
SELECT Newid() as MasterUserId,alias,case when NetworkName='NULL' then 'Subscribe' else NetworkName end as Network,TTUserId,o.Personid
FROM [BIDW].[Temporary].[FebNewUsers2019] O
Left join chisql20.mess.dbo.users U on o.ttuserid=u.userid 
where PreviousUserName in ('none') and NetworkName='TTWEB'
)N
left join MasterUser MU on N.alias=MU.username


--------------------Queries to check quality of the data------

Select userid,count(distinct masteruserid) from masteruser
group by userid
order by 2 desc

Select username,count(distinct masteruserid) from masteruser
group by username
order by 2 desc

Select userid,count(distinct masteruserid) from #Temp
group by userid
order by 2 desc

Select username,count(distinct masteruserid) from #Temp
group by username
order by 2 desc