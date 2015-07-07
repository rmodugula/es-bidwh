USE [BIDW]
GO

/****** Object:  View [dbo].[VW_RevenueImpactSSO]    Script Date: 01/22/2014 13:24:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER VIEW [dbo].[VW_RevenueImpactSSO] 
as
select Year, Month, MonthName, Accountid, AccountName, DeliveryName, ChangeInPrice, UpgradeRevenue as Upgrades, DownGradeRevenue as Downgrades,
 AddRevenue as Adds, CancelRevenue as Cancels, NetRevenue as TotalChange, 
PriorMonthRevenue as BaselineRevenue, CurrentRevenue as TargetRevenue,PriceGroup, PriceGroupDesc, CusttomerGroup, TTConversionDate, 
SalesOffice, SalesRegion
from dbo.RevenueImpactReporting
where SalesOffice = (select salesoffice from staff
where username=(select replace(suser_sname(),'INTAD\','')))
-- and YEAR=2013 and MONTH=11




GO


