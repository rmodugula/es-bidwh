USE [BIDW]
GO

/****** Object:  View [dbo].[MonthlyBillingDataAggregate]    Script Date: 2/14/2017 3:04:11 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




ALTER view [dbo].[MonthlyBillingDataAggregate] as
	SELECT 
		Month, 
		Year, 
		cast(str(Month)+'-'+str(1)+'-'+str(Year) as Date) As Date,		
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
		SUM(isnull(TotalAmount,0)) AS 'BilledAmount+Tax', 
		AdditionalInfo, 
		case when MonthlyBillingData.Region in ('','None') or MonthlyBillingData.Region is null then R.Region else MonthlyBillingData.Region END as Region,
		[city],
		MonthlyBillingData.[State], 
		MonthlyBillingData.Country, 
		R.CountryName,
		BranchName as Branch, 
		[Action] 
		--, SUM(case when (isnull(BilledAmount,0) = 0 ) then 0 else isnull(LicenseCount,0) end) AS LicenseCount --and [source]=0
		--, SUM( isnull(LicenseCount,0) ) as LicenseCount		
		--, BillableLicenseCount , NonBillableLicenseCount
		, SUM( isnull(LicenseCount, 0) ) as Fills 
		, SUM( isnull(BillableLicenseCount, 0) )  as LicenseCount --BillableLicenseCount
		, SUM( isnull(NonBillableLicenseCount, 0) ) as NonBillableLicenseCount
		, MasterAccountName , TTChangeType , CreditReason , TTLICENSEFILEID, DataAreaId
		, ActiveBillableToday, ActiveNonBillableToday
		, PriceGroup,TTBillingOnBehalfOf,SalesType,NetworkShortName,TTUserCompany,MIC
		, case when productname like '%Transaction%' then TTDESCRIPTION else deliveryname END as UserName
		, TTPassThroughPrice
		,isnull(BranchName,SalesOffice) as SalesOffice
		,InvoiceId
		,TTUserId
	FROM MonthlyBillingData
	left join Product on MonthlyBillingData.ProductSku = Product.ProductSku
	left join Account on MonthlyBillingData.AccountId = Account.Accountid	--left join Account on MonthlyBillingData.CrmId = Account.CrmId
	left join Branch on MonthlyBillingData.BranchId = Branch.BranchId
	Left Join Network N on MonthlyBillingData.AccountId=N.AccountId
	Left Join (SELECT distinct [Country],[CountryName],Region,case when country<>'US' then '-' else State end as State,SalesOffice FROM [BIDW].[dbo].[RegionMap]
                 where CountryName is not null)R
			  on MonthlyBillingData.Country=R.Country 
			  and (case when MonthlyBillingData.country<>'US' then '-' else isnull(nullif(MonthlyBillingData.State,''),'Unassigned') end)=isnull(nullif(r.[State],''),'Unassigned')
	where MonthlyBillingData.ProductSku<>0
	and product.ProductCategoryId<>'PrePay'
  	GROUP BY --Id, 
  	Month, Year, MonthlyBillingData.CrmId, Account.AccountName, CustGroup, MonthlyBillingData.ProductSku, Product.ProductName, Product.ProductCategoryId, Product.ProductCategoryName,
	AdditionalInfo, MonthlyBillingData.Region,R.Region,City,MonthlyBillingData.[State], MonthlyBillingData.Country,R.CountryName,BranchName, [Action], MasterAccountName, TTChangeType , CreditReason , TTLICENSEFILEID --,  BillableLicenseCount , NonBillableLicenseCount
	, DataAreaId, ActiveBillableToday, ActiveNonBillableToday, PriceGroup,ProductSubGroup,TTBillingOnBehalfOf,SalesType,NetworkShortName,MonthlyBillingData.Accountid,TTUserCompany,ReportingGroup,Screens,MIC,TTDESCRIPTION,deliveryname,TTPassThroughPrice,SalesOffice,InvoiceId,TTUserId



































GO


