USE `ledger`;
DROP procedure IF EXISTS `sp_period_end_cal`;

DELIMITER $$
USE `ledger`$$
PROCEDURE `sp_period_end_cal`()
BEGIN
create temporary table total as 
select sum(amount_paid) as total ,period_id,paid_id from ledger.expense_detail exp
where exp.period_id in (select Period_id from ledger.period_detail c where curdate() between c.Starting_from and c.Ending_on)
group by exp.period_id,exp.paid_id;

create temporary table credit as 
select sum(amount_paid) as total ,period_id,paid_id from ledger.misc_credit cred
where cred.period_id in (select Period_id from ledger.period_detail c where curdate() between c.Starting_from and c.Ending_on)
group by cred.period_id,cred.paid_id;

insert into expense_summary(amount,period_id,paid_id)
select  
ifnull((a.total-b.total),a.total) as total,a.period_id,a.paid_id
from total a left join credit b
on  a.period_id=b.period_id
and a.paid_id=b.paid_id;

/*Code added here*/
insert into expense_summary(amount,period_id,paid_id)
select sum(-pp.total) as total ,pp.period_id,pp.paid_id from credit pp
where not exists (select * from total cc where cc.paid_id =pp.paid_id)
group by pp.paid_id,pp.period_id;
/*Ends here*/

drop temporary table total;
drop temporary table credit;

END$$

DELIMITER ;

