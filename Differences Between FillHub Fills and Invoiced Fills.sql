select z.*,MasterAccountName,AccountName,ProductName from											
(											
select a.Year,a.Month,a.Username,a.Accountid,a.ProductSku,a.fills as BIDWFills,b.fills as CacheFills,a.fills-b.fills as Difference,InvoicedAmount from											
(											
Select Year,Month,Username,Accountid,AxProductId as ProductSku,sum(fills) as Fills from fills F											
left join product p on f.AxProductId=p.ProductSku											
where year=2016 and month=6 and platform<>'ttweb'											
and isbillable='Y'											
group by Year,Month,Username,AccountId,AxProductId											
)A											
left join											
(											
SELECT Year,Month,lineitemidentifier as Userid,IC.CompanyId as [Accountid],pfwcode as Productsku,sum(fillquantity) as Fills,sum(total) as InvoicedAmount from chisql20.[Licensing2].[dbo].[InvoiceLineItem] I											
Left Join chisql20.[Licensing2].[dbo].[Invoice] IC on I.InvoiceId=IC.InvoiceId											
left join  chisql20.[Licensing2].[dbo].[Product] P on I.ProductId=P.ProductId											
where year=2016 and month=6											
group by Year,Month,lineitemidentifier,IC.CompanyId,pfwcode											
)B											
on A.Year=b.year and a.Month=b.month and a.username=b.userid and a.accountid=b.Accountid and a.ProductSku=b.Productsku											
)Z											
Left join chisql12.bidw.dbo.account A on z.AccountId=a.Accountid											
left join chisql12.bidw.dbo.product p on z.ProductSku=p.ProductSku											
where difference<>0											