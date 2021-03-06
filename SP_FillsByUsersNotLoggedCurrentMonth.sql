USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_FillsByUsersNotLoggedCurrentMonth]    Script Date: 4/7/2016 10:58:26 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_FillsByUsersNotLoggedCurrentMonth]

     
AS
BEGIN

select Year,Month,UserName,MarketName as ExchangeName,NetworkId,AxProductId,SUM(fills)as Fills from Fills F 
Left join Exchange E
on F.ExchangeId=E.ExchangeId
Left join [BIDW].[dbo].[Market] M
on f.MarketId=m.MarketID and f.platform=m.platform
where UserName not in 
(
select UserName from dbo.LastLogin 
where YEAR(lastlogindate)=YEAR(getdate()) and MONTH(lastlogindate)=MONTH(getdate())
union 
select distinct [LOGIN] as UserName from fillhub.dbo.UserLogin
where YEAR(lastlogin)=YEAR(getdate()) and MONTH(lastlogin)=MONTH(getdate())
)
--(select UserName from dbo.LastLogin where YEAR(lastlogindate)=YEAR(getdate()) 
--and MONTH(lastlogindate)=MONTH(getdate()))
and YEAR=YEAR(getdate()) and MONTH=MONTH(getdate())
and e.ExchangeName<>'<none>'
and IsBillable = 'Y'
group by Year,Month,NetworkId,UserName,AxProductId,MarketName
end



