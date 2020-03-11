
CREATE procedure [dbo].[__sp_audit_get_changes]
	@schema_name as varchar(100),
	@table_name as nvarchar(100),
	@from_date as datetime = null,
	@to_date as datetime = null,
	@key_value as nvarchar(100) = null
as
declare
	@database_name nvarchar(100) = db_name(),
	@columns as nvarchar(max),
	@query as nvarchar(max);
	
	select @columns =
		stuff(
		(
        select 
			',' 
			+ '__$row_xml.value(''' 
			+ '(row/' + column_name + ')[1]'', ''' 
			+  data_type +
				case
					when data_type = 'nvarchar' then '(' + char_max_length + ')'
					when data_type = 'varchar' then '(' + char_max_length + ')'
					when data_type = 'nchar' then '(' + char_max_length + ')'
					when data_type = 'char' then '(' + char_max_length + ')'
					when data_type = 'decimal' then '(' + numeric_precision_scale +  ')'
					else ''
				end
			+ '' 
			+ ''') as ' + column_name 
        from (
			select top 100 percent
				*,
				iif(character_maximum_length = -1, 'max', cast(character_maximum_length as varchar(20))) as char_max_length,
				cast(numeric_precision as varchar(20)) + ', ' + cast(numeric_scale as varchar(20)) as numeric_precision_scale
			from information_schema.columns 
			where 
				table_name = @table_name
				and table_schema = @schema_name
			order by ordinal_position	
		) c
		for xml path('')				
	), 1, 1, '')



set @query = '
select
	__$audit_id,
	__$transaction_id,
	__$audit_datetime,
	__$action,
	case 
		when __$action = 1 then ''DELETE''
		when __$action = 2 then ''INSERT''
		when __$action = 3 then ''UPDATE (before)''
		when __$action = 4 then ''UPDATE (after)''
	end as __$action_name,
	__$host_name,
	__$user_name,
	__$proc_name,
	__$application_name,
	__$key_name,
	__$key_value,
	'
	+ @columns + '
from __audit_log 
where 
	__$database_name = @database_name and
	__$schema_name = @schema_name and
	__$table_name = @table_name 
'

if (@from_date is not null)
	set @query = @query + ' and __$audit_datetime >= @from_date'

if (@to_date is not null)
	set @query = @query + ' and __$audit_datetime <= @to_date'

if (@key_value is not null) 
	set @query = @query + ' and __$key_value = @key_value'


exec sp_executesql 
	@query, 
	N'@database_name nvarchar(100), @schema_name nvarchar(100), @table_name nvarchar(100), @key_value nvarchar(100), @from_date datetime, @to_date datetime', 
	@database_name = @database_name,
	@schema_name = @schema_name,
	@table_name = @table_name, 
	@from_date = @from_date,
	@to_date = @to_date,
	@key_value = @key_value
	
