USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_Load_TNTUserLoginData]    Script Date: 9/12/2014 9:58:26 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[SP_Load_TNTUserLoginData]
  
AS
BEGIN

Delete TNTUserLogins
where year=year(getdate()) and month=month(getdate())
Insert into TNTUserLogins
Select Year([Mostrecentlogin]) as Year, Month([Mostrecentlogin]) as Month,
Username, DisplayName, UserGroup, Status, Email, Phone, MostrecentXTDate, 
MostrecentXTIP, MostrecentXTversion, Mostrecentlogin, LogindatemorerecentthanXTdate,
Getdate() as LastUpdatedDate
from bidw_ods.[dbo].[TNTData_ODS]
where Year([Mostrecentlogin])=year(getdate()) and Month([Mostrecentlogin])=month(getdate())
Order by [Mostrecentlogin] asc

End




