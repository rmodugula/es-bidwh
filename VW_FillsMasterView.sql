USE [BIDW]
GO

/****** Object:  View [dbo].[VW_FillsMasterView]    Script Date: 10/22/2015 10:58:38 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER VIEW [dbo].[VW_FillsMasterView] 
as
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
end as [MonthName],Enddate as MonthDate,DayofMonth
,F.UserName,U.FullName,ExchangeName,E.ExchangeFlavor
,NetworkName,MarketName,A.MasterAccountName,A.AccountName,U.City,U.PostalCode,U.CountryCode,P.ProductName as AXProductName
,ProductType,F.ProductName,FillType,FillStatus,Contracts as Contracts,Fills as Fills,FixAdapterName,OpenClose
,OrderFlags,LastOrderSource,FirstOrderSource,OrderSourceHistory,FillCategoryId
,TransactionDate,BillingServerDate,IsBillable,MDT,FunctionalityArea,CustomField1,CustomField2,CustomField3
 from dbo.Fills F
left join dbo.Exchange E on F.ExchangeId=E.ExchangeId
left join dbo.Account A on F.AccountId=A.Accountid
left join dbo.Product P on F.AxProductId=P.ProductSku
left join dbo.Network N on F.NetworkId=N.NetworkId
left join dbo.Market M on F.MarketId=M.MarketID
left join (select Year, Month,Username,FullName,Accountid,CountryCode,City,PostalCode,Platform,CustomField1,CustomField2,CustomField3 from dbo.[user] 
--where YEAR=YEAR(getdate()) and MONTH=Month(getdate())
) U 
on F.UserName=U.UserName and F.AccountId=U.AccountId and f.Year=u.Year and f.Month=u.Month and f.platform=u.platform
left join TimeInterval T
on f.Year=t.Year and f.Month=t.Month
--where F.Year=2013 and F.Month=12
























GO


