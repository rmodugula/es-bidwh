USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetAlertedForNoBillingAccount-TTFills]    Script Date: 4/25/2016 11:07:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[GetAlertedForNoBillingAccount-TTFills]
     
AS

Begin

IF (
Select count(*) from
(
Select Year,Month,BilledCompanyName,Notes,IsDirectBill,cast(Fills as int) as Fills from 
(
SELECT year(startdate) as Year,month(startdate) as Month,[companyname] as BilledCompanyName,isnull(Notes,'') as Notes,
case when IsDirectBill=0 then 'N'
     when IsDirectBill=1 then 'Y'
	else 'Null' end as IsDirectBill
,sum([quantity]) as Fills
FROM chisql20.[TTWebBillingProcessor].[dbo].[BillableLines] B
left join chisql20.[MESS].[dbo].[CompanyDirectBillHistory] H on year(startdate)=h.year and month(startdate)=h.Month and b.Companyid=h.CompanyId
left join 
(
select Distinct Year,Month,billedCompanyId,Notes from
(
select *,row_number() over (partition by billedcompanyid order by notes desc) as row from
(
SELECT DISTINCT [Year] , [Month],BilledCompanyId, Notes FROM chisql20.TTFills.dbo.AggregatedFills
  WHERE year=year(getdate()) and month=month(getdate())
  )Q
  )X where row=1
 
 ) A
  on year(startdate)=a.year and month(startdate)=a.Month and b.Companyid=a.BilledCompanyId 
where year(startdate)=year(getdate()) and month(startdate)=month(getdate()) 
and (billingaccount ='' or billingaccount is null)
group by  year(startdate),month(startdate),[companyname],IsDirectBill,Notes
)Final
)Q
)<>0

Begin


DECLARE @tableHTML  NVARCHAR(MAX) ;

SET @tableHTML =
    N'<H1>No Billing Account in Current Month for TTFills</H1>' +
    N'<table border="1">' +
	N'<tr><th>Year</th><th>Month</th><th>BilledCompanyName</th>' +
    N'<th>Notes</th><th>IsDirectBill</th><th>Fills</th>' +
    CAST ( ( SELECT distinct td = Year,       '',
	                td = Month,       '',
	                td = BilledCompanyName,       '',
					td = Notes, '',
					td = IsDirectBill,'',
                    td = Fills, ''
               from (
Select Year,Month,BilledCompanyName,Notes,IsDirectBill,cast(Fills as int) as Fills from 
(
SELECT year(startdate) as Year,month(startdate) as Month,[companyname] as BilledCompanyName,isnull(Notes,'') as Notes,
case when IsDirectBill=0 then 'N'
     when IsDirectBill=1 then 'Y'
	else 'Null' end as IsDirectBill
,sum([quantity]) as Fills
FROM chisql20.[TTWebBillingProcessor].[dbo].[BillableLines] B
left join chisql20.[MESS].[dbo].[CompanyDirectBillHistory] H on year(startdate)=h.year and month(startdate)=h.Month and b.Companyid=h.CompanyId
left join 
(
select Distinct Year,Month,billedCompanyId,Notes from
(
select *,row_number() over (partition by billedcompanyid order by notes desc) as row from
(
SELECT DISTINCT [Year] , [Month],BilledCompanyId, Notes FROM chisql20.TTFills.dbo.AggregatedFills
  WHERE year=year(getdate()) and month=month(getdate())
  )Q
  )X where row=1
 
 ) A
  on year(startdate)=a.year and month(startdate)=a.Month and b.Companyid=a.BilledCompanyId 
where year(startdate)=year(getdate()) and month(startdate)=month(getdate()) 
and (billingaccount ='' or billingaccount is null)
group by  year(startdate),month(startdate),[companyname],IsDirectBill,Notes
)Final
)Q
              FOR XML PATH('tr'), TYPE 
    ) AS NVARCHAR(MAX) ) +
    N'</table>' ;


  BEGIN
    EXEC msdb.dbo.SP_SEND_DBMAIL
      @profile_name='CHISQL12DBMail Public Profile',
	 @recipients='ax-support@tradingtechnologies.com;Melissa.Albertini@tradingtechnologies.com',
      --@recipients='ram.modugula@tradingtechnologies.com;Mark.mcclowry@tradingtechnologies.com;Melissa.Albertini@tradingtechnologies.com;Johanri.Gerber@tradingtechnologies.com',
	 --@recipients='ram.modugula@tradingtechnologies.com',
      @subject = 'Action Required: Billing Account needed in Current Month for TTFills',
      @body = @tablehtml,
      @body_format = 'HTML'
	  --@attach_query_result_as_file = 1 ;
  END --IF EXISTS

  



END

END



