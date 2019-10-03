# -----------------------------------------------------------
# Create table engine_audit_log
# -----------------------------------------------------------

CREATE TABLE engine_audit_log (
    ID                          INT NOT NULL IDENTITY (1, 1),
    D_TIME                      DATETIME NULL,
    EXCHANGE_ID                 NVARCHAR(255) NULL,
    TRACKING_ID                 NVARCHAR(255) NULL,
    ROUND_TRIP_MS               INT NULL,
    PROXY_ROUND_TRIP_MS         INT NULL,
    USER_INFO_ROUND_TRIP_MS     INT NULL,
    REQUESTED_RESOURCE          NVARCHAR(255) NULL,
    SUBJECT                     NVARCHAR(255) NULL,
    AUTH_MECH                   NVARCHAR(255) NULL,
    CLIENT                      NVARCHAR(255) NULL,
    METHOD                      NVARCHAR(255) NULL,
    REQUEST_URI                 NVARCHAR(MAX) NULL,
    RESPONSE_CODE               INT,
    FAILED_RULE_TYPE            NVARCHAR(255) NULL,
    FAILED_RULE_NAME            NVARCHAR(255) NULL,
    FAILED_RULE_CLASS           NVARCHAR(2048) NULL,
    APPLICATION_NAME            NVARCHAR(255) NULL,
    RESOURCE_NAME               NVARCHAR(255) NULL,
    PATH_PREFIX                 NVARCHAR(255) NULL,
    CONSTRAINT PK_engine_audit_log PRIMARY KEY(ID ASC) ON [PRIMARY]
) ON [PRIMARY]
GO
