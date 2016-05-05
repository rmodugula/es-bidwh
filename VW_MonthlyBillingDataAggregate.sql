USE [BIDW]
GO

/****** Object:  View [dbo].[MonthlyBillingDataAggregate]    Script Date: 5/5/2016 2:14:47 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







ALTER view [dbo].[MonthlyBillingDataAggregate] as
	SELECT 
		Month, 
		Year, 		
		MonthlyBillingData.CrmId as CrmId, 
		MonthlyBillingData.Accountid,
		isnull(Account.AccountName,'Unassigned') as AccountName, 
		CustGroup,
		MonthlyBillingData.ProductSku as ProductSku, 
		isnull(Product.ProductName,'Unassigned') as ProductName, 
		isnull(Product.ReportingGroup,'Unassigned') as ReportingGroup, 
		isnull(Product.Screens,'Unassigned') as Screens, 
		--case when productcategoryid in (4,6,10) then 101 else isnull(Product.ProductCategoryId,-1) end as ProductCategoryId, 
		isnull(Product.ProductCategoryId , -1) as ProductCategoryId,
		--case when productcategoryid in (4,6,10) then 'Other Trading and Support Products' else isnull(Product.ProductCategoryName,'Unassigned') end as ProductCategoryName,
		isnull(Product.ProductCategoryName,'Unassigned') as ProductCategoryName,
		isnull(Product.ProductSubGroup,'Unassigned') as ProductSubGroup,
		SUM(isnull(BilledAmount,0)) AS BilledAmount, 
		AdditionalInfo, 
		Region,
		[city],
		[State], 
		Country, 
		BranchName as Branch, 
		[Action] 
		--, SUM(case when (isnull(BilledAmount,0) = 0 ) then 0 else isnull(LicenseCount,0) end) AS LicenseCount --and [source]=0
		--, SUM( isnull(LicenseCount,0) ) as LicenseCount		
		--, BillableLicenseCount , NonBillableLicenseCount
		, SUM( isnull(BillableLicenseCount, 0) ) as LicenseCount --BillableLicenseCount
		, SUM( isnull(NonBillableLicenseCount, 0) ) as NonBillableLicenseCount
		, MasterAccountName , TTChangeType , CreditReason , TTLICENSEFILEID, DataAreaId
		, ActiveBillableToday, ActiveNonBillableToday
		, PriceGroup,TTBillingOnBehalfOf,SalesType,NetworkShortName,TTUserCompany,MIC
	FROM MonthlyBillingData
	left join Product on MonthlyBillingData.ProductSku = Product.ProductSku
	left join Account on MonthlyBillingData.AccountId = Account.Accountid	--left join Account on MonthlyBillingData.CrmId = Account.CrmId
	left join Branch on MonthlyBillingData.BranchId = Branch.BranchId
	Left Join Network N on MonthlyBillingData.AccountId=N.AccountId
	where MonthlyBillingData.ProductSku<>0
	and product.ProductCategoryId<>'PrePay'
  	GROUP BY --Id, 
  	Month, Year, MonthlyBillingData.CrmId, Account.AccountName, CustGroup, MonthlyBillingData.ProductSku, Product.ProductName, Product.ProductCategoryId, Product.ProductCategoryName,
	AdditionalInfo, Region, City,[State], Country, 	BranchName, [Action], MasterAccountName, TTChangeType , CreditReason , TTLICENSEFILEID --,  BillableLicenseCount , NonBillableLicenseCount
	, DataAreaId, ActiveBillableToday, ActiveNonBillableToday, PriceGroup,ProductSubGroup,TTBillingOnBehalfOf,SalesType,NetworkShortName,MonthlyBillingData.Accountid,TTUserCompany,ReportingGroup,Screens,MIC















GO


