USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetTTNetNewUserstoBillingAccount]    Script Date: 8/4/2014 2:42:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[GetTTNetNewUserstoBillingAccount](@month char(10), @year int)
     
     
AS
BEGIN

Declare @CurrentMonthdate Date
Declare @MonthName Char(3)
Set @MonthName= case @month
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
end
Set @CurrentMonthdate = DATEFROMPARTS(@year, @MonthName, 1)
Select Y.*,Z.ProductName from
(
SELECT distinct B.UserName,FullName,B.AccountId, AccountName FROM 
(
select distinct UserName,AccountId from Fills
--where YEAR=2014 and MONTH=1
where YEAR=@year and MONTH=@MonthName
and IsBillable='Y'

EXCEPT

select distinct UserName,AccountId from Fills F join TimeInterval T on F.Year=t.Year and f.Month=t.Month
where cast(enddate as date)<@CurrentMonthdate --<Ram 8/4/2014> Improved Performance by tweaking the filter
--FillId<
--(select MIN(fillid) from Fills
----where YEAR=2014 and MONTH=1
--where YEAR=@year and MONTH=@MonthName
--)
--and IsBillable='Y'
)B left join Account A
on B.AccountId=A.Accountid
left outer join (select * from dbo.[User] where YEAR=@year and MONTH=@MonthName) U on B.UserName=U.UserName and B.AccountId=U.AccountId
)Y
left join
(
select distinct username,AccountId,p.ProductName from Fills F
left join Product P
on f.AxProductId=P.ProductSku
where YEAR=@year and MONTH=@MonthName and IsBillable='Y'
)Z
on y.UserName=z.UserName and y.AccountId=z.AccountId
order by 1,2


end




