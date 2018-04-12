drop schema if exists forum_example;
create schema forum_example;

drop schema if exists forum_example_private;
create schema forum_example_private;

drop table if exists forum_example.person;
create table forum_example.person(
    id serial primary key,
    first_name text not null check (char_length(first_name) < 80),
    last_name text check (char_length(last_name) < 80),
    about text,
    created_at timestamp default now()
);

comment on table forum_example.person is 'A user of the forum';
comment on table forum_example.person.id is 'The primary unique identifier for the person';
comment on table forum_example.person.first_name is 'The person`s first name';
comment on table forum_example.person.last_name is 'The person`s last name';
comment on table forum_example.person.about is 'A short description about the person, written by itself';
comment on table forum_example.person.created_at is 'The time this record was created';

create type forum_example.post_topic as enum (
    'discussion',
    'inspiration',
    'help',
    'showcase'
);

create table forum_example.post(
    id serial primary key,
    author_id integer not null references forum_example.person(id),
    headline text not null check(char_length(headline) < 280),
    body text,
    topic forum_example.post_topic,
    created_at timestamp default now()
);

comment on table forum_example.post is 'A forum post written by a person';
comment on table forum_example.post.id is 'The primary key for the post';
comment on table forum_example.post.headline is 'The title of the post';
comment on table forum_example.post.author_id is 'The id of the author person';
comment on table forum_example.post.topic is 'The topic this has been posted in';
comment on table forum_example.post.body is 'The main body text of our post';
comment on table forum_example.post.created_at is 'The time this post was created';

