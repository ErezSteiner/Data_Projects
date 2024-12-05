In this project I will examine and analyze all shot attempts(excluding free throws) that occur in a particular NBA season, using MSSQL, Python and Power BI.  
  
Data source: nba.com via https://github.com/DomSamangy/NBA_Shots_04_24/tree/main

The rational for how I decided to turn the data into relational tables is explained in the DB creation script itself.

Currently the plan is to insert only the 2024 season into the SQL DB, but there's data from 2004-2024 that I will analyze in Python and won't insert into the SQL DB.
The DB is being set up in such a way that it can accommodate the data from the other years with junction tables when needed.
