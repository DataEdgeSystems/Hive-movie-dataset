create external table if not exists movies(movieid int, movie_title string, genres ARRAY<STRING>) ROW FORMAT DELIMITED FIELDS TERMINATED BY '#' COLLECTION ITEMS TERMINATED BY '|';

load data local inpath 'Downloads/movies.dat' into table movies ;

create external table if not exists ratings_2(userid int, movieid int, rating int, Timestamps string) ROW FORMAT DELIMITED FIELDS TERMINATED BY '#';

load data local inpath 'Downloads/ratings.dat' into table ratings_2;

create table movies_new(movieid int, movie_title string, genre string); 

INSERT OVERWRITE TABLE movies_new select movieid, movie_title,genre from movies LATERAL VIEW explode(genres)genreTable AS genre;

create table movies_joined(userid int, genre string, avg_ratings float);

insert overwrite table movies_joined select r1.userid, m1.genre, avg(r1.rating) from movies_new m1 JOIN ratings_2 r1 ON (m1.movieid=r1.movieid) group by r1.userid,m1.genre;

--final query:-

create external table output_movie_ratings ( user_id int, genres string, avg_rating int);

insert overwrite table output
select userid, genre, avg_ratings from (select userid, genre, avg_ratings, rank() over (partition by userid order by avg_ratings desc) as rank from movies_joined) ranking_table where ranking_table.rank<=5 order by userid, avg_ratings desc;
