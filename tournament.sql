-- Table definitions for the tournament project.
--
-- Put your SQL 'create table' statements in this file; also 'create view'
-- statements if you choose to use it.
--
-- You can write comments in this file by starting them with two dashes, like
-- these lines here.

drop database tournament;
create database tournament;
\c tournament;

create table players (id serial primary key, name text);

create view player_count as
	select coalesce(count(id), '0') as sum
	from players;

create table matches (
	id serial primary key, winner_id integer, loser_id integer);

-- count player losses
create view losers as
  select loser_id as id, count(loser_id) as matches from matches 
	group by loser_id;

-- count player wins
create view winners as
  select winner_id as id, count(winner_id) as matches from matches
  group by winner_id;

-- combine wins and losses views
create view player_matches as
  select * from winners full join losers using (id, matches);

-- standings view returns id, name, win count, and match count
create view standings as
	select players.id, players.name,
	-- replace null results with 0
	coalesce(winners.matches, '0') as wins,
	coalesce(player_matches.matches, '0') as matches
	-- left join to include players that haven't played yet
	from players
	left join winners on players.id = winners.id
	left join player_matches on player_matches.id = players.id
	group by players.id, winners.matches, player_matches.matches
	order by winners.matches desc;

