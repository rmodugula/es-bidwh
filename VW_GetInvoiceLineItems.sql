USE [BIDW]
GO

/****** Object:  View [dbo].[VW_GetInvoiceLineItems]    Script Date: 6/23/2016 3:59:39 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




ALTER VIEW [dbo].[VW_GetInvoiceLineItems]
AS

Select distinct Year,Month,rtrim(substring(datename(m,cast(str(month)+'-'+str(01)+'-'+str(year) as Date)),1,3))+' '+ltrim(str(year)) as ServiceMonth,  TTDescription,ProductCategoryName as ItemGroup,ProductName as ItemName,DELIVERYNAME as MoreInfo,ConfigId as Configuration,LicenseCount as Qty,TTUsage as '%ofMonth',
InvoiceId as Invoice,Currency,SalesPrice,LineAmount,TAXAMOUNT as Tax,TotalAmount as Total,City,State,Country,TTBillingOnBehalfOf as Company,MIC,SalesType as Source from MonthlyBillingData M
Left join Product P on M.ProductSku=P.ProductSku




GO


