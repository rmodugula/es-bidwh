USE [BIDW]
GO

/****** Object:  View [dbo].[VW_TransactionsMatrixTrending]    Script Date: 9/19/2014 11:38:06 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






ALTER VIEW [dbo].[VW_TransactionsMatrixTrending] 
as

select Year,Month,MonthName,count(UserName) as NumberOfTraders,case when ExchangeName='CBOT' then 'CME' else ExchangeName end as ExchangeName,ExchangeFlavor,NetworkName,MarketName,MasterAccountName,AccountName,
CountryCode,AXProductName,
--ProductType,ProductName,FillType,FillStatus
SUM(fills) as Fills,sum(Contracts) as Contracts,FixAdapterName,OpenClose,OrderFlags,LastOrderSource,
FirstOrderSource,OrderSourceHistory,FillCategoryId,IsBillable,MDT,FunctionalityArea,Region
--,CustomField1,CustomField2,CustomField3 
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
,F.UserName,U.FullName,ExchangeName,E.ExchangeFlavor
,NetworkName,MarketName,A.MasterAccountName,A.AccountName,U.CountryCode,P.ProductName as AXProductName
,ProductType,F.ProductName,FillType,FillStatus,Fills as Fills,Contracts,FixAdapterName,OpenClose
,OrderFlags,LastOrderSource,FirstOrderSource,OrderSourceHistory,FillCategoryId
,IsBillable,MDT,FunctionalityArea,CustomField1,CustomField2,CustomField3,region
 from (select * from dbo.Fills where AccountId<>'C100271') F
left join dbo.Exchange E on F.ExchangeId=E.ExchangeId
left join dbo.Account A on F.AccountId=A.Accountid
left join dbo.Product P on F.AxProductId=P.ProductSku
left join dbo.Network N on F.NetworkId=N.NetworkId
left join dbo.Market M on F.MarketId=M.MarketID
left join (select Username,FullName,Accountid,CountryCode,CustomField1,CustomField2,CustomField3 from dbo.[user] where YEAR=YEAR(getdate()) and MONTH=Month(getdate())) U on F.UserName=U.UserName and F.AccountId=U.AccountId
left join 
(select distinct Country, Region from RegionMap)R
on u.CountryCode=r.Country
)Q
--where YEAR=2014
group by Year, Month, MonthName,ExchangeName,ExchangeFlavor, NetworkName, MarketName, MasterAccountName, AccountName,
CountryCode, AXProductName,FixAdapterName, OpenClose, OrderFlags, 
--ProductType, ProductName, FillType, FillStatus
LastOrderSource, FirstOrderSource, OrderSourceHistory, FillCategoryId, IsBillable, MDT,Region, FunctionalityArea
--, CustomField1, CustomField2, CustomField3






GO


