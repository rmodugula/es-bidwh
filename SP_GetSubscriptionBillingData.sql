USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetSubscriptionBillingData]    Script Date: 09/19/2013 16:04:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER procedure [dbo].[GetSubscriptionBillingData]
as 
Begin

 declare @today date;
 declare @currMonth int;
 
 set @today = CONVERT(VARCHAR(10), GETDATE(), 101);
 set @currMonth = datePart(mm, @today)
  
 set NoCount on;
  
  select A.DATAAREAID as AXCompany, Account.MasterAccountName, Account.AccountName, A.CustGroup, Product.ProductName, Product.ProductCategoryName
  , A.BilledAmount, A.TTUsage
  , A.ConfigId as NumberOfMarkets, A.DELIVERYNAME, A.TTDESCRIPTION, A.AdditionalInfo
  , A.City, A.State, A.Country, A.DeliveryZipCode as Zip
  , A.TTLICENSEFILEID  
  , isnull(A.BillableLicenseCount, 0)  as BillableLicenseCount 
  , isnull(A.NonBillableLicenseCount, 0)  as NonBillableLicenseCount
  , A.TTChangeType 
  , Case when A.TTChangeType = 'Cancellation' then A.TTBillEnd
         Else NULL End as CancellationDate  
   , case when (A.TTBillEnd = '' and A.BilledAmount = 0) then 'Permanent Trial'
    when (A.TTBillEnd != '' and A.BilledAmount = 0) then  'Temporary Trial' End AS Trial
   , Case when A.TTBillStart <> '' then A.TTBillStart
      ELSE NULL END AS TTBillStart
  , Case when A.TTBillEnd <> '' then A.TTBillEnd
      ELSE NULL END AS TTBillEnd
  , A.Region  , Branch.BranchName as SalesOffice
  , A.SalesId, A.SalesPrice , A.ActiveBillableToday, A.ActiveNonBillableToday
  from dbo.MonthlyBillingData A 
  left join Product on A.ProductSku = Product.ProductSku
	left join Account on A.AccountId = Account.Accountid	--left join Account on MonthlyBillingData.CrmId = Account.CrmId
	left join Branch on A.BranchId = Branch.BranchId
  where A.SalesType = 'Subscription'
  and (A.TTBillStart = '' or A.TTBillStart <= @today )
  and (A.TTBillEnd = '' or A.TTBillEnd >= @today)
  and A.Month = @currMonth
  
  order by Account.MasterAccountName
  

End





