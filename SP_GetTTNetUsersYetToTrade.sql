USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetTTNetUsersYetToTrade]    Script Date: 04/03/2014 09:43:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[GetTTNetUsersYetToTrade]
(@year int, @month int)
     
    
AS
Declare @PriorMonth int, @PriorYear int
Set @PriorYear= case when @month=1 then @year-1 else @year end
Set @PriorMonth = case when @Month=1 then 12 else @Month-1 end 

BEGIN

select distinct Q.UserName,AccountId,MasterAccountName from
(
select distinct Username from Fills
where YEAR=@PriorYear and MONTH=@PriorMonth and UserName <>''
and UserName not in 
(select distinct UserName from Fills
where YEAR=@year and MONTH=@month and UserName <>'')
)Q
left join
(
select distinct Username, U.Accountid,MasterAccountName from [User] U
left join Account A 
on U.AccountId=A.Accountid
where YEAR=@year and MONTH=@month

and U.AccountId<>''
)S
on q.UserName=s.UserName
order by 1


end




