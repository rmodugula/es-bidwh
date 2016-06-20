USE [BIDW]
GO

/****** Object:  View [dbo].[MonthlyBillingDataAggregateLiveTransactions]    Script Date: 6/20/2016 10:22:15 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



ALTER view [dbo].[MonthlyBillingDataAggregateLiveTransactions] as
Select
Month, Year,cast(str(Month)+'-'+str(1)+'-'+str(Year) as Date) As Date,A.CrmId,IC.CompanyId as [Accountid],IC.InvoiceName as [AccountName],
case when pfwcode in (20992,20995,20997,20996,20993) then 'MultiBrokr' when pfwcode in (20998,20005,10106,20999) then 'Trnx SW' else '' end as [CustGroup]
,Pt.Productsku,pt.[ProductName],ReportingGroup,Screens,pt.ProductCategoryId,pt.[ProductCategoryName] ,pt.ProductSubGroup 
,sum(total) as Billedamount,UserId as AdditionalInfo,'' as Region,city, State, I.Country,CountryName,'' as Branch, '' as Action, 1 as Licensecount,0 as NonBillableLicenseCount,
A.MasterAccountName,'' as TTChangeType, '' as CreditReason, '' as TTLICENSEFILEID,RevenueDestination as DataAreaId,0 as ActiveBillableToday, 0 as ActiveNonBillableToday,
'' as PriceGroup,RevenueDestination as  TTBillingOnBehalfOf, 'InvoiceLive' as SalesType, '' as NetworkShortName, '' as TTUserCompany,'' as MIC
from chisql20.[Licensing2].[dbo].[InvoiceFillDataCache] I
Left Join chisql20.[Licensing2].[dbo].[InvoiceConfig] IC on I.InvoiceConfigId=IC.InvoiceConfigId
Left Join chisql20.[Licensing2].[dbo].[Product] P on I.ProductId=P.ProductId
Left join chisql12.bidw.dbo.Account A on IC.CompanyId=A.accountid 
Left join chisql12.bidw.dbo.Product Pt on pfwcode=pt.productsku
Left Join (SELECT distinct [Country],[CountryName] FROM [BIDW].[dbo].[RegionMap]
                 where CountryName is not null)R
			  on I.Country=R.Country
where pt.ProductCategoryId<>'PrePay'
--year=year(getdate()) and month=month(getdate())
group by
Month, Year,A.CrmId,IC.CompanyId,IC.InvoiceName,
(case when pfwcode in (20992,20995,20997,20996,20993) then 'MultiBrokr' when pfwcode in (20998,20005,10106,20999) then 'Trnx SW' else '' end)
,Pt.Productsku,pt.ProductName,ReportingGroup,Screens,pt.ProductCategoryId,pt.[ProductCategoryName] ,pt.ProductSubGroup 
,UserId,city, State, I.Country,CountryName, A.MasterAccountName,RevenueDestination 

UNION ALL

Select * from [dbo].[MonthlyBillingDataAggregate]
where SalesType<>'InvoiceProj'









GO


