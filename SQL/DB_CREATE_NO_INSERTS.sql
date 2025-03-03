--This is the DB creation script without the inserts
--the 200k row inserts makes the script difficult to navigate for the purpose of looking at the table relations and comments.

--This script will create a DB that will hold information about all shot attempts over a regular NBA season
--Currently the plan is to insert only the 2024 season, but theres data from 2004-2024
--The db is being set up in such a way that it can accommodate data from multiple years
--Data source: nba.com via https://github.com/DomSamangy/NBA_Shots_04_24/tree/main




--Creatng DB, checking if it exists first.
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'NBA_Shots')
BEGIN
    CREATE DATABASE NBA_Shots
END
GO

--Switching to the newly created DB in order to create tables
USE NBA_Shots;
GO

--Creating the Seasons table
--This table will hold every seasons in a single col that will serve as the ID and the date, like 2004, 2005 etc.

CREATE Table Seasons
(
Season smallint,
CONSTRAINT PK_Season PRIMARY KEY (Season),
)
GO

--Creating the Teams table

CREATE Table Teams
(
Team_ID int, 
CONSTRAINT PK_Team_ID PRIMARY KEY (Team_ID),
)
GO

--Creating the Team History Table

CREATE Table Team_History
(
History_ID smallint IDENTITY(1,1), 
CONSTRAINT PK_History_ID PRIMARY KEY (History_ID),
Team_ID int, 
CONSTRAINT FK_Team_History_Teams FOREIGN KEY (Team_ID) REFERENCES Teams(Team_ID),
Team_Name VARCHAR(50),
Season_Start smallint,
CONSTRAINT FK_Season_Start FOREIGN KEY (Season_Start) REFERENCES Seasons(Season),
Season_End smallint,
CONSTRAINT FK_Season_End FOREIGN KEY (Season_End) REFERENCES Seasons(Season)
)
GO
--The reason for having a team table and a team history table is to deal with teams that changed their name,
--like the bobcats -> hornets, sonics -> thunder
--Season start and season end is when the team started and stopped using a particular name
--most teams will have 0 for the start date since the season they started using
--their name is not in the data range (2004-2024). only 3 teams changed their name during this period.
--only teams affected by name changes and relocations during the data range will have their history point to a real season


--Creating the Players Table
--This will hold the basic information about the players
CREATE Table Players
(
Player_ID int, 
CONSTRAINT PK_Player_ID PRIMARY KEY (Player_ID),
Player_Name VARCHAR(50),
Position_Group VARCHAR(5), --forward, guard, etc
Position VARCHAR(10) -- shooting guard, point guard, small forward, etc
)
GO

--Creating the Games Table
--This table will hold identifying information about individual games

CREATE Table Games
(
Game_ID int,
CONSTRAINT PK_Game_ID PRIMARY KEY (Game_ID),
Game_Date DATE,
Home_Team int,
CONSTRAINT FK_Home_Team FOREIGN KEY (Home_Team) REFERENCES Teams(Team_ID),
Away_Team int,
CONSTRAINT FK_Away_Team FOREIGN KEY (Away_Team) REFERENCES Teams(Team_ID),
Season smallint,
CONSTRAINT FK_Season_Game FOREIGN KEY (Season) REFERENCES Seasons(Season)
)
GO

--Creating the Player Teams Table
--This table exist to deal with the situation of players playing for different teams in the the same season.

CREATE Table Player_Teams --I will refer to this table AS PT in the keys
(
Player_Team_ID int IDENTITY(1,1),
CONSTRAINT PK_PT_ID PRIMARY KEY (Player_Team_ID),
Player_ID int, 
CONSTRAINT FK_PT_Player_ID FOREIGN KEY (Player_ID) REFERENCES Players(Player_ID),
Team_ID int, 
CONSTRAINT FK_PT_Team_ID FOREIGN KEY (Team_ID) REFERENCES Teams(Team_ID),
Season smallint,
CONSTRAINT FK_PT_Season FOREIGN KEY (Season) REFERENCES Seasons(Season)
)
GO

--Creating the Shots table
--Will show unique shot attempst, with all identifying information about the particular shot
--this is the "meat" of the data

CREATE TABLE Shots
(
Shot_ID int IDENTITY(1,1),
CONSTRAINT PK_Shot_ID PRIMARY KEY (Shot_ID),
Season_ID smallint,
CONSTRAINT FK_Shot_Season_ID FOREIGN KEY(Season_ID) REFERENCES Seasons(Season),
Team_ID INT,
CONSTRAINT FK_Shot_Team_ID FOREIGN KEY (Team_ID) REFERENCES Teams (Team_ID),
Player_ID int,
CONSTRAINT FK_Shot_Player_ID FOREIGN KEY (Player_ID) REFERENCES Players(Player_ID),
Game_ID int,
CONSTRAINT FK_Shot_Game_ID FOREIGN KEY (Game_ID) REFERENCES Games(Game_ID),
Shot_Made BIT, --according to the documentations BIT is the correct way to store Booleans(TRUE/FALSE) as 1 and 0
Action_Type VARCHAR(50), --jump shot, layup, tip in, etc. the type of the shot.
Shot_Type VARCHAR(15), --2 points or 3 points
Basic_Zone VARCHAR(25), --the general location of the shot attempt: mid range, above the break, in the paint, etc.
Zone_Name VARCHAR(25), --the zone location of the shot: cetner, left side, right side, etc.
Zone_Range VARCHAR(25), --This range is descriptive and not numeric, for example "less than 8 feet" 
Loc_x smallint, --actual x,y coordinates of the player attemping the shot
Loc_y smallint, 
Shot_Distance tinyint, --This is the actual distance of the shot from the basket in feet
Quarter tinyint, -- the quarter in which the shot was attempted, from 1 to 4 and potential overtime quarters (5+)
Mins_left tinyint, --minutes left until the quarter is over
secs_left tinyint --seconds left until the quarter is over
)
GO
