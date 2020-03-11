CREATE TABLE [dbo].[__audit_log] (
    [__$audit_id]         BIGINT        CONSTRAINT [DF___audit_log_audit_id] DEFAULT (NEXT VALUE FOR [__audit_log_sequence]) NOT NULL,
    [__$transaction_id]   BIGINT        NULL,
    [__$audit_datetime]   DATETIME2 (7) NOT NULL,
    [__$database_name]    VARCHAR (100) NOT NULL,
    [__$schema_name]      VARCHAR (100) NOT NULL,
    [__$table_name]       VARCHAR (255) NOT NULL,
    [__$key_name]         VARCHAR (100) NULL,
    [__$key_value]        VARCHAR (255) NULL,
    [__$action]           INT           NULL,
    [__$row_xml]          XML           NULL,
    [__$host_name]        VARCHAR (255) NULL,
    [__$user_name]        VARCHAR (255) NULL,
    [__$application_name] VARCHAR (255) NULL,
    [__$proc_name]        VARCHAR (255) NULL,
    CONSTRAINT [PK___audit_log] PRIMARY KEY CLUSTERED ([__$audit_id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX___audit_log]
    ON [dbo].[__audit_log]([__$database_name] ASC, [__$schema_name] ASC, [__$table_name] ASC, [__$key_value] ASC);

