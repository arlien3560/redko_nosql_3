LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS map
MERGE (u:User {userId: toInteger(map.userId)})
SET u.gender = map.gender, 
    u.age = toInteger(map.age), 
    u.occupation = toInteger(map.occupation);

CREATE CONSTRAINT user_id_unique FOR (u:User) REQUIRE u.userId  IS UNIQUE;

LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS map
MERGE (m:Movie {movieId: toInteger(map.movieId)})
SET m.title = map.title, 
    m.year = toInteger(apoc.text.regexGroups(map.title, '\\((\\d{4})\\)')[0][1])
WITH m, split(map.genres, '|') AS genres
UNWIND genres AS g
MERGE (genre:Genre {name: g})
MERGE (m)-[:HAS_GENRE]->(genre);

CREATE CONSTRAINT movie_id_unique FOR (m:Movie) REQUIRE m.movieId IS UNIQUE;
CREATE CONSTRAINT genre_unique FOR (g:Genre) REQUIRE g.name IS UNIQUE;

CALL apoc.periodic.iterate(
    "LOAD CSV WITH HEADERS FROM 'file:///ratings.csv' AS map RETURN map",
    "MATCH (u: User {userId: toInteger(map.userId)})
    MATCH (m: Movie {movieId: toInteger(map.movieId)})
    MERGE (u)-[:RATED {rating: toFloat(map.rating), timestamp: map.timestamp}]->(m)",
    {batchSize: 1000, parallel: false}
);
