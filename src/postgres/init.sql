-- SELECT :'pguser';
-- SELECT :'pgpass';
-- Set the password for the user
alter user :'pguser' password :'pgpass';
-- Create database with name of user so connection that doesn't specify a database doesn't fail
create database :'pguser';
