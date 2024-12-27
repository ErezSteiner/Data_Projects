--First I want to see the top 10 scorers for the season, and see the point differential between subsequent scorers, and the differential from the scoring leader
WITH
pnts_by_player
AS
(SELECT
        p.Player_ID,
        p.Player_Name,
        SUM(points_scored) AS total_points
FROM Players AS p
    INNER JOIN vw_points_scored AS pnts
        ON p.Player_ID = pnts.Player_ID
GROUP BY p.Player_ID, p.Player_Name)
,
rnktbl
AS
(SELECT
        pbp.Player_ID,
        pbp.Player_Name,
        pbp.total_points,
        DENSE_RANK() OVER(ORDER BY pbp.total_points DESC) AS pnts_rank,
        ISNULL(total_points - LAG(total_points, 1) OVER (ORDER BY total_points DESC), 0) as pnt_diff_rows,
        total_points - FIRST_VALUE(total_points) OVER(ORDER BY total_points DESC) AS pnt_diff_topscr
FROM pnts_by_player AS pbp
)
SELECT
        Player_ID,
        Player_Name,
        total_points,
        pnt_diff_rows,
        pnt_diff_topscr
FROM rnktbl AS r
WHERE pnts_rank < 11;
/*
Player_ID   Player_Name             total_points    pnt_diff_rows   pnt_diff_topscr
1629029	    Luka Doncic	                1892	        0	            0
1628973	    Jalen Brunson	        1791	        -101	            -101
203999	    Nikola Jokic	        1727	        -64	            -165
203507	    Giannis Antetokounmpo	1708	        -19	            -184
1628983	    Shai Gilgeous-Alexander	1687	        -21	            -205
201142	    Kevin Durant	        1670	        -17	            -222
201939	    Stephen Curry	        1657	        -13	            -235
1628368	    DeAaron Fox	                1654	        -3	            -238
1630162	    Anthony Edwards	        1626	        -28	            -266
1628369	    Jayson Tatum	        1573	        -53	            -319
*/
/*

First CTE (pnts_by_player):
Joins the players table with the points scored view, and groups by the player information and SUMs the total amount of points per player.

Second CTE(rnktbl):
Uses DENSE_RANK to order the results to allow for future filtering, DENSE is the way to go here because of potential ties.
The CTE also calculates two point differentials, one between each player and one between every subsequent player and the top scorer in the particular table.
The point differential between each player is nested inside an ISNULL in order to deal with the null result of comparing top scorer to no one.

Final Selection:
Selects the relevant data and filter it to the top 10 scorers.

*/

/*
Checking the success rate per shot type,
but only for shot_ids that were attempted by players with at least 100 points scored in that shot type
This is done in order to avoid players with few attempts skewing the results and to also filter out heaves(when a player attempts a low quality shot when shot clock is about to run out)
and other low volume shot types like "hook bank shot" that have very few attempts.
*/

WITH
shots_with_score
AS
(SELECT
        s.Shot_ID,
        s.Player_ID,
        s.Action_Type,
        s.Shot_Made,
        pnts.points_scored,
        SUM(pnts.points_scored) OVER(PARTITION BY s.Player_ID, s.Action_Type) as tot_player_scr
FROM Shots AS s
    INNER JOIN vw_points_scored AS pnts
        ON s.Shot_ID = pnts.Shot_ID)
,
fltrtbl
AS
(
SELECT
        Shot_ID,
        Action_Type,
        Shot_Made,
        points_scored
FROM shots_with_score as sws
WHERE tot_player_scr >= 100
)
,
totaltbl
AS
(SELECT 
        Shot_ID,
        Action_Type,
        CAST(COUNT(Shot_ID) OVER(PARTITION BY Action_Type) AS float) AS total_attempted,
        CAST(SUM(CAST(Shot_Made AS int)) OVER(PARTITION BY Action_Type)AS float) AS total_made
FROM fltrtbl AS f)
,
ratetbl
AS
(
SELECT
        Action_Type,
        SUM(total_made) / SUM(total_attempted) * 100 as success_rate
FROM totaltbl AS t
GROUP BY Action_Type)

SELECT
        Action_Type,
        CONCAT(FORMAT(r.success_rate, '#.##'), '%') as success_rate
FROM ratetbl AS r
ORDER BY r.success_rate DESC




/*
Action_Type                             success_rate
Driving Dunk Shot	                92.21%
Alley Oop Dunk Shot	                91.71%
Cutting Dunk Shot	                87.7%
Cutting Layup Shot	                75.24%
Driving Finger Roll Layup Shot	        67.15%
Floating Jump shot	                63.03%
Running Layup Shot	                63.01%
Layup Shot	                        62.5%
Hook Shot	                        61.45%
Turnaround Hook Shot	                57.47%
Driving Layup Shot	                52.49%
Driving Floating Jump Shot	        49.71%
Turnaround Jump Shot	                47.75%
Fadeaway Jump Shot	                47.37%
Running Jump Shot	                45.24%
Pullup Jump shot	                41.12%
Step Back Jump shot	                40.63%
Jump Shot	                        38.62%
*/

/*
First CTE (shots_with_score):
Joins the Shots table with the vw_points_scored view.
Sums the points scored by player and action type using a window function.
This allows the next CTE to filter out low volume shot types and players.

Second CTE (fltrtbl):
Filters the results to include only those with a total player score (tot_player_scr) of 100 or more.
This ensures that only significant shot types and players are considered.

Third CTE (totaltbl):
Calculates the total attempted shots and made shots per shot type.
Shot_Made is stored bitwise, so it needs to be CAST before summing to allow it to be summed(its bitwise)
and to also provide for proper division in the subsequent CTE.

Fourth CTE(ratetbl):
In this table I do the actual success rate calculation,
grouping the rows by Action_Type to calculate the success rate per action type.
This approach is more efficient than using DISTINCT,
as it avoids unnecessary sorting and deduplication.
I could have also formatted the result here and ordered on them doing ORDER BY 2,
But I think an additional CTE to format the text and order on an actual number is more "correct".

Final Selection:
Uses CONCAT and FORMAT to display the results neatly,
and then ordering the results based on the numerical value in the previous CTE.
*/


/*
Christmas game analysis
The NBA Christmas day games are unique in such that they are not part of the "normal" scheduling and only popular teams get to play
in one of the 5 games that occur on that day
The games are all nationally televised(unlike normal games which might not be) and usually have the highest ratings for the season
What I want to see is how the players performed in those games as opposed to their seasonal average
*/

WITH
christmastbl
AS
(SELECT
        pnts.Player_ID,
        SUM(points_scored) AS total_pnts
FROM vw_points_scored as pnts
        INNER JOIN Games AS g
                ON pnts.Game_ID = g.Game_ID
WHERE g.Game_Date = '2023-12-25'
GROUP BY pnts.Player_ID)
,
difftbl
AS
(SELECT
        x.Player_ID,
        x.total_pnts AS pnts_in_christmas_game,
        p.pts_per_game AS season_avg,
        ((x.total_pnts / p.pts_per_game)-1) * 100 as percent_diff
             
FROM christmastbl as x
        INNER JOIN vw_points_per_game as p
        ON p.player_ID = x.Player_ID)

SELECT
        d.Player_ID,
        p.Player_Name,
        d.pnts_in_christmas_game,
        FORMAT(d.season_avg, '0.##') AS season_avg,
        FORMAT(d.percent_diff, '0.##') + '%' AS change_percent
FROM difftbl AS d
        INNER JOIN Players AS p
                ON d.Player_ID = p.player_ID
ORDER BY d.percent_diff DESC;


/*
Player_ID,      Player_Name,            pnts_in_christmas_game, season_avg,     change_percent
1628964	        Mo Bamba	        17	                4.47	        280.37%
1629002	        Chimezie Metu	        20	                6.09	        228.47%
1627884	        Derrick Jones Jr.	21	                7.47	        181.25%
1628960	        Grayson Allen	        32	                11.8	        171.19%
1631170	        Jaime Jaquez Jr.	23	                9.96	        130.92%
1627752	        Taurean Prince	        17	                8.29	        104.95%
1641726	        Dereck Lively II	16	                8.04	        99.1%
1626162	        Kelly Oubre Jr.	        24	                12.87	        86.51%
...
*/


/*
First CTE (christmastbl):
This CTE sums all the points the players scored on Christmas day, by joining the points scored view to the games table and limiting the date to 25/12/2023.

Second CTE(difftbl):
This CTE joins the pts_per_game view and calculates the difference between the average score of the player and their score in the Christmas game.

Final Selection:
Joins the players table to get players name, and format the results.
*/


--Team score analysis
WITH
teampoints
AS

(SELECT 
        s.Team_ID,
        s.Game_ID,
        SUM(pnts.points_scored) AS game_score

FROM Shots AS s
        INNER JOIN vw_points_scored AS pnts
                ON s.Shot_ID = pnts.Shot_ID
GROUP BY s.Team_ID, s.Game_ID)
,
sumdifftbl
AS
(SELECT
        t.Team_ID,
        th.Team_Name,
        t.Game_ID,
        g.Game_Date,
        ROW_NUMBER() OVER(PARTITION BY t.Team_ID ORDER BY g.Game_Date) AS team_game_number,
        t.game_score,
        SUM(t.game_score) OVER(PARTITION BY t.Team_ID ORDER BY g.Game_Date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS rolling_sum,
        FORMAT((CAST(t.game_score AS float) / LAG(t.game_score, 1) OVER(PARTITION BY t.Team_ID ORDER BY g.Game_Date) - 1) * 100,'0.00') + '%' AS change_rate

FROM teampoints AS t
        INNER JOIN Games AS g
                ON t.Game_ID = g .Game_ID
        INNER JOIN Team_History AS th
                ON th.Team_ID = t.Team_ID)

SELECT
        sd.Team_ID,
        sd.Team_Name,
        sd.Game_ID,
        sd.Game_Date,
        sd.team_game_number,
        sd.game_score,
        CASE WHEN team_game_number = 1
                THEN 'First Game'
                ELSE sd.change_rate
                END as change_rate,
        sd.rolling_sum AS rolling_points_sum
FROM sumdifftbl AS sd


/*
Team_ID         Team_Name       Game_ID         Game_Date       team_game_number        game_score      change_rate     rolling_points_sum
1610612737	Atlanta Hawks	22300063	2023-10-25	1	                83	        First Game	83
1610612737	Atlanta Hawks	22300079	2023-10-27	2	                96	        15.66%	        179
1610612737	Atlanta Hawks	22300097	2023-10-29	3	                109	        13.54%	        288
1610612737	Atlanta Hawks	22300104	2023-10-30	4	                110	        0.92%	        398
1610612737	Atlanta Hawks	22300117	2023-11-01	5	                101	        -8.18%	        499
1610612737	Atlanta Hawks	22300135	2023-11-04	6	                104	        2.97%	        603
1610612737	Atlanta Hawks	22300155	2023-11-06	7	                90	        -13.46%	        693
1610612737	Atlanta Hawks	22300172	2023-11-09	8	                97	        7.78%	        790
1610612737	Atlanta Hawks	22300175	2023-11-11	9	                94	        -3.09%	        884
...
*/

/*
First CTE (teampoints):
This CTE joins the points scored view with the shots table and sums each teams score per game.

Second CTE(sumdifftbl):
This CTE joins the game table and the team history table to get the game date and team name respectively. I use ROW_NUMBER() to number each of the 82 games each team plays.
I use SUM to create a rolling average, and LAG to do a percentage change between each row.

Final Selection:
To change the NULL to a more informative value, I use a case on the game number rather than the actual value in the percentage change.
I did that in order to avoid having to use 0 as the condiction for the case, because it might catch situations
in which the team scored the same amount in subsequent games
*/


/*
Finding all Back to Back games
A back to back in the NBA is when a team plays games on subsequent days
*/

GO

WITH
stbl
AS
(SELECT
        s.Game_ID,
        s.Team_ID
from Shots AS s
GROUP BY s.Game_ID, s.Team_ID)
,
wtbl
AS
(SELECT
        s.Game_ID,
        g.Game_Date,
        LAG(g.Game_Date, 1) OVER(PARTITION BY s.team_id ORDER BY g.Game_Date) AS prevGameDate,
        s.Team_ID,
        t.Team_Name,
        ROW_NUMBER() OVER(PARTITION BY s.Team_ID ORDER BY g.Game_Date) AS team_game_number
FROM stbl AS s
        INNER JOIN Team_History AS t
                ON s.Team_ID = t.Team_ID
        INNER JOIN Games AS g
                ON s.Game_ID = g.Game_ID)
,
daystbl
AS
(SELECT
        w.Game_ID,
        w.Game_Date,
        w.prevGameDate,
        DATEDIFF(DAY,w.prevGameDate,  w.Game_Date) AS DaysSinceLastGame,
        w.Team_ID,
        w.Team_Name,
        w.team_game_number
FROM wtbl AS w)
,
b2btbl
AS
(SELECT
        d.Game_ID,
        d.Game_Date,
        d.DaysSinceLastGame,
        CASE
                WHEN DaysSinceLastGame = 1
                        THEN 1 --true
                        ELSE 0 --false
                END AS b2bcheck,
        d.Team_ID,
        d.Team_Name,
        d.team_game_number
FROM daystbl AS d)
SELECT
        b.Game_ID,
        b.Game_Date,
        b.b2bcheck,
        b.Team_ID,
        b.Team_Name,
        b.team_game_number,
        SUM(b2bcheck) OVER(PARTITION BY b.team_id) AS b2bGameCountPerTeam,
        SUM(b2bcheck) OVER() AS b2bGamesForLeague

FROM b2btbl AS b
WHERE b2bcheck = 1;
/*
Game_ID	        Game_Date	b2bcheck	Team_ID	        Team_Name	   team_game_number	b2bGameCountPerTeam	b2bGamesForLeague
2230010         2023-10-30	1	        1610612737	Atlanta Hawks	    4	                15	                422
22300193	2023-11-15	1	        1610612737      Atlanta Hawks	    11	                15	                422
22300227	2023-11-22	1	        1610612737      Atlanta Hawks	    14	                15	                422
22300246	2023-11-26	1	        1610612737      Atlanta Hawks	    16	                15	                422
...
*/
/*
First CTE (stbl):
Grouped the shot tables game_ID and Team_ID, to get a list of all the games each team played.

Second CTE (wtbl):
Joined the Team_History table to get the team name, and the Game table to get the game date.
I then used LAG to get the previous game date for future calculations and used ROW_NUMBER to number the games in order from 1 to 82.

Third CTE(daystbl):
In this CTE I used DATEDIFF() to calculate the days between games.

Fourth CTE(b2btbl):
In this CTE I used a case to check and mark games that are the second part of a B2B, the games that teams don't get to rest for.

Final Selection:
I used SUM to count the total amount of B2B per team and for the entire league.
Some of the previous CTE's could have been condensed but I  believe it would have been difficult to read them in that case.
*/


--points per shot attempt
/*
Points per shot attempt is an efficiency metric used in the NBA to see how many points a player scores per
shot attempt on average, ignoring free throws. 
*/

WITH
aggtbl
AS
(SELECT
        pts.Player_ID,
        COUNT(*) AS attempts,
        SUM(pts.points_scored) AS total_points
FROM vw_points_scored AS pts
GROUP BY pts.Player_ID)
,
ppatbl
AS
(SELECT
        a.Player_ID,
        a.attempts,
        a.total_points,
        AVG(a.attempts) OVER() AS avg_attempts,
        FORMAT((CAST(a.total_points AS float) / a.attempts), '0.0000') AS points_per_attempt
FROM aggtbl AS a)
,
dnrtbl
AS
(SELECT
        p.Player_ID,
        p.attempts,
        p.total_points,
        p.points_per_attempt,
        DENSE_RANK() OVER(ORDER BY p.points_per_attempt DESC) AS DNR        
FROM ppatbl AS p
WHERE p.attempts > p.avg_attempts)
SELECT
        d.Player_ID,
        p.Player_Name,
        d.attempts,
        d.total_points,
        d.points_per_attempt
FROM dnrtbl AS d
        INNER JOIN Players AS p
                ON p.Player_ID = d.Player_ID
WHERE d.DNR < 11;

/*
Player_ID	Player_Name	attempts	total_points	points_per_attempt
1629655	        Daniel Gafford	480	        696	        1.4500
1630188	        Jalen Smith	395	        529	        1.3392
1630167	        Obi Toppin	579	        766	        1.3230
203497	        Rudy Gobert	614	        812	        1.3225
1627826	        Ivica Zubac	519	        674	        1.2987
1628960	        Grayson Allen	682	        885	        1.2977
201143	        Al Horford	419	        536	        1.2792
1629021	        Moritz Wagner	552	        702	        1.2717
1628386	        Jarrett Allen	819	        1038	        1.2674
1629651	        Nic Claxton	582	        733	        1.2595
*/

/*
First CTE (aggtbl):
In this CTE I used two aggregate functions to calculate the attempts per player and the total score of the player in the given season.
Second CTE(ppatbl):
In the second CTE I created an average of the league shot attempts to filter low volume but highly efficient players. I also calculated the actual points per shot attempt and formatted it neatly.
Third CTE(dnrtbl):
In the third CTE I created a dense rank to allow me to select whichever subset of players I would like to. In addition, I filtered all the players who have less attempts than the leagues average.
Final Selection:
I joined the players table in order to get the players name, selected all the relevant columns and filtered on the dense rank to only show the top 10 players by points per shot attempt.
*/

