/* ------------------------------------------------------------
 * Create table engine_audit_log
 */------------------------------------------------------------

CREATE TABLE engine_audit_log (
    ID                          SERIAL PRIMARY KEY,
    D_TIME                      TIMESTAMP WITHOUT TIME ZONE,
    EXCHANGE_ID                 VARCHAR(255),
    TRACKING_ID                 VARCHAR(255),
    ROUND_TRIP_MS               INT,
    PROXY_ROUND_TRIP_MS         INT,
    USER_INFO_ROUND_TRIP_MS     INT,
    REQUESTED_RESOURCE          VARCHAR(255),
    SUBJECT                     VARCHAR(255),
    AUTH_MECH                   VARCHAR(255),
    CLIENT                      VARCHAR(255),
    METHOD                      VARCHAR(255),
    REQUEST_URI                 TEXT,
    RESPONSE_CODE               INT,
    FAILED_RULE_TYPE            VARCHAR(255),
    FAILED_RULE_NAME            VARCHAR(255),
    FAILED_RULE_CLASS           VARCHAR(2048),
    APPLICATION_NAME            VARCHAR(255),
    RESOURCE_NAME               VARCHAR(255),
    PATH_PREFIX                 VARCHAR(255)
);
