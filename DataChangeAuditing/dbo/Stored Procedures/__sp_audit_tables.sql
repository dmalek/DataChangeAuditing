
create procedure [dbo].[__sp_audit_tables]
as
select
	object_name(g.parent_id) as table_name,
    g.name as trigger_name,
	g.is_disabled	
from sys.triggers g 
where 
    g.type = 'tr'
	and g.name like '__%_audittr_iud';
