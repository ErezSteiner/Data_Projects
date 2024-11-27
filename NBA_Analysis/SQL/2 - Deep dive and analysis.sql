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

--CTE's were made to avoid having to use calculations in the filtering sections, and for ease of reading. also to improve performance since we got 200k rows
--the dense rank is needed in order to deal with potential ties.
--LAG is used to calculate the point differential between rows, nested inside an ISNULL to deal with the first row being null
--FIRST_VALUE is used to get the scoring leaders point total and calculate the differential from that. ISNULL not needed here as the value will just be 0 for the top scorer



