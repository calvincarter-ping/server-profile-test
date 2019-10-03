/* ------------------------------------------------------------
 * Create table api_audit_log
 */------------------------------------------------------------

CREATE TABLE api_audit_log (
    ID                   SERIAL PRIMARY KEY,
    D_TIME               TIMESTAMP WITHOUT TIME ZONE,
    EXCHANGE_ID          VARCHAR(255),
    TRACKING_ID          VARCHAR(255),
    SUBJECT              VARCHAR(255),
    AUTH_MECH            VARCHAR(255),
    CLIENT               VARCHAR(255),
    METHOD               VARCHAR(255),
    REQUEST_URI          TEXT,
    RESPONSE_CODE        INT
);