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
