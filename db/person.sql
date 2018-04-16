create table $SCHEMA.person(
    id serial primary key,
    first_name text not null check (char_length(first_name) < 80),
    last_name text check (char_length(last_name) < 80),
    about text,
    created_at timestamp default now()
);

comment on table $SCHEMA.person is 'A user of the forum';
comment on column $SCHEMA.person.id is 'The primary unique identifier for the person';
comment on column $SCHEMA.person.first_name is 'The person`s first name';
comment on column $SCHEMA.person.last_name is 'The person`s last name';
comment on column $SCHEMA.person.about is 'A short description about the person, written by itself';
comment on column $SCHEMA.person.created_at is 'The time this record was created';
grant select on table $SCHEMA.person to $SCHEMA_$ANON, $SCHEMA_$FUSER;
grant update, delete on table $SCHEMA.person to $SCHEMA_$FUSER;
alter table $SCHEMA.person enable row level security;
create policy select_person on $SCHEMA.person for select using(true);
create policy update_person on $SCHEMA.person for update using(
    id = current_setting('jwt.claim.person_id')::integer
);
create policy delete_person on $SCHEMA.person for delete using(
    id = current_setting('jwt.claim.person_id')::integer
);

create function $SCHEMA.person_full_name(
    person $SCHEMA.person
) returns text as $$
    select person.first_name || ' ' || person.last_name
$$ language sql stable;

comment on function $SCHEMA.person_full_name($SCHEMA.person) is 'A person`s full name, which is a concatenation of their first and last name';
grant execute on function $SCHEMA.person_full_name($SCHEMA.person) to $SCHEMA_$ANON, $SCHEMA_$FUSER;

alter table $SCHEMA.person add column updated_at timestamp default now();
comment on column $SCHEMA.person.updated_at is 'Gives last date this person was updated';

create trigger person_updated_at before update
    on $SCHEMA.person
    for each row
    execute procedure $SCHEMA_private.set_updated_at();


create table $SCHEMA_private.person_account(
    person_id integer primary key references $SCHEMA.person(id) on delete cascade,
    email text not null unique check (email ~* '^.+@.+$'),
    password_hash text not null
);

comment on table $SCHEMA_private.person_account is 'Private information about a person`s account';
comment on column $SCHEMA_private.person_account.person_id is 'The person id associated to this account';
comment on column $SCHEMA_private.person_account.email is 'The person`s email';
comment on column $SCHEMA_private.person_account.password_hash is 'An opaque hash of the person`s password';


create extension if not exists "pgcrypto";

create function $SCHEMA.register_person(
    first_name text,
    last_name text,
    email text,
    password text
) returns $SCHEMA.person as $$
declare
    person $SCHEMA.person;
begin
    insert into $SCHEMA.person (first_name, last_name)
    values (first_name, last_name)
    returning * into person;

    insert into $SCHEMA.person_account (person_id, email, password)
    values (person.id, email, crypt(password, gen_salt('bf')));

    return person;
end
$$ language plpgsql strict security definer;

comment on function $SCHEMA.register_person(text, text, text, text) is 'Register a single person and create an account for him';
grant execute on function $SCHEMA.person_full_name($SCHEMA.person) to $SCHEMA_$ANON;



create type $SCHEMA.$JWT as(
    role text,
    person_id integer
);

create function $SCHEMA.authenticate(
    email text,
    password text
) returns $SCHEMA.$JWT as $$
declare
    account $SCHEMA_private.person_account;
begin
    select a.* into account
    from $SCHEMA_private.person_account as a
    where a.email = $1;

    if account.password_hash = crypt(password, account.password_hash) then
        return ('$SCHEMA_person', account.person_id)::$SCHEMA.$JWT;
    else
        return null;
    end if;
end
$$ language plpgsql strict security definer;

create function $SCHEMA.current_person(
) returns $SCHEMA.person as $$
    select *
    from $SCHEMA.person
    where id = current_setting('jwt.claim.person_id')::integer
$$ language sql stable;

comment on function $SCHEMA.current_person() is 'Gets the person who was identified by our JWT';

