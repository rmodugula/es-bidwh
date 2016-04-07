USE [BIDW]
GO

/****** Object:  View [dbo].[VW_TTFills_MetricTrends]    Script Date: 4/7/2016 11:07:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO











ALTER VIEW [dbo].[VW_TTFills_MetricTrends] 
as
select Year,Month,Day(TransactionDate) as Day,TransactionDate,F.MarketId,MarketName,c.Name as CompanyName,sum(contracts) as Contracts,sum(Volume) as Fills from Chisql12.BIDW.dbo.fills F
Left join [BIDW].[dbo].[Market] M
on f.MarketId=m.MarketID and f.platform=m.platform
Left join chisql20.[MESS].[dbo].[Companies] c on f.CompanyId=c.companyid
where f.platform='TTWEB'
--and year=2015 and month=10 
Group By Year,Month,Day(TransactionDate),TransactionDate,F.MarketId,MarketName,c.Name











GO


