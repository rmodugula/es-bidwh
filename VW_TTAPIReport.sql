USE [BIDW]
GO

/****** Object:  View [dbo].[VW_TTAPIReport]    Script Date: 12/17/2013 16:07:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[VW_TTAPIReport] 
as
SELECT distinct Name as NetworkName,shortname as NetworkShortName,case when NetworkName like 'Alaron%' then 'Alaron Trading' else A.MasterAccountName end as MasterCustomer ,LF.AccountId,BillingAccountid,[TTAPIEnabled]
FROM fillhublink.[fillhub].[dbo].[LicenseFile] LF left join 
(select accountid,accountname,masteraccountname,crmid from Account) A
on LF.accountid=A.CrmId
where isActive = 1 and licensefileid <> 0



GO


