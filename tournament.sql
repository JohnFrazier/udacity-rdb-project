-- Table definitions for the tournament project.
--
-- Put your SQL 'create table' statements in this file; also 'create view'
-- statements if you choose to use it.
--
-- You can write comments in this file by starting them with two dashes, like
-- these lines here.


create table players (id serial primary key, name varchar(80));


create table matches (
	id serial primary key, winner_id integer, loser_id integer);


create table player_game_stats(
	-- create a row for each player and game
	id serial primary key, match_id integer, player_id integer,
	player_won boolean);


-- standings view returns id, name, win count, and match count
create view standings as
	select players.id, players.name,
	-- count number of entries where player_won is true
	count(nullif(player_won = false, true)) as wins,
	-- count game stats to get matches
	count(player_game_stats) as matches
	-- join players and game stats by id
	-- right join to include players that haven't played yet
	from player_game_stats right join players
	on player_game_stats.player_id = players.id
	group by players.id
	order by wins desc;


-- whenever an row goes into matches, insert rows in player_game_stats
-- for the match players
create or replace function fill_player_stats() returns trigger as $$
begin
	insert into player_game_stats(match_id, player_id, player_won)
	values(new.id, new.winner_id, true);

	insert into player_game_stats(match_id, player_id, player_won)
	values(new.id, new.loser_id, false);

	return new;
end
$$ language plpgsql;

create trigger fill_on_match after insert on matches for each row
	execute procedure fill_player_stats();


-- whenever players are removed, remove them from player_game_stats
-- and matches

create function removed_player() returns trigger as $$
begin
	delete from player_game_stats where player_id = old.id;

	return old;
end $$ language plpgsql;

create trigger remove_player before delete on players for each row
	execute procedure removed_player();
