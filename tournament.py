#!/usr/bin/env python
#
# tournament.py -- implementation of a Swiss-system tournament
#

import psycopg2


def connect():
    """Connect to the PostgreSQL database.  Returns a database connection."""
    db = psycopg2.connect("dbname=tournament")
    cur = db.cursor()
    return db, cur


def deleteMatches():
    """Remove all the match records from the database."""
    db, cur = connect()
    cur.execute("delete from matches;")
    db.commit()
    cur.close()


def deletePlayers():
    """Remove all the player records from the database."""
    db, cur = connect()
    cur.execute("delete from players;")
    db.commit()
    cur.close()


def countPlayers():
    """Returns the number of players currently registered."""
    db, cur = connect()
    cur.execute("select count(id) from players;")
    # remove tuple wrapper from fetched result.
    (count,) = cur.fetchone()
    cur.close()
    # return 0 instead of None when there are no players registered
    ret = count if count else 0
    return ret


def registerPlayer(name):
    """Adds a player to the tournament database.

    The database assigns a unique serial id number for the player.  (This
    should be handled by your SQL database schema, not in your Python code.)

    Args:
      name: the player's full name (need not be unique).
    """
    db, cur = connect()
    cur.execute("insert into players ( name ) values ( %s );", (name,))
    db.commit()
    cur.close()


def playerStandings():
    """Returns a list of the players and their win records, sorted by wins.

    The first entry in the list should be the player in first place, or a
    player tied for first place if there is currently a tie.

    Returns:
      A list of tuples, each of which contains (id, name, wins, matches):
        id: the player's unique id (assigned by the database)
        name: the player's full name (as registered)
        wins: the number of matches the player has won
        matches: the number of matches the player has played
    """
    db, cur = connect()
    cur.execute("select * from standings;")
    ret = cur.fetchall()
    return ret


def reportMatch(winner, loser):
    """Records the outcome of a single match between two players.

    Args:
      winner:  the id number of the player who won
      loser:  the id number of the player who lost
    """
    winning_score = 3
    losing_score = 0

    # insert into matches, return new match id.
    db, cur = connect()
    cur.execute(
        "insert into matches (winner_id, loser_id) "
        "values (%s, %s) returning id;", (winner, loser))
    (matchid,) = cur.fetchone()

    # create player stats entry for each player

    cur.execute(
        "insert into player_game_stats "
        "(match_id, player_id, score, player_won) values "
        "(%s, %s, %s, %s);",
        (matchid, winner, winning_score, True))

    cur.execute(
        "insert into player_game_stats "
        "(match_id, player_id, score, player_won) values "
        "(%s, %s, %s, %s);",
        (matchid, loser, losing_score, False))

    db.commit()


def swissPairings():
    """Returns a list of pairs of players for the next round of a match.

    Assuming that there are an even number of players registered, each player
    appears exactly once in the pairings.  Each player is paired with another
    player with an equal or nearly-equal win record, that is, a player adjacent
    to him or her in the standings.

    Returns:
      A list of tuples, each of which contains (id1, name1, id2, name2)
        id1: the first player's unique id
        name1: the first player's name
        id2: the second player's unique id
        name2: the second player's name
    """

    db, cur = connect()
    # fetch list of players ordered by wins
    cur.execute("select id,name from standings;")
    p = cur.fetchall()
    # slice players list and pair up top players
    ret = [(a[0], a[1], b[0], b[1]) for a, b in zip(p[::2], p[1::2])]
    print ret
    return ret
