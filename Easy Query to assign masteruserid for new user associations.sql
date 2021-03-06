-------------------Back up tables----------------------------
select * 
Into MasterUser_20190715
from masteruser


SELECT  *
into [dbo].[ChurnedUsersByMonth_20190715]
  FROM [BIDW].[dbo].[ChurnedUsersByMonth]

  SELECT  *
into [dbo].[UserAddsByMonth_20190715]
  FROM [dbo].[UserAddsByMonth]


Select *  
Into [dbo].[MasterUserWithReasons_20190715]
from [dbo].[MasterUserWithReasons]
-------------------------------------------------------------------------------


----------Update already existing masteruser into Masteruser table for subscription to subscription username changes--------------
Insert into MasterUser
Select distinct mu.MasterUserId,t.Deliveryname,t.NetworkName,ttuserid,t.personid
--t.*,mu.masteruserid,u.alias
from (
SELECT [MasterUserId],[MasterAccountName],[Username],[Deliveryname],[TTUserId],[Personid]
,[NetworkName],[PreviousUserName],[PreviousDeliveryName],[PreviousNetworkName],[PreviousNetworkShortName]
FROM [BIDW].[Temporary].[JunNewUsers2019]
where PreviousUserName not in ('none')  and NetworkName='Subscribe'  and PreviousDeliveryName='All'
)T left join masteruser MU on PreviousUserName=mu.username or PreviousUserName=mu.username
Left join chisql20.mess.dbo.users U on t.ttuserid=u.userid


----------Update already existing masteruser into Masteruser table for subscription to Other network username changes--------------
Insert into MasterUser
Select distinct mu.MasterUserId,t.Deliveryname,PreviousNetworkShortName,ttuserid,isnull(t.personid,0) as PersonId
from (
SELECT [MasterUserId],[MasterAccountName],[Username],[Deliveryname],[TTUserId],[Personid]
,[NetworkName],[PreviousUserName],[PreviousDeliveryName],[PreviousNetworkName],[PreviousNetworkShortName]
FROM [BIDW].[Temporary].[JunNewUsers2019]
where PreviousUserName not in ('none')  and NetworkName='Subscribe'  and PreviousDeliveryName<>'All'
)T left join masteruser MU on PreviousDeliveryName=mu.username or PreviousUserName=mu.username
Left join chisql20.mess.dbo.users U on t.ttuserid=u.userid
where mu.MasterUserId is not null
--and PreviousNetworkShortName<>'TTWEB'

----------Update already existing/ masterusers into Masteruser table for unibroker network to Other/same network username changes--------------
Insert into MasterUser
Select distinct mu.MasterUserId,t.Username,NetworkName,ttuserid,isnull(t.personid,0) as PersonId
from (
SELECT [MasterUserId],[MasterAccountName],[Username],[Deliveryname],[TTUserId],[Personid]
,[NetworkName],[PreviousUserName],[PreviousDeliveryName],[PreviousNetworkName],[PreviousNetworkShortName]
FROM [BIDW].[Temporary].[JunNewUsers2019]
where PreviousUserName not in ('none')  and NetworkName not in ('Subscribe','7xASP','TTWEB')  
)T left join masteruser MU on PreviousUserName=mu.username or PreviousDeliveryName=mu.username
Left join chisql20.mess.dbo.users U on t.ttuserid=u.userid
where mu.MasterUserId is not null and t.username<>'All'


----------Add new masterusers into Masteruser table for unibroker network to Other/same network username changes--------------
drop table #NewMUUni
Select newid() as MasterUserId,t.Username,NetworkName,previoususername,PreviousNetworkShortName,ttuserid,t.personid
Into #NewMUUni
from (
SELECT [MasterUserId],[MasterAccountName],[Username],[Deliveryname],[TTUserId],[Personid]
,[NetworkName],[PreviousUserName],[PreviousDeliveryName],[PreviousNetworkName],[PreviousNetworkShortName]
FROM [BIDW].[Temporary].[JunNewUsers2019]
where PreviousUserName not in ('none')  and NetworkName not in ('Subscribe','7xASP','TTWEB')  
)T left join masteruser MU on PreviousUserName=mu.username or PreviousDeliveryName=mu.username
Left join chisql20.mess.dbo.users U on t.ttuserid=u.userid
where mu.MasterUserId is null

Insert into MasterUser
Select MasterUserId,Username,NetworkName,TTUserId,Personid from #NewMUUni
UNION
Select MasterUserId,PreviousUserName,NetworkName,TTUserId,Personid from #NewMUUni


----------Update already existing/ masterusers into Masteruser table for multibroker network to Other/same network username changes--------------
Insert into MasterUser
Select distinct isnull(mu.MasterUserId,newid()),t.Username,PreviousNetworkShortName,ttuserid,isnull(t.personid,0) as PersonId
--t.*,mu.masteruserid,u.alias
from (
SELECT [MasterUserId],[MasterAccountName],[Username],[Deliveryname],[TTUserId],[Personid]
,[NetworkName],[PreviousUserName],[PreviousDeliveryName],[PreviousNetworkName],[PreviousNetworkShortName]
FROM [BIDW].[Temporary].[JunNewUsers2019]
where PreviousUserName not in ('none')  and NetworkName in ('7xASP')  
)T left join masteruser MU on PreviousDeliveryName=mu.username or PreviousUserName=mu.username
Left join chisql20.mess.dbo.users U on t.ttuserid=u.userid


----------Temp query to load all TTWEB related & new users--------------
Insert into MasterUser
SELECT distinct isnull(mu1.MasterUserId,newid()) as MasterUserid,[PreviousUserName],[NetworkName],[TTUserId],J.[Personid]
FROM [BIDW].[Temporary].[JunNewUsers2019] J
left join masteruser MU on J.ttuserid=MU.UserId
left join masteruser MU1 on j.PreviousUserName=mu1.username or j.PreviousDeliveryName=mu1.username 
where NetworkName in ('ttweb')  and [PreviousNetworkShortName]='ttweb'
and mu.MasterUserId is null




----------Temp query to load all TTWEB related new users--------------
drop table #temp
Select distinct mu.MasterUserId,alias,isnull(NetworkName,'TTWEB') as NetworkName,ttuserid,t.personid,t.MasterUserId as OldMasterUserId
Into #Temp
from (
SELECT [MasterUserId],[MasterAccountName],[Username],[Deliveryname],[TTUserId],[Personid]
,[NetworkName],[PreviousUserName],[PreviousDeliveryName],[PreviousNetworkName],[PreviousNetworkShortName]
FROM [BIDW].[Temporary].[JunNewUsers2019]
where PreviousUserName not in ('none')  and NetworkName in ('TTWEB')  and [PreviousNetworkShortName]<>'TTWEB'
)T left join masteruser MU on t.PreviousUserName=mu.username or t.PreviousDeliveryName=mu.username 
Left join chisql20.mess.dbo.users U on t.ttuserid=u.userid
where mu.MasterUserId is not null 

-------Brand new TTWEB users associating to itself. So we create new users for them in Master User table---------------
Insert into MasterUser
select MasterUserid,alias,networkname,ttuserid,personid from #Temp
where ttuserid not in 
(select distinct userid from masteruser)

--------------------Existing TTWEB Users associated to old masteruserid. We merge these and associate the old masteruserid
--Insert into MasterUser

select * from #Temp
where MasterUserId is not null
and cast(MasterUserId as varchar(50))<>cast(OldMasterUserId as varchar(50))
and len(oldmasteruserid)=36
order by ttuserid

Update MasterUser
set MasterUserId='92B61DDD-989C-4431-B3A0-8B506AC5FC6A'
where MasterUserId='77567FD9-474D-4C9E-BCB3-6A8203D29A26'

-----------------------New TTWEB Associations to be loaded in Master User-------------------------
Insert into MasterUser
select MasterUserId,alias,NetworkName,TTUserId,personid from #Temp
where MasterUserId is not null
and cast(MasterUserId as varchar(50))<>cast(OldMasterUserId as varchar(50))
and len(oldmasteruserid)<>36


----------Add New masterusers into Masteruser table for TTWEB network to Other/same network username changes--------------
Insert into MasterUser
--Insert Into #Temp
Select newid() as MasterUserId,alias,isnull(NetworkName,'TTWEB') as NetworkName,ttuserid,t.personid
--t.*,mu.masteruserid,u.alias
from (
SELECT [MasterUserId],[MasterAccountName],[Username],[Deliveryname],[TTUserId],[Personid]
,[NetworkName],[PreviousUserName],[PreviousDeliveryName],[PreviousNetworkName],[PreviousNetworkShortName]
FROM [BIDW].[Temporary].[JunNewUsers2019]
where PreviousUserName not in ('none')  and NetworkName in ('TTWEB')  
)T left join masteruser MU on t.PreviousUserName=mu.username or t.PreviousDeliveryName=mu.username
Left join chisql20.mess.dbo.users U on t.ttuserid=u.userid
where mu.MasterUserId is null and NetworkName='TTWEB' and PreviousNetworkName='TTWEB'


--------------Insert new masteruserid for new Non -TTWEB users ----------------
Insert into MasterUser

SELECT  Newid() as MasterUserId,case when networkname='Subscribe' then deliveryname else username end as Username
,case when NetworkName='NULL' then 'Subscribe' else NetworkName end as Network,TTUserId,o.Personid
FROM [BIDW].[Temporary].[JunNewUsers2019] O
Left join chisql20.mess.dbo.users U on o.ttuserid=u.userid
where PreviousUserName in ('none') and NetworkName<>'TTWEB'


--------------Insert new masteruserid for new users TTWEB----------------
Insert into MasterUser
--Insert Into #Temp
Select distinct isnull(MU.MasterUserId,N.MasterUserId) as MasterUserid,alias,Network,ttuserid,N.PersonId from 
(
SELECT Newid() as MasterUserId,alias,case when NetworkName='NULL' then 'Subscribe' else NetworkName end as Network,TTUserId,o.Personid
FROM [BIDW].[Temporary].[JunNewUsers2019] O
Left join chisql20.mess.dbo.users U on o.ttuserid=u.userid 
where PreviousUserName in ('none') and NetworkName='TTWEB'
)N
left join MasterUser MU on N.alias=MU.username
where alias not in 
(
select distinct username from MasterUser
where username in 
(
Select distinct alias from 
(
SELECT Newid() as MasterUserId,alias,case when NetworkName='NULL' then 'Subscribe' else NetworkName end as Network,TTUserId,o.Personid
FROM [BIDW].[Temporary].[JunNewUsers2019] O
Left join chisql20.mess.dbo.users U on o.ttuserid=u.userid 
where PreviousUserName in ('none') and NetworkName='TTWEB'
)N
left join MasterUser MU on N.alias=MU.username
)
)



-----------------------------add remaining new users using this  Query for MBD MasterUser-------------
Insert into Masteruser
Select newid(),TTdescription,NetworkShortName,0,0 from MonthlyBillingDataAggregate_MasterUser
where year=2019 and month=6 and screens='screens'
and len(masteruserid)<>36 and CustGroup in ('MultiBrokr','Trnx SW')


Insert into Masteruser
Select isnull(MasterUserId,newid()) as MasterUserid,TTdescription,network,TTUserId,isnull(personid,0) from (
Select distinct TTdescription,'TTWEB' as network,TTUserId,u.personid,mu.MasterUserId from MonthlyBillingDataAggregate_MasterUser M
left join chisql20.mess.dbo.users U on m.TTUserId=u.userid
left join MasterUser mu on m.TTdescription=mu.username or m.ttuserid=mu.userid
where year=2019 and month=6 and screens='screens'
and len(m.masteruserid)<>36 and CustGroup not in ('MultiBrokr','Trnx SW') and TTUserId<>''
)p


-----------------------Remove duplicate records in masteruser---------------------------
Select distinct * into #TempMU from MasterUser

--Delete MasterUser
--insert into MasterUser
--select * from #TempMU


-----------------------------------Add remaining userid's to Masteruserid' for all new personid's added--------------------

insert into masteruser
Select * from (
select Masteruserid,alias,'TTWEB' as networtshortname,userid,p.personid from (
select distinct Userid,alias,personid from chisql20.mess.dbo.users
where userid<>0 and personid<>0 and companyid<>63
and personid in 
(select distinct personid from masteruser)
)p
left join 
(
Select distinct personid,masteruserid from masteruser
where personid<>0
)mu on p.personid=mu.personid

except 

Select * from MasterUser
)h
where userid not in 
(select distinct userid from MasterUser)
order by personid


----------Test query----
select * from MonthlyBillingDataAggregate_MasterUser 
where year=2019 and month=6 and screens='screens'
and len(masteruserid)<>36 and TTUserId<>''




--------------------Queries to check quality of the data------

Select userid,count(distinct masteruserid) from masteruser
group by userid
having count(distinct masteruserid)>1
order by 2 desc

Select username,count(distinct cast(masteruserid as char(50))+cast(personid as varchar(20))) from masteruser
where username not like '%Asingh%' and NetworkShortName='TTWEB'
group by username
having count(distinct cast(masteruserid as char(50))+cast(personid as varchar(20)))>1
order by 2 desc

Select username,count(distinct masteruserid) from masteruser
where username not like '%Asingh%' and NetworkShortName<>'TTWEB'
group by username
having count(distinct masteruserid)>1
order by 2 desc

select personid,count(distinct masteruserid) from MasterUser
group by personid
having count(distinct masteruserid)>1
order by 2 desc