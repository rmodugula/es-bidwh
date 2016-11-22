USE [BIDW]
GO

/****** Object:  View [dbo].[VW_TransactionsMatrixSummary]    Script Date: 11/22/2016 4:09:30 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO








ALTER VIEW [dbo].[VW_TransactionsMatrixSummary] 
as

select Year,Month,MonthName,TransactionDate,cast(case when platform<>'TTWEB' then Username else cast(Userid as char) END as char) as UserName,FullName,case when ExchangeName='CBOT' then 'CME' else ExchangeName end as ExchangeName,ExchangeFlavor,NetworkName
,case when MarketName='CBOT' then 'CME' else MarketName end as MarketName,case when platform='TTWEB' then isnull(MasterAccountName,companyname) else MasterAccountName end as CompanyName
,case when platform='TTWEB' then isnull(AccountName,companyname) else AccountName end as AccountName,
CountryCode,AXProductName,
SUM(fills) as Fills,sum(Contracts) as Contracts,FixAdapterName
,IsBillable,MDT,FunctionalityArea,Region,[Platform],case when platform ='TTWEB' then usercompany else accountname end as UserCompany
from 
(
select 
F.Year,F.Month, 
case F.Month 
when 1 then 'Jan'
when 2 then 'Feb'
when 3 then 'Mar'
when 4 then 'Apr'
when 5 then 'May'
when 6 then 'Jun'
when 7 then 'Jul'
when 8 then 'Aug'
when 9 then 'Sep'
when 10 then 'Oct'
when 11 then 'Nov'
when 12 then 'Dec'
end as [MonthName]
,F.UserName,U.FullName,F.UserId,TransactionDate,case when f.[platform]<>'TTWEB' and MarketName='KCG' then 'LSE' else MarketName End as ExchangeName,E.ExchangeFlavor
,NetworkName,MarketName,f.AccountId,A.MasterAccountName,A.AccountName,U.CountryCode,P.ProductName as AXProductName
,ProductType,F.ProductName,FillType,FillStatus,Fills as Fills,Contracts,FixAdapterName,OpenClose
,OrderFlags,LastOrderSource,FirstOrderSource,OrderSourceHistory,FillCategoryId
,IsBillable,MDT,FunctionalityArea,CustomField1,CustomField2,CustomField3,region,f.[Platform],case when f.platform='TTWEB' then tc.companyname else c.CompanyName end as CompanyName
,NetworkLocation,Uc.companyname as UserCompany
 from (select * from dbo.Fills) F
left join dbo.Exchange E on F.ExchangeId=E.ExchangeId
left join dbo.Account A on F.AccountId=A.Accountid
left join dbo.Product P on F.AxProductId=P.ProductSku
left join dbo.Network N on F.NetworkId=N.NetworkId
Left join [BIDW].[dbo].[Market] M
on f.MarketId=m.MarketID and f.platform=m.platform
left join (
select * from 
(
select distinct year, Month, Username,UserId,FullName,Accountid,CountryCode,Platform,CustomField1,CustomField2,CustomField3
,row_number() over (partition by year, Month, Username,UserId,FullName,CountryCode,Accountid,Platform order by CustomField1 desc,CustomField2 desc,CustomField3 desc) as rowfilter 
from dbo.[user]
)uf
where rowfilter=1
) U 
on f.year=u.year and f.Month=u.Month and F.UserName=U.UserName and F.AccountId=U.AccountId and f.Platform=u.platform
left join 
(select distinct Country, Region from RegionMap)R
on u.CountryCode=r.Country
Left join (select distinct companyId, companyname from Company) C on f.CompanyId=c.CompanyId
left join ( select distinct companyId, companyname from dbo.ttcompanies) TC on f.CompanyId=tc.companyid
Left join (select U.*,Name as CompanyName from chisql20.mess.dbo.users U 
  left join chisql20.Mess.[dbo].[Companies] C on u.companyid=c.companyid) UC on f.userid=uc.userid
)Q
 --where AccountId<>'C100271'
--where YEAR=2014 and month=8
group by Year, Month, MonthName,ExchangeName,ExchangeFlavor, NetworkName, MarketName, MasterAccountName, AccountName,
CountryCode, AXProductName,FixAdapterName,IsBillable, MDT,Region, FunctionalityArea,[Platform],CompanyName,UserId,UserName,FullName,TransactionDate,usercompany



































GO


