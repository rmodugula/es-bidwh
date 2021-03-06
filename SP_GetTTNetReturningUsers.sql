USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetTTNetReturningUsers]    Script Date: 04/03/2014 09:42:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[GetTTNetReturningUsers]
(@year int, @Month int)
          
AS
Declare @PriorMonthDate smalldatetime,@PriorMonth int, @PriorYear int, @D int, @Y int
Set @PriorYear= case when @month=1 then @year-1 else @year end
Set @PriorMonth = case when @Month=1 then 12 else @Month-1 end 
Set @D = MONTH(@priormonth)
Set @Y= YEAR(@priormonth)
Set @PriorMonthDate = CONVERT(varchar,@PriorMonth) + '/1/' + CONVERT(varchar,@PriorYear)
BEGIN

select distinct Q.UserName,AccountId,MasterAccountName from
(
select * from
(
select distinct UserName from Fills F left join TimeInterval T
on F.Year=t.Year and f.Month=t.Month
where EndDate<@PriorMonthDate 
and UserName in (select distinct UserName from Fills 
where UserName <>'' and YEAR=@year and MONTH=@Month)
)q
where UserName not in (select distinct UserName from Fills
where YEAR=@PriorYear and MONTH=@PriorMonth and UserName <>'')
) Q
left join
(
select distinct Username, U.Accountid,MasterAccountName from [User] U
left join Account A 
on U.AccountId=A.Accountid
where YEAR=@year and MONTH=@Month
and U.AccountId<>''
)S
on q.UserName=s.UserName
order by 1

end



