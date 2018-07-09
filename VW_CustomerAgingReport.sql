/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.2100)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2012
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/

USE [TT_DYNAX09_PRD]
GO

/****** Object:  View [dbo].[vw_CustomerAgingReport]    Script Date: 7/9/2018 3:54:26 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO









ALTER VIEW [dbo].[vw_CustomerAgingReport]
AS 

Select MasterAccountName, CompanyName, BillingAccountId,
TransactionOutStandingAmount, 
case when CompanyAccountId='TTBR' then (TransactionOutStandingAmount/(ENDOFDAYRATE/10)) else 
TransactionOutStandingAmount end as TransactionOutStandingAmountUSD , 
MasterOutStandingAmount,
case when CompanyAccountId='TTBR' then (MasterOutStandingAmount/(ENDOFDAYRATE/10)) 
else MasterOutStandingAmount end as MasterOutStandingAmountUSD, DueDate,
 TransactionDate, CompanyAccountId, TTInvoiceBilled, TransactionTypeId, TTCRMID, TransactionType, CompanyAccountName,
 PrimarySuccessLead, CustomerGroup,OrgType,ClientTier,ClientType from 
(
select TM.MasterAccountName as MasterAccountName,Q.*,ENUMITEMNAME as TransactionType
,D.Name as CompanyAccountName,PrimarySuccessLead,CustomerGroup,OrgType,ClientTier,ClientType
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
Select Distinct AccountId,MasterAccountName,CustomerGroup from chisql12.bidw.dbo.account) TM 
on Q.BillingAccountId=TM.accountid
Left Join 
(
Select CrmId,isnull(PrimarySuccessLead,customersuccessmanager) as PrimarySuccessLead,OrgType,ClientTier,ClientType from
(
SELECT Distinct [MasterAccountName],[CrmId],orgtype,clienttier,clienttype,PrimarySuccessLead,customersuccessmanager
,row_number() over (partition by crmid order by PrimarySuccessLead desc,customersuccessmanager desc ) as rowid
FROM chisql12.[BIDW].[dbo].[TTCoverageMappings] TC left join chisql12.Synap.dbo.organization o on tc.orgid=o.id
)g where rowid=1
)TTC on Q.TTCRMID=TTC.Crmid
where tm.MasterAccountName not like '%Trading Technologies%'
)Bal
left join 
(
Select * from 
(
SELECT     D.ID AS EXCHANGERATECOMPANY, V.CURRENCYCODE, V.DATEKEY, V.ENDOFDAYRATE
FROM         dbo.DATAAREA AS D CROSS JOIN
(SELECT     EXCHANGERATECOMPANY, CURRENCYCODE, DATEKEY, ENDOFDAYRATE
FROM          dbo.BIEXCHANGERATES
WHERE      (UPPER(EXCHANGERATECOMPANY) =
(SELECT     TOP (1) UPPER(EXCHANGERATECOMPANY) AS EXPR1
    FROM          dbo.BICONFIGURATION AS B)) AND (UPPER(CURRENCYCODE) IN
(SELECT     CASE WHEN UPPER(CURRENCYCODE) IS NULL THEN '' ELSE UPPER(CURRENCYCODE) END AS CURRENCYCODE
    FROM          dbo.COMPANYINFO))) AS V
)Final where  CURRENCYCODE='brl' and EXCHANGERATECOMPANY='ttus'
)rate on bal.TransactionDate=rate.DATEKEY

GO


