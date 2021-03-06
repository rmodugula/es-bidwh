USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetInvoiceBillingData]    Script Date: 09/19/2013 16:01:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[GetInvoiceBillingData] (@Month	int,	@Year int)
as 
Begin

 declare @today datetime;
 declare @axDefaultDate datetime;
 
 set @today = CONVERT(VARCHAR(10), GETDATE(), 101);

  
  set NoCount on;
  
  
  
  select A.DATAAREAID as AXCompany, Account.MasterAccountName, Account.AccountName, Product.ProductName, Product.ProductCategoryName
  , A.SalesPrice, A.TTUsage, A.LINEAMOUNT, A.TAXAMOUNT, A.TotalAmount
  , Case when A.TTBillStart <> '' then A.TTBillStart
      ELSE NULL END AS TTBillStart
  , Case when A.TTBillEnd <> '' then A.TTBillEnd
      ELSE NULL END AS TTBillEnd
  , A.ConfigId as NumberOfMarkets, A.DELIVERYNAME, A.TTDESCRIPTION
  , A.City, A.State, A.Country, A.DeliveryZipCode as Zip
  , A.TTLICENSEFILEID  
  , isnull(A.BillableLicenseCount, 0)  as BillableLicenseCount 
  , isnull(A.NonBillableLicenseCount, 0)  as NonBillableLicenseCount
  , A.TTChangeType 
  , Case when A.TTChangeType = 'Cancellation' then A.TTBillEnd
         Else NULL End as CancellationDate  
   , case when (A.TTBillEnd = '' and A.BilledAmount = 0) then 'Permanent Trial'
    when (A.TTBillEnd != '' and A.BilledAmount = 0) then  'Temporary Trial' End AS Trial
  , A.Region  , Branch.BranchName as SalesOffice
  , A.InvoiceId, A.CustGroup
    
  from dbo.MonthlyBillingData A 
  left join Product on A.ProductSku = Product.ProductSku
	left join Account on A.AccountId = Account.Accountid	--left join Account on MonthlyBillingData.CrmId = Account.CrmId
	left join Branch on A.BranchId = Branch.BranchId
  where A.SalesType = 'Invoice'
  and A.Month = @Month 
  and A.Year = @Year
  
  order by Account.MasterAccountName

End

