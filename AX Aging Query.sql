select TM.MasterAccountName as MasterAccountName,Q.*,ENUMITEMNAME as TransactionType
,D.Name as CompanyAccountName,PrimarySuccessLead
from
(
SELECT Name as CompanyName,CUSTTRANSOPEN.ACCOUNTNUM as BillingAccountId
, CUSTTRANSOPEN.AMOUNTCUR as TransactionOutStandingAmount
, CUSTTRANSOPEN.AMOUNTMST as MasterOutStandingAmount, CUSTTRANSOPEN.DueDate, 
CUSTTRANSOPEN.TRANSDATE as TransactionDate, 
upper(CUSTTRANSOPEN.DATAAREAID) as CompanyAccountId
, CUSTTRANSOPEN.TTInvoiceBilled
, CASE WHEN RIGHT(CUSTTRANS.invoice, 2) = 'FC' AND CUSTTRANS.Transtype = 8 THEN 7
 WHEN LEFT(CUSTTRANS.invoice, 1) = 'P' AND 
CUSTTRANS.Transtype = 8 THEN 2 ELSE CUSTTRANS.transtype END AS TransactionTypeId
,TTCRMID
FROM dbo.CUSTTRANSOPEN INNER JOIN
dbo.CUSTTRANS ON custtransopen.DATAAREAID = custtrans.DATAAREAID 
AND custtrans.RECID = custtransopen.REFRECID
Inner Join dbo.CUSTTABLE on custtransopen.ACCOUNTNUM=CUSTTABLE.INVOICEACCOUNT
)Q
Inner Join
(
SELECT A.ENUMITEMVALUE, A.ENUMITEMLABEL AS ENUMITEMNAME FROM 
[DBO].SRSANALYSISENUMS A WHERE A.ENUMID = 137 AND A.LANGUAGEID = 'en-us'
)TT on Q.TransactionTypeId=ENUMITEMVALUE
Left Join [DBO].DATAAREA D on Q.CompanyAccountId=ID
Left Join 
(
Select Distinct AccountId,MasterAccountName from chisql12.bidw.dbo.account) TM 
on Q.BillingAccountId=TM.accountid
Left Join 
(
Select CrmId,PrimarySuccessLead from
(
SELECT Distinct [MasterAccountName],[CrmId],PrimarySuccessLead
,row_number() over (partition by crmid order by PrimarySuccessLead desc ) as rowid
FROM chisql12.[BIDW].[dbo].[TTCoverageMappings]
)g where rowid=1
)TTC on Q.TTCRMID=TTC.Crmid

--Select * from CUSTTABLE


--select Distinct CRMGUID,CUSTOMERNAME from TTMASTERCUSTOMER
--where CRMGUID <>''
--where CUSTOMERNAME='BAML'