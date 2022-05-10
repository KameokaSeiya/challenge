-- Updates a version 1 database to version 2

BEGIN TRANSACTION;

ALTER TABLE tblFILES ADD COLUMN 'taskid' VARCHAR(32);

-- Get the version current
UPDATE tblREGISTRY2 SET 'version' = 4;

COMMIT TRANSACTION;