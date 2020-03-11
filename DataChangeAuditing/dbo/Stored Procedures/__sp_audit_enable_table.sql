

CREATE procedure [dbo].[__sp_audit_enable_table] 	
	@schema_name varchar(100),
	@table_name varchar(100),
	@key_name varchar(100),
	@captured_column_list varchar(100)
as

if (@schema_name is null)
	set @schema_name = schema_name();

if (@captured_column_list is null)
	set @captured_column_list = '*';

declare @sqltext nvarchar(max) = '
CREATE OR ALTER TRIGGER [' + @schema_name + '].[__' + @table_name + '_audittr_iud] ON ['+ @schema_name + '].['+ @table_name + ']
WITH EXECUTE AS CALLER
FOR INSERT, UPDATE, DELETE
AS
BEGIN
    set nocount on
  
	declare @user_name as nvarchar(100) = suser_sname()
    declare @deleted as xml 
	declare @inserted as xml 
    
	set @deleted = (select ' + @captured_column_list + ' from deleted for xml path (''row''))
    set @inserted = (select ' + @captured_column_list + ' from inserted for xml path (''row''))
        
    exec __sp_audit_log 
		@proc_id = @@procid,
		@table_name = ''' + @table_name + ''',
		@key_name = ''' + @key_name + ''',
		@user_name = @user_name,
		@deleted = @deleted,
		@inserted = @inserted 

END
'

exec sp_executesql @sqltext;
