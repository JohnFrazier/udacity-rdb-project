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
	select row_number() over (),
	players.id, players.name,
	-- replace null results with 0
	coalesce(winners.matches, '0') as wins,
	coalesce(player_matches.matches, '0') as matches
	-- left join to include players that haven't played yet
	from players
	left join winners on players.id = winners.id
	left join player_matches on player_matches.id = players.id
	group by players.id, winners.matches, player_matches.matches
	order by winners.matches desc;

-- create view for playerStandings()
create view playerStandings as
	select id, name, wins, matches from standings;

-- get rows with even row numbers for pairing
-- add new row numbers for later joining
create view left_players as
	select row_number() over () as row, *
	from standings s
	where mod(s.row_number, 2) = 0;

-- get rows with odd row numbers
-- add new row numbers for later joining
create view right_players as
	select row_number() over () as row, *
	from standings s
	where mod(s.row_number, 2) = 1;

-- join above on new row numbers and rename columns
create view swissPairings as
	select l.id as player1_id, l.name as player1_name,
	r.id as player2_id, r.name as player2_name
	from left_players l
	inner join right_players r
	using (row);
