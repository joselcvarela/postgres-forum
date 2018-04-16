drop database ff;

create database ff;

\c ff

alter default privileges revoke execute on functions from public;

create schema $SCHEMA;

create schema $SCHEMA_private;

create role $POSTGRES_USER login password '$POSTGRES_PASSWORD';

create role $SCHEMA_$ANON;
grant $SCHEMA_$ANON to $POSTGRES_USER;

create role $SCHEMA_person;
grant $SCHEMA_person to $POSTGRES_USER;

grant usage on schema $SCHEMA to $SCHEMA_$ANON, $SCHEMA_person;

create function $SCHEMA_private.set_updated_at() returns trigger as $$ 
begin
    new.updated_at := current_timestamp;
    return new;
end;
$$ language plpgsql;