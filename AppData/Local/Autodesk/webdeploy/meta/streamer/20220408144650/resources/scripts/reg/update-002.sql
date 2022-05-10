-- Updates a version 2 database to version 3

PRAGMA foreign_keys = no;
BEGIN TRANSACTION;

-- Create the new version TABLE
CREATE TABLE tblREGISTRY2 (
  'version' INTEGER);
INSERT INTO tblREGISTRY2 ('version') VALUES (3);

-- Get the original version table current
UPDATE tblREGISTRY SET 'version' = 3;

-- Change the Primary Key For the Applications table.  Not allowed
-- by alter-table, so handling by create temp, populate, delete, rename
CREATE TABLE tmpAPPLICATIONS (
    'uuid' VARCHAR(41),
    'stream' VARCHAR(10),
    'version' VARCHAR(20) NOT NULL,
    'manifest' TEXT,
    CONSTRAINT "PK" PRIMARY KEY ('uuid', 'stream'));

INSERT INTO tmpAPPLICATIONS ('uuid', 'stream', 'version', 'manifest')
  SELECT app.uuid, strm.tag as stream, app.version, app.manifest
   FROM tblAPPLICATIONS AS app, tblSTREAM AS strm;

DROP TABLE tblAPPLICATIONS;
ALTER TABLE tmpAPPLICATIONS RENAME TO tblAPPLICATIONS;

-- Change the Primary Key for the Packages table
CREATE TABLE tmpPACKAGES (
    'checksum' VARCHAR(41),
    'stream' VARCHAR(10),
    'install_size' INTEGER,
    'manifest' TEXT,
    CONSTRAINT "PK" PRIMARY KEY ('checksum', 'stream'));

INSERT INTO tmpPACKAGES ('checksum', 'stream', 'install_size', 'manifest')
  SELECT pkg.checksum, strm.tag AS stream, pkg.install_size, pkg.manifest
    FROM tblPACKAGES AS pkg, tblSTREAM AS strm;

DROP TABLE tblPACKAGES;
ALTER TABLE tmpPACKAGES RENAME TO tblPACKAGES;

-- Change the Primary Key for the Package/Application relationship table.
CREATE TABLE tmpAPPLICATIONPACKAGES (
    'application' VARCHAR(41),
    'package' VARCHAR(41),
    'appstream' VARCHAR(10),
    'pkgstream' VARCHAR(10),
    CONSTRAINT "APP_FK" FOREIGN KEY ('application', 'appstream')
      REFERENCES tblAPPLICATIONS ('uuid', 'stream'),
    CONSTRAINT "PKG_FK" FOREIGN KEY ('package', 'pkgstream')
      REFERENCES tblPACKAGES ('checksum', 'stream')
    );

INSERT INTO tmpAPPLICATIONPACKAGES ('application', 'appstream', 'package',
                                    'pkgstream')
  SELECT  apkg.application, strm.tag AS appstream, apkg.package, strm.tag AS pkgstream
    FROM tblAPPLICATIONPACKAGES AS apkg, tblSTREAM AS strm;

DROP TABLE tblAPPLICATIONPACKAGES;
ALTER TABLE tmpAPPLICATIONPACKAGES RENAME TO tblAPPLICATIONPACKAGES;

-- Change the Primary Key for the files table.
CREATE TABLE tmpFILES (
    'pkgid' VARCHAR(41),
    'stream' VARCHAR(10),
    'path' VARCHAR(1024) PRIMARY KEY,
    CONSTRAINT "PKG_FK" FOREIGN KEY ('pkgid', 'stream')
      REFERENCES tblPACKAGES ('checksum', 'stream')
      ON DELETE SET NULL
);

INSERT INTO tmpFILES ('pkgid', 'stream', 'path')
  SELECT f.pkgid, strm.tag AS stream,  f.path
    FROM tblFILES AS f, tblSTREAM AS strm;

DROP TABLE tblFILES;
ALTER TABLE tmpFILES RENAME TO tblFILES;

-- Add the new, special stream last so that it doesn't complicate our
-- table copies/select statments.
INSERT INTO tblSTREAM  ('tag') VALUES ('_ALL');

-- Correct the references to the special "Materials" Package which is shared
-- by all streams.
UPDATE tblFILES SET 'stream' = '_ALL'
  WHERE pkgid = 'd4930ee3984d127e017b1484d10f6c6c05154582' OR
    pkgid = '6c3147ce73a0134fcf9fa05da85f443ae9e45e7a';
UPDATE tblPACKAGES SET 'stream' = '_ALL'
  WHERE checksum = 'd4930ee3984d127e017b1484d10f6c6c05154582' OR
    checksum = '6c3147ce73a0134fcf9fa05da85f443ae9e45e7a';
UPDATE tblAPPLICATIONPACKAGES SET 'pkgstream' = '_ALL'
  WHERE package = 'd4930ee3984d127e017b1484d10f6c6c05154582' OR
    package = '6c3147ce73a0134fcf9fa05da85f443ae9e45e7a';


COMMIT TRANSACTION;
PRAGMA foreign_keys = yes;
