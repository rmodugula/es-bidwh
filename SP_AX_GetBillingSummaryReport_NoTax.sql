USE [TT_DYANX09_PRD]
GO
/****** Object:  StoredProcedure [dbo].[AX_GetBillingSummaryReport_NoTax]    Script Date: 8/4/2016 3:17:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[AX_GetBillingSummaryReport_NoTax]
	-- Add the parameters for the stored procedure here
	@Month int,
	@Year int,
	@AccountId nvarchar(10),
	@CustGroup nvarchar(max),
	@dataareaID nvarchar(max),
	@ProductId nvarchar(max),
	@ItemGroup nvarchar(max)
AS
BEGIN
declare @date as nvarchar(10);
set @date =  CAST(@Month as nvarchar)+'/1/'+  CAST(@Year as nvarchar)

 (select 
SALESTABLE.CUSTACCOUNT as Account, 
Custtable.NAME as Name, 
CUSTTABLE.CUSTGROUP as CustGroup,

SUM(LineAmount) as SubTotal,
SUM(LineAmount)  as Total
from SALESLINE , CUSTTABLE, SALESTABLE
where 
SALESLINE.CUSTACCOUNT = CUSTTABLE.ACCOUNTNUM and
SALESTABLE.SALESSTATUS = 1
and SALESLINE.SALESID = SALESTABLE.SALESID
 and SALESLINE.ITEMGROUPID NOT IN ('CREDITS', 'Write-Off')
and (SALESLINE.CUSTACCOUNT in (@AccountId) or ('' in (@AccountId)))
and (SALESLINE.DATAAREAID in (select Value from  dbo.split(',',@dataareaID)) or ('All' in (@dataareaID)))
 and (CUSTTABLE.CUSTGROUP in (select Value from  dbo.split(',',@CustGroup)) or ('All' in (@CustGroup)))
and Month(SALESTABLE.RECEIPTDATEREQUESTED)= @Month
 and year(SALESTABLE.RECEIPTDATEREQUESTED)= @Year
 and  ((MONTH(SALESLINE.TTBILLEND)>= @Month  and year(SALESLINE.TTBILLEND)=@Year or year(SALESLINE.TTBILLEND)>@Year)or(SALESLINE.TTBILLEND='')) 
 and ((MONTH(SALESLINE.TTBILLSTART)<=@Month and year(SALESLINE.TTBILLSTART)=@Year or year(SALESLINE.TTBILLSTART)<@Year)or(SALESLINE.TTBILLSTART=''))
 and (SALESLINE.itemid in (select Value from  dbo.split(',',@ProductId)) or ('All' in (@ProductId))) -- <Ram 08/06/2014> Added Product Name as a Prompt in SSRS Report as Per Jira BI-183
 and (ITEMGROUPID in (select Value from  dbo.split(',',@ItemGroup)) or ('All' in (@ItemGroup)))

group by SALESTABLE.CUSTACCOUNT, CUSTTABLE.NAME, CUSTTABLE.CUSTGROUP

union

select 
CustInvoiceJour.INVOICEACCOUNT as Account, 
Custtable.NAME as Name, 
CUSTTABLE.CUSTGROUP as CustGroup,

case when CUSTINVOICEJOUR.DATAAREAID = 'ttbr'
then sum(CustInvoiceTrans.LINEAMOUNT * dbo.fnGetExchangeRt(CUSTINVOICEJOUR.DATAAREAID, CUSTINVOICEJOUR.INVOICEDATE, 'USD')) 
else 
SUM(CustInvoiceTrans.LineAmount) End as SubTotal,

--SUM(CustInvoiceTrans.LineAmount) as SubTotal,
case when CUSTINVOICEJOUR.DATAAREAID = 'ttbr'
then CUSTINVOICEJOUR.INVOICEAMOUNT * dbo.fnGetExchangeRt(CUSTINVOICEJOUR.DATAAREAID, CUSTINVOICEJOUR.INVOICEDATE, 'USD') 
else 
CUSTINVOICEJOUR.INVOICEAMOUNT End as Total
--CUSTINVOICEJOUR.INVOICEAMOUNT as Total
from CustInvoiceTrans , CUSTTABLE, CustInvoiceJour
where 
CustInvoiceJour.INVOICEACCOUNT = CUSTTABLE.ACCOUNTNUM 
and CUSTINVOICETRANS.SALESID !=''
 and CustInvoiceTrans.ITEMGROUPID NOT IN ('CREDITS', 'Write-Off')
and CustInvoiceTrans.INVOICEID = CUSTINVOICEJOUR.INVOICEID
and (CustInvoiceJour.INVOICEACCOUNT in (@AccountId) or ('' in (@AccountId)))
and (CustInvoiceTrans.DATAAREAID in (select Value from  dbo.split(',',@dataareaID)) or ('All' in (@dataareaID)))
and (CUSTTABLE.CUSTGROUP in (select Value from  dbo.split(',',@CustGroup)) or ('All' in (@CustGroup)))
and  MONTH(CustInvoiceJour.INVOICEDATE)=@Month
and YEAR(CustInvoiceJour.INVOICEDATE)=@Year  
and (CustInvoiceTrans.itemid in (select Value from  dbo.split(',',@ProductId)) or ('All' in (@ProductId))) -- <Ram 08/06/2014> Added Product Name as a Prompt in SSRS Report as Per Jira BI-183
 and (ITEMGROUPID in (select Value from  dbo.split(',',@ItemGroup)) or ('All' in (@ItemGroup)))

group by CustInvoiceJour.DATAAREAID, CustInvoiceJour.INVOICEDATE , CustInvoiceJour.INVOICEACCOUNT, CUSTTABLE.NAME, CUSTTABLE.CUSTGROUP, CUSTINVOICEJOUR.INVOICEAMOUNT
)
order by NAME, CustGroup
 
END
