select year,month,sum(cancels) as Cancels from ChurnedUsersByMonth
where ChurnType='core' and cancels>0 and ReasonForLeaving not like '%stop%'
Group by Year,Month
order by 1,2


select date,sum(adds) from UserAddsByMonth
Group by date
order by 1

