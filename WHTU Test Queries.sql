/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [WhatHappenedtoUser],sum(billedamount),sum(licensecount),sum([TargetBilledAmount]),sum([TargetLicenseCount])
  FROM [dbo].[GetWhatHappenedtoScreens&User_test]
  where TargetTimePeriod='2019-04-01' and BaseTimePeriod='2019-03-01'
  Group by  [WhatHappenedtoUser]


  /****** Script for SelectTopNRows command from SSMS  ******/
SELECT [WhatHappenedtoUser],sum(billedamount),sum(licensecount),sum([TargetBilledAmount]),sum([TargetLicenseCount])
  FROM [dbo].[GetWhatHappenedtoScreens&User]
  where TargetTimePeriod='2019-04-01' and BaseTimePeriod='2019-03-01'
  Group by  [WhatHappenedtoUser]

SELECT *
  FROM [dbo].[GetWhatHappenedtoScreens&User_test]
  where TargetTimePeriod='2019-04-01' and BaseTimePeriod='2019-03-01'



  /****** Script for SelectTopNRows command from SSMS  ******/
SELECT sum(billedamount),sum(licensecount),sum([TargetBilledAmount]),sum([TargetLicenseCount])
  FROM [Reporting].[WHatHappenedtoScreens]
  where TargetTimePeriod='2019-04-01' and BaseTimePeriod='2019-03-01'
