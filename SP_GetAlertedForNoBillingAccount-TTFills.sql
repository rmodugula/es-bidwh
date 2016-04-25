USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetAlertedForNoBillingAccount-TTFills]    Script Date: 4/25/2016 10:49:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[GetAlertedForNoBillingAccount-TTFills]
     
AS

Begin

IF (Select count(*) from
(
SELECT DISTINCT
       A.[Year] , A.[Month], e.Companyname as BilledCompanyName , C.Companyname , d.Companyname AS BrokerName ,IsDirectBill , SUM(Quantity) AS Fills , Notes
FROM chisql20.TTFills.dbo.AggregatedFills AS A LEFT JOIN ( SELECT DISTINCT
                                                         CompanyId , Name AS Companyname
                                                  FROM chisql20.mess.dbo.Companies
                                                ) AS C ON A.Companyid = c.CompanyId
                                      LEFT JOIN ( SELECT DISTINCT
                                                         CompanyId , Name AS Companyname
                                                  FROM chisql20.mess.dbo.Companies
                                                ) AS D ON A.BrokerId = d.CompanyId
                                      LEFT JOIN chisql20.mess.dbo.markets AS m ON A.MarketId = m.MarketId
							   left join chisql20.[MESS].[dbo].[CompanyDirectBillHistory] H on a.year=h.year and a.Month=h.Month and a.Companyid=h.CompanyId
							   Left join ( SELECT DISTINCT  CompanyId , Name AS Companyname FROM chisql20.mess.dbo.Companies) E on a.BilledCompanyId=e.CompanyId
WHERE A.year=year(getdate()) and A.month=month(getdate())
      AND
      ( BillingAccountId IS NULL
        OR
        BillingAccountId = '' )
GROUP BY A.[Year] , A.[Month] , C.Companyname , d.Companyname , Notes,IsDirectBill,e.Companyname
)Q)<>0

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
SELECT DISTINCT
       A.[Year] , A.[Month], e.Companyname as BilledCompanyName , C.Companyname , d.Companyname AS BrokerName, Notes,case when IsDirectBill=1 then 'Y' else 'N' end as IsDirectBill , SUM(Quantity) AS Fills 
FROM chisql20.TTFills.dbo.AggregatedFills AS A LEFT JOIN ( SELECT DISTINCT
                                                         CompanyId , Name AS Companyname
                                                  FROM chisql20.mess.dbo.Companies
                                                ) AS C ON A.Companyid = c.CompanyId
                                      LEFT JOIN ( SELECT DISTINCT
                                                         CompanyId , Name AS Companyname
                                                  FROM chisql20.mess.dbo.Companies
                                                ) AS D ON A.BrokerId = d.CompanyId
                                      LEFT JOIN chisql20.mess.dbo.markets AS m ON A.MarketId = m.MarketId
							     left join chisql20.[MESS].[dbo].[CompanyDirectBillHistory] H on a.year=h.year and a.Month=h.Month and a.Companyid=h.CompanyId
								Left join ( SELECT DISTINCT  CompanyId , Name AS Companyname FROM chisql20.mess.dbo.Companies) E on a.BilledCompanyId=e.CompanyId
WHERE A.year=year(getdate()) and A.month=month(getdate())
      AND
      ( BillingAccountId IS NULL
        OR
        BillingAccountId = '' )
GROUP BY A.[Year] , A.[Month] , C.Companyname , d.Companyname, Notes,IsDirectBill,e.Companyname
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



