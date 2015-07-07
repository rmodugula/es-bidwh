USE [BIDW]
GO

/****** Object:  View [dbo].[VW_RevenueImpactReportingSummary]    Script Date: 03/11/2014 11:46:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER VIEW [dbo].[VW_RevenueImpactReportingSummary] 
as
select Year, Month, MonthName, Accountid, AccountName, PriceGroup, PriceGroupDesc, 
CusttomerGroup,SalesOffice, SalesRegion, BillingEndDate, sum(RevenueChange) as RevenueChange , 
RevenueChangeType, sum(NetRevenue) as NetRevenue, sum(PriorMonthRevenue) as PriorMonthRevenue, sum(CurrentRevenue) as CurrentRevenue, 
sum(CountChange) as CountChange, CountsChangeType, sum(NetCount) as NetCount, sum(PriorMonthLicenseCount) as PriorMonthLicenseCount, 
sum(CurrentLicenseCount) as CurrentLicenseCount
from dbo.VW_RevenueImpactReporting
--where YEAR=2013 and MONTH=11
group by Year, Month, MonthName, Accountid, AccountName, PriceGroup, PriceGroupDesc, 
CusttomerGroup,SalesOffice, SalesRegion, BillingEndDate,RevenueChangeType,CountsChangeType



GO


