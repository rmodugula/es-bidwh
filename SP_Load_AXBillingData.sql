USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_Load_AXBillingData]    Script Date: 3/20/2017 4:13:09 PM ******/
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
Declare @TransPriorProj int

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
declare @lastinvoicemonth int, @lastinvoiceyear int  
-- ****  End Variables used only for LastInvoice Calc  ****


-- *****  lastInvoiceMonth Caluclation  *******
set @currMonth = DATEPART(mm, Getdate())
set @currYear = DATEPART(yyyy , Getdate())
set @currentMonthDate = CONVERT(varchar, @currMonth) + '/1/' + CONVERT(varchar, @currYear)
set @tempDate = @currentMonthDate
set @lastinvoicemonth = (select Month from (select *,row_number() over (order by id desc) as row from fillhub.dbo.InvoiceMonth)Q where ROW=1)
set @lastinvoiceyear = (select YEAR from (select *,row_number() over (order by id desc) as row from fillhub.dbo.InvoiceMonth)Q where ROW=1)

set @i = @currMonth
set @j = @currYear
set @totalInvoices = 0

   IF (select COUNT(*) from chisql12.fillhub.dbo.invoicemonth  
 where YEAR=@Year AND MONTH =@Month) =0
	  Begin
	    set @tempDate = DATEADD(m, -1, @tempDate)
	    set @i = DATEPART(mm , @tempDate)  --  set @i = (@i - 1)
	    set @j = DATEPART(yyyy , @tempDate)
	    --set @i = @lastinvoicemonth  --  set @i = (@i - 1)
	    --set @j = @lastinvoiceyear
	  End  
	  
	  
set @InvoiceProjYear = (select YEAR from(select *, ROW_NUMBER() over (order by id desc) as num from chisql12.fillhub.dbo.invoicemonth)Q where num=1)
set @InvoiceProjMonth = (select Month from(select *, ROW_NUMBER() over (order by id desc) as num from chisql12.fillhub.dbo.invoicemonth)Q where num=1)
set @InvoiceProjDate = 	CONVERT(varchar, @InvoiceProjMonth) + '/1/' + CONVERT(varchar, @InvoiceProjYear)  
	  
--End  -- end while
----select @i as LastInvoicedMonth

declare @lastInvoiceMonthDate smalldatetime  
--set @lastInvoiceMonthDate = CONVERT(varchar, @i) + '/1/' + CONVERT(varchar, @j)
set @lastInvoiceMonthDate = CONVERT(varchar, @lastinvoicemonth) + '/1/' + CONVERT(varchar, @lastinvoiceyear)
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

If(@FirstDayOfMonth >@lastInvoiceMonthDate)
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
------------------------------<Ram 6/6/2014> Updated code To only Load Invoice Projections from prior month once the data is loaded from FillHub to AX monthly-----------------
--set @InvoiceProjYear = case when (select COUNT(*) from CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.CUSTINVOICETRANS 
--where YEAR(invoicedate)=@qYear and MONTH(invoicedate)=@qMonth
--and itemid in (20997,20999,20005,20996,20998,10106))>0 then @qYear
--else (select YEAR from(select *, ROW_NUMBER() over (order by id desc) as num from chisql12.fillhub.dbo.invoicemonth)Q where num=1) End
--set @InvoiceProjMonth = case when (select COUNT(*) from CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.CUSTINVOICETRANS 
--where YEAR(invoicedate)=@qYear and MONTH(invoicedate)=@qMonth
--and itemid in (20997,20999,20005,20996,20998,10106))>0 then @qMonth else
--(select Month from(select *, ROW_NUMBER() over (order by id desc) as num from chisql12.fillhub.dbo.invoicemonth)Q where num=1) End
--set @InvoiceProjDate = 	CONVERT(varchar, @InvoiceProjMonth) + '/1/' + CONVERT(varchar, @InvoiceProjYear)  
Set @TransPriorProj= case when (select COUNT(*) from CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.CUSTINVOICETRANS
where YEAR(invoicedate)=@qYear and MONTH(invoicedate)=@qMonth
and itemid in (20997,20999,20005,20996,20998,10106,20995,20992,20993) and lineamount>0)>0 then 0 else 1 end
/*
select @i as LastInvMonth , @j as LastInvYear, @Month as SelectedMonth
, @Year as SelectedYear, @qMonth as queryMonth , @qYear as queryYear
,  @isProjection as isProjection 
, @lastInvoiceMonthLastDate as LastInvMonthLastDate
*/

set @axDefaultDate = '1900-01-01 00:00:00.000'


Create Table #TrnxProjInVoiceMonth
(LineItemId varchar(50), Month int, Year Int,CrmId varchar(50), Productsku int, Accountid varchar(50),CustGroup varchar(50),BilledAmount Numeric(28,2), AdditionalInfo varchar(100),
Region varchar(50),City varchar(50),State varchar(50),Country varchar(50),BranchId varchar(50),Action varchar(5),LicenseCount int,BillableLicenseCount int, NonBillableLicenseCount int,
TTChangeType varchar(50),CreditReason varchar(50),TTLICENSEFILEID varchar(50), SalesType varchar(50),ConfigId varchar(25),DeliveryZipCode varchar(10),TTNOTES nvarchar(500),
TTBILLSTART datetime,TTBILLEND datetime,LineRecId bigint, SalesId varchar(50),tax money,Currency char(10), TTUsage numeric(18,10), LineAmount Numeric(28,12),
TAXAMOUNT Numeric(28,12),TotalAmount Numeric(28,12),InvoiceId varchar(50),CREATEDDATETIME datetime,DELIVERYNAME varchar(100),TTDESCRIPTION varchar(500),
DataAreaId varchar(4),SalesPrice Numeric(28,12),ActiveBillableToday int,ActiveNonBillableToday int
,Productname varchar(50),PriceGroup varchar(100),TTCONVERSIONDATE datetime,Name varchar(50),
TTBillingOnBehalfOf varchar(10),TTSalesCommissionException int,TTUSERCOMPANY varchar(255)
,CreatedDate Datetime, ModifiedDate Datetime,MIC varchar(50),TTPASSTHROUGHPRICE numeric(28,12),TTUserid varchar(50),TTID varchar(100),TTIDEmail varchar(100))
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
   , '7x Projections' as SalesType 
   , '1' as ConfigId
   , A.TTDELIVERYZIPCODE as DeliveryZipCode , A.TTNOTES, A.TTBILLSTART , case when @Month >=month(getdate()) then '1900-01-01 00:00:00.000' else A.TTBILLEND end as TTBILLEND, A.RECID as LineRecId , A.SALESID --<Ram:07/29/2013:1700> Changed the TTBillend to be open ended for all the projection data
   , NULL as Tax, A.currencycode as Currency, A.TTUSAGE   
   , A.LINEAMOUNT , A.TAXAMOUNT , (A.LINEAMOUNT + A.TAXAMOUNT) as TotalAmount
   , Null as InvoiceId, null as  CREATEDDATETIME , A.TTDLVNAME as DELIVERYNAME, A.TTDESCRIPTION
   , A.DATAAREAID , A.SALESPRICE   
   , dbo.fnGetBillableQuantity( A.QTY , A.TTBILLSTART , A.TTBILLEND , @today , @Year, A.LINEAMOUNT ) as ActiveBillableToday  
   , dbo.fnGetNonBillableQuantity( A.QTY , A.TTBILLSTART , A.TTBILLEND , @today , @Year, A.LINEAMOUNT ) as ActiveNonBillableToday,P.Productname, nullif(C.PriceGroup,'') as PriceGroup, TTCONVERSIONDATE
   ,pg.name,TTBillingOnBehalfOf, TTSalesCommissionException,TTUSERCOMPANY,A.CreatedDatetime as CreatedDate, A.ModifiedDatetime as ModifiedDate,TTMIC as MIC,TTPASSTHROUGHPRICE,A.TTUserId
   ,A.TTID,A.TTIDEmail
            
  from CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.CUSTINVOICETRANS A
  inner join  CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.CUSTINVOICEJOUR B
  on A.INVOICEID = B.INVOICEID and A.DATAAREAID = B.DATAAREAID
  inner join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.CUSTTABLE C  -- for CustGroup
  on B.INVOICEACCOUNT = C.INVOICEACCOUNT and B.DATAAREAID  = c.DATAAREAID
  left join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.TTLocationSalesRegionMapping E   -- left join, since location on line item is not a mandatory field
  on A.DIMENSION3_ = E.LOCATIONNUM
  left join chisql12.bidw.dbo.Product P on A.ITEMID = P.ProductSku
     left join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.PRICEDISCGROUP PG on PG.groupid=c.pricegroup

  where 
 (C.CUSTGROUP in ('Trnx SW','MultiBrokr') and A.ITEMID in ('20996', '20997', '20998', '20999', '10106','20005','20995','20992','20993') ) -- Included ProductSku 20005 <Ram:06/24/2013>
  and DATEPART(mm, A.INVOICEDATE) = @qMonth 
  and  DATEPART(yyyy, A.INVOICEDATE) = @qYear
  and A.SALESID != ''  -- do not pull FTI Invoices
  and  A.salesid not in
( select distinct salesid from CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.CUSTINVOICEJOUR
where YEAR(invoicedate)=@Year and MONTH(invoicedate)=@Month
--and day(invoicedate)<>3 
--and custgroup not in ('Trnx SW','MultiBrokr') 
)


Create Table #TrnxProjPriorInVoiceMonth
(LineItemId varchar(50), Month int, Year Int,CrmId varchar(50), Productsku int, Accountid varchar(50),CustGroup varchar(50),BilledAmount Numeric(28,2), AdditionalInfo varchar(100),
Region varchar(50),City varchar(50),State varchar(50),Country varchar(50),BranchId varchar(50),Action varchar(5),LicenseCount int,BillableLicenseCount int, NonBillableLicenseCount int,
TTChangeType varchar(50),CreditReason varchar(50),TTLICENSEFILEID varchar(50), SalesType varchar(50),ConfigId varchar(25),DeliveryZipCode varchar(10),TTNOTES nvarchar(500),
TTBILLSTART datetime,TTBILLEND datetime,LineRecId bigint, SalesId varchar(50),tax money,Currency char(10), TTUsage numeric(18,10), LineAmount Numeric(28,12),
TAXAMOUNT Numeric(28,12),TotalAmount Numeric(28,12),InvoiceId varchar(50),CREATEDDATETIME datetime,DELIVERYNAME varchar(100),TTDESCRIPTION varchar(500),
DataAreaId varchar(4),SalesPrice Numeric(28,12),ActiveBillableToday int,ActiveNonBillableToday int
,Productname varchar(50),PriceGroup varchar(100),TTCONVERSIONDATE datetime,Name varchar(50),
TTBillingOnBehalfOf varchar(10),TTSalesCommissionException int,TTUSERCOMPANY varchar(255),CreatedDate Datetime
, ModifiedDate Datetime,MIC varchar(50),TTPASSTHROUGHPRICE numeric(28,12),TTUserid varchar(50),TTID varchar(100),TTIDEmail varchar(100))
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
   , '7x Projections' as SalesType 
   , '1' as ConfigId
   , A.TTDELIVERYZIPCODE as DeliveryZipCode , A.TTNOTES, A.TTBILLSTART , case when @Month >=month(getdate()) then '1900-01-01 00:00:00.000' else A.TTBILLEND end as TTBILLEND, A.RECID as LineRecId , A.SALESID --<Ram:07/29/2013:1700> Changed the TTBillend to be open ended for all the projection data
   , NULL as Tax, A.Currencycode as Currency, A.TTUSAGE   
   , A.LINEAMOUNT , A.TAXAMOUNT , (A.LINEAMOUNT + A.TAXAMOUNT) as TotalAmount
   , Null as InvoiceId, null as  CREATEDDATETIME , A.TTDLVNAME as DELIVERYNAME, A.TTDESCRIPTION
   , A.DATAAREAID , A.SALESPRICE   
   , dbo.fnGetBillableQuantity( A.QTY , A.TTBILLSTART , A.TTBILLEND , @today , @Year, A.LINEAMOUNT ) as ActiveBillableToday  
   , dbo.fnGetNonBillableQuantity( A.QTY , A.TTBILLSTART , A.TTBILLEND , @today , @Year, A.LINEAMOUNT ) as ActiveNonBillableToday,P.Productname, nullif(C.PriceGroup,'') as PriceGroup, TTCONVERSIONDATE
   ,pg.name,TTBillingOnBehalfOf,TTSalesCommissionException,TTUSERCOMPANY,A.CreatedDatetime as CreatedDate, A.ModifiedDatetime as ModifiedDate,TTMIC as MIC,TTPASSTHROUGHPRICE,A.TTUserId
   ,A.TTID,A.TTIDEmail
            
  from CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.CUSTINVOICETRANS A
  inner join  CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.CUSTINVOICEJOUR B
  on A.INVOICEID = B.INVOICEID and A.DATAAREAID = B.DATAAREAID
  inner join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.CUSTTABLE C  -- for CustGroup
  on B.INVOICEACCOUNT = C.INVOICEACCOUNT and B.DATAAREAID  = c.DATAAREAID
  left join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.TTLocationSalesRegionMapping E   -- left join, since location on line item is not a mandatory field
  on A.DIMENSION3_ = E.LOCATIONNUM
  left join chisql12.bidw.dbo.Product P on A.ITEMID = P.ProductSku
     left join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.PRICEDISCGROUP PG on PG.groupid=c.pricegroup

  where 
  @TransPriorProj=1 and
 (C.CUSTGROUP in ('Trnx SW','MultiBrokr') and A.ITEMID in ('20996', '20997', '20998', '20999', '10106','20005','20995','20992','20993') ) -- Included ProductSku 20005 <Ram:06/24/2013>
  and DATEPART(mm, A.INVOICEDATE) = @InvoiceProjMonth 
  and  DATEPART(yyyy, A.INVOICEDATE) = @InvoiceProjYear
  and A.SALESID != ''  -- do not pull FTI Invoices
  and  A.salesid not in
( select distinct salesid from CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.CUSTINVOICEJOUR
where YEAR(invoicedate)=@Year and MONTH(invoicedate)=@Month 
--and day(invoicedate)<>3 
--and custgroup not in ('Trnx SW','MultiBrokr') 
)


Create Table #SalesProj
(LineItemId varchar(50), Month int, Year Int,CrmId varchar(50), Productsku int, Accountid varchar(50),CustGroup varchar(50),BilledAmount Numeric(28,2), AdditionalInfo varchar(100),
Region varchar(50),City varchar(50),State varchar(50),Country varchar(50),BranchId varchar(50),Action varchar(5),LicenseCount int,BillableLicenseCount int, NonBillableLicenseCount int,
TTChangeType varchar(50),CreditReason varchar(50),TTLICENSEFILEID varchar(50), SalesType varchar(50),ConfigId varchar(25),DeliveryZipCode varchar(10),TTNOTES nvarchar(500),
TTBILLSTART datetime,TTBILLEND datetime,LineRecId bigint, SalesId varchar(50),tax money,Currency char(10), TTUsage numeric(18,10), LineAmount Numeric(28,12),
TAXAMOUNT Numeric(28,12),TotalAmount Numeric(28,12),InvoiceId varchar(50),CREATEDDATETIME datetime,DELIVERYNAME varchar(100),TTDESCRIPTION varchar(500),
DataAreaId varchar(4),SalesPrice Numeric(28,12),ActiveBillableToday int,ActiveNonBillableToday int
,Productname varchar(50),PriceGroup varchar(100),TTCONVERSIONDATE datetime,Name varchar(50),
TTBillingOnBehalfOf varchar(10),TTSalesCommissionException int,TTUSERCOMPANY varchar(255),CreatedDate Datetime
, ModifiedDate Datetime,MIC varchar(50),TTPASSTHROUGHPRICE numeric(28,12),TTUserid varchar(50),TTID varchar(100),TTIDEmail varchar(100))
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
      , A.ttusage ) as BilledAmount
 --, dbo.fnGetLineAmount(A.SALESQTY, A.TTBACKUPSALESQTY , A.SALESPRICE, A.PRICEUNIT, A.LINEDISC, A.TTLINEDISCOUNT, A.LINEPERCENT      
 --     , dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) ) as BilledAmount
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
      ,  dbo.fnGetLineAmount(A.SALESQTY, A.TTBACKUPSALESQTY , A.SALESPRICE, A.PRICEUNIT, A.LINEDISC, A.TTLINEDISCOUNT, A.LINEPERCENT,A.TTusage)      
      --, dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) )
       ) as BillableLicenseCount  

, dbo.fnGetNonBillableQuantity( A.SalesQty , A.TTBILLSTART , A.TTBILLEND , @LastDayOfMonth , @Year
      ,  dbo.fnGetLineAmount(A.SALESQTY, A.TTBACKUPSALESQTY , A.SALESPRICE, A.PRICEUNIT, A.LINEDISC, A.TTLINEDISCOUNT, A.LINEPERCENT,A.TTusage)      
      --, dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) )
       ) as NonBillableLicenseCount       
, A.TTCHANGETYPE 
/*, Case when A.TTREASONCODE = 0 Then 'None'  when A.TTREASONCODE = 1 Then 'New Product'   when A.TTREASONCODE = 2 Then 'Upgrade' 
     When A.TTREASONCODE = 3 Then 'Downgrade'  When A.TTREASONCODE = 4 Then 'Transfer' When A.TTREASONCODE = 6 Then 'Cancellation' End as ReasonCode     */
, A.PORT as CreditReason
, A.TTLICENSEFILEID 
   , 'AX Sales Lines' as SalesType 
   , '1' as ConfigId
 , A.DELIVERYZIPCODE as DeliveryZipCode , A.TTNOTES, A.TTBILLSTART , A.TTBILLEND , A.RECID as LineRecId, A.SALESID
-- , CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.fn_TTGetAvaTax(A.SalesId, A.RecId) as Tax
--  , CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.fn_TTGetAvaTaxRate(A.SalesId, A.RecId) as TaxRate
 , NULL as Tax, A.Currencycode as Currency, A.TTUSAGE 
 , NULL LINEAMOUNT , NULL as TAXAMOUNT , NULL as TotalAmount
 , Null as InvoiceId, A.CREATEDDATETIME , A.DELIVERYNAME, A.TTDESCRIPTION
 , A.DATAAREAID , A.SALESPRICE
 
 , dbo.fnGetBillableQuantity( A.SalesQty , A.TTBILLSTART , A.TTBILLEND , @today , @Year
      ,  dbo.fnGetLineAmount(A.SALESQTY, A.TTBACKUPSALESQTY , A.SALESPRICE, A.PRICEUNIT, A.LINEDISC, A.TTLINEDISCOUNT, A.LINEPERCENT,A.TTUSAGE)      
      --, dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) )
       ) as ActiveBillableToday  

, dbo.fnGetNonBillableQuantity( A.SalesQty , A.TTBILLSTART , A.TTBILLEND , @today , @Year
      ,  dbo.fnGetLineAmount(A.SALESQTY, A.TTBACKUPSALESQTY , A.SALESPRICE, A.PRICEUNIT, A.LINEDISC, A.TTLINEDISCOUNT, A.LINEPERCENT ,A.TTUSAGE)       
      --, dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) )
       ) as ActiveNonBillableToday,P.Productname, nullif(C.PriceGroup,'') as PriceGroup, TTCONVERSIONDATE
   ,pg.name,TTBillingOnBehalfOf, TTSalesCommissionException,TTUSERCOMPANY ,A.CreatedDatetime as CreatedDate
   , A.ModifiedDatetime as ModifiedDate,TTMIC as MIC,TTPASSTHROUGHPRICE,A.TTUserId,A.TTID,A.TTIDEmail
 
 from CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.SALESLINE A
 inner join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.SALESTABLE B
 on  A.SALESID = B.SALESID and A.DATAAREAID = B.DATAAREAID
 inner join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.CUSTTABLE C
 on B.INVOICEACCOUNT = C.INVOICEACCOUNT and B.DATAAREAID = c.DATAAREAID
 left join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.TTLocationSalesRegionMapping E   -- left join, since location on line item is not a mandatory field
 on A.DIMENSION3_ = E.LOCATIONNUM
 inner join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.INVENTDIM F
 on A.INVENTDIMID = F.INVENTDIMID and A.DATAAREAID = F.DATAAREAID
 left join chisql12.bidw.dbo.Product P on A.ITEMID = P.ProductSku
   left join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.PRICEDISCGROUP PG on PG.groupid=c.pricegroup
 where  
 @isProjection = 1  and 
 A.SALESSTATUS = 1 -- 1 corresponds 'Open Order' Line status
 and (A.TTBILLSTART = @axDefaultDate  or A.TTBILLSTART <= @LastDayOfMonth)
 and (A.TTBILLEND = @axDefaultDate or A.TTBILLEND >= @FirstDayOfMonth) 
 --and C.CUSTGROUP =  'TTNETHost' --  'Subscribe' , TTNETHost is temporary
and A.ITEMID in ('20996', '20997', '20998', '20999', '10106','20005','20995','20992','20993')-- Included ProductSku 20005 <Ram:06/24/2013>
--and A.SALESID != ''
and  A.salesid not in
( select distinct salesid from CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.CUSTINVOICEJOUR
where YEAR(invoicedate)=@Year and MONTH(invoicedate)=@Month 
--and day(invoicedate)<>3 
--and custgroup not in ('Trnx SW','MultiBrokr') ----- Temp Code Delete it 01/06/2016 Ram----
)


Create Table #Final
(Id varchar(200), Month int, Year int, CrmId varchar(50), AccountId varchar(50), ExchangeId smallint, 
CustGroup nvarchar(50), PriceGroup varchar(50), PriceGroupDesc varchar(100), ProductSku int, BilledAmount Numeric(28,2), 
AdditionalInfo varchar(500), Region varchar(50), City varchar(50), State varchar(50), Country varchar(50), BranchId int
,Action varchar(50), LicenseCount int, BillableLicenseCount int, NonBillableLicenseCount int,
TTChangeType varchar(100), CreditReason varchar(200), TTLICENSEFILEID varchar(50), SalesType varchar(20)
,ConfigId varchar(25), DeliveryZipCode varchar(10), TTNotes varchar(500), TTBillStart datetime, TTBillEnd datetime, 
LineRecId bigint , SalesId nvarchar(50), Tax money, Currency char(10), TTUsage numeric(18,10), LineAmount numeric(28,12)
,TAXAMOUNT numeric(28,12), TotalAmount numeric(28,12), InvoiceId nvarchar(50), CREATEDDATETIME datetime, DELIVERYNAME varchar(500),
TTDESCRIPTION varchar(500), TTCONVERSIONDATE datetime, DataAreaId varchar(4), SalesPrice numeric(28,12)
, ActiveBillableToday int, ActiveNonBillableToday int, LastUpdatedDate datetime, 
TTBillingOnBehalfOf nvarchar(10), Username varchar(500), TTSalesCommissionException int, TTUserCompany varchar(255)
, CreatedDate datetime, ModifiedDate datetime,MIC varchar(50),TTPASSTHROUGHPRICE numeric(28,12),TTUserid varchar(50),TTID varchar(100),TTIDEmail varchar(100))

Insert Into #Final

select  id,Month, Year,CrmId,AccountId,ExchangeId,CustGroup,PriceGroup,PriceGroupDesc,ProductSku, isnull(BilledAmount,0) as BilledAmount, 
AdditionalInfo, Region,[city],[State], Country, BranchId, [Action], LicenseCount,  
case when productsku in ('20996', '20997', '20998', '20999', '10106','20005','20995','20992','20993')
then case when ConcatenatedName Is null then 0 when ROW_NUMBER() over (PARTITION By ConcatenatedName Order By id desc,ConcatenatedName)=1 then 1
else 0 end else BillableLicenseCount end as BillableLicenseCount, 
NonBillableLicenseCount , TTCHANGETYPE, CreditReason, TTLICENSEFILEID,SalesType, ConfigId, DeliveryZipCode,
TTNotes, TTBillStart, TTBillEnd, LineRecId, SALESID, Tax, Currency, TTUSAGE, LINEAMOUNT , TAXAMOUNT , TotalAmount , INVOICEID, CREATEDDATETIME , DELIVERYNAME, TTDESCRIPTION,TTCONVERSIONDATE, DATAAREAID, SALESPRICE
, ActiveBillableToday, ActiveNonBillableToday,GETDATE() as LastUpdatedDate,TTBillingOnBehalfOf --<Ram 02/10/2014 19:15> Added Logic to Handle Duplicate License Counts for Transaction Products
,Deliveryname as Username,TTSalesCommissionException,TTUSERCOMPANY,CreatedDate, ModifiedDate,MIC,TTPASSTHROUGHPRICE,TTUserId,TTID,TTIDEmail
from 
(

select  Id,Month, Year,CrmId,AccountId,isnull(E.ExchangeId,0) as ExchangeId,CustGroup,PriceGroup,PriceDescription as PriceGroupDesc,
NP.ProductSku,BilledAmount, AdditionalInfo, Region,[city],[State], Country, BranchId, [Action], 
LicenseCount,  BillableLicenseCount, NonBillableLicenseCount , TTCHANGETYPE, CreditReason, TTLICENSEFILEID
, SalesType, ConfigId, DeliveryZipCode, TTNotes, TTBillStart, TTBillEnd, LineRecId, SALESID, Tax, Currency, TTUSAGE
, LINEAMOUNT , TAXAMOUNT , TotalAmount , INVOICEID, CREATEDDATETIME , DELIVERYNAME, TTDESCRIPTION,TTCONVERSIONDATE, DATAAREAID, SALESPRICE
, ActiveBillableToday, ActiveNonBillableToday,GETDATE() as LastUpdatedDate,TTBillingOnBehalfOf --<Ram 01/22/2014 13:15> Added TTBillingOnBehalfOf field as per Jira BI-75
,TTSalesCommissionException,TTUSERCOMPANY,CreatedDate, ModifiedDate,MIC,TTPASSTHROUGHPRICE,TTUserId,TTID,TTIDEmail
 ,CAST(Year AS CHAR)+'-'+CAST(MONTH as char)+cast(AccountId as CHAR)+'-'+SalesType+'-'+isnull(Invoiceid,0)+'-'+cast(NP.ProductSku as CHAR)+'-'+cast(TTDESCRIPTION as CHAR)+'-' as ConcatenatedName --<Ram 02/10/2014 19:15> Added Logic to Handle Duplicate License Counts for Transaction Products
 --,CAST(Year AS CHAR)+'-'+CAST(MONTH as char)+cast(AccountId as CHAR)+'-'+cast(NP.ProductSku as CHAR)+'-'+cast(TTDESCRIPTION as CHAR)+'-' as ConcatenatedName --<Ram 02/10/2014 19:15> Added Logic to Handle Duplicate License Counts for Transaction Products
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
			, SalesType, ConfigId, DeliveryZipCode, TTNotes, TTBillStart, TTBillEnd, LineRecId, SALESID, Tax, Currency, TTUSAGE
			, LINEAMOUNT , TAXAMOUNT , TotalAmount , INVOICEID, CREATEDDATETIME , DELIVERYNAME, TTDESCRIPTION,TTCONVERSIONDATE, DATAAREAID, SALESPRICE
			, ActiveBillableToday, ActiveNonBillableToday,Productname,TTBillingOnBehalfOf,TTSalesCommissionException,TTUSERCOMPANY, CreatedDate, ModifiedDate,MIC,TTPASSTHROUGHPRICE,TTUserId,TTID,TTIDEmail
	FROM (

-- AX Invoice data, good for non-projection case
Select  A.INVOICEID + ' - ' + convert(varchar,A.LineNum) + ' - ' +  convert(varchar, A.RECID)+'-'+C.ACCOUNTNUM as LineItemId   --A.RecId as LineItemId  , +  ' - ' + CONVERT(varchar, RAND())
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
   , 'AX Invoices' as SalesType 
   , '1' as ConfigId
   , A.TTDELIVERYZIPCODE as DeliveryZipCode , A.TTNOTES, A.TTBILLSTART , A.TTBILLEND , A.RECID as LineRecId, A.SALESID
   , NULL as Tax, A.Currencycode as Currency, A.TTUSAGE
   , A.LINEAMOUNT , A.TAXAMOUNT , (A.LINEAMOUNT + A.TAXAMOUNT) as TotalAmount
   , A.INVOICEID, null as  CREATEDDATETIME , A.TTDLVNAME as DELIVERYNAME, A.TTDESCRIPTION
   , A.DATAAREAID , A.SALESPRICE 
   , dbo.fnGetBillableQuantity( A.QTY , A.TTBILLSTART , A.TTBILLEND , @today , @Year, A.LINEAMOUNT ) as ActiveBillableToday  
   , dbo.fnGetNonBillableQuantity( A.QTY , A.TTBILLSTART , A.TTBILLEND , @today , @Year, A.LINEAMOUNT ) as ActiveNonBillableToday
   ,P.Productname
   , nullif(C.PriceGroup,'') as PriceGroup
   , TTCONVERSIONDATE
   ,pg.name,TTBillingOnBehalfOf,TTSalesCommissionException,TTUSERCOMPANY,A.CreatedDatetime as CreatedDate, A.ModifiedDatetime as ModifiedDate,TTMIC as MIC,TTPASSTHROUGHPRICE,A.TTUserId,A.TTID,A.TTIDEmail
   
            
  from CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.CUSTINVOICETRANS A
  inner join  CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.CUSTINVOICEJOUR B
  on A.INVOICEID = B.INVOICEID and A.DATAAREAID = B.DATAAREAID
  inner join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.CUSTTABLE C  -- for CustGroup
  on B.INVOICEACCOUNT = C.INVOICEACCOUNT and B.DATAAREAID  = c.DATAAREAID
  --inner join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.SALESLINE D  -- StartDate and EndDate  (decide left or inner ) inner - ignore FTI based invoice data
  --on B.SALESID = D.SALESID and B.DATAAREAID = D.DATAAREAID and A.LINENUM = D.LINENUM  and A.ITEMID = D.ITEMID
  left join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.TTLocationSalesRegionMapping E   -- left join, since location on line item is not a mandatory field
  on A.DIMENSION3_ = E.LOCATIONNUM
  left join chisql12.bidw.dbo.Product P on A.ITEMID = P.ProductSku
  left join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.PRICEDISCGROUP PG on PG.groupid=c.pricegroup

  where 
  --@isProjection = 0 and 
  DATEPART(mm, A.INVOICEDATE) = @Month 
  and  DATEPART(yyyy, A.INVOICEDATE) = @year
  --and A.invoicedate<>'2015-12-03 00:00:00.000'
  --and A.SALESID != ''  -- do not pull FTI Invoices
--  and  A.salesid not in
--( select distinct salesid from CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.CUSTINVOICEJOUR
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
 , dbo.fnGetLineAmount(A.SALESQTY, A.TTBACKUPSALESQTY , A.SALESPRICE, A.PRICEUNIT, A.LINEDISC, A.TTLINEDISCOUNT, A.LINEPERCENT,A.TTUSAGE) as BilledAmount       
      --, dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) ) as BilledAmount
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
      ,  dbo.fnGetLineAmount(A.SALESQTY, A.TTBACKUPSALESQTY , A.SALESPRICE, A.PRICEUNIT, A.LINEDISC, A.TTLINEDISCOUNT, A.LINEPERCENT,A.TTUSAGE)     
      --, dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) )
       ) as BillableLicenseCount  

, dbo.fnGetNonBillableQuantity( A.SalesQty , A.TTBILLSTART , A.TTBILLEND , @LastDayOfMonth , @Year
      ,  dbo.fnGetLineAmount(A.SALESQTY, A.TTBACKUPSALESQTY , A.SALESPRICE, A.PRICEUNIT, A.LINEDISC, A.TTLINEDISCOUNT, A.LINEPERCENT ,A.TTUSAGE)     
      --, dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) )
       ) as NonBillableLicenseCount       
, A.TTCHANGETYPE 
/*, Case when A.TTREASONCODE = 0 Then 'None'  when A.TTREASONCODE = 1 Then 'New Product'   when A.TTREASONCODE = 2 Then 'Upgrade' 
     When A.TTREASONCODE = 3 Then 'Downgrade'  When A.TTREASONCODE = 4 Then 'Transfer' When A.TTREASONCODE = 6 Then 'Cancellation' End as ReasonCode     */
, A.PORT as CreditReason
, A.TTLICENSEFILEID 
, 'AX Sales Lines' as SalesType
 --, CASE when A.SALESTYPE = 2 Then 'Subscription'
 --      when A.SALESTYPE = 3 Then 'Sales Order' END as SalesType
 , F.CONFIGID
 , A.DELIVERYZIPCODE as DeliveryZipCode , A.TTNOTES, A.TTBILLSTART , A.TTBILLEND , A.RECID as LineRecId, A.SALESID
-- , CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.fn_TTGetAvaTax(A.SalesId, A.RecId) as Tax
--  , CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.fn_TTGetAvaTaxRate(A.SalesId, A.RecId) as TaxRate
 , NULL as Tax, A.Currencycode as Currency, A.TTUSAGE 
 , NULL LINEAMOUNT , NULL as TAXAMOUNT , NULL as TotalAmount
 , Null as InvoiceId, A.CREATEDDATETIME , A.DELIVERYNAME, A.TTDESCRIPTION
 , A.DATAAREAID , A.SALESPRICE
 
 , dbo.fnGetBillableQuantity( A.SalesQty , A.TTBILLSTART , A.TTBILLEND , @today , @Year
      ,  dbo.fnGetLineAmount(A.SALESQTY, A.TTBACKUPSALESQTY , A.SALESPRICE, A.PRICEUNIT, A.LINEDISC, A.TTLINEDISCOUNT, A.LINEPERCENT,A.TTUSAGE)      
      --, dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) )
       ) as ActiveBillableToday  

, dbo.fnGetNonBillableQuantity( A.SalesQty , A.TTBILLSTART , A.TTBILLEND , @today , @Year
      ,  dbo.fnGetLineAmount(A.SALESQTY, A.TTBACKUPSALESQTY , A.SALESPRICE, A.PRICEUNIT, A.LINEDISC, A.TTLINEDISCOUNT, A.LINEPERCENT,A.TTUSAGE)       
      --, dbo.fnGetTTUsage(@FirstDayOfMonth, @LastDayOfMonth, @DaysInMonth, @Month, @Year, A.TTBILLSTART, A.TTBILLEND) )
       ) as ActiveNonBillableToday,P.Productname, nullif(C.PriceGroup,'') as PriceGroup, TTCONVERSIONDATE
   ,pg.name,TTBillingOnBehalfOf, TTSalesCommissionException,TTUSERCOMPANY,A.CreatedDatetime as CreatedDate, A.ModifiedDatetime as ModifiedDate,TTMIC as MIC,TTPASSTHROUGHPRICE,A.TTUserId
   ,A.TTID,A.TTIDEmail
 from CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.SALESLINE A
 inner join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.SALESTABLE B
 on  A.SALESID = B.SALESID and A.DATAAREAID = B.DATAAREAID
 inner join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.CUSTTABLE C
 on B.INVOICEACCOUNT = C.INVOICEACCOUNT and B.DATAAREAID = c.DATAAREAID
 left join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.TTLocationSalesRegionMapping E   -- left join, since location on line item is not a mandatory field
 on A.DIMENSION3_ = E.LOCATIONNUM
 inner join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.INVENTDIM F
 on A.INVENTDIMID = F.INVENTDIMID and A.DATAAREAID = F.DATAAREAID
 left join chisql12.bidw.dbo.Product P on A.ITEMID = P.ProductSku
   left join CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.PRICEDISCGROUP PG on PG.groupid=c.pricegroup
 where  
 @isProjection = 1  and 
 A.SALESSTATUS = 1 -- 1 corresponds 'Open Order' Line status
 and (A.TTBILLSTART = @axDefaultDate  or A.TTBILLSTART <= @LastDayOfMonth)
 and (A.TTBILLEND = @axDefaultDate or A.TTBILLEND >= @FirstDayOfMonth) 
 --and C.CUSTGROUP =  'TTNETHost' --  'Subscribe' , TTNETHost is temporary
and A.ITEMID not in ('20996', '20997', '20998', '20999', '10106','20005','20995','20992','20993')-- Included ProductSku 20005 <Ram:06/24/2013>
and C.Custgroup not in ('RevRoyalty','Credits','RevNote','RevAdminHK','','RevAllctd','AllctdRev') --- Added not to project these ItemGroups Data
and  A.salesid not in
( select distinct salesid from CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.CUSTINVOICEJOUR
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
where Accountid not in
(
select distinct Accountid 
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


DELETE chisql12.bidw.dbo.MonthlyBillingData
WHERE Month = @Month AND Year = @Year
INSERT INTO chisql12.bidw.dbo.MonthlyBillingData
Select * from #Final


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

 update M
 set LicenseCount=-1, BillableLicenseCount=-1
  from Monthlybillingdata M join Product P 
 on m.productsku=p.productsku
  where (m.ProductSku in (20202) or Productsubgroup ='Credits') and 
 (LicenseCount<=-1 or BillableLicenseCount<=-1)
---------------------------------------------------------------------------------------------------------------------------------

-----------------------Update the Username Field with Unique Usernames---------

Update A
Set A.username=b.UpdatedDeliveryName
from [MonthlyBillingData] A
left join 
(
select distinct Year,Month,Productsku,case when deliveryname not like '% – %' and deliveryname not like '%(%' and deliveryname not like '%-%' and deliveryname not like '%/%' and LenOfUpdatedDeliveryName=CommaplinUpdatedDeliveryName then substring(UpdatedDeliveryName,1,CommaplinUpdatedDeliveryName-1) else UpdatedDeliveryName end as UpdatedDeliveryName,deliveryname from
(
select distinct Year,month,Productsku,deliveryname,charindex(',',deliveryname) as commaindex,
rtrim(ltrim(case when deliveryname not like '% – %' and deliveryname not like '%(%' and deliveryname not like '%-%' and deliveryname not like '%/%' then substring(deliveryname,(charindex(',',deliveryname))+1,100)+' '+substring(deliveryname,1,(charindex(',',deliveryname))) else deliveryname end)) as UpdatedDeliveryName
,len(rtrim(ltrim(substring(deliveryname,(charindex(',',deliveryname))+1,100)+' '+substring(deliveryname,1,(charindex(',',deliveryname)))))) as LenOfUpdatedDeliveryName,
charindex(',',rtrim(ltrim(substring(deliveryname,(charindex(',',deliveryname))+1,100)+' '+substring(deliveryname,1,(charindex(',',deliveryname)))))) as CommaplinUpdatedDeliveryName  from MonthlyBillingData
where year in (year(getdate()),year(getdate())-1)
--and month in (11,12) and
--and accountid<>'C100120' 
and productsku in (20000,20200,20005,20999)
--and DeliveryName like '%ghali%'
)Q
)B
on A.year=b.year and A.month=b.month and a.ProductSku=b.ProductSku and a.DELIVERYNAME=b.DELIVERYNAME
where  a.productsku in (20000,20200,20005,20999)
and a.year in (year(getdate()),year(getdate())-1)

------------------------------------------------------------------------------------------------------


---------------------------------------------------------Calculate TTusage for Sales Lines whose ttbillstart is prior month----------------
if (select COUNT(*) from chisql12.fillhub.dbo.invoicemonth  
 where YEAR=@year AND MONTH =@month) = 0
--If (@year=year(getdate()) and @month=month(getdate())+1)
Begin
update MonthlyBillingData
set TTUsage=1
--select * from MonthlyBillingData
where year=@Year and month=@month and ttusage<>1
and productsku in (20000,20200) 
and ttbillstart<=(select DATEADD(month,@Month-1,DATEADD(year,@Year-1900,0)))
and (ttbillend >=(select DATEADD(day,-1,DATEADD(month,@Month,DATEADD(year,@Year-1900,0)))) or ttbillend='1900-01-01 00:00:00.000')
End
----------------------------------------------------------------------------------------------------------


-------------------------------------------Update BillableLicensecount=0 for 100% discounted Invoices----------

Update monthlybillingdata
Set BillableLicenseCount=0
where year=@Year and month=@month and billedamount=0 and BillableLicenseCount>0

---------------------------------------------------------------------------------------------------------------

-------------------------------------------Update BillableLicensecount=-1 for 100% discounted Invoices fo non-credit products 04/12/2016----------
 update M
 set BillableLicenseCount=-1
  from Monthlybillingdata M join Product P 
 on m.productsku=p.productsku
 where year=@Year and month=@month and billedamount<0 and screens='screens'

 
---------------------------------------------------------------------------------------------------------------

/*
-----------------------------------------------Update Region in MonthlyBillingData----------------------------------------

Update M
Set m.region=r.RegionUpdated
from MonthlyBillingData M
--select distinct r.region,m.country from MonthlyBillingData M
Left Join 
(
select LocationNum,TTSalesRegion, Case when TTSALESREGION = 1 Then 'Asia Pacific' 
         when TTSALESREGION = 2 Then 'Europe' when TTSALESREGION = 3 Then 'North America'
         when TTSALESREGION = 4  Then 'South America' Else 'None'   End 
         as RegionUpdated from  CHIAXSQLPROD.TT_DYNAX09_PRD.dbo.TTLocationSalesRegionMapping 
)R
on M.BranchId=R.LocationNum
where year=2011
and m.region<>r.RegionUpdated


Update M
Set m.region=r.region
from MonthlyBillingData M
--select distinct r.region,m.country from MonthlyBillingData M
Left Join RegionMap R
on M.country=R.country
where year=@Year and month=@month and m.Region like '%none%' and m.country<>'Unassigned'


Update M
Set m.region=r.region
from MonthlyBillingData M
--select Distinct R.region,m.Region,m.country from MonthlyBillingData M
Left Join RegionMap R
on M.country=R.country
where year=@Year and month=@month and m.Region='North America' 
and m.country not in 
(
select distinct country from RegionMap
where Region='North America'
)


Update M
Set m.region=r.region
from MonthlyBillingData M
--select Distinct R.region,m.Region,m.country from MonthlyBillingData M
Left Join RegionMap R
on M.country=R.country
where year=@Year and month=@month and m.Region='Asia Pacific' 
and m.country not in 
(
select distinct country from RegionMap
where Region='Asia Pacific'
)

Update M
Set m.region=r.region
from MonthlyBillingData M
--select Distinct R.region,m.Region,m.country from MonthlyBillingData M
Left Join RegionMap R
on M.country=R.country
where year=@Year and month=@month and m.Region='Europe' 
and m.country not in 
(
select distinct country from RegionMap
where Region='Europe'
)


Update M
Set m.region=r.region
from MonthlyBillingData M
--select Distinct R.region,m.Region,m.country from MonthlyBillingData M
Left Join RegionMap R
on M.country=R.country
where year=@Year and month=@month and m.Region='South America' 
and m.country not in 
(
select distinct country from RegionMap
where Region='South America'
)

*/
---------------------------------------------------------------------------------------------------------------------------

--------Temp Code----------

--delete monthlybillingdata
----select * from monthlybillingdata
--where year=2015 and month=8 and salestype='InvoiceProj' and accountid='C100339'


