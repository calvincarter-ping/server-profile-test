# -----------------------------------------------------------
# Create table agent_audit_log
# -----------------------------------------------------------

CREATE TABLE agent_audit_log (
    ID                  INTEGER PRIMARY KEY,
    D_TIME              TIMESTAMP,
    EXCHANGE_ID         VARCHAR2(255),
    TRACKING_ID         VARCHAR2(255),
    ROUND_TRIP_MS       INTEGER,
    REQUESTED_RESOURCE  VARCHAR2(255),
    CLIENT              VARCHAR2(255),
    METHOD              VARCHAR2(255),
    REQUEST_URI         CLOB,
    RESPONSE_CODE       INTEGER,
    APPLICATION_NAME    VARCHAR2(255),
    RESOURCE_NAME       VARCHAR2(255),
    PATH_PREFIX         VARCHAR2(255)
);

CREATE SEQUENCE agent_audit_log_sequence
START WITH 1
INCREMENT BY 1;

CREATE OR REPLACE TRIGGER agent_audit_log_trigger BEFORE INSERT ON agent_audit_log REFERENCING NEW AS NEW FOR EACH ROW BEGIN SELECT agent_audit_log_sequence.nextval INTO :NEW.ID FROM dual;

END;
.
RUN
