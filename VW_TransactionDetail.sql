USE [BIDW]
GO

/****** Object:  View [dbo].[VW_TransactionDetail]    Script Date: 03/24/2014 16:16:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




ALTER VIEW [dbo].[VW_TransactionDetail] 
as

select Y.Year,Y.Month,Y.Network,#FATrx as '# of FA Trx',#XTTrx as '# of XT Trx',#XTProTrx as '# of XTPro Trx',ISNULL(#XT,0) AS '# of XT',
ISNULL(#XTPro,0) AS '# of XTPro',ISNULL(#XTCap,0) AS '# of XTCap'
,ISNULL(#XTProCap,0) AS '# of XTProCap',CASE WHEN (#XT =0 OR #xt IS NULL) THEN 0 ELSE XTBilledAmount/#XT END as 'Avg.Price Per XT',
CASE WHEN (#XTPro =0 OR #XTPro IS NULL) THEN 0 ELSE XTPBilledAmount/#XTPro END as 'Avg.Price Per XTPro',
BTEC,BVMF,CBOT,CFE,NYMEX,CMEexclNYMEX,Eurex,FIX,ICE_IPE,LME,MEFF,MX,NYSE_LIFFE,NYSE_Liffe_US,OSE,SFE
,SGX,TFX,TOCOM,TSE,TTSIM from 
(
select Q.Year,Q.Month,Network,Accountid,SUM(#FATrx) as #FATrx,SUM(#XTTrx) as #XTTrx,SUM(#XTProTrx) as #XTProTrx,
--,sum(#XT) as #XT, 
--count(#XTCap) as #XTCap
--,case when sum(#XT)=0 then 0 else SUM(Billedamount)/SUM(#XT) end as #AvgPriceXT,
SUM(BTEC) as BTEC,SUM(BVMF) as BVMF,
SUM(CBOT) as CBOT,
SUM(CFE) as CFE,
SUM(NYMEX) as NYMEX,
SUM(CMEexclNYMEX) as CMEexclNYMEX,
SUM(Eurex) as Eurex,
SUM(FIX) as FIX,
SUM(ICE_IPE) as ICE_IPE,
SUM(LME) as LME,
SUM(MEFF) as MEFF,
SUM(MX) as MX,
SUM(NYSE_LIFFE) as NYSE_LIFFE,
SUM(NYSE_Liffe_US) as NYSE_Liffe_US,
SUM(OSE) as OSE,
SUM(SFE) as SFE,
sum(SGX) as SGX,
SUM(TFX) as TFX,
SUM(TOCOM) as TOCOM,
SUM(TSE) as TSE,
SUM(TTSIM) as TTSIM
 from 
(
select c.accountid, 
  c.AccountName as Network
,a.month as Month
,a.year as Year
, isnull(case when axproductid='20998' then SUM(fills) end,0) as #FATrx
, isnull(case when axproductid in ('20005') then SUM(fills) end,0) as #XTTrx
, isnull(case when axproductid in ('20999') then SUM(fills) end,0) as #XTProTrx
, isnull(Case when b.ExchangeName like 'BTec%' then SUM(fills) end,0) as BTEC
, isnull(case when b.ExchangeName like 'BVMF%' then SUM(fills) end,0) as BVMF
, isnull(case when b.ExchangeName like '%CBOT%' then SUM(fills) end,0) as CBOT
,	isnull(case   when b.ExchangeName like 'CFE%' then SUM(fills) end,0) as CFE
,	isnull(case    when (b.ExchangeName like 'CME%' or b.ExchangeName like 'Chicago Mercantile Exchange%') and a.ProductName in ('WWN','YPN','YQN','YRN','AX','QT','QR','BB','BZ','BZT','BBT','WF'
							 ,'WU','WY','CJ','CJT','KT','KTT','HXE','TT','TTT','CL','CAY','XKN'
							 ,'XKT','XCN','XCT','LO','CLBB','CLRE','CLT','LCE','LNE','OG','LR'
							 ,'LRT','LU','LUT','HO','GHY','OH','HCY','HOT','HOCL','QM','QH','QG'
							 ,'QU','NG','DGY','ON','NGT','QEN','PA','PL','PN','ZIY','RB','OB','RBT'
							 ,',ZXY','RE','RET','RNN','YIN','YJN','YKN','YMN','SO','HZ','RSN','YO'
							 ,'YOT','UX','HU','HUT') then SUM(fills) end,0) as NYMEX
,	isnull(case   when (b.ExchangeName like 'CME%' and a.ProductName Not in ('WWN','YPN','YQN','YRN','AX','QT','QR','BB','BZ','BZT','BBT','WF'
							 ,'WU','WY','CJ','CJT','KT','KTT','HXE','TT','TTT','CL','CAY','XKN'
							 ,'XKT','XCN','XCT','LO','CLBB','CLRE','CLT','LCE','LNE','OG','LR'
							 ,'LRT','LU','LUT','HO','GHY','OH','HCY','HOT','HOCL','QM','QH','QG'
							 ,'QU','NG','DGY','ON','NGT','QEN','PA','PL','PN','ZIY','RB','OB','RBT'
							 ,',ZXY','RE','RET','RNN','YIN','YJN','YKN','YMN','SO','HZ','RSN','YO'
							 ,'YOT','UX','HU','HUT'))
							 or 
							 (b.ExchangeName like 'Chicago Mercantile Exchange%' and a.ProductName Not in ('WWN','YPN','YQN','YRN','AX','QT','QR','BB','BZ','BZT','BBT','WF'
							 ,'WU','WY','CJ','CJT','KT','KTT','HXE','TT','TTT','CL','CAY','XKN'
							 ,'XKT','XCN','XCT','LO','CLBB','CLRE','CLT','LCE','LNE','OG','LR'
							 ,'LRT','LU','LUT','HO','GHY','OH','HCY','HOT','HOCL','QM','QH','QG'
							 ,'QU','NG','DGY','ON','NGT','QEN','PA','PL','PN','ZIY','RB','OB','RBT'
							 ,',ZXY','RE','RET','RNN','YIN','YJN','YKN','YMN','SO','HZ','RSN','YO'
							 ,'YOT','UX','HU','HUT')) 					 
				 then SUM(fills) end,0) as 'CMEexclNYMEX'				 
,	isnull(case   when b.ExchangeName like 'Eurex%' then SUM(fills) end,0) as Eurex
,isnull(case	   when b.ExchangeName like 'FIX%' then SUM(fills) end,0) as FIX
,isnull(case	   when b.ExchangeName like 'ICE_IPE%' then SUM(fills) end,0) as ICE_IPE
,isnull(case	   when b.ExchangeName like 'LME%' then SUM(fills) end,0) as LME
,isnull(case	   when b.ExchangeName like 'MEFF%' then SUM(fills) end,0) as MEFF
,	isnull(case   when b.ExchangeName like 'MX%' then SUM(fills) end,0) as MX
,isnull(case	   when b.ExchangeName like 'NYSE_LIFFE-%' OR b.ExchangeName = 'NYSE_LIFFE' then SUM(fills) end,0) as NYSE_LIFFE
,isnull(case	   when b.ExchangeName like 'NYSE_Liffe_US%' then SUM(fills) end,0) as NYSE_Liffe_US
,isnull(case	   when b.ExchangeName like 'OSE%' then SUM(fills) end,0) as OSE
,	isnull(case   when b.ExchangeName like 'SFE%' then SUM(fills) end,0) as SFE
,	isnull(case   when b.ExchangeName like 'SGX%' then SUM(fills) end,0) as SGX
,isnull(case	   when b.ExchangeName like 'TFX%' then SUM(fills) end,0) as TFX
,	isnull(case   when b.ExchangeName like 'TOCOM%' then SUM(fills) end,0) as TOCOM
,	isnull(case   when b.ExchangeName like 'TSE%' then SUM(fills) end,0) as TSE
,	isnull(case   when b.ExchangeName like 'TTSIM%' then SUM(fills) end,0) as TTSIM
from
	(
	select 	ExchangeId,sum(Fills) as Fills,ProductName,AccountId,month,year,TransactionDate,AxProductId
	from dbo.fills 	where IsBillable='Y' 
	--and YEAR=2013 and MONTH=11
	group by  ExchangeId,ProductName,AccountId,month,year,TransactionDate,AxProductId
		)a
left join
	(
	select * from dbo.Exchange
	)b
on a.ExchangeId=b.ExchangeID
left join
	(
	select * from dbo.Account
	)c
on a.AccountId=c.AccountId
 group by c.AccountName,b.ExchangeName,a.ProductName,a.month,a.year,a.AxProductId,c.Accountid
 )Q
 Group by Q.Network,Q.Year,Q.Month,Q.Accountid
 )Y
 left join 
 (
select bd.Year,bd.Month,bd.AccountId,bd.AccountName, #XT, #XTPro,isnull(#XTCap,0) as #XTCap,isnull(#XTProCap,0) as #XTProCap
, XTBilledamount, XTPBilledAmount
from
(
 select YEAR,MONTH,accountname,AccountId,SUM(#XTPro) as #XTPro,SUM(#XT) as #XT
 ,SUM(XTBilledAmount) as XTBilledAmount,SUM(XTPBilledAmount) as XTPBilledAmount from 
 (
 select year,month,AccountName,M.AccountId,case when productsku=20999 then SUM(BillableLicenseCount) end as #XTPro,
case when productsku=20005 then SUM(BillableLicenseCount) end as #XT,
case when productsku=20005 then sum(BilledAmount) end as XTBilledAmount,
case when productsku=20999 then sum(BilledAmount) end as XTPBilledAmount
from MonthlyBillingData M join Account A
on M.AccountId=A.Accountid
where ProductSku in (20999,20005)
group by AccountName,M.AccountId,YEAR,MONTH,ProductSku
) K
group by YEAR,MONTH,accountname,AccountId
) BD
left join
(
select Year,Month,Accountid,SUM(#XTCap) as #XTCap,SUM(#XTProCap) as #XTProCap from 
(
SELECT year(INVOICEDATE) as Year,Month(INVOICEDATE) as Month,[TTCUSTNAME],A.Accountid,
 case when itemid=20005 then COUNT(TTDESCRIPTION) end as #XTCap,
  case when itemid=20999 then COUNT(TTDESCRIPTION) end as #XTProCap
  FROM chiaxsql01.[TT_DYANX09_PRD].[dbo].[CUSTINVOICETRANS] CT join account A
  on CT.TTCUSTNAME=A.accountname
  where TTLINEDISCOUNT <>0
  and ITEMID in (20005,20999)
  --and INVOICEDATE = '2013-11-30'
  group by [TTCUSTNAME],year(INVOICEDATE),Month(INVOICEDATE),accountid,itemid
  ) L
  group by Year,Month,Accountid
  )CAP
  on BD.Year=Cap.Year and bd.Month=cap.Month and bd.AccountId=cap.Accountid
  )Z
on Y.Accountid=z.AccountId and y.Year=Z.Year and Y.Month=Z.Month
where Network not like '%TRADECO%'
and  Network not like '%MultiBroker%'
--and y.Year=2013 and y.Month=11




GO


