USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetChangeInFillsByExchange]    Script Date: 4/7/2016 10:45:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[GetChangeInFillsByExchange]
@RunYear Int = Null,
@RunMonth Int = Null
     
     
AS

Declare @Year int, @Month int
IF @RunMonth is Null and @RunMonth is Null
Begin 
set @Year = (select YEAR from(select *, ROW_NUMBER() over (order by id desc) as num from chisql12.fillhub.dbo.invoicemonth)Q where num=1)
set @Month = (select Month from(select *, ROW_NUMBER() over (order by id desc) as num from chisql12.fillhub.dbo.invoicemonth)Q where num=1)
--Set @Year=YEAR(getdate()) 
--Set @Month=MONTH(getdate())
end
else 
Begin
Set @Year=@RunYear
Set @Month=@RunMonth
End

Declare @PriorYear int, @PriorMonth int

SET @PriorYear = CASE WHEN @Month=1 THEN @Year-1 else @Year end
SET @PriorMonth = Case when @Month=1 then 12 else @Month-1 end


BEGIN
select isnull(A.ExchangeName,B.ExchangeName) as ExchangeName,isnull(A.Fills,0)-isnull(B.Fills,0) as ChangeInFills,A.fills as TargetFills,B.Fills as PriorFills
--,round(case when b.Fills=0 then 0 else cast((isnull(A.Fills,0)-isnull(B.Fills,0)) as numeric)/cast(b.Fills as numeric) end,2) as '%ChangeInFills'
 from
(
Select ExchangeName,Sum(fills) as Fills from
(
select MarketName as ExchangeName,SUM(fills) as Fills from Fills F
left join Exchange E
on f.ExchangeId=e.ExchangeId
Left join [BIDW].[dbo].[Market] M
on f.MarketId=m.MarketID and f.platform=m.platform
where IsBillable='Y'
and YEAR=@Year and MONTH=@Month
group by MarketName,Networkid
)Z 
Group by ExchangeName
)A
full outer join
(
Select ExchangeName,Sum(fills) as Fills from
(
select MarketName as ExchangeName,SUM(fills) as Fills from Fills F
left join Exchange E
on f.ExchangeId=e.ExchangeId
Left join [BIDW].[dbo].[Market] M
on f.MarketId=m.MarketID and f.platform=m.platform
where IsBillable='Y'
and YEAR=@PriorYear and MONTH=@PriorMonth
group by MarketName,Networkid
)y
Group by ExchangeName
)B
on A.ExchangeName=b.ExchangeName
order by 1
end




