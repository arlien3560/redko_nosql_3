MATCH (n)
WITH n, COUNT { (n)--() } AS degree
WHERE degree > 1000
RETURN labels(n), coalesce(n.title, n.userId) AS name,  degree
ORDER BY degree DESC
LIMIT 20;

MATCH (g:Genre)--()
WITH g, count(*) AS degree
RETURN g.name, degree
ORDER BY degree DESC;

