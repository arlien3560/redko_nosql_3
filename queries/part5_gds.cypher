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

MATCH (a:User {userId: 1}), (b:User {userId: 100})
CALL gds.shortestPath.dijkstra.stream('userGraph', {
  sourceNode: id(a),
  targetNode: id(b),
  relationshipWeightProperty: 'weight'
})
YIELD totalCost, nodeIds
RETURN
  totalCost,
  [nodeId IN nodeIds | gds.util.asNode(nodeId).userId] AS userChain,
  size(nodeIds) - 2 AS intermediateUsers;

CALL gds.graph.drop('userGraph');
MATCH ()-[sim:SIMILAR]-() DELETE sim;
