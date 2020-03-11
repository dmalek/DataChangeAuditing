
CREATE     procedure [dbo].[__sp_audit_log]
	@proc_id int,
	@table_name as nvarchar(100),
	@key_name as nvarchar(100),
	@user_name as nvarchar(50),
	@deleted as xml,
	@inserted as xml
as

-- akcije: -1 ignoriraj, 1 DELETE, 2 INSERT, 3 UPDATE (before), 4 UPDATE (after)
declare 
	@deleted_action as int = -1,								-- što bilježimo za podatke iz delete tablice
	@insertd_action as int = -1;								-- što bilježimo za podatke iz inserted tablice

if iif(@deleted is not null, 1, 0) = 0 and iif(@inserted is not null, 1, 0) = 1	
begin
	--	INSERT
	set @deleted_action = -1
	set @insertd_action = 2			-- (-1 ako ne želimo bilježiti nove zapisa)
end
else if iif(@deleted is not null, 1, 0) = 1 and iif(@inserted is not null, 1, 0) = 1	
begin
	--	UPDATE
	set @deleted_action = 3
	set @insertd_action = 4			-- (-1 ako ne želimo bilježiti nove vrjednosti zapisa)		
end
else if iif(@deleted is not null, 1, 0) = 1 and iif(@inserted is not null, 1, 0) = 0
begin
	--	DELETE
	set @deleted_action = 1
	set @insertd_action = -1		
end
        	 
begin try
	-- upiši stare vrijednosti podataka
	if (@deleted_action > 0)
		insert into __audit_log( [__$transaction_id], [__$audit_datetime], [__$database_name], [__$schema_name], [__$table_name], [__$key_name], [__$key_value], [__$action], [__$row_xml], [__$host_name], [__$user_name], [__$proc_name],[__$application_name]) 
		select 		
			current_transaction_id(), getdate(), db_name(), schema_name(), @table_name, @key_name, 
			row.value('(*[local-name()=sql:variable("@key_name")])[1]', 'varchar(100)') as key_value,
			@deleted_action, 
			row.query('.') as row_xml,	
			host_name(), @user_name, object_name(@proc_id), app_name()
		from 
			@deleted.nodes('/row') as ref(row)	

	-- upiši nove vrijednosti podataka
	if (@insertd_action > 0)
		insert into __audit_log( [__$transaction_id], [__$audit_datetime], [__$database_name], [__$schema_name], [__$table_name], [__$key_name], [__$key_value], [__$action], [__$row_xml], [__$host_name], [__$user_name], [__$proc_name],[__$application_name]) 
		select 		
			current_transaction_id(), getdate(), db_name(), schema_name(), @table_name, @key_name, 
			row.value('(*[local-name()=sql:variable("@key_name")])[1]', 'varchar(100)') as key_value,
			@insertd_action, 
			row.query('.') as row_xml,		
			host_name(), @user_name, object_name(@proc_id), app_name()
		from 
			@inserted.nodes('/row') as ref(row)
end try   
begin catch 
	-- ništa
end catch
