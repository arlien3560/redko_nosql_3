MATCH (g: Genre {name: "Thriller"})<-[:HAS_GENRE]-(m: Movie)<-[r:RATED]-(:User)
WITH m, avg(r.rating) AS avgRating
WHERE avgRating > 4.0
RETURN m.title AS Title, avgRating AS AverageRating
ORDER BY avgRating DESC;

MATCH (u: User)-[r:RATED {rating: 5.0}]->(m: Movie)
WITH u, count(r) as ratingCount
WHERE ratingCount > 50
RETURN u.userId, ratingCount
ORDER BY ratingCount DESC;


MATCH (u1: User {userId: 1})-[r1:RATED]->(m: Movie)<-[r2:RATED]-(u2: User {userId: 2})
WHERE r1.rating >= 4 AND r2.rating >= 4
RETURN m.title;

MATCH (g:Genre)<-[:HAS_GENRE]-(m:Movie)<-[r:RATED]-(:User)
WITH g, avg(toFloat(r.rating)) AS avgRating, count(r) AS countRating
WHERE countRating > 100
RETURN g.name AS Genre, avgRating AS AverageRating, countRating AS RatingsCount
ORDER BY avgRating DESC;


MATCH (u:User {userId: 1})-[r1:RATED]->(commonMovie:Movie)<-[r2:RATED]-(similar:User)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND similar <> u
MATCH (similar)-[r3:RATED]->(rec:Movie)
WHERE r3.rating >= 4 AND NOT EXISTS { (u)-[:RATED]->(rec) }
RETURN rec.title AS Recommendation, count(DISTINCT similar) AS strength
ORDER BY strength DESC
LIMIT 10;

MATCH path = shortestPath(
  (u1:User {userId: 1})-[:RATED*]-(u2:User {userId: 2})
)
RETURN path, length(path) AS hops;