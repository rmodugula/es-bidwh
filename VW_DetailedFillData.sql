USE [BIDW]
GO

/****** Object:  View [dbo].[DetailedFillData]    Script Date: 03/24/2014 16:13:43 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




ALTER VIEW [dbo].[DetailedFillData] 
as

select  
  c.MasterAccountName
  ,c.AccountName as Network
, a.UserName as UserId
, b.ExchangeName as Exchange
, Case when b.ExchangeName like 'BTec%' then 'BTec'
   	   when b.ExchangeName like 'BVMF%' then 'BVMF'
	   when b.ExchangeName like '%CBOT%' then 'CBOT'
	   when b.ExchangeName like 'CFE%' then 'CFE'
	 --  when b.ExchangeName like 'Chicago Mercantile Exchange%' then 'CME'
	 --  when b.ExchangeName like 'CME%' then 'CME'		 
	   when (b.ExchangeName like 'CME%' or b.ExchangeName like 'Chicago Mercantile Exchange%') and a.ProductName in ('WWN','YPN','YQN','YRN','AX','QT','QR','BB','BZ','BZT','BBT','WF'
							 ,'WU','WY','CJ','CJT','KT','KTT','HXE','TT','TTT','CL','CAY','XKN'
							 ,'XKT','XCN','XCT','LO','CLBB','CLRE','CLT','LCE','LNE','OG','LR'
							 ,'LRT','LU','LUT','HO','GHY','OH','HCY','HOT','HOCL','QM','QH','QG'
							 ,'QU','NG','DGY','ON','NGT','QEN','PA','PL','PN','ZIY','RB','OB','RBT'
							 ,',ZXY','RE','RET','RNN','YIN','YJN','YKN','YMN','SO','HZ','RSN','YO'
							 ,'YOT','UX','HU','HUT') then 'NYMEX'
	   when b.ExchangeName like 'CME%' and a.ProductName Not in ('WWN','YPN','YQN','YRN','AX','QT','QR','BB','BZ','BZT','BBT','WF'
							 ,'WU','WY','CJ','CJT','KT','KTT','HXE','TT','TTT','CL','CAY','XKN'
							 ,'XKT','XCN','XCT','LO','CLBB','CLRE','CLT','LCE','LNE','OG','LR'
							 ,'LRT','LU','LUT','HO','GHY','OH','HCY','HOT','HOCL','QM','QH','QG'
							 ,'QU','NG','DGY','ON','NGT','QEN','PA','PL','PN','ZIY','RB','OB','RBT'
							 ,',ZXY','RE','RET','RNN','YIN','YJN','YKN','YMN','SO','HZ','RSN','YO'
							 ,'YOT','UX','HU','HUT') then 'CME (excl NYMEX)'					 
	   when b.ExchangeName like 'Chicago Mercantile Exchange%' and a.ProductName Not in ('WWN','YPN','YQN','YRN','AX','QT','QR','BB','BZ','BZT','BBT','WF'
							 ,'WU','WY','CJ','CJT','KT','KTT','HXE','TT','TTT','CL','CAY','XKN'
							 ,'XKT','XCN','XCT','LO','CLBB','CLRE','CLT','LCE','LNE','OG','LR'
							 ,'LRT','LU','LUT','HO','GHY','OH','HCY','HOT','HOCL','QM','QH','QG'
							 ,'QU','NG','DGY','ON','NGT','QEN','PA','PL','PN','ZIY','RB','OB','RBT'
							 ,',ZXY','RE','RET','RNN','YIN','YJN','YKN','YMN','SO','HZ','RSN','YO'
							 ,'YOT','UX','HU','HUT') then 'CME (excl NYMEX)'				 
	   when b.ExchangeName like 'Eurex%' then 'Eurex'
	   when b.ExchangeName like 'FIX%' then 'FIX'
	   when b.ExchangeName like 'ICE_IPE%' then 'ICE_IPE'
	   when b.ExchangeName like 'LME%' then 'LME'
	   when b.ExchangeName like 'MEFF%' then 'MEFF'
	   when b.ExchangeName like 'MX%' then 'MX'
	   when b.ExchangeName like 'NYSE_LIFFE-%' OR b.ExchangeName = 'NYSE_LIFFE' then 'NYSE_LIFFE'
	   when b.ExchangeName like 'NYSE_Liffe_US%' then 'NYSE_LIFFE_US'
	   when b.ExchangeName like 'OSE%' then 'OSE'
	   when b.ExchangeName like 'SFE%' then 'SFE'
	   when b.ExchangeName like 'SGX%' then 'SGX'
	   when b.ExchangeName like 'TFX%' then 'TFX'
	   when b.ExchangeName like 'TOCOM%' then 'TOCOM'
	   when b.ExchangeName like 'TSE%' then 'TSE'
	   when b.ExchangeName like 'TTSIM%' then 'TTSIM'
	   Else b.ExchangeName 	 
  End as ExchangeConsolidated
, a.Fills
, a.ProductName
,a.month as fMonth
,a.year as fYear
, a.TransactionDate
,a.AXCompany
,a.CustomerGroup
from
	(
	select  UserName
	, ExchangeId
	, Fills
	, ProductName
	, F.AccountId
	,F.month
	,F.year
	, TransactionDate
	,DataAreaId as AXCompany
	, CustGroup as CustomerGroup
	from dbo.fills F left join (select distinct year,month,accountid,dataareaid,custgroup from MonthlyBillingData)M
	on F.Year=M.Year and F.Month=M.Month and F.AccountId=M.AccountId
	where 
IsBillable='Y'
--and m.Year=2013 and m.Month=11
	
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








GO


