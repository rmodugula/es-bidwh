USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[FillSummary]    Script Date: 09/19/2013 16:00:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[FillSummary](@pmonth integer, @pyear integer)
     
     
AS
BEGIN

select Network, ExchangeConsolidated, ProductName, UserId, sum(fills) as Fills
from dbo.DetailedFillData
where fmonth = @pmonth and fyear = @pyear
and Network Not like '%Multibroker%' and Network not like '%TRADECO%'
group by Network, ExchangeConsolidated, ProductName, UserID
order by Network, ExchangeConsolidated

end



