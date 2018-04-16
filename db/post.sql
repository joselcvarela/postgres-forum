create type $SCHEMA.post_topic as enum (
    'discussion',
    'inspiration',
    'help',
    'showcase'
);

create table $SCHEMA.post(
    id serial primary key,
    author_id integer not null references $SCHEMA.person(id),
    headline text not null check(char_length(headline) < 280),
    body text,
    topic $SCHEMA.post_topic,
    created_at timestamp default now()
);

comment on table $SCHEMA.post is 'A forum post written by a person';
comment on column $SCHEMA.post.id is 'The primary key for the post';
comment on column $SCHEMA.post.headline is 'The title of the post';
comment on column $SCHEMA.post.author_id is 'The id of the author person';
comment on column $SCHEMA.post.topic is 'The topic this has been posted in';
comment on column $SCHEMA.post.body is 'The main body text of our post';
comment on column $SCHEMA.post.created_at is 'The time this post was created';
grant select on table $SCHEMA.post to $SCHEMA_$ANON, $SCHEMA_$FUSER;
grant insert, update, delete on table $SCHEMA.post to $SCHEMA_$FUSER;
grant usage on sequence $SCHEMA.post_id_seq to $SCHEMA_$FUSER;
alter table $SCHEMA.post enable row level security;
create policy select_post on $SCHEMA.post for select using(true);
create policy insert_post on $SCHEMA.post for insert with check(
    author_id = current_setting('jwt.claim.person_id')::integer
);
create policy update_post on $SCHEMA.post for update using(
    author_id = current_setting('jwt.claim.person_id')::integer
);
create policy delete_post on $SCHEMA.post for delete using(
    author_id = current_setting('jwt.claim.person_id')::integer
);

create function $SCHEMA.post_summary(
    post $SCHEMA.post,
    length int default 50,
    omission text default '...'
) returns text as $$
    select case
        when post.body is null then null
        else substr(post.body, length) || omission
    end
$$ language sql stable;

comment on function $SCHEMA.post_summary($SCHEMA.post, int, text) is 'A truncated version for the body of summaries';
grant execute on function $SCHEMA.post_summary($SCHEMA.post, int, text) to $SCHEMA_$ANON, $SCHEMA_$FUSER;

create function $SCHEMA.person_latest_post(
    person $SCHEMA.person
) returns $SCHEMA.post as $$
    select post.*
    from $SCHEMA.post as post
    where post.author_id = person.id
    order by created_at desc
    limit 1
$$ language sql stable;

comment on function $SCHEMA.person_latest_post($SCHEMA.person) is 'Get`s the latest post written by the person';
grant execute on function $SCHEMA.person_latest_post($SCHEMA.person) to $SCHEMA_$ANON, $SCHEMA_$FUSER;

create function $SCHEMA.search_posts(
    search text
) returns setof $SCHEMA.post as $$
    select post.*
    from $SCHEMA.post
    where post.headline ilike ('%' || search || '%') or post.body ilike ('%' || search || '%')
$$ language sql stable;

comment on function $SCHEMA.search_posts(text) is 'Returns posts containing a given search term';
grant execute on function $SCHEMA.search_posts(text) to $SCHEMA_$ANON, $SCHEMA_$FUSER;

alter table $SCHEMA.post add column updated_at timestamp default now();
comment on column $SCHEMA.post.updated_at is 'Gives last date this post was updated';

create trigger post_updated_at before update
    on $SCHEMA.post
    for each row
    execute procedure $SCHEMA_private.set_updated_at();
