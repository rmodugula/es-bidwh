use bidw
select sum(billedamount) from Reporting.BillingDataSummary
where year=2019 and month=6 and screens='screens'

select sum(billedamount) from MonthlyBillingDataSummary
where year=2019 and month=6 and screens='screens'


select sum(billedamount) from MonthlyBillingDataAggregate
where year=2019 and month=6 and screens='screens'

select sum(billedamount) from MonthlyBillingDataAggregate_domo
where year=2019 and month=6 and screens='screens'


select sum(billedamount) from [dbo].[MonthlyBillingDataAggregate_MasterUser]
where year=2019 and month=6 and screens='screens'


select sum(billedamount) from [dbo].[MonthlyBillingDataAggregate_MasterUser_Coverage]
where year=2019 and month=6 and screens='screens'


select sum(contracts),sum(volume) from fills
where year=2019 and month=6 and platform='ttweb'

select sum(contracts),sum(volume) from fillsummary
where year=2019 and month=6 and platform='ttweb'

select sum(quantity) from chisql20.[TTFills].[dbo].[AggregatedFills]
where year=2019 and month=6 and billable=1
and axproductid<>'84000'
