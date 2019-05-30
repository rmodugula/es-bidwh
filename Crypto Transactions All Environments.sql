SELECT Year(TransactTime) as Year,Month(transacttime) as Month,f.[MarketId],M.MarketName
,[TransactTime] as TransactionTime,[LastQty] as LastQuantity,[Source],SourceName
,f.[UserId],Email,FirstName+' '+LastName as FullName,c.Companyid as UserCompanyId
,c.name as UserCompany,[BrokerId],cb.Name as BrokerName,f.[InstrumentId],ProductType
,Symbol as ProductName,IsManualFill,OrderId
,[FillType],[LastPrice],[LastUsdPrice],LastQty*LastUsdPrice as NotionalUSD
,'Prod-Live' as Environment
FROM [TTFills].[dbo].[fills] F
left join chisql20.Mess.dbo.Markets M on F.marketid=M.marketid
Left join chisql20.TTFills.dbo.TTSource TS on f.Source=TS.SourceId
Left Join Chisql20.Mess.dbo.Users U on f.UserId=U.userid
Left Join Chisql20.Mess.dbo.companies c on u.companyid=c.companyid
Left Join Chisql20.Mess.dbo.companies cb on f.BrokerId=cb.companyid
Left Join Chisql20.Mess.dbo.instruments I on f.InstrumentId=i.InstrumentId and f.MarketId=i.MarketId
Left Join Chisql20.Mess.dbo.exchangeproducts ep on i.productid=ep.ProductId and i.MarketId=ep.MarketId
where M.iscrypto=1 and (IsManualFill=0 or IsManualFill is null)


UNION ALL

SELECT Year(TransactTime) as Year,Month(transacttime) as Month,f.[MarketId],M.MarketName
,[TransactTime] as TransactionTime,[LastQty] as LastQuantity,[Source],SourceName
,f.[UserId],Email,FirstName+' '+LastName as FullName,c.Companyid as UserCompanyId
,c.name as UserCompany,[BrokerId],cb.Name as BrokerName,f.[InstrumentId],ProductType
,Symbol as ProductName,IsManualFill,OrderId
,[FillType],[LastPrice],[LastUsdPrice],LastQty*LastUsdPrice as NotionalUSD
,'ALT-Live' as Environment
FROM [TTFills-ALT].[dbo].[fills] F
left join chisql20.[Mess].dbo.Markets M on F.marketid=M.marketid
Left join chisql20.[TTFills].dbo.TTSource TS on f.Source=TS.SourceId
Left Join Chisql20.[Mess-ALT].dbo.Users U on f.UserId=U.userid
Left Join Chisql20.[Mess-ALT].dbo.companies c on u.companyid=c.companyid
Left Join Chisql20.[Mess-ALT].dbo.companies cb on f.BrokerId=cb.companyid
Left Join Chisql20.[Mess-ALT].dbo.instruments I on f.InstrumentId=i.InstrumentId and f.MarketId=i.MarketId
Left Join Chisql20.[Mess-ALT].dbo.exchangeproducts ep on i.productid=ep.ProductId and i.MarketId=ep.MarketId
where M.iscrypto=1 and (IsManualFill=0 or IsManualFill is null)


