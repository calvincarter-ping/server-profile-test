# -----------------------------------------------------------
# Create table api_audit_log
# -----------------------------------------------------------

CREATE TABLE api_audit_log (
    ID                   INTEGER PRIMARY KEY,
    D_TIME               TIMESTAMP,
    EXCHANGE_ID          VARCHAR2(255),
    TRACKING_ID          VARCHAR2(255),
    SUBJECT              VARCHAR2(255),
    AUTH_MECH            VARCHAR2(255),
    CLIENT               VARCHAR2(255),
    METHOD               VARCHAR2(255),
    REQUEST_URI          CLOB,
    RESPONSE_CODE        INTEGER
);

CREATE SEQUENCE api_audit_log_sequence
START WITH 1
INCREMENT BY 1;

CREATE OR REPLACE TRIGGER api_audit_log_trigger BEFORE INSERT ON api_audit_log REFERENCING NEW AS NEW FOR EACH ROW BEGIN SELECT api_audit_log_sequence.nextval INTO :NEW.ID FROM dual;

END;
.
RUN

