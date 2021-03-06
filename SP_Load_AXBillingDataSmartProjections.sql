USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_Load_AXBillingData]    Script Date: 05/21/2014 16:15:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[SP_Load_AXBillingData]
	@Month	int,
	@Year		int 
AS


-- **** Global Variables ***
declare @FirstDayOfMonth smalldatetime , @LastDayOfMonth smalldatetime , @FirstDayOfNextMonth smalldatetime 
declare @qMonth int , @qYear int -- month and year to be used for query
declare @isProjection int
Declare @axDefaultDate smalldatetime
DECLARE @DaysInMonth	decimal(10,6)
DECLARE @LastMonth int ,@LastYear int  --, @TxMonth int, @TxYear int
declare @PriorYear int
Declare @PriorMonth int

SET @FirstDayOfMonth = CONVERT(varchar,@Month) + '/1/' + CONVERT(varchar,@Year)
SET @FirstDayOfNextMonth = DATEADD(m,1,@FirstDayOfMonth)
SET @DaysInMonth = CONVERT(decimal(10,6),DATEDIFF(d,@FirstDayOfMonth,DATEADD(m,1,@FirstDayOfMonth)))
SET @LastDayOfMonth = DATEADD(d,-1,@FirstDayOfNextMonth)
SET @LastMonth = DATEPART(mm, DATEADD(d,-1,@FirstDayOfMonth))
SET @LastYear = DATEPART(yyyy, DATEADD(d,-1,@FirstDayOfMonth))
set @PriorYear= (case when MONTH(getdate())=1 then YEAR(getdate())-1 else YEAR(getdate()) end)  -- <Ram 1/10/2014 11:35 AM> Load Only Non-Invoiced Months Data - Jira BI-80
set @PriorMonth = (case when MONTH(getdate())=1 then 12 else MONTH(getdate())-1 end)
-- **** end Global Variables ***


-- ****  Variables used only for LastInvoice Calc  ****
declare @totalInvoices int
declare @i int , @j int -- @i is month and @j is year
declare @currMonth int, @currYear int , @currentMonthDate smalldatetime , @tempDate smalldatetime , @InvoiceProjYear int, @InvoiceProjMonth int, @InvoiceProjDate smalldatetime
  
-- ****  End Variables used only for LastInvoice Calc  ****


-- *****  lastInvoiceMonth Caluclation  *******
set @currMonth = DATEPART(mm, Getdate())
set @currYear = DATEPART(yyyy , Getdate())
set @currentMonthDate = CONVERT(varchar, @currMonth) + '/1/' + CONVERT(varchar, @currYear)
set @tempDate = @currentMonthDate

set @i = @currMonth
set @j = @currYear
set @totalInvoices = 0

   IF (select COUNT(*) from chisql12.fillhub.dbo.invoicemonth  
 where YEAR=@Year AND MONTH =@Month) =0
	  Begin
	    set @tempDate = DATEADD(m, -1, @tempDate)
	    set @i = DATEPART(mm , @tempDate)  --  set @i = (@i - 1)
	    set @j = DATEPART(yyyy , @tempDate)
	  End  
set @InvoiceProjYear = (select YEAR from(select *, ROW_NUMBER() over (order by id desc) as num from chisql12.fillhub.dbo.invoicemonth)Q where num=1)
set @InvoiceProjMonth = (select Month from(select *, ROW_NUMBER() over (order by id desc) as num from chisql12.fillhub.dbo.invoicemonth)Q where num=1)
set @InvoiceProjDate = 	CONVERT(varchar, @InvoiceProjMonth) + '/1/' + CONVERT(varchar, @InvoiceProjYear)  
	  
--End  -- end while
----select @i as LastInvoicedMonth

declare @lastInvoiceMonthDate smalldatetime  
set @lastInvoiceMonthDate = CONVERT(varchar, @i) + '/1/' + CONVERT(varchar, @j)
--set @FirstDayOfMonth = CONVERT(varchar, @Month) + '/1/' + CONVERT(varchar, @Year)

-- *****  End lastInvoiceMonth Caluclation  *******

/* Last Invoice Month Caluclation from ABS  - we will not use this any more per Mark)
-- get the last closed month (but not beyond the current month) fpr tx data
SELECT TOP 1 @TxMonth = Month, @TxYear = Year FROM licensing2.dbo.Invoice i
WHERE (SELECT COUNT(*) FROM licensing2.dbo.Invoice WHERE Month = i.Month AND Year = i.Year AND IsClosed = 0) = 0
--AND Year <= @Year AND Month <= @Month  ---jg oct 30 2009 removed  and replaced with line below - did not work correctly over year end 
AND convert(datetime,CONVERT(varchar,Month) + '/1/' + CONVERT(varchar,Year)) <= convert(datetime,CONVERT(varchar,@Month) + '/1/' + CONVERT(varchar,@Year)) 

ORDER BY Year DESC, Month DESC
*/

-- @lastInvoiceMonthLastDate is used for Invoice Projections
declare @lastInvoiceMonthLastDate smalldatetime  
set @lastInvoiceMonthLastDate = DATEADD(m, 1, @lastInvoiceMonthDate)
set @lastInvoiceMonthLastDate = DATEADD(d, -1, @lastInvoiceMonthLastDate)

declare @today smalldatetime
set @today =  CAST(GETDATE() as DATE )

If(@FirstDayOfMonth >= @lastInvoiceMonthDate)
Begin
  --set @tempDate = DATEADD(m, -1, @tempDate)
  --set @i = DATEPART(mm , @tempDate)  --  set @i = (@i - 1)
  --set @j = DATEPART(yyyy , @tempDate)
  set @qMonth = @i
  set @qYear = @j
  set @isProjection = 1  -- True, this is Projection
End Else 
Begin
  set @qMonth = @Month
  set @qYear = @Year
  set @isProjection = 0
End

/*
select @i as LastInvMonth , @j as LastInvYear, @Month as SelectedMonth
, @Year as SelectedYear, @qMonth as queryMonth , @qYear as queryYear
,  @isProjection as isProjection 
, @lastInvoiceMonthLastDate as LastInvMonthLastDate
*/

set @axDefaultDate = '1900-01-01 00:00:00.000'


Create Table #TrnxProjInVoiceMonth
(LineItemId varchar(50), Month int, Year Int,CrmId varchar(50), Productsku int, Accountid varchar(50),CustGroup varchar(50),BilledAmount Numeric(28,2), AdditionalInfo varchar(50),
Region varchar(50),City varchar(50),State varchar(50),Country varchar(50),BranchId varchar(50),Action varchar(5),LicenseCount int,BillableLicenseCount int, NonBillableLicenseCount int,
TTChangeType varchar(50),CreditReason varchar(50),TTLICENSEFILEID varchar(50), SalesType varchar(50),ConfigId varchar(10),DeliveryZipCode varchar(10),TTNOTES nvarchar(500),
TTBILLSTART datetime,TTBILLEND datetime,LineRecId bigint, SalesId varchar(50),tax money,TaxRate Real, TTUsage numeric(18,10), LineAmount Numeric(28,12),
TAXAMOUNT Numeric(28,12),TotalAmount Numeric(28,12),InvoiceId varchar(50),CREATEDDATETIME datetime,DELIVERYNAME varchar(60),TTDESCRIPTION varchar(250),
DataAreaId varchar(4),SalesPrice Numeric(28,12),ActiveBillableToday int,ActiveNonBillableToday int
,Productname varchar(50),PriceGroup varchar(100),TTCONVERSIONDATE datetime,Name varchar(50),
TTBillingOnBehalfOf varchar(10))
Insert into #TrnxProjInVoiceMonth
Select  distinct A.INVOICEID + ' - ' + convert(varchar,A.LineNum) + ' - ' +  convert(varchar, A.RECID) as LineItemId   --A.RecId as LineItemId  , +  ' - ' + CONVERT(varchar, RAND())
  , @Month as Month 
  , @Year as Year 
  , C.TTCRMID as CrmId , A.ITEMID as ProductSku , C.ACCOUNTNUM as AccountId , C.CUSTGROUP
  , Case when (A.DATAAREAID ='ttbr' and  A.CURRENCYCODE = 'BRL') then (A.LINEAMOUNT *  dbo.fnGetExchangeRt(A.DATAAREAID, A.INVOICEDATE, 'USD') ) --A.LINEAMOUNT as BilledAmount
         else A.LINEAMOUNT End as BilledAmount  
 , Case when  P.ProductCategoryId = 'RevGW' then (A.TTDLVNAME + ' (' + A.TTDESCRIPTION+')')
      Else A.TTDLVNAME  End as AdditionalInfo    
  , Case when E.TTSALESREGION = 1 Then 'Asia Pacific' 
         when E.TTSALESREGION = 2 Then 'Europe' when E.TTSALESREGION = 3 Then 'North America'
         when E.TTSALESREGION = 4  Then 'South America' Else 'None'   End 
         as Region
  , ISNULL(A.TTDLVCITY, 'Unassigned') as City 
  , case when A.DLVSTATE = '' Then 'Unassigned'   when A.DLVSTATE =  NULL Then 'Unassigned'    Else A.DLVSTATE  End      as State
  , case when A.DLVCOUNTRYREGIONID = '' Then 'Unassigned'   when A.DLVCOUNTRYREGIONID =  NULL Then 'Unassigned'    Else A.DLVCOUNTRYREGIONID  End      as Country  
   ,  ISNULL(A.DIMENSION3_, 'Unassigned') as BranchId       
  , ' ' as Action,  A.QTY as LicenseCount   
  , dbo.fnGetBillableQuantity( A.QTY , A.TTBILLSTART , A.TTBILLEND , @lastInvoiceMonthLastDate , @qYear, A.LINEAMOUNT ) as BillableLicenseCount  
  , dbo.fnGetNonBillableQuantity( A.QTY , A.TTBILLSTART , A.TTBILLEND , @lastInvoiceMonthLastDate , @qYear, A.LINEAMOUNT ) as NonBillableLicenseCount
  , A.TTCHANGETYPE 
  , A.PORT as CreditReason
  , A.TTLICENSEFILEID 
   , 'InvoiceProj' as SalesType 
   , '1' as ConfigId
   , A.TTDELIVERYZIPCODE as DeliveryZipCode , A.TTNOTES, A.TTBILLSTART , case when @Month >=month(getdate()) then '1900-01-01 00:00:00.000' else A.TTBILLEND end as TTBILLEND, A.RECID as LineRecId , A.SALESID --<Ram:07/29/2013:1700> Changed the TTBillend to be open ended for all the projection data
   , NULL as Tax, NULL as TaxRate, A.TTUSAGE   
   , A.LINEAMOUNT , A.TAXAMOUNT , (A.LINEAMOUNT + A.TAXAMOUNT) as TotalAmount
   , Null as InvoiceId, null as  CREATEDDATETIME , A.TTDLVNAME as DELIVERYNAME, A.TTDESCRIPTION
   , A.DATAAREAID , A.SALESPRICE   
   , dbo.fnGetBillableQuantity( A.QTY , A.TTBILLSTART , A.TTBILLEND , @today , @Year, A.LINEAMOUNT ) as ActiveBillableToday  
   , dbo.fnGetNonBillableQuantity( A.QTY , A.TTBILLSTART , A.TTBILLEND , @today , @Year, A.LINEAMOUNT ) as ActiveNonBillableToday,P.Productname, nullif(C.PriceGroup,'') as PriceGroup, TTCONVERSIONDATE
   ,pg.name,TTBillingOnBehalfOf
            
  from chiaxsql01.TT_DYANX09_PRD.dbo.CUSTINVOICETRANS A
  inner join  chiaxsql01.TT_DYANX09_PRD.dbo.CUSTINVOICEJOUR B
  on A.INVOICEID = B.INVOICEID and A.DATAAREAID = B.DATAAREAID
  inner join chiaxsql01.TT_DYANX09_PRD.dbo.CUSTTABLE C  -- for CustGroup
  on B.INVOICEACCOUNT = C.INVOICEACCOUNT and B.DATAAREAID  = c.DATAAREAID
  left join chiaxsql01.TT_DYANX09_PRD.dbo.TTLocationSalesRegionMapping E   -- left join, since location on line item is not a mandatory field
  on A.DIMENSION3_ = E.LOCATIONNUM
  left join chiaxsql01.apollo.dbo.Product P on A.ITEMID = P.ProductSku
     left join chiaxsql01.TT_DYANX09_PRD.dbo.PRICEDISCGROUP PG on PG.groupid=c.pricegroup

  where 
 (C.CUSTGROUP in ('Trnx SW','MultiBrokr') and A.ITEMID in ('20996', '20997', '20998', '20999', '10106','20005') ) -- Included ProductSku 20005 <Ram:06/24/2013>
  and DATEPART(mm, A.INVOICEDATE) = @qMonth 
  and  DATEPART(yyyy, A.INVOICEDATE) = @qYear
  and A.SALESID != ''  -- do not pull FTI Invoices
  and  A.salesid not in
( select distinct salesid from chiaxsql01.TT_DYANX09_PRD.dbo.CUSTINVOICEJOUR
where YEAR(invoicedate)=@Year and MONTH(invoicedate)=@Month
)


Create Table #TrnxProjPriorInVoiceMonth
(LineItemId varchar(50), Month int, Year Int,CrmId varchar(50), Productsku int, Accountid varchar(50),CustGroup varchar(50),BilledAmount Numeric(28,2), AdditionalInfo varchar(50),
Region varchar(50),City varchar(50),State varchar(50),Country varchar(50),BranchId varchar(50),Action varchar(5),LicenseCount int,BillableLicenseCount int, NonBillableLicenseCount int,
TTChangeType varchar(50),CreditReason varchar(50),TTLICENSEFILEID varchar(50), SalesType varchar(50),ConfigId varchar(10),DeliveryZipCode varchar(10),TTNOTES nvarchar(500),
TTBILLSTART datetime,TTBILLEND datetime,LineRecId bigint, SalesId varchar(50),tax money,TaxRate Real, TTUsage numeric(18,10), LineAmount Numeric(28,12),
TAXAMOUNT Numeric(28,12),TotalAmount Numeric(28,12),InvoiceId varchar(50),CREATEDDATETIME datetime,DELIVERYNAME varchar(60),TTDESCRIPTION varchar(250),
DataAreaId varchar(4),SalesPrice Numeric(28,12),ActiveBillableToday int,ActiveNonBillableToday int
,Productname varchar(50),PriceGroup varchar(100),TTCONVERSIONDATE datetime,Name varchar(50),
TTBillingOnBehalfOf varchar(10))
Insert into #TrnxProjPriorInVoiceMonth
Select  distinct A.INVOICEID + ' - ' + convert(varchar,A.LineNum) + ' - ' +  convert(varchar, A.RECID) as LineItemId   --A.RecId as LineItemId  , +  ' - ' + CONVERT(varchar, RAND())
  , @Month as Month 
  , @Year as Year 
  , C.TTCRMID as CrmId , A.ITEMID as ProductSku , C.ACCOUNTNUM as AccountId , C.CUSTGROUP
  , Case when (A.DATAAREAID ='ttbr' and  A.CURRENCYCODE = 'BRL') then (A.LINEAMOUNT *  dbo.fnGetExchangeRt(A.DATAAREAID, A.INVOICEDATE, 'USD') ) --A.LINEAMOUNT as BilledAmount
         else A.LINEAMOUNT End as BilledAmount  
 , Case when  P.ProductCategoryId = 'RevGW' then (A.TTDLVNAME + ' (' + A.TTDESCRIPTION+')')
      Else A.TTDLVNAME  End as AdditionalInfo    
  , Case when E.TTSALESREGION = 1 Then 'Asia Pacific' 
         when E.TTSALESREGION = 2 Then 'Europe' when E.TTSALESREGION = 3 Then 'North America'
         when E.TTSALESREGION = 4  Then 'South America' Else 'None'   End 
         as Region
  , ISNULL(A.TTDLVCITY, 'Unassigned') as City 
  , case when A.DLVSTATE = '' Then 'Unassigned'   when A.DLVSTATE =  NULL Then 'Unassigned'    Else A.DLVSTATE  End      as State
  , case when A.DLVCOUNTRYREGIONID = '' Then 'Unassigned'   when A.DLVCOUNTRYREGIONID =  NULL Then 'Unassigned'    Else A.DLVCOUNTRYREGIONID  End      as Country  
   ,  ISNULL(A.DIMENSION3_, 'Unassigned') as BranchId       
  , ' ' as Action,  A.QTY as LicenseCount   
  , dbo.fnGetBillableQuantity( A.QTY , A.TTBILLSTART , A.TTBILLEND , @lastInvoiceMonthLastDate , @qYear, A.LINEAMOUNT ) as BillableLicenseCount  
  , dbo.fnGetNonBillableQuantity( A.QTY , A.TTBILLSTART , A.TTBILLEND , @lastInvoiceMonthLastDate , @qYear, A.LINEAMOUNT ) as NonBillableLicenseCount
  , A.TTCHANGETYPE 
  , A.PORT as CreditReason
  , A.TTLICENSEFILEID 
   , 'InvoiceProj' as SalesType 
   , '1' as ConfigId
   , A.TTDELIVERYZIPCODE as DeliveryZipCode , A.TTNOTES, A.TTBILLSTART , case when @Month >=month(getdate()) then '1900-01-01 00:00:00.000' else A.TTBILLEND end as TTBILLEND, A.RECID as LineRecId , A.SALESID --<Ram:07/29/2013:1700> Changed the TTBillend to be open ended for all the projection data
   , NULL as Tax, NULL as TaxRate, A.TTUSAGE   
   , A.LINEAMOUNT , A.TAXAMOUNT , (A.LINEAMOUNT + A.TAXAMOUNT) as TotalAmount
   , Null as InvoiceId, null as  CREATEDDATETIME , A.TTDLVNAME as DELIVERYNAME, A.TTDESCRIPTION
   , A.DATAAREAID , A.SALESPRICE   
   , dbo.fnGetBillableQuantity( A.QTY , A.TTBILLSTART , A.TTBILLEND , @today , @Year, A.LINEAMOUNT ) as ActiveBillableToday  
   , dbo.fnGetNonBillableQuantity( A.QTY , A.TTBILLSTART , A.TTBILLEND , @today , @Year, A.LINEAMOUNT ) as ActiveNonBillableToday,P.Productname, nullif(C.PriceGroup,'') as PriceGroup, TTCONVERSIONDATE
   ,pg.name,TTBillingOnBehalfOf
            
  from chiaxsql01.TT_DYANX09_PRD.dbo.CUSTINVOICETRANS A
  inner join  chiaxsql01.TT_DYANX09_PRD.dbo.CUSTINVOICEJOUR B
  on A.INVOICEID = B.INVOICEID and A.DATAAREAID = B.DATAAREAID
  inner join chiaxsql01.TT_DYANX09_PRD.dbo.CUSTTABLE C  -- for CustGroup
  on B.INVOICEACCOUNT = C.INVOICEACCOUNT and B.DATAAREAID  = c.DATAAREAID
  left join chiaxsql01.TT_DYANX09_PRD.dbo.TTLocationSalesRegionMapping E   -- left join, since location on line item is not a mandatory field
  on A.DIMENSION3_ = E.LOCATIONNUM
  left join chiaxsql01.apollo.dbo.Product P on A.ITEMID = P.ProductSku
     left join chiaxsql01.TT_DYANX09_PRD.dbo.PRICEDISCGROUP PG on PG.groupid=c.pricegroup

  where 
 (C.CUSTGROUP in ('Trnx SW','MultiBrokr') and A.ITEMID in ('20996', '20997', '20998', '20999', '10106','20005') ) -- Included ProductSku 20005 <Ram:06/24/2013>
  and DATEPART(mm, A.INVOICEDATE) = @InvoiceProjMonth 
  and  DATEPART(yyyy, A.INVOICEDATE) = @InvoiceProjYear
  and A.SALESID != ''  -- do not pull FTI Invoices
  and  A.salesid not in
( select distinct salesid from chiaxsql01.TT_DYANX09_PRD.dbo.CUSTINVOICEJOUR
where YEAR(invoicedate)=@Year and MONTH(invoicedate)=@Month
)


Create Table #SalesProj
(LineItemId varchar(50), Month int, Year Int,CrmId varchar(50), Productsku int, Accountid varchar(50),CustGroup varchar(50),BilledAmount Numeric(28,2), AdditionalInfo varchar(50),
Region varchar(50),City varchar(50),State varchar(50),Country varchar(50),BranchId varchar(50),Action varchar(5),LicenseCount int,BillableLicenseCount int, NonBillableLicenseCount int,
TTChangeType varchar(50),CreditReason varchar(50),TTLICENSEFILEID varchar(50), SalesType varchar(50),ConfigId varchar(10),DeliveryZipCode varchar(10),TTNOTES nvarchar(500),
TTBILLSTART datetime,TTBILLEND datetime,LineRecId bigint, SalesId varchar(50),tax money,TaxRate Real, TTUsage numeric(18,10), LineAmount Numeric(28,12),
TAXAMOUNT Numeric(28,12),TotalAmount Numeric(28,12),InvoiceId varchar(50),CREATEDDATETIME datetime,DELIVERYNAME varchar(60),TTDESCRIPTION varchar(250),
DataAreaId varchar(4),SalesPrice Numeric(28,12),ActiveBillableToday int,ActiveNonBillableToday int
,Productname varchar(50),PriceGroup varchar(100),TTCONVERSIONDATE datetime,Name varchar(50),
TTBillingOnBehalfOf varchar(10))
Insert into #SalesProj

select distinct A.SALESID + ' - ' + convert(varchar,A.LineNum)   + ' - ' +  convert(varchar, A.RECID) as LineItemId   -- +  ' - ' + CONVERT(varchar, RAND())
 , @Month as Month --DATEPART(mm, A.INVOICEDATE) as Month 
 , @Year as Year -- DATEPART(yyyy , A.InvoiceDate) as Year
 , C.TTCRMID as CrmId , A.ITEMID as ProductSku, C.ACCOUNTNUM as AccountId, C.CUSTGROUP
  --, A.LineAmount * ( dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) ) as BilledAmount 
  /*
 , (  (A.SalesQty * ( dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) ) ) 
     * ( (A.SALESPRICE/A.PRICEUNIT) - A.LINEDISC )
        ) * A.LINEPERCENT  as BilledAmount
        */
 , dbo.fnGetLineAmount(A.SALESQTY, A.TTBACKUPSALESQTY , A.SALESPRICE, A.PRICEUNIT, A.LINEDISC, A.TTLINEDISCOUNT, A.LINEPERCENT      
      , dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) ) as BilledAmount
      --, 1.00 ) as BilledAmount
 , case when  P.ProductCategoryId = 'RevGW' then (A.DELIVERYNAME + ' (' + A.TTDESCRIPTION+')')
      Else A.DELIVERYNAME  End as AdditionalInfo 
 --, ISNULL(E.TTSALESREGION , 'Unassigned') as Region 
   , Case when E.TTSALESREGION = 1 Then 'Asia Pacific' 
         when E.TTSALESREGION = 2 Then 'Europe' when E.TTSALESREGION = 3 Then 'North America'
         when E.TTSALESREGION = 4  Then 'South America' When E.TTSALESREGION = 0 Then 'None'  Else 'Unassigned'  End 
         as Region
 , ISNULL(A.DELIVERYCITY, 'Unassigned') as City , ISNULL(A.DELIVERYSTATE, 'Unassigned') as State
 , isNULL(A.DELIVERYCOUNTRYREGIONID, 'Unassigned') as Country , ISNULL(A.DIMENSION3_, 'Unassigned') as BranchId       
 , ' ' as Action
 --,  A.SALESQTY as LicenseCount     
 , CASE When ISNULL(A.SalesQty, 0) > 0 Then A.SALESQTY
        when ( ISNULL(A.SalesQty, 0) = 0 and ISNULL(A.TTBACKUPSALESQTY, 0) > 0) Then A.TTBACKUPSALESQTY
        Else 1 End as LicenseCount
 , dbo.fnGetBillableQuantity( A.SalesQty , A.TTBILLSTART , A.TTBILLEND , @LastDayOfMonth , @Year
      ,  dbo.fnGetLineAmount(A.SALESQTY, A.TTBACKUPSALESQTY , A.SALESPRICE, A.PRICEUNIT, A.LINEDISC, A.TTLINEDISCOUNT, A.LINEPERCENT      
      , dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) )
       ) as BillableLicenseCount  

, dbo.fnGetNonBillableQuantity( A.SalesQty , A.TTBILLSTART , A.TTBILLEND , @LastDayOfMonth , @Year
      ,  dbo.fnGetLineAmount(A.SALESQTY, A.TTBACKUPSALESQTY , A.SALESPRICE, A.PRICEUNIT, A.LINEDISC, A.TTLINEDISCOUNT, A.LINEPERCENT      
      , dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) )
       ) as NonBillableLicenseCount       
, A.TTCHANGETYPE 
/*, Case when A.TTREASONCODE = 0 Then 'None'  when A.TTREASONCODE = 1 Then 'New Product'   when A.TTREASONCODE = 2 Then 'Upgrade' 
     When A.TTREASONCODE = 3 Then 'Downgrade'  When A.TTREASONCODE = 4 Then 'Transfer' When A.TTREASONCODE = 6 Then 'Cancellation' End as ReasonCode     */
, A.PORT as CreditReason
, A.TTLICENSEFILEID 
   , 'InvoiceProj' as SalesType 
   , '1' as ConfigId
 , A.DELIVERYZIPCODE as DeliveryZipCode , A.TTNOTES, A.TTBILLSTART , A.TTBILLEND , A.RECID as LineRecId, A.SALESID
-- , chiaxsql01.TT_DYANX09_PRD.dbo.fn_TTGetAvaTax(A.SalesId, A.RecId) as Tax
--  , chiaxsql01.TT_DYANX09_PRD.dbo.fn_TTGetAvaTaxRate(A.SalesId, A.RecId) as TaxRate
 , NULL as Tax, NULL as TaxRate, A.TTUSAGE 
 , NULL LINEAMOUNT , NULL as TAXAMOUNT , NULL as TotalAmount
 , Null as InvoiceId, A.CREATEDDATETIME , A.DELIVERYNAME, A.TTDESCRIPTION
 , A.DATAAREAID , A.SALESPRICE
 
 , dbo.fnGetBillableQuantity( A.SalesQty , A.TTBILLSTART , A.TTBILLEND , @today , @Year
      ,  dbo.fnGetLineAmount(A.SALESQTY, A.TTBACKUPSALESQTY , A.SALESPRICE, A.PRICEUNIT, A.LINEDISC, A.TTLINEDISCOUNT, A.LINEPERCENT      
      , dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) )
       ) as ActiveBillableToday  

, dbo.fnGetNonBillableQuantity( A.SalesQty , A.TTBILLSTART , A.TTBILLEND , @today , @Year
      ,  dbo.fnGetLineAmount(A.SALESQTY, A.TTBACKUPSALESQTY , A.SALESPRICE, A.PRICEUNIT, A.LINEDISC, A.TTLINEDISCOUNT, A.LINEPERCENT      
      , dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) )
       ) as ActiveNonBillableToday,P.Productname, nullif(C.PriceGroup,'') as PriceGroup, TTCONVERSIONDATE
   ,pg.name,TTBillingOnBehalfOf      
 
 from chiaxsql01.TT_DYANX09_PRD.dbo.SALESLINE A
 inner join chiaxsql01.TT_DYANX09_PRD.dbo.SALESTABLE B
 on  A.SALESID = B.SALESID and A.DATAAREAID = B.DATAAREAID
 inner join chiaxsql01.TT_DYANX09_PRD.dbo.CUSTTABLE C
 on B.INVOICEACCOUNT = C.INVOICEACCOUNT and B.DATAAREAID = c.DATAAREAID
 left join chiaxsql01.TT_DYANX09_PRD.dbo.TTLocationSalesRegionMapping E   -- left join, since location on line item is not a mandatory field
 on A.DIMENSION3_ = E.LOCATIONNUM
 inner join chiaxsql01.TT_DYANX09_PRD.dbo.INVENTDIM F
 on A.INVENTDIMID = F.INVENTDIMID and A.DATAAREAID = F.DATAAREAID
 left join chiaxsql01.apollo.dbo.Product P on A.ITEMID = P.ProductSku
   left join chiaxsql01.TT_DYANX09_PRD.dbo.PRICEDISCGROUP PG on PG.groupid=c.pricegroup
 where  
 @isProjection = 1  and 
 A.SALESSTATUS = 1 -- 1 corresponds 'Open Order' Line status
 and (A.TTBILLSTART = @axDefaultDate  or A.TTBILLSTART <= @LastDayOfMonth)
 and (A.TTBILLEND = @axDefaultDate or A.TTBILLEND >= @FirstDayOfMonth) 
 --and C.CUSTGROUP =  'TTNETHost' --  'Subscribe' , TTNETHost is temporary
and A.ITEMID in ('20996', '20997', '20998', '20999', '10106','20005')-- Included ProductSku 20005 <Ram:06/24/2013>
--and A.SALESID != ''
and  A.salesid not in
( select distinct salesid from chiaxsql01.TT_DYANX09_PRD.dbo.CUSTINVOICEJOUR
where YEAR(invoicedate)=@Year and MONTH(invoicedate)=@Month
)


DELETE chisql12.bidw.dbo.MonthlyBillingData
WHERE Month = @Month AND Year = @Year
INSERT INTO chisql12.bidw.dbo.MonthlyBillingData

select  id,
		Month, 
		Year, 		
		CrmId,
		AccountId,
		 ExchangeId,
		CustGroup,
		PriceGroup,
		PriceGroupDesc,
		--AccountName, 
		ProductSku, 
		--ProductName, 
		--ProductCategoryId, 
		--ProductCategoryName,
			BilledAmount, 
		AdditionalInfo, 
		Region,
		[city],
		[State], 
		Country, 
		BranchId, 
		[Action], 
			LicenseCount,  
			case when productsku in ('20996', '20997', '20998', '20999', '10106','20005')
			then case when ConcatenatedName Is null then 0 
                      when ROW_NUMBER() over (PARTITION By ConcatenatedName Order By id,ConcatenatedName ASC)=1 then 1
                      else 0 end
             else 
             BillableLicenseCount end as BillableLicenseCount, 
			NonBillableLicenseCount , TTCHANGETYPE, CreditReason, TTLICENSEFILEID
			, SalesType, ConfigId, DeliveryZipCode, TTNotes, TTBillStart, TTBillEnd, LineRecId, SALESID, Tax, TaxRate, TTUSAGE
			, LINEAMOUNT , TAXAMOUNT , TotalAmount , INVOICEID, CREATEDDATETIME , DELIVERYNAME, TTDESCRIPTION,TTCONVERSIONDATE, DATAAREAID, SALESPRICE
			, ActiveBillableToday, ActiveNonBillableToday,GETDATE() as LastUpdatedDate,TTBillingOnBehalfOf from --<Ram 02/10/2014 19:15> Added Logic to Handle Duplicate License Counts for Transaction Products
(

select  id,
		Month, 
		Year, 		
		CrmId,
		AccountId,
		isnull(E.ExchangeId,0) as ExchangeId,
		CustGroup,
		PriceGroup,
		PriceDescription as PriceGroupDesc,
		--AccountName, 
		NP.ProductSku, 
		--ProductName, 
		--ProductCategoryId, 
		--ProductCategoryName,
			BilledAmount, 
		AdditionalInfo, 
		Region,
		[city],
		[State], 
		Country, 
		BranchId, 
		[Action], 
			LicenseCount,  BillableLicenseCount, NonBillableLicenseCount , TTCHANGETYPE, CreditReason, TTLICENSEFILEID
			, SalesType, ConfigId, DeliveryZipCode, TTNotes, TTBillStart, TTBillEnd, LineRecId, SALESID, Tax, TaxRate, TTUSAGE
			, LINEAMOUNT , TAXAMOUNT , TotalAmount , INVOICEID, CREATEDDATETIME , DELIVERYNAME, TTDESCRIPTION,TTCONVERSIONDATE, DATAAREAID, SALESPRICE
			, ActiveBillableToday, ActiveNonBillableToday,GETDATE() as LastUpdatedDate,TTBillingOnBehalfOf --<Ram 01/22/2014 13:15> Added TTBillingOnBehalfOf field as per Jira BI-75
,  CAST(Year AS CHAR)+'-'+CAST(MONTH as char)+cast(AccountId as CHAR)+'-'+cast(NP.ProductSku as CHAR)+'-'+cast(TTDESCRIPTION as CHAR)+'-' as ConcatenatedName --<Ram 02/10/2014 19:15> Added Logic to Handle Duplicate License Counts for Transaction Products
from
(
	SELECT 
		LineItemId as id,
		Month, 
		Year, 		
		CrmId,
		AccountId,
		CustGroup,
		PriceGroup,
		isnull(name,'No Price Group' ) as PriceDescription,
		--AccountName, 
		convert(int,ProductSku) as ProductSku, 
		--ProductName, 
		--ProductCategoryId, 
		--ProductCategoryName,
			BilledAmount, 
		AdditionalInfo, 
		Region,
		[city],
		[State], 
		Country, 
		BranchId, 
		[Action], 
			LicenseCount,  BillableLicenseCount, NonBillableLicenseCount , TTCHANGETYPE, CreditReason, TTLICENSEFILEID
			, SalesType, ConfigId, DeliveryZipCode, TTNotes, TTBillStart, TTBillEnd, LineRecId, SALESID, Tax, TaxRate, TTUSAGE
			, LINEAMOUNT , TAXAMOUNT , TotalAmount , INVOICEID, CREATEDDATETIME , DELIVERYNAME, TTDESCRIPTION,TTCONVERSIONDATE, DATAAREAID, SALESPRICE
			, ActiveBillableToday, ActiveNonBillableToday,Productname,TTBillingOnBehalfOf
	FROM (

-- AX Invoice data, good for non-projection case
Select  A.INVOICEID + ' - ' + convert(varchar,A.LineNum) + ' - ' +  convert(varchar, A.RECID) as LineItemId   --A.RecId as LineItemId  , +  ' - ' + CONVERT(varchar, RAND())
  , @Month as Month --DATEPART(mm, A.INVOICEDATE) as Month 
  , @Year as Year -- DATEPART(yyyy , A.InvoiceDate) as Year
  , C.TTCRMID as CrmId , A.ITEMID as ProductSku , C.ACCOUNTNUM as AccountId , C.CUSTGROUP
  , Case when (A.DATAAREAID ='ttbr' and  A.CURRENCYCODE = 'BRL') then (A.LINEAMOUNT *  dbo.fnGetExchangeRt(A.DATAAREAID, A.INVOICEDATE, 'USD') ) --A.LINEAMOUNT as BilledAmount
         else A.LINEAMOUNT End as BilledAmount
 , Case when  P.ProductCategoryId = 'RevGW' then (A.TTDLVNAME + ' (' + A.TTDESCRIPTION+')')
      Else A.TTDLVNAME  End as AdditionalInfo    
   --,' ' as Region,  ' ' as City , ' ' as State,  ' ' as Country ,  1 as BranchId
  --, E.TTSALESREGION as Region   
  , Case when E.TTSALESREGION = 1 Then 'Asia Pacific' 
         when E.TTSALESREGION = 2 Then 'Europe' when E.TTSALESREGION = 3 Then 'North America'
         when E.TTSALESREGION = 4  Then 'South America' Else 'None'   End 
         as Region
  , ISNULL(A.TTDLVCITY, 'Unassigned') as City 
  , case when A.DLVSTATE = '' Then 'Unassigned'   when A.DLVSTATE =  NULL Then 'Unassigned'    Else A.DLVSTATE  End      as State
  , case when A.DLVCOUNTRYREGIONID = '' Then 'Unassigned'   when A.DLVCOUNTRYREGIONID =  NULL Then 'Unassigned'    Else A.DLVCOUNTRYREGIONID  End      as Country  
   ,  ISNULL(A.DIMENSION3_, 'Unassigned') as BranchId       
  , ' ' as Action,  A.QTY as LicenseCount   
  , dbo.fnGetBillableQuantity( A.QTY , A.TTBILLSTART , A.TTBILLEND , @LastDayOfMonth , @Year, A.LINEAMOUNT ) as BillableLicenseCount  
  , dbo.fnGetNonBillableQuantity( A.QTY , A.TTBILLSTART , A.TTBILLEND , @LastDayOfMonth , @Year, A.LINEAMOUNT ) as NonBillableLicenseCount
  , A.TTCHANGETYPE 
  /*, Case when A.TTREASONCODE = 0 Then 'None'  when A.TTREASONCODE = 1 Then 'New Product'   when A.TTREASONCODE = 2 Then 'Upgrade'
     When A.TTREASONCODE = 3 Then 'Downgrade'  When A.TTREASONCODE = 4 Then 'Transfer' When A.TTREASONCODE = 6 Then 'Cancellation' End as ReasonCode     */
  , A.PORT as CreditReason
  , A.TTLICENSEFILEID 
   , 'Invoice' as SalesType 
   , '1' as ConfigId
   , A.TTDELIVERYZIPCODE as DeliveryZipCode , A.TTNOTES, A.TTBILLSTART , A.TTBILLEND , A.RECID as LineRecId, A.SALESID
   , NULL as Tax, NULL as TaxRate, A.TTUSAGE
   , A.LINEAMOUNT , A.TAXAMOUNT , (A.LINEAMOUNT + A.TAXAMOUNT) as TotalAmount
   , A.INVOICEID, null as  CREATEDDATETIME , A.TTDLVNAME as DELIVERYNAME, A.TTDESCRIPTION
   , A.DATAAREAID , A.SALESPRICE 
   , dbo.fnGetBillableQuantity( A.QTY , A.TTBILLSTART , A.TTBILLEND , @today , @Year, A.LINEAMOUNT ) as ActiveBillableToday  
   , dbo.fnGetNonBillableQuantity( A.QTY , A.TTBILLSTART , A.TTBILLEND , @today , @Year, A.LINEAMOUNT ) as ActiveNonBillableToday
   ,P.Productname
   , nullif(C.PriceGroup,'') as PriceGroup
   , TTCONVERSIONDATE
   ,pg.name,TTBillingOnBehalfOf
   
            
  from chiaxsql01.TT_DYANX09_PRD.dbo.CUSTINVOICETRANS A
  inner join  chiaxsql01.TT_DYANX09_PRD.dbo.CUSTINVOICEJOUR B
  on A.INVOICEID = B.INVOICEID and A.DATAAREAID = B.DATAAREAID
  inner join chiaxsql01.TT_DYANX09_PRD.dbo.CUSTTABLE C  -- for CustGroup
  on B.INVOICEACCOUNT = C.INVOICEACCOUNT and B.DATAAREAID  = c.DATAAREAID
  --inner join chiaxsql01.TT_DYANX09_PRD.dbo.SALESLINE D  -- StartDate and EndDate  (decide left or inner ) inner - ignore FTI based invoice data
  --on B.SALESID = D.SALESID and B.DATAAREAID = D.DATAAREAID and A.LINENUM = D.LINENUM  and A.ITEMID = D.ITEMID
  left join chiaxsql01.TT_DYANX09_PRD.dbo.TTLocationSalesRegionMapping E   -- left join, since location on line item is not a mandatory field
  on A.DIMENSION3_ = E.LOCATIONNUM
  left join chiaxsql01.apollo.dbo.Product P on A.ITEMID = P.ProductSku
  left join chiaxsql01.TT_DYANX09_PRD.dbo.PRICEDISCGROUP PG on PG.groupid=c.pricegroup

  where 
  --@isProjection = 0 and 
  DATEPART(mm, A.INVOICEDATE) = @Month 
  and  DATEPART(yyyy, A.INVOICEDATE) = @year
  --and A.SALESID != ''  -- do not pull FTI Invoices
--  and  A.salesid not in
--( select distinct salesid from chiaxsql01.TT_DYANX09_PRD.dbo.CUSTINVOICEJOUR
--where YEAR(invoicedate)=@currYear and MONTH(invoicedate)=@currMonth
--)
  --and C.CUSTGROUP =  'TTNETHost' --  'Subscribe' , TTNETHost is temporary
  /* and (@isProjection = 0   or
 (D.TTBILLSTART = @axDefaultDate  or D.TTBILLSTART <= @LastDayOfMonth)
	and (D.TTBILLEND = @axDefaultDate or D.TTBILLEND >= @FirstDayOfMonth)
  )	 */  
  
  
  Union 
  
  -- AX SO data , good for projections case
select A.SALESID + ' - ' + convert(varchar,A.LineNum)   + ' - ' +  convert(varchar, A.RECID) as LineItemId   -- +  ' - ' + CONVERT(varchar, RAND())
 , @Month as Month --DATEPART(mm, A.INVOICEDATE) as Month 
 , @Year as Year -- DATEPART(yyyy , A.InvoiceDate) as Year
 , C.TTCRMID as CrmId , A.ITEMID as ProductSku, C.ACCOUNTNUM as AccountId, C.CUSTGROUP
  --, A.LineAmount * ( dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) ) as BilledAmount 
  /*
 , (  (A.SalesQty * ( dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) ) ) 
     * ( (A.SALESPRICE/A.PRICEUNIT) - A.LINEDISC )
        ) * A.LINEPERCENT  as BilledAmount
        */
 , dbo.fnGetLineAmount(A.SALESQTY, A.TTBACKUPSALESQTY , A.SALESPRICE, A.PRICEUNIT, A.LINEDISC, A.TTLINEDISCOUNT, A.LINEPERCENT      
      , dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) ) as BilledAmount
      --, 1.00 ) as BilledAmount
 , case when  P.ProductCategoryId = 'RevGW' then (A.DELIVERYNAME + ' (' + A.TTDESCRIPTION+')')
      Else A.DELIVERYNAME  End as AdditionalInfo 
 --, ISNULL(E.TTSALESREGION , 'Unassigned') as Region 
   , Case when E.TTSALESREGION = 1 Then 'Asia Pacific' 
         when E.TTSALESREGION = 2 Then 'Europe' when E.TTSALESREGION = 3 Then 'North America'
         when E.TTSALESREGION = 4  Then 'South America' When E.TTSALESREGION = 0 Then 'None'  Else 'Unassigned'  End 
         as Region
 , ISNULL(A.DELIVERYCITY, 'Unassigned') as City , ISNULL(A.DELIVERYSTATE, 'Unassigned') as State
 , isNULL(A.DELIVERYCOUNTRYREGIONID, 'Unassigned') as Country , ISNULL(A.DIMENSION3_, 'Unassigned') as BranchId       
 , ' ' as Action
 --,  A.SALESQTY as LicenseCount     
 , CASE When ISNULL(A.SalesQty, 0) > 0 Then A.SALESQTY
        when ( ISNULL(A.SalesQty, 0) = 0 and ISNULL(A.TTBACKUPSALESQTY, 0) > 0) Then A.TTBACKUPSALESQTY
        Else 1 End as LicenseCount
 , dbo.fnGetBillableQuantity( A.SalesQty , A.TTBILLSTART , A.TTBILLEND , @LastDayOfMonth , @Year
      ,  dbo.fnGetLineAmount(A.SALESQTY, A.TTBACKUPSALESQTY , A.SALESPRICE, A.PRICEUNIT, A.LINEDISC, A.TTLINEDISCOUNT, A.LINEPERCENT      
      , dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) )
       ) as BillableLicenseCount  

, dbo.fnGetNonBillableQuantity( A.SalesQty , A.TTBILLSTART , A.TTBILLEND , @LastDayOfMonth , @Year
      ,  dbo.fnGetLineAmount(A.SALESQTY, A.TTBACKUPSALESQTY , A.SALESPRICE, A.PRICEUNIT, A.LINEDISC, A.TTLINEDISCOUNT, A.LINEPERCENT      
      , dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) )
       ) as NonBillableLicenseCount       
, A.TTCHANGETYPE 
/*, Case when A.TTREASONCODE = 0 Then 'None'  when A.TTREASONCODE = 1 Then 'New Product'   when A.TTREASONCODE = 2 Then 'Upgrade' 
     When A.TTREASONCODE = 3 Then 'Downgrade'  When A.TTREASONCODE = 4 Then 'Transfer' When A.TTREASONCODE = 6 Then 'Cancellation' End as ReasonCode     */
, A.PORT as CreditReason
, A.TTLICENSEFILEID 
, 'Sales Lines' as SalesType
 --, CASE when A.SALESTYPE = 2 Then 'Subscription'
 --      when A.SALESTYPE = 3 Then 'Sales Order' END as SalesType
 , F.CONFIGID
 , A.DELIVERYZIPCODE as DeliveryZipCode , A.TTNOTES, A.TTBILLSTART , A.TTBILLEND , A.RECID as LineRecId, A.SALESID
-- , chiaxsql01.TT_DYANX09_PRD.dbo.fn_TTGetAvaTax(A.SalesId, A.RecId) as Tax
--  , chiaxsql01.TT_DYANX09_PRD.dbo.fn_TTGetAvaTaxRate(A.SalesId, A.RecId) as TaxRate
 , NULL as Tax, NULL as TaxRate, A.TTUSAGE 
 , NULL LINEAMOUNT , NULL as TAXAMOUNT , NULL as TotalAmount
 , Null as InvoiceId, A.CREATEDDATETIME , A.DELIVERYNAME, A.TTDESCRIPTION
 , A.DATAAREAID , A.SALESPRICE
 
 , dbo.fnGetBillableQuantity( A.SalesQty , A.TTBILLSTART , A.TTBILLEND , @today , @Year
      ,  dbo.fnGetLineAmount(A.SALESQTY, A.TTBACKUPSALESQTY , A.SALESPRICE, A.PRICEUNIT, A.LINEDISC, A.TTLINEDISCOUNT, A.LINEPERCENT      
      , dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) )
       ) as ActiveBillableToday  

, dbo.fnGetNonBillableQuantity( A.SalesQty , A.TTBILLSTART , A.TTBILLEND , @today , @Year
      ,  dbo.fnGetLineAmount(A.SALESQTY, A.TTBACKUPSALESQTY , A.SALESPRICE, A.PRICEUNIT, A.LINEDISC, A.TTLINEDISCOUNT, A.LINEPERCENT      
      , dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) )
       ) as ActiveNonBillableToday,P.Productname, nullif(C.PriceGroup,'') as PriceGroup, TTCONVERSIONDATE
   ,pg.name,TTBillingOnBehalfOf      
 
 from chiaxsql01.TT_DYANX09_PRD.dbo.SALESLINE A
 inner join chiaxsql01.TT_DYANX09_PRD.dbo.SALESTABLE B
 on  A.SALESID = B.SALESID and A.DATAAREAID = B.DATAAREAID
 inner join chiaxsql01.TT_DYANX09_PRD.dbo.CUSTTABLE C
 on B.INVOICEACCOUNT = C.INVOICEACCOUNT and B.DATAAREAID = c.DATAAREAID
 left join chiaxsql01.TT_DYANX09_PRD.dbo.TTLocationSalesRegionMapping E   -- left join, since location on line item is not a mandatory field
 on A.DIMENSION3_ = E.LOCATIONNUM
 inner join chiaxsql01.TT_DYANX09_PRD.dbo.INVENTDIM F
 on A.INVENTDIMID = F.INVENTDIMID and A.DATAAREAID = F.DATAAREAID
 left join chiaxsql01.apollo.dbo.Product P on A.ITEMID = P.ProductSku
   left join chiaxsql01.TT_DYANX09_PRD.dbo.PRICEDISCGROUP PG on PG.groupid=c.pricegroup
 where  
 @isProjection = 1  and 
 A.SALESSTATUS = 1 -- 1 corresponds 'Open Order' Line status
 and (A.TTBILLSTART = @axDefaultDate  or A.TTBILLSTART <= @LastDayOfMonth)
 and (A.TTBILLEND = @axDefaultDate or A.TTBILLEND >= @FirstDayOfMonth) 
 --and C.CUSTGROUP =  'TTNETHost' --  'Subscribe' , TTNETHost is temporary
and A.ITEMID not in ('20996', '20997', '20998', '20999', '10106','20005')-- Included ProductSku 20005 <Ram:06/24/2013>
and C.Custgroup not in ('RevRoyalty','Credits','RevNote','RevAdminHK','','RevAllctd','AllctdRev') --- Added not to project these ItemGroups Data
and  A.salesid not in
( select distinct salesid from chiaxsql01.TT_DYANX09_PRD.dbo.CUSTINVOICEJOUR
where YEAR(invoicedate)=@Year and MONTH(invoicedate)=@Month
)

Union
 
Select * from #SalesProj
-----------------------------
 --Projection data from InvoiceLines for Transactional Software customers (Trnx SW)
union

select * from
(
Select * from #TrnxProjInVoiceMonth
union 
select * from #TrnxProjPriorInVoiceMonth
)Q
where Salesid not in
(
select distinct salesid 
from
(
Select * from #SalesProj
)Q1
)

 ) BillingData
 )NP
 left outer join 
 (
 select a.*, b.* from
(
select ProductSku, rtrim(replace(ProductName,'Gateway',''))as Productname, ProductCategoryId, ProductCategoryName from dbo.Product
--where ProductName like 'CME%'
)a
join
(
select * from dbo.Exchange
--where exchangeshortname ='CME'
)b 
on a.Productname=b.ExchangeFlavor
)E
 on NP.ProductSku=E.productsku and rtrim(replace(NP.ProductName,'Gateway',''))=E.Productname
)Final
where ProductSku<>0


--select @FirstDayOfMonth as FirstDayOfMonth, 
-- @LastDayOfMonth as LastDayOfMonth,
-- @FirstDayOfNextMonth as FirstDayOfNextMonth,
-- @qMonth as qMonth ,
-- @qYear as qYear,
-- @axDefaultDate as axDefaultDate, 
-- @DaysInMonth as DaysInMonth	,
-- @LastMonth as LastMonth,
-- @currMonth as currMonth,
-- @currYear as currYear,
-- @currentMonthDate as currentMonthDate,
-- @tempDate as tempDate,
-- @lastInvoiceMonthLastDate as lastInvoiceMonthLastDate ,
-- @today  as today,
--@FirstDayOfMonth as FirstDayOfMonth,
-- @lastInvoiceMonthDate as lastInvoiceMonthDate,
-- @invoiceprojyear,
-- @invoiceprojmonth
 
drop table #TrnxProjInVoiceMonth
drop table #TrnxProjPriorInVoiceMonth
drop table #SalesProj


---------------------------------------Update Credit BillableLicensecounts to -1 <Ram 3/10/2014> 11:42--------------------------------------------
update A
set BillableLicenseCount=LicenseCount
from MonthlyBillingData A
left join Product P
on A.ProductSku=p.ProductSku
Where ProductName like 'Credit%' --<Ram 5/14/2014> Updated to See Credits in Sales Metrics
--where ProductCategoryName ='Credits'
and BillableLicenseCount=0

---------------------------------------------------------------------------------------------------------------------------------

