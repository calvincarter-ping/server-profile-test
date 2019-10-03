/* ------------------------------------------------------------
 * Create table agent_audit_log
 */------------------------------------------------------------

CREATE TABLE agent_audit_log (
    ID                  SERIAL PRIMARY KEY,
    D_TIME              TIMESTAMP WITHOUT TIME ZONE,
    EXCHANGE_ID         VARCHAR(255),
    TRACKING_ID         VARCHAR(255),
    ROUND_TRIP_MS       INT,
    REQUESTED_RESOURCE  VARCHAR(255),
    CLIENT              VARCHAR(255),
    METHOD              VARCHAR(255),
    REQUEST_URI         TEXT,
    RESPONSE_CODE       INT,
    APPLICATION_NAME    VARCHAR(255),
    RESOURCE_NAME       VARCHAR(255),
    PATH_PREFIX         VARCHAR(255)
);