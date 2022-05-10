
-- Updates a version 1 database to version 2

BEGIN TRANSACTION;

CREATE TABLE tblFILES (
  'pkgid' VARCHAR(41) CONSTRAINT 'file-pkg'
      REFERENCES tblPACKAGES ('checksum') ON DELETE SET NULL,
  'path' VARCHAR(1024) PRIMARY KEY
);

-- Get the version current
UPDATE tblREGISTRY SET 'version' = 2;

COMMIT TRANSACTION;