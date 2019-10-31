/****** Script for SelectTopNRows command from SSMS  ******/
SELECT distinct  b.[UserId]
      ,b.UserName,mu.MasterUserId as Mu1,mu1.MasterUserId as Mu2
	  --Into #ft
  FROM #data B
  left join Masteruser Mu on B.userid=mu.userid
  left join Masteruser Mu1 on B.Username=mu1.username
  where isnull(cast(mu.MasterUserId as varchar(36)),'-')=isnull(cast(mu1.MasterUserId as varchar(36)),'-')
  order by 3

  Drop table #Data
  SELECT  [UserId],[XTraderUserName]
	  ,case when [XTraderUserName] like '%(%' 
	  then ltrim(rtrim(substring([XTraderUserName],1,abs(charindex('(',[XTraderUserName])-1)))) 
	  else [XTraderUserName] End as UserName
	  --Into #Data
  FROM chisql20.[PromoCodes].[dbo].[BillingUserPromo]
  where startdate ='2019-09-01 00:00:00.0000000 +00:00'
  and XTraderUserName is not null


  Select * from #ft
  where mu1 is not null
  order by 3

  Insert into masteruser
    Select mu2,alias,'TTWEB',f.userid,personid from #ft f
	left join chisql20.mess.dbo.users u on f.userid=u.userid
  where mu1 is null
  order by 3




  exec GetMasterUser '48600'
    exec GetMasterUser 'MQS_TRADER2'


	Update MasterUser
	set MasterUserId='AFAB3AC2-EF96-4F57-8AA3-DE21647F4290'
	where MasterUserId='0F488351-B6F4-4F2B-B11C-DFE007AB58ED'

insert into MasterUser
select '13562D23-404C-4DE0-B359-0E48FC55A367','FCJHUNT','7xASP',0,0


select * from chisql20.mess.dbo.users
where userid=48600