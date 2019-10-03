# -----------------------------------------------------------
# Create table agent_audit_log
# -----------------------------------------------------------

CREATE TABLE agent_audit_log (
    ID                  INT NOT NULL IDENTITY (1, 1),
    D_TIME              DATETIME NULL,
    EXCHANGE_ID         NVARCHAR(255) NULL,
    TRACKING_ID         NVARCHAR(255) NULL,
    ROUND_TRIP_MS       INT NULL,
    REQUESTED_RESOURCE  NVARCHAR(255) NULL,
    CLIENT              NVARCHAR(255) NULL,
    METHOD              NVARCHAR(255) NULL,
    REQUEST_URI         NVARCHAR(MAX),
    RESPONSE_CODE       INT NULL,
    APPLICATION_NAME    NVARCHAR(255) NULL,
    RESOURCE_NAME       NVARCHAR(255) NULL,
    PATH_PREFIX         NVARCHAR(255) NULL,
    CONSTRAINT PK_agent_audit_log PRIMARY KEY(ID ASC) ON [PRIMARY]
) ON [PRIMARY]
GO