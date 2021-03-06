USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetTransactionDetail]    Script Date: 03/24/2014 16:13:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[GetTransactionDetail](@pmonth char(10), @pyear integer)
     
     
AS
BEGIN

select MasterAccountName as MasterCustomer,Network, ExchangeConsolidated as Exchange, ProductName, UserId,AXCompany,CustomerGroup,sum(fills) as Fills
from dbo.DetailedFillData
where fmonth = @pmonth 
and fyear = @pyear
and Network Not like '%Multibroker%' and Network not like '%TRADECO%'
group by MasterAccountName,Network, ExchangeConsolidated, ProductName, UserID,AXCompany,CustomerGroup
order by Network, ExchangeConsolidated

end




