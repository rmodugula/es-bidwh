/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.2218)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2017
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/

USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetTTNETUsersNotTradedPriorMonth_DOMO]    Script Date: 7/9/2018 10:52:59 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[GetTTNETUsersNotTradedPriorMonth_DOMO]

     
AS

Declare @Year int, @Month int, @Date date, @Enddate date

SET @Year=year(getdate())
SET @Month=month(getdate())
SET @Date = (Select Startdate from Timeinterval where year=@Year and month=@Month)
SET @Enddate = dateadd(mm,-7,getdate())

Create Table #Final
(Year int, Month int, Networkid int, NetworkShortName varchar(10),NetworkName varchar(100),MasterAccountName varchar(100)
,AccountId varchar(100),UserCompany varchar(100),Username varchar(100),FillCategory varchar(50),FullName varchar(100)
,Email varchar(200),Phone varchar(100),CountryName varchar(100),CountryCode char(10),State varchar(100),City varchar(100),PostalCode varchar(100)
,BrokerName varchar(100),UserLastTradedYearMonth varchar(50),UserLastTradedDate date,MonthsTradedInLast12Months int)


While @Enddate<=@date

BEGIN

SET NOCOUNT ON;
Create Table #Users
(Networkid int, NetworkShortName varchar(10),NetworkName varchar(100),MasterAccountName varchar(100),AccountId varchar(100),UserCompany varchar(100),Username varchar(100),FillCategory varchar(50)
,FullName varchar(100),Email varchar(200),Phone varchar(100),CountryName varchar(100),CountryCode char(10),State varchar(100),City varchar(100),PostalCode varchar(100),Brokername varchar(100))

Insert Into #Users
Select x.NetworkId,x.NetworkShortName,NetworkName,MasterAccountName,x.AccountId,isnull(UserCompany,MasterAccountName) as UserCompany,x.Username,FillCategory
,case when networkname='TTWEB' then FullName else isnull(Deliveryname,'') END as FullName,isnull(Email,'') as Email
,isnull(Phone,'') as Phone,CountryName,CountryCode,case when CountryCode<>'US' then 'Unassigned' when state='' then 'Unassigned' else ltrim(rtrim(isnull(nullif(State,'<None>'),''))) END as State,isnull(City,'') as City
,isnull(PostalCode,'') as PostalCode,BrokerName 
 from 
(
SELECT  Q.NetworkId,NetworkShortName,NetworkName,case when networkname='TTWEB' then isnull(MasterAccountName,d.CompanyName) else MasterAccountName End as MasterAccountName
,fc.AccountId,case when q.networkid=1 then ltrim(rtrim(replace(replace(d.CompanyName,'(Managed)',''),'(managed)',''))) else c.CompanyName END as UserCompany,fc.Username,FillCategory,isnull(br.CompanyName,MasterAccountName) as BrokerName
FROM 
(
SELECT DISTINCT Networkid,Companyid,isnull(cast(MasterUserId as varchar(50)),f.username) as MasterUserId FROM [bidw].[dbo].fills F
left join MasterUser M on f.username=m.UserName
WHERE year = @Year AND month = @Month and isbillable='Y'
EXCEPT
SELECT DISTINCT Networkid,Companyid,isnull(cast(MasterUserId as varchar(50)),f.username) as MasterUserId FROM [bidw].[dbo].fills F
left join MasterUser M on f.username=m.UserName
WHERE year =
            CASE
              WHEN @Month = 1 THEN @Year - 1
              ELSE @Year
            END
AND month =
           CASE
             WHEN @Month = 1 THEN 12
             ELSE @Month - 1
           END
and isbillable='Y'
)Q
left Join Network N on q.NetworkId=n.NetworkId
left join (Select * from Company where companyid<>0) C on Q.companyid=c.companyid and q.networkid=c.networkid
left join (Select * from ttCompanies) D on Q.companyid=d.companyid 
Left join (Select * from Company where companyid<>0) br on Q.CompanyId=br.companyid and q.networkid=br.networkid
left join 
(
select distinct Networkid,MasterAccountName,f.Accountid,CompanyId,isnull(cast(MasterUserId as varchar(50)),f.username) as MasterUserId,f.Username
,Description as FillCategory from fills F
left join [fillhub].[dbo].[FillCategory] FC on F.FillCategoryId=fc.FillCategoryId
left join MasterUser M on f.username=m.UserName
left join Account A on f.AccountId=A.Accountid
where year=@Year and month=@Month and IsBillable='Y' 
)Fc on Q.networkid=fc.NetworkId and Q.CompanyId=fc.CompanyId and q.MasterUserId=fc.MasterUserId
)X

Left join 
(
	Select * from
	(
	select distinct NetworkshortName,Username,case when UserGroup='<General>' then Customer else UserGroup END as UserGroup, DeliveryName, Email,Phone,row_number() over (partition by username order by email desc) as Row from Lastlogin  where year=@Year and month=@Month
	)Q where row=1
) L
on x.NetworkshortName=l.networkshortname and x.username=l.username
left join 
(
select distinct UserName,FullName,Accountid,NetworkId,CountryCode,CountryName,State,City,PostalCode from [user] u
left join 
(SELECT Distinct [Country],[CountryName]
FROM [BIDW].[dbo].[RegionMap]) R
on u.countrycode=r.Country
where year=@Year and month=@Month
) U
on x.username=u.username and x.accountid=u.accountid and x.networkid=u.NetworkId


Insert Into #Final
Select Final.*,MonthsTradedInLast12Months from
(
Select @Year as Year, @Month as Month, U.*,isnull(rtrim(cast(TransactionDate as varchar(20))),'FirstTrade') as UserLastTradedYearMonth,TransactionDate as UserLastTradedDate from #Users U
left join 
(
Select Cast(year as varchar)+'-'+cast(month as varchar) as YearMonth,TransactionDate, Username from
(
select distinct Year,Month,TransactionDate,Username,row_number() over (partition by username order by year desc, month desc,TransactionDate desc) as row from fills
where isbillable='Y' and cast(cast(year as varchar)+(case when len(month)=1 then '0'+cast(month as varchar) else cast(month as varchar) end) as int)<
cast(cast(@Year as varchar)+(case when len(@Month)=1 then '0'+cast(@Month as varchar) else cast(@Month as varchar) end) as int)
and cast(networkid as varchar)+cast(accountid as varchar)+'-'+username in 
(
Select distinct cast(networkid as varchar)+cast(accountid as varchar)+'-'+username
from
(
Select * from #Users
)Q
)
)X
where row=1
) L
on U.username=l.username
)Final
left join
(
Select Networkid,AccountId,Username,count(distinct cast(cast(Month as char(2))+'-01-'+cast(Year as char(4)) as date)) as MonthsTradedInLast12Months
from Fills
where cast(cast(month as char(2))+'-01-'+cast(Year as char(4)) as date)>=dateadd(m,-12,cast(cast(@Month as char(2))+'-01-'+cast(@Year as char(4)) as date))
and cast(cast(month as char(2))+'-01-'+cast(Year as char(4)) as date)<cast(cast(@Month as char(2))+'-01-'+cast(@Year as char(4)) as date)
and IsBillable='Y'
group by Networkid,AccountId,Username
)M
on final.Networkid=M.NetworkId and final.AccountId=M.AccountId and final.Username=M.UserName

Drop table #Users

Set @Year= case when @month =1 then @Year-1 else @Year End
Set @Month = case when @Month=1 then 12 else @Month-1 End 
Set @Date = (Select Startdate from Timeinterval where year=case when @month =1 then @Year-1 else @Year End and month=case when @Month=1 then 12 else @Month-1 End )


END

Select Distinct cast(cast(month as char(2))+'-'+'01'+'-'+cast(year as char(4)) as date) as Date,F.*,U.ContactId,isnull(U.CrmContactUrl,'') as CrmContactUrl
,isnull(U.FullName,'') as ContactName,lower(isnull(a.CrmId,ac.crmid)) as CrmId,SalesOffice,Region,UserGroup from #Final F
Left Join 
(SELECT distinct [tt_contactlookup] as ContactId,[tt_contactlookupname] as FullName,[tt_name] as Username,NetworkName
,tt_network as Networkshortname
, 'https://tradingtechnologies.crm.dynamics.com/main.aspx?etn=contact&pagetype=entityrecord&id={'+cast([tt_contactlookup] as varchar(100))+'}' as CrmContactUrl
FROM [CRMOnlineBI].[dbo].[7xUsers] x
Left join (Select distinct NetworkName,NetworkShortName from chisql12.BIDW.dbo.Network where NetworkLocation='TTNET') N on ltrim(x.tt_network)=ltrim(n.networkshortname)
)U 
on F.NetworkShortName=U.Networkshortname and F.Username=u.Username
Left Join 
( SELECT distinct CompanyName,[CrmId]
                FROM [BIDW].[dbo].[Company] where crmid is not null
				UNION
				SELECT distinct CompanyName,[CrmId]
                FROM [BIDW].[dbo].[TTCompanies] where crmid is not null) A
on F.UserCompany=A.CompanyName
left join (select distinct Accountid,crmid from Account where Accountid not like 'LGCY%')AC
on f.AccountId=Ac.Accountid
left join 
(
select * from 
(
select *,row_number() over (partition by state,country,region order by salesoffice ) as rowid from
(
select distinct case when country<>'US' then 'Unassigned' else state end as State,Country,salesoffice,Region 
from MonthlyBillingDataAggregate
where ProductName like '%Transaction%' and SalesOffice is not null
and year=year(getdate()) and BilledAmount>0
)r)y where rowid=1
)SO
on f.State=so.State and f.CountryCode=so.Country
left join
(
select * from 
(
select distinct UserName,UserGroup,row_number() over (partition by UserName order by usergroup) as rowid from 
(
Select Distinct UserName,replace(replace(UserGroup,'(Managed)',''),'(managed)','')  as UserGroup from
(
select distinct UserGroup,UserName from lastlogin 
)w
)Y 
)t where rowid=1 
)UG on f.Username=ug.UserName
where f.Username is not null and f.username<>'' and f.username<>'0'