USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetNewUserstoBillingAccount]    Script Date: 02/21/2014 15:30:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[GetNewUserstoBillingAccount](@month char(10), @year int)
     
     
AS
BEGIN

SELECT B.UserName,FullName,B.AccountId, AccountName FROM 
(
select distinct UserName,AccountId from Fills
--where YEAR=2014 and MONTH=1
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
end)
and IsBillable='Y'

EXCEPT

select distinct UserName,AccountId from Fills 
where FillId<
(select MIN(fillid) from Fills
--where YEAR=2014 and MONTH=1
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
end)
)
--and IsBillable='Y'
)B left join Account A
on B.AccountId=A.Accountid
left outer join (select * from dbo.[User] where YEAR=@year and MONTH=(case @month
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
end)) U on B.UserName=U.UserName and B.AccountId=U.AccountId
order by 1,2



end



