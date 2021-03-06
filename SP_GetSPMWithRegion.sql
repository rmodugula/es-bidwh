USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetSPMWithRegion]    Script Date: 7/13/2017 9:26:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--exec GetSPMWithRegion 7,2009

ALTER PROCEDURE [dbo].[GetSPMWithRegion] 
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
		  ,case when spm.salesoffice in ('Office-Chicago','Office-Houston') then 'Americas Central '
		        when spm.SalesOffice in ('Office-New York','Office-Sao Paulo') then 'Americas East' else spm.Region END as [Region]
		  ,spm.[Country]
		  ,spm.CountryName
		  ,spm.[State]
		  --,isnull(reg.SalesRegion,'Unmapped') as SalesRegion --case when [Country]= 'UNITED STATES' then [State] else [Country] end as CountryState
		  ,isnull(spm.SalesOffice,'Unmapped') as SalesOffice
		  ,[City]
		  ,AdditionalInfo
		  ,isnull([BilledAmount],0) as [BilledAmount]
		  ,isnull([BilledAmount+Tax],0) as [BilledAmount+Tax]
		  ,isnull([BilledAmount] - [BilledAmountY],0) as [BilledAmountYDelta]
		  ,isnull([BilledAmount] - [BilledAmountQ],0) as [BilledAmountQDelta]
		  ,isnull([BilledAmount] - [BilledAmountM],0) as [BilledAmountMDelta]
		  ,isnull([LicenseCount],0) as [LicenseCount]
		  ,isnull([LicenseCount] - [LicenseCountY],0) as [LicenseCountYDelta]
		  ,isnull([LicenseCount] - [LicenseCountQ],0) as [LicenseCountQDelta]
		  ,isnull([LicenseCount] - [LicenseCountM],0) as [LicenseCountMDelta]
		  , NonBillableLicenseCount
		  , spm.MasterAccountName, TTChangeType, CreditReason , TTLicenseFileID as NetworkShortName
		  , ActiveBillableToday, ActiveNonBillableToday, PriceGroup,TTBillingOnBehalfOf,Salestype as Source,TTUserCompany,MIC,TTPassThroughPrice
		  --,SalesManager,CustomerSuccessManager
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
			  ,CountryName
			  ,[State]
			  ,[City]
			  ,AdditionalInfo
			  ,sum(isnull(case when ([Month] = @inputMonth and [Year] = @inputYear) then [BilledAmount] end,0))  AS [BilledAmount]
			  ,sum(isnull(case when ([Month] = @inputMonth and [Year] = @inputYear) then [BilledAmount+Tax] end,0))  AS [BilledAmount+Tax]
			  ,sum(isnull(case when (Month = @EndOfLastYearMonth and Year = @EndOfLastYearYear) then [BilledAmount] end,0))  AS [BilledAmountY]
			  ,sum(isnull(case when (Month = @LastQuaterMonth and Year = @LastQuaterYear) then [BilledAmount] end,0)) AS [BilledAmountQ]
			  ,sum(isnull(case when (Month = @LastMonthMonth and Year = @LastMonthYear) then [BilledAmount] end,0)) AS [BilledAmountM]
			  ,sum(isnull(case when ([Month] = @inputMonth and [Year] = @inputYear) then [LicenseCount] end,0))  AS [LicenseCount]
			  ,sum(isnull(case when (Month = @EndOfLastYearMonth and Year = @EndOfLastYearYear) then [LicenseCount] end,0))  AS [LicenseCountY]
			  ,sum(isnull(case when (Month = @LastQuaterMonth and Year = @LastQuaterYear) then [LicenseCount] end,0)) AS [LicenseCountQ]
			  ,sum(isnull(case when (Month = @LastMonthMonth and Year = @LastMonthYear) then [LicenseCount] end,0)) AS [LicenseCountM]
 			  ,sum(isnull(case when ([Month] = @inputMonth and [Year] = @inputYear) then NonBillableLicenseCount end,0))  AS [NonBillableLicenseCount]
 			  , MasterAccountName, TTChangeType, CreditReason , SalesOffice, TTLICENSEFILEID, DataAreaId
			  --, BillableLicenseCount , NonBillableLicenseCount
			   , ActiveBillableToday, ActiveNonBillableToday, PriceGroup,TTBillingOnBehalfOf,SalesType -- <Ram:08/27/2013:1300> Included PriceGroup field
			   ,TTUserCompany,MIC,TTPassThroughPrice
			   --,SalesManager,CustomerSuccessManager
		from MonthlyBillingDataAggregate
		where	
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
			  ,CountryName
			  ,[city]
	  		  ,AdditionalInfo
	  		  , MasterAccountName, TTChangeType, CreditReason, SalesOffice, TTLICENSEFILEID,DataAreaId
	  		  , ActiveBillableToday, ActiveNonBillableToday, PriceGroup,TTBillingOnBehalfOf,SalesType,[Accountid],TTUserCompany,ReportingGroup,Screens,MIC,TTPassThroughPrice
			  --,SalesManager,CustomerSuccessManager
			  --  , BillableLicenseCount , NonBillableLicenseCount

	) spm
	
	
END


















