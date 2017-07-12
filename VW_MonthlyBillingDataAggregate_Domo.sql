USE [BIDW]
GO

/****** Object:  View [dbo].[MonthlyBillingDataAggregate_Domo]    Script Date: 7/12/2017 9:57:03 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






ALTER view [dbo].[MonthlyBillingDataAggregate_Domo] as

Select Month, Year, Date, final.CrmId, Accountid, AccountName, CustGroup, ProductSku, ProductName, ReportingGroup, Screens, ProductCategoryId, ProductCategoryName, ProductSubGroup, BilledAmount
, [BilledAmount+Tax], AdditionalInfo, TTdescription, Region, city, State, Country, CountryName, Branch, Action, Fills, LicenseCount, NonBillableLicenseCount, MasterAccountName, TTChangeType
, CreditReason, TTLICENSEFILEID, DataAreaId, ActiveBillableToday, ActiveNonBillableToday, PriceGroup, TTBillingOnBehalfOf, SalesType, NetworkShortName, TTUserCompany, MIC, UserName
, TTPassThroughPrice, final.SalesOffice, InvoiceId, TTUserId, isnull(SalesManager,SalesMD) as SalesManager, isnull(CustomerSuccessManager,PrimarySuccessLead) as CustomerSuccessManager, TTID, TTIDEmail
 from
(
	SELECT 
		Month, 
		Year, 
		cast(concat(month,'-','01','-',year) as date) as Date,
		--cast(str(Month)+'-'+str(1)+'-'+str(Year) as Date) As Date,		
		lower(MonthlyBillingData.CrmId) as CrmId, 
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
		TTdescription,
		MonthlyBillingData.Region,
		--case when MonthlyBillingData.Region in ('','None') or MonthlyBillingData.Region is null then R.Region else MonthlyBillingData.Region END as Region,
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
		, Account.MasterAccountName , TTChangeType , CreditReason , TTLICENSEFILEID, DataAreaId
		, ActiveBillableToday, ActiveNonBillableToday
		, PriceGroup,TTBillingOnBehalfOf,SalesType,NetworkShortName,nullif(TTUserCompany,'') as TTUserCompany,MIC
		, case when productname like '%Transaction%' then TTDESCRIPTION else deliveryname END as UserName
		, TTPassThroughPrice
		--,isnull(BranchName,SalesOffice) as SalesOffice
		,case when MonthlyBillingData.branchid=90 then 'Office-London' else BranchName END as SalesOffice ----moving all Indian invoices to Sales Office in London.
		,InvoiceId
		,TTUserId
		--,SalesManager
		--,cs.CustomerSuccessManager
		,TTID,TTIDEmail
		,lower(isnull(isnull(u.crmid,DynamicsId),MonthlyBillingData.crmid)) as TTUserCompanyCRMId
	FROM MonthlyBillingData
	left join Product on MonthlyBillingData.ProductSku = Product.ProductSku
	left join Account on MonthlyBillingData.AccountId = Account.Accountid	--left join Account on MonthlyBillingData.CrmId = Account.CrmId
	left join Branch on (case when MonthlyBillingData.BranchId =25 then 12 else MonthlyBillingData.BranchId END)= Branch.BranchId
	Left Join Network N on MonthlyBillingData.AccountId=N.AccountId
	Left Join (SELECT distinct [Country],[CountryName],Region,case when country<>'US' then '-' else State end as State,SalesOffice FROM [BIDW].[dbo].[RegionMap]
                 where CountryName is not null)R
			  on MonthlyBillingData.Country=R.Country 
			  and (case when MonthlyBillingData.country<>'US' then '-' else isnull(nullif(MonthlyBillingData.State,''),'Unassigned') end)=isnull(nullif(r.[State],''),'Unassigned')
			  left join (select distinct Companyname,Crmid from bidw_ods.[dbo].[UserCompaniesMapping] where len(crmid)>10) U 
                 on rtrim(replace(replace(MonthlyBillingData.TTUserCompany,'(Managed)',''),'(managed)',''))=U.CompanyName
			 left join (SELECT Name,DynamicsId FROM (SELECT Distinct [Name] ,[DynamicsId],row_number() over (partition by name order by [DynamicsId]) as row FROM [Synap].[dbo].[Organization] where DynamicsId is not null)W WHERE ROW=1) O
			 on MonthlyBillingData.TTUserCompany=o.Name
	where MonthlyBillingData.ProductSku<>0
	and product.ProductCategoryId<>'PrePay'
	--and year=2017 and month=5
  	GROUP BY --Id, 
  	Month, Year, MonthlyBillingData.CrmId, Account.AccountName, CustGroup, MonthlyBillingData.ProductSku, Product.ProductName, Product.ProductCategoryId, Product.ProductCategoryName,
	AdditionalInfo, MonthlyBillingData.Region,R.Region,City,MonthlyBillingData.[State], MonthlyBillingData.Country,R.CountryName,BranchName, [Action], Account.MasterAccountName, TTChangeType , CreditReason , TTLICENSEFILEID --,  BillableLicenseCount , NonBillableLicenseCount
	, DataAreaId, ActiveBillableToday, ActiveNonBillableToday, PriceGroup,ProductSubGroup,TTBillingOnBehalfOf,SalesType,NetworkShortName,MonthlyBillingData.Accountid,TTUserCompany,ReportingGroup,Screens,MIC,TTDESCRIPTION,deliveryname,TTPassThroughPrice,InvoiceId,TTUserId
	--,SalesManager,cs.CustomerSuccessManager
	,TTdescription,TTID,TTIDEmail,lower(isnull(isnull(u.crmid,DynamicsId),MonthlyBillingData.crmid)),MonthlyBillingData.branchid
)Final
	Left Join 
	( 
	        SELECT Distinct CrmID,[SalesOffice],ISNULL(CustomerSuccessManager,PrimarySuccessLead) as CustomerSuccessManager,SalesMD as SalesManager
           FROM [BIDW].[dbo].[TTCoverageMappings]
           where crmid is not null
	) CS ------- Added this code to get SalesManagers and CS Managers mapped for every customer and salesoffice
on Final.TTUserCompanyCRMId=cs.CRMID and Final.SalesOffice=cs.SalesOffice
Left Join 
	( 
	        SELECT distinct CrmID,PrimarySuccessLead,SalesMD
           FROM [BIDW].[dbo].[TTCoverageMappings]
           where crmid is not null
	) psl ------- Added this code to assign primary success lead if no CSM is assigned
on Final.TTUserCompanyCRMId=psl.CRMID 










































GO


