USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_NewTTNetUsers]    Script Date: 03/07/2014 13:13:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_NewTTNetUsers](@month char(10), @year int)
     
     
AS
BEGIN

select B.UserName,B.FullName,B.AccountId,A.Accountname
from
(
select Q.* from 
(
select distinct f.UserName,f.AccountId,u.FullName,f.IsBillable from Fills F
left outer join dbo.[User] U on F.UserName=U.UserName and f.Year=u.Year and f.Month=u.Month and f.AccountId=u.AccountId
where f.IsBillable='Y' and f.YEAR=@year and f.MONTH=
(case @month
when 'Jan' then 1
when 'Feb' then 2
when 'Mar' then 3
when 'Apr' then 4
when 'May' then 5
when 'Jun' then 6
when 'Jul' then 7
when 'Aug' then 8
when 'Sep' then 9
when 'Oct' then 10
when 'Nov' then 11
when 'Dec' then 12
end)
) Q
where q.username not in (select distinct UserName from Fills 
where FillId<
(select MIN(fillid) from Fills
where YEAR=@year and MONTH=(case @month
when 'Jan' then 1
when 'Feb' then 2
when 'Mar' then 3
when 'Apr' then 4
when 'May' then 5
when 'Jun' then 6
when 'Jul' then 7
when 'Aug' then 8
when 'Sep' then 9
when 'Oct' then 10
when 'Nov' then 11
when 'Dec' then 12
end)))
)B join dbo.Account A
on B.AccountId=A.accountid

end



