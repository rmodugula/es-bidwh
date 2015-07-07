USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_FillsByUsersNotLoggedCurrentMonth]    Script Date: 10/29/2013 16:29:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_FillsByUsersNotLoggedCurrentMonth]

     
AS
BEGIN

select Year,Month,UserName,E.ExchangeName,NetworkId,AxProductId,SUM(fills)as Fills from Fills F join Exchange E
on F.ExchangeId=E.ExchangeId
where UserName not in 
(
select UserName from dbo.LastLogin 
where YEAR(lastlogindate)=YEAR(getdate()) and MONTH(lastlogindate)=MONTH(getdate())
union 
select distinct [LOGIN] as UserName from fillhublink.fillhub.dbo.UserLogin
where YEAR(lastlogin)=YEAR(getdate()) and MONTH(lastlogin)=MONTH(getdate())
)
--(select UserName from dbo.LastLogin where YEAR(lastlogindate)=YEAR(getdate()) 
--and MONTH(lastlogindate)=MONTH(getdate()))
and YEAR=YEAR(getdate()) and MONTH=MONTH(getdate())
and e.ExchangeName<>'<none>'
and IsBillable = 'Y'
group by Year,Month,E.ExchangeName,NetworkId,UserName,AxProductId
end



