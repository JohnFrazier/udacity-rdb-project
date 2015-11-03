-- Table definitions for the tournament project.
--
-- Put your SQL 'create table' statements in this file; also 'create view'
-- statements if you choose to use it.
--
-- You can write comments in this file by starting them with two dashes, like
-- these lines here.

create table players (id serial primary key, name varchar(80));


create table matches (
	id serial primary key, player1_id integer, player2_id integer);


create table player_game_stats(
	-- create a row for each player and game
	id serial primary key, match_id integer, player_id integer,
	score integer, player_won boolean);


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

