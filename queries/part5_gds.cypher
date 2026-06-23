MATCH (m1:Movie)<-[r1:RATED]-(u:User)-[r2:RATED]->(m2:Movie)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND id(m1) < id(m2)
WITH m1, m2, count(u) AS weight
WHERE size([(m1)<-[:RATED]-() | 1]) > 20
  AND size([(m2)<-[:RATED]-() | 1]) > 20
WITH m1, m2, weight
ORDER BY weight DESC
LIMIT 50000
MERGE (m1)-[co:CO_RATED]-(m2)
SET co.weight = weight;

CALL gds.graph.project(
  'movieGraph',
  'Movie',
  { CO_RATED: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

CALL gds.pageRank.stream('movieGraph', {
  relationshipWeightProperty: 'weight'
})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).title AS movie, score
ORDER BY score DESC
LIMIT 20;

CALL gds.graph.drop('movieGraph');
MATCH ()-[co:CO_RATED]-() DELETE co;




MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = 5 AND r2.rating = 5 AND id(u1) < id(u2)
WITH u1, u2, count(m) AS weight
WITH u1, u2, weight
ORDER BY weight DESC
LIMIT 50000
MERGE (u1)-[sim:SIMILAR]-(u2)
SET sim.weight = weight;

CALL gds.graph.project(
  'userSimilarity',
  'User',
  { SIMILAR: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

CALL gds.louvain.write('userSimilarity', {
  relationshipWeightProperty: 'weight',
  writeProperty: 'community'
})
YIELD communityCount, modularity, modularities;

MATCH (u:User)
WHERE u.community IS NOT NULL
WITH u.community AS community, count(*) AS size
RETURN community, size
ORDER BY size DESC
LIMIT 10;

MATCH (u:User)
WHERE u.community IS NOT NULL
WITH u.community AS community, count(*) AS size
ORDER BY size DESC
LIMIT 10
WITH collect(community) AS topCommunities
MATCH (u:User)-[r:RATED]->(m:Movie)-[:HAS_GENRE]->(g:Genre)
WHERE u.community IN topCommunities AND r.rating = 5
WITH u.community AS community, g.name AS genre, count(*) AS cnt
ORDER BY cnt DESC
WITH community, collect({genre: genre, cnt: cnt})[0..3] AS topGenres
RETURN community, topGenres
ORDER BY community;

CALL gds.graph.drop('userSimilarity');
MATCH ()-[sim:SIMILAR]-() DELETE sim;
MATCH (u:User) REMOVE u.community;



MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = 5 AND r2.rating = 5 AND id(u1) < id(u2)
WITH u1, u2, count(m) AS weight
WITH u1, u2, weight
ORDER BY weight DESC
LIMIT 50000
MERGE (u1)-[sim:SIMILAR]-(u2)
SET sim.weight = weight;

CALL gds.graph.project(
  'userGraph',
  'User',
  { SIMILAR: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

MATCH (u:User)-[:SIMILAR]-()
WITH u, count(*) AS deg
ORDER BY deg DESC
LIMIT 10
RETURN u.userId, deg;

MATCH (a:User), (b:User)
WHERE a.userId IN [4277,1285,3391,5100,4448,1835,549,5795,4169,3539]
  AND b.userId IN [4277,1285,3391,5100,4448,1835,549,5795,4169,3539]
  AND a.userId < b.userId
WITH a, b
CALL gds.shortestPath.dijkstra.stream('userGraph', {
  sourceNode: id(a),
  targetNode: id(b),
  relationshipWeightProperty: 'weight'
})
YIELD nodeIds
WITH size(nodeIds) - 1 AS hops
RETURN count(*) AS pairs, avg(hops) AS avgHops, min(hops) AS minHops, max(hops) AS maxHops;

MATCH (u:User)-[:SIMILAR]-()
WITH u, count(*) AS deg
ORDER BY deg DESC
SKIP 1200 LIMIT 10
RETURN u.userId, deg;

MATCH (a:User), (b:User)
WHERE a.userId IN [4139,4132,2063,5574,285,4049,4001,3998,3979,5592]
  AND b.userId IN [4139,4132,2063,5574,285,4049,4001,3998,3979,5592]
  AND a.userId < b.userId
WITH a, b
CALL gds.shortestPath.dijkstra.stream('userGraph', {
  sourceNode: id(a),
  targetNode: id(b),
  relationshipWeightProperty: 'weight'
})
YIELD nodeIds
WITH size(nodeIds) - 1 AS hops
RETURN count(*) AS pairs, avg(hops) AS avgHops, min(hops) AS minHops, max(hops) AS maxHops;

CALL gds.graph.drop('userGraph');
MATCH ()-[sim:SIMILAR]-() DELETE sim;
