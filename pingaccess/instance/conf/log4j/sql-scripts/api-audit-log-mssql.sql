# -----------------------------------------------------------
# Create table api_audit_log
# -----------------------------------------------------------

CREATE TABLE api_audit_log (
    ID                   INT NOT NULL IDENTITY (1, 1),
    D_TIME               DATETIME NULL,
    EXCHANGE_ID          NVARCHAR(255) NULL,
    TRACKING_ID          NVARCHAR(255) NULL,
    SUBJECT              NVARCHAR(255) NULL,
    AUTH_MECH            NVARCHAR(255) NULL,
    CLIENT               NVARCHAR(255) NULL,
    METHOD               NVARCHAR(255) NULL,
    REQUEST_URI          NVARCHAR(MAX) NULL,
    RESPONSE_CODE        INT NULL,
    CONSTRAINT PK_api_audit_log PRIMARY KEY(ID ASC) ON [PRIMARY]
) ON [PRIMARY]
GO