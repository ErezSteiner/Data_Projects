--The table information can be easily viewed in the file "DB_CREATE_NO_INSERTS.sql"
--But the tables and the cols are named in a self evident manner

--First some basic exploration, just to see how much data I'm dealing with for the 2024 regular NBA season.

SELECT
        COUNT(p.Player_ID) AS tot_players
FROM Players AS p; 
--568 players
--can also do a COUNT(DISTINCT Player_ID) on player_teams to get the same number


SELECT 
        count(g.Game_ID) AS tot_games
FROM Games AS g;
--with 30 teams and 82 games played by each team, we expect 2460 games.
--each game has two teams playing in it, so the actual game IDs we get is 1230.

SELECT
        s.Shot_Made,
        COUNT(s.Shot_ID) AS tot_shot
FROM Shots AS s
GROUP BY s.Shot_Made;

-- 103,793 baskets and 114,962 misses for a total of 218,701 shot attempts.

--The original data has a COL for a shot made that is TRUE/FALSE,
--And a col for the type of shot: 2/3 points.
--The next order of business is to create a view that has a new caculated col
--With the actual amount of points awarded from the shot attempt, 0, 2 or 3.
--(free throw attempts are are not considered a "shot attempt here" and are not recorded)

GO
CREATE VIEW vw_points_scored AS
SELECT 
    s.Shot_ID,
    s.Player_ID,
    s.Game_ID,
        CASE
            WHEN Shot_Made = 0
                THEN 0
            WHEN Shot_Made = 1 AND Shot_Type = '2PT Field Goal'
                THEN 2
            WHEN Shot_Made = 1 AND Shot_Type = '3PT Field Goal'
                THEN 3
            END AS points_scored
FROM Shots AS s;
GO
--Not holding any other information in the view beside the keys and the score, I'll join everything else as needed.

SELECT 
    sum(points_scored) AS tot_pnts
FROM vw_points_scored;

--a total of 239,057 of non penalty points were scored in the season.



