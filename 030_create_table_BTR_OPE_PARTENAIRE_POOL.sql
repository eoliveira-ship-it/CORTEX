--------------------------------------------------------------------------------
-- CAL-Version : 1.1                                                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Script        : 030_create_table_BTR_OPE_PARTENAIRE_POOL.sql               --
-- Objet         : Ajout table pour projet LTBCE                              --
--                                                                            --
-- Type          : Script de creation de table Oracle                         --
--------------------------------------------------------------------------------
-- Domaine       : RINT                                                       --
-- Application   : 030  - Déclarations Des Risques                            --
--------------------------------------------------------------------------------
-- Creation      : le 19/07/2022 par KLX Risque                               --
--                                                                            --
-- Modifications                                                              --
-- -------------                                                              --
-- 19/07/2022 CUNHAVI : Création table BTR_OPE_PARTENAIRE_POOL - Mantis 62593 --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
CREATE TABLE BTR_OPE_PARTENAIRE_POOL
(
    DT_ARRETE               DATE NOT NULL,     
    ID_PARTENAIRE_POOL      VARCHAR2(15) NOT NULL,
    CD_SYS_INT              VARCHAR2(5)  NOT NULL,
    ID_OPERATION            VARCHAR2(15) NOT NULL,
    ID_TYPE_POOL            VARCHAR2(1)  NOT NULL,
    QUOTE_PART_POOL         FLOAT(126)   ,
    MNT_VIVANT_FINANCMT     NUMBER(16,2) ,
    FLAG_CHEF_POOL          VARCHAR2(1)  ,
    SEQ_ID_PARTENAIRE_POOL  NUMBER(10) NOT NULL  ,
    SEQ_ID_TYPE_POOL        NUMBER(10) NOT NULL  ,
    TOP_ENG                 CHAR(1) , 
    CONSTRAINT PK_BTR_PARTENAIRE_POOL PRIMARY KEY (ID_OPERATION, ID_PARTENAIRE_POOL, CD_SYS_INT, ID_TYPE_POOL, SEQ_ID_PARTENAIRE_POOL, SEQ_ID_TYPE_POOL)
)
TABLESPACE DDR_DATA
LOGGING
NOCACHE
NOPARALLEL;

CREATE OR REPLACE PUBLIC SYNONYM BTR_OPE_PARTENAIRE_POOL FOR BTR_OPE_PARTENAIRE_POOL;
GRANT SELECT ON BTR_OPE_PARTENAIRE_POOL TO public;
GRANT SELECT ON BTR_OPE_PARTENAIRE_POOL TO SASNOTES;
GRANT SELECT ON BTR_OPE_PARTENAIRE_POOL TO ROLE_DDR_CS;
GRANT SELECT, INSERT, UPDATE, DELETE ON BTR_OPE_PARTENAIRE_POOL TO ROLE_DDR_BAT;
GRANT DEBUG ON BTR_OPE_PARTENAIRE_POOL TO ROLE_DDR_DEBUG;
--GRANT SELECT ON BTR_OPE_PARTENAIRE_POOL TO CONSULT;
COMMIT;