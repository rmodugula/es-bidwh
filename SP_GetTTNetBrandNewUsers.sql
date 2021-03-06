USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetTTNetBrandNewUsers]    Script Date: 8/4/2014 2:58:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[GetTTNetBrandNewUsers]
(@year int, @Month int)
     
     
AS
BEGIN

Declare @CurrentMonthdate Date
Set @CurrentMonthdate = DATEFROMPARTS(@year, @Month, 1)

select distinct B.UserName,B.FullName,B.AccountId,A.Accountname
from
(
select Q.* from 
(
select distinct f.UserName,f.AccountId,u.FullName,f.IsBillable from Fills F
left outer join dbo.[User] U on F.UserName=U.UserName and f.Year=u.Year and f.Month=u.Month and f.AccountId=u.AccountId
where f.YEAR=@year and f.MONTH=@month
) Q
where q.username not in 
(
select distinct UserName from Fills F join TimeInterval T on F.Year=t.Year and f.Month=t.Month
where cast(enddate as date)<@CurrentMonthdate --<Ram 8/4/2014> Improved Performance by tweaking the filter
--FillId< (select MIN(fillid) from Fills where YEAR=@year and MONTH=@month)
)
)B join dbo.Account A
on B.AccountId=A.accountid

end




