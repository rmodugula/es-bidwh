USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetSalesMetrics]    Script Date: 8/16/2016 10:09:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[GetSalesMetrics] 
	@inputMonth int, -- = DatePart(month,GetDate()), 
	@inputYear int -- = DatePart(year,GetDate()), 
AS
BEGIN

SET NOCOUNT ON;
	declare @EndOfLastYearMonth int
	declare @EndOfLastYearYear int
	declare @LastQuaterMonth int
	declare @LastQuaterYear int
	declare @LastMonthMonth int
	declare @LastMonthYear int
	declare @FirstDayOfMonth date
	declare @LastDayOfMonth date
	declare @FirstDayOfNextMonth date
	select @EndOfLastYearMonth  = 12
	select @EndOfLastYearYear   = datepart(year,dateadd(y,-1,'1/1/'+ cast(@inputYear as char(4))))
	select @LastQuaterMonth  =	case when ((@inputMonth  IN (1,2,3))) then   12
									 when ((@inputMonth  IN (4,5,6))) then   3 
									 when ((@inputMonth  IN (7,8,9))) then   6 
									 when ((@inputMonth  IN (10,11,12))) then   9 
								end    
	select @LastQuaterYear  =	case when ((@inputMonth  IN (1,2,3))) then   @EndOfLastYearYear
									 else @inputYear	
								end    
	select @LastMonthMonth  =	case when ((@inputMonth  IN (1))) then   12
									 else @inputMonth -1	
								end    
	select @LastMonthYear  =	case when ((@inputMonth  IN (1))) then   @inputYear - 1
									 else @inputYear	
								end    

	select @FirstDayOfMonth = CONVERT(varchar,@inputMonth) + '/1/' + CONVERT(varchar,@inputYear)
	select @FirstDayOfNextMonth = DATEADD(m,1,@FirstDayOfMonth)
	select @LastDayOfMonth = DATEADD(d,-1,@FirstDayOfNextMonth)
	print @EndOfLastYearMonth
	print @EndOfLastYearYear
	print @LastQuaterMonth
	print @LastQuaterYear
	print @LastMonthMonth
	print @LastMonthYear
	select 
	      DataAreaId as AXCompany		  
		  ,[AccountName]
		  ,[Accountid]
		  ,[CustGroup]
		  ,[ProductName]
		  ,[ProductCategoryName]
		  , ProductSubGroup as ItemSubGroup
		  , ReportingGroup
		  , Screens
		  ,spm.[Region]
		  ,spm.[Country]
		  ,spm.[State]
		  --,isnull(reg.SalesRegion,'Unmapped') as SalesRegion --case when [Country]= 'UNITED STATES' then [State] else [Country] end as CountryState
		  ,isnull(spm.SalesOffice,'Unmapped') as SalesOffice
		  ,[City]
		  ,AdditionalInfo
		  ,isnull([BilledAmount],0) as [BilledAmount]
		  ,isnull([BilledAmount] - [BilledAmountY],0) as [BilledAmountYDelta]
		  ,isnull([BilledAmount] - [BilledAmountQ],0) as [BilledAmountQDelta]
		  ,isnull([BilledAmount] - [BilledAmountM],0) as [BilledAmountMDelta]
		  ,isnull([LicenseCount],0) as [LicenseCount]
		  ,isnull([LicenseCount] - [LicenseCountY],0) as [LicenseCountYDelta]
		  ,isnull([LicenseCount] - [LicenseCountQ],0) as [LicenseCountQDelta]
		  ,isnull([LicenseCount] - [LicenseCountM],0) as [LicenseCountMDelta]
		  , NonBillableLicenseCount
		  , MasterAccountName, TTChangeType, CreditReason , TTLicenseFileID as NetworkShortName
		  , ActiveBillableToday, ActiveNonBillableToday, PriceGroup,TTBillingOnBehalfOf,Salestype as Source,TTUserCompany,TTPassThroughPrice
	from
	(	

	select
			  [AccountName]
			  ,[Accountid]
			  ,[CustGroup]
			  ,[ProductName]
			  ,[ProductCategoryName]
			  ,ProductSubGroup
			  ,ReportingGroup
			  , Screens
			  ,[Region]
			  ,[Country]
			  ,[State]
			  ,[City]
			  ,AdditionalInfo
			  ,sum(isnull(case when ([Month] = @inputMonth and [Year] = @inputYear) then [BilledAmount] end,0))  AS [BilledAmount]
			  ,sum(isnull(case when (Month = @EndOfLastYearMonth and Year = @EndOfLastYearYear) then [BilledAmount] end,0))  AS [BilledAmountY]
			  ,sum(isnull(case when (Month = @LastQuaterMonth and Year = @LastQuaterYear) then [BilledAmount] end,0)) AS [BilledAmountQ]
			  ,sum(isnull(case when (Month = @LastMonthMonth and Year = @LastMonthYear) then [BilledAmount] end,0)) AS [BilledAmountM]
			  ,sum(isnull(case when ([Month] = @inputMonth and [Year] = @inputYear) then [LicenseCount] end,0))  AS [LicenseCount]
			  ,sum(isnull(case when (Month = @EndOfLastYearMonth and Year = @EndOfLastYearYear) then [LicenseCount] end,0))  AS [LicenseCountY]
			  ,sum(isnull(case when (Month = @LastQuaterMonth and Year = @LastQuaterYear) then [LicenseCount] end,0)) AS [LicenseCountQ]
			  ,sum(isnull(case when (Month = @LastMonthMonth and Year = @LastMonthYear) then [LicenseCount] end,0)) AS [LicenseCountM]
 			  ,sum(isnull(case when ([Month] = @inputMonth and [Year] = @inputYear) then NonBillableLicenseCount end,0))  AS [NonBillableLicenseCount]
 			  , MasterAccountName, TTChangeType, CreditReason , Branch as SalesOffice, TTLICENSEFILEID, DataAreaId
			  --, BillableLicenseCount , NonBillableLicenseCount
			   , ActiveBillableToday, ActiveNonBillableToday, PriceGroup,TTBillingOnBehalfOf,SalesType -- <Ram:08/27/2013:1300> Included PriceGroup field
			   ,TTUserCompany,TTPassThroughPrice
		from
		(
		Select * from  MonthlyBillingDataAggregateLiveTransactions
		where salestype<>'Invoicelive'

		UNION ALL

		Select * from  MonthlyBillingDataAggregateLiveTransactions
		where salestype='Invoicelive'
		and accountid not in 
		(
		Select distinct custaccount  from chiaxsql01.TT_DYANX09_PRD.dbo.SALESLINE 
		where  ITEMID in ('20996', '20997', '20998', '20999', '10106','20005','20995','20992','20993','20991','20994','80000','80001','80002','80003')
		and (TTBILLSTART = '01/01/1900'  or TTBILLSTART <= @LastDayOfMonth)
		and (TTBILLEND = '01/01/1900' or TTBILLEND >= @FirstDayOfMonth) 

 )
		)q
		where	
		salestype <> (case when @inputMonth=month(getdate()) and @inputYear=year(getdate()) then 'InvoiceProj' else '' END) and
				-- jg 6 mar 2012 --remove below to allow adustments to enter reports
				-- jg 6 mar 2012 later try again --change below back to allow adustments to enter reports but not 0 based transactions
                --( ((isnull([BilledAmount],0) <> 0 and [source]=0)or [source]=1) )
                --( (isnull([LicenseCount],0) > 0) or isnull([BillableLicenseCount],0) >0  or  isnull([NonBillableLicenseCount],0) >0 )
                ( (isnull([LicenseCount],0) != 0)  or  isnull([NonBillableLicenseCount],0) >0  or ISNULL(BilledAmount, 0) >0  )
				and  
					( (Month = @inputMonth and Year = @inputYear)
				or (Month = @EndOfLastYearMonth and Year = @EndOfLastYearYear)
				or (Month = @LastQuaterMonth and Year = @LastQuaterYear)
				or (Month = @LastMonthMonth and Year = @LastMonthYear))
		group by			  
			  [AccountName]
			  ,[CustGroup]
			  ,[ProductName]
			  ,[ProductCategoryName]
			  , ProductSubGroup
			  ,[Region]
			  ,[State]
			  ,[Country]
			  ,[city]
	  		  ,AdditionalInfo
	  		  , MasterAccountName, TTChangeType, CreditReason, Branch, TTLICENSEFILEID,DataAreaId
	  		  , ActiveBillableToday, ActiveNonBillableToday, PriceGroup,TTBillingOnBehalfOf,SalesType,[Accountid],TTUserCompany,ReportingGroup,Screens,TTPassThroughPrice


--		UNION ALL


--Select * from
--(
--select
--			  IC.InvoiceName as [AccountName] ,IC.CompanyId as [Accountid] ,
--			  case when pfwcode in (20992,20995,20997,20996,20993) then 'MultiBrokr'
--			       when pfwcode in (20998,20005,10106,20999) then 'Trnx SW' else '' end as [CustGroup],Product as [ProductName] ,p.[ProductCategoryName] ,pt.ProductSubGroup 
--			  ,pt.ReportingGroup , pt.Screens ,'' as [Region] ,[Country]
--			  ,[State] ,[City] ,UserId as AdditionalInfo
--			  ,sum(isnull(case when ([Month] = @inputMonth and [Year] = @inputYear) then [Total] end,0))  AS [BilledAmount]
--			  ,sum(isnull(case when (Month = @EndOfLastYearMonth and Year = @EndOfLastYearYear) then [Total] end,0))  AS [BilledAmountY]
--			  ,sum(isnull(case when (Month = @LastQuaterMonth and Year = @LastQuaterYear) then [Total] end,0)) AS [BilledAmountQ]
--			  ,sum(isnull(case when (Month = @LastMonthMonth and Year = @LastMonthYear) then [Total] end,0)) AS [BilledAmountM]
--			  ,sum(isnull(case when ([Month] = @inputMonth and [Year] = @inputYear) then 1 end,0))  AS [LicenseCount]
--			  ,sum(isnull(case when (Month = @EndOfLastYearMonth and Year = @EndOfLastYearYear) then 1 end,0))  AS [LicenseCountY]
--			  ,sum(isnull(case when (Month = @LastQuaterMonth and Year = @LastQuaterYear) then 1 end,0)) AS [LicenseCountQ]
--			  ,sum(isnull(case when (Month = @LastMonthMonth and Year = @LastMonthYear) then 1 end,0)) AS [LicenseCountM]
-- 			  ,sum(isnull(case when ([Month] = @inputMonth and [Year] = @inputYear) then 0 end,0))  AS [NonBillableLicenseCount]
-- 			  , A.MasterAccountName, '' as TTChangeType, '' as CreditReason , '' as SalesOffice, '' as TTLICENSEFILEID, RevenueDestination as DataAreaId
--			  --, BillableLicenseCount , NonBillableLicenseCount
--			   , 0 as ActiveBillableToday, 0 as ActiveNonBillableToday, '' as PriceGroup,RevenueDestination as TTBillingOnBehalfOf,'TrnxProj' as SalesType 
--			   ,'' as TTUserCompany
--		from chisql20.[Licensing2].[dbo].[InvoiceFillDataCache] I
--		Left Join chisql20.[Licensing2].[dbo].[InvoiceConfig] IC on I.InvoiceConfigId=IC.InvoiceConfigId
--		Left Join chisql20.[Licensing2].[dbo].[Product] P on I.ProductId=P.ProductId
--		Left join chisql12.bidw.dbo.Account A on IC.CompanyId=A.accountid 
--		Left join chisql12.bidw.dbo.Product Pt on pfwcode=pt.productsku
--		where	
--						-- jg 6 mar 2012 --remove below to allow adustments to enter reports
--				-- jg 6 mar 2012 later try again --change below back to allow adustments to enter reports but not 0 based transactions
--                --( ((isnull([BilledAmount],0) <> 0 and [source]=0)or [source]=1) )
--                --( (isnull([LicenseCount],0) > 0) or isnull([BillableLicenseCount],0) >0  or  isnull([NonBillableLicenseCount],0) >0 )
--                ( (isnull(1,0) != 0)  or  isnull(0,0) >0  or ISNULL([Total], 0) >0  )
--				and  
--					( (Month = @inputMonth and Year = @inputYear)
--				or (Month = @EndOfLastYearMonth and Year = @EndOfLastYearYear)
--				or (Month = @LastQuaterMonth and Year = @LastQuaterYear)
--				or (Month = @LastMonthMonth and Year = @LastMonthYear))
--		group by			  
--			  IC.InvoiceName
--			  ,(case when pfwcode in (20992,20995,20997,20996,20993) then 'MultiBrokr' when pfwcode in (20998,20005,10106,20999) then 'Trnx SW' else '' end)
--			  ,Product
--			  ,p.[ProductCategoryName]
--			  , pt.ProductSubGroup
--			  ,pfwcode
--			  --,'' as [Region]
--			  ,[State]
--			  ,[Country]
--			  ,[city]
--	  		  ,userid
--	  		  , MasterAccountName
--			  --, TTChangeType, CreditReason, Branch, TTLICENSEFILEID
--			  ,RevenueDestination
--	  		  --, ActiveBillableToday, ActiveNonBillableToday, PriceGroup,TTBillingOnBehalfOf ,SalesType
--			  ,Ic.companyid
--			  --,TTUserCompany
--			  ,ReportingGroup,Screens
--			  )Q
--			  where salestype <> (case when @inputMonth<>month(getdate()) then 'TrnxProj' else '' END)
--			  --and @inputYear<>year(getdate()


	

	) spm
	

END


















