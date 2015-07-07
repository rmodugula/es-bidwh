USE [BIDW]
GO

/****** Object:  View [dbo].[VW_ScreensImpactSSO]    Script Date: 01/22/2014 13:25:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER VIEW [dbo].[VW_ScreensImpactSSO] 
as
select Year, Month, MonthName, Accountid, AccountName, DeliveryName, UpgradeCount as Upgrades, DowngradeCount as Downgrades, AddCount as Adds, 
CancelCount as Cancels, NetCount as TotalChange, 
PriorMonthLicenseCount as BaselineCount, CurrentLicenseCount as TargetCount, PriceGroup, PriceGroupDesc, CusttomerGroup, TTConversionDate, 
SalesOffice, SalesRegion
from dbo.RevenueImpactReporting
where SalesOffice = (select salesoffice from staff
where username=(select replace(suser_sname(),'INTAD\','')))
--and YEAR=2013 and MONTH=11




GO


