-- Query 1
SELECT * FROM event e WHERE e.enddate - e.startdate > 0 ORDER BY e.startdate, e.title;
-- Clarifications:
-- test: e.eid, CAST(e.title AS VARCHAR(10)), CAST(e.description AS VARCHAR(10)), e.startdate, e.enddate, e.organizer, e.postcode
-- require: *

-- Query 2
SELECT e.eid, e.title FROM event e WHERE e.postcode IN (SELECT r.postcode FROM region r WHERE r.name = 'Golden Horseshoe') ORDER BY e.title;

-- Query 3
SELECT u.uid, u.name FROM user u WHERE (u.uid IN (SELECT r.user FROM review r)) AND NOT (u.uid IN (SELECT e.organizer FROM event e));

-- Query 4a
SELECT * FROM event e LEFT JOIN (SELECT r.event, COUNT(*) nrev, AVG(CAST(r.score AS DECIMAL)) ascore FROM review r GROUP BY r.event) stat ON e.eid = stat.event ORDER BY stat.ascore DESC, e.title;
-- Clarifications: cast score to decimal to get accurate average score.
-- test: e.eid, e.title, stat.nrev, stat.ascore
-- require: *

-- Query 4b
SELECT * FROM event e LEFT JOIN (SELECT r.event, COUNT(*) nrev, AVG(CAST(r.score AS DECIMAL)) ascore FROM review r GROUP BY r.event) stat ON e.eid = stat.event WHERE stat.nrev >= 5 ORDER BY stat.ascore DESC, e.title;
-- Clarifications:
-- test: e.eid, e.title, stat.nrev, stat.ascore
-- require: *

-- Query 5
SELECT e.eid, e.title FROM event e LEFT JOIN review r ON e.eid = r.event WHERE e.organizer = r.user OR e.startdate > r.reviewdate;
-- Clarifications: only use strict larger (>) to filter events whose reviewdate earlier than startdate, because the review can be on the same day but still after the event.

-- Query 6
SELECT user.uid, user.name FROM user LEFT JOIN review ON user.uid = review.user LEFT JOIN event ON review.event = event.eid WHERE (review.event IS NULL) OR EXISTS (SELECT name FROM region WHERE user.postcode = region.postcode INTERSECT SELECT name FROM region WHERE event.postcode = region.postcode);
-- Clarifications: assume 'From a logic standpoint, a user that has not reviewed events has also only reviewed events in regions associated with that user.'
-- test: user.uid, user.name, user.postcode, event.postcode
-- require: user.uid, user.name

-- Query 7
SELECT e1.eid AS fstid, e2.eid AS sndid FROM event e1 JOIN event e2 ON e1.eid != e2.eid WHERE NOT EXISTS((SELECT word FROM keyword k WHERE e1.eid = k.event EXCEPT SELECT word FROM keyword k WHERE e2.eid = k.event) UNION (SELECT word FROM keyword k WHERE e2.eid = k.event EXCEPT SELECT word FROM keyword k WHERE e1.eid = k.event)) ORDER BY e1.eid, e2.eid;
-- Clarifications: set A = set B <=> NOT EXIST ((A - B) UNION (B - A))

-- Query 8a
SELECT event.eid, SUM(review.score) AS pscore FROM event LEFT JOIN review ON event.eid = review.event GROUP BY event.eid, event.title ORDER BY SUM(review.score) DESC;
-- Clarifications: 
-- test: event.eid, event.title, SUM(review.score)
-- require: event.eid, SUM(review.score)
-- as the pro said: no order needed for this one - ORDER BY pscore DESC, event.title

-- Query 8b
SELECT event.eid, event.title FROM event LEFT JOIN review ON event.eid = review.event GROUP BY event.eid, event.title HAVING SUM(review.score) = (SELECT MAX(t.pscore) FROM (SELECT event.eid, SUM(review.score) AS pscore FROM event LEFT JOIN review ON event.eid = review.event GROUP BY event.eid, event.title ORDER BY pscore DESC, event.title) AS t) ORDER BY event.title;
-- Clarifications: 
-- get MAX value: SELECT MAX(t.pscore) FROM (SELECT event.eid, SUM(review.score) AS pscore FROM event LEFT JOIN review ON event.eid = review.event GROUP BY event.eid, event.title ORDER BY pscore DESC, event.title) AS t
-- then using nested query

-- Query 9
(SELECT user.uid, 'keyword' AS badge FROM user WHERE user.uid IN (SELECT t.user FROM (SELECT p.user, p.word, p.num, q.max_num FROM (SELECT r.user, k.word, COUNT(*) AS num FROM review r LEFT JOIN keyword k ON r.event = k.event GROUP BY r.user, k.word) p JOIN (SELECT t.word, MAX(t.NUM) AS max_num FROM (SELECT r.user, k.word, COUNT(*) AS num FROM review r LEFT JOIN keyword k ON r.event = k.event GROUP BY r.user, k.word) AS t GROUP BY t.word) q ON p.word = q.word) t WHERE t.num = t.max_num)) UNION (SELECT user.uid, 'region' AS badge FROM user WHERE user.uid IN (SELECT p.user FROM (SELECT t.user, t.name, COUNT(*) AS num FROM (SELECT review.user, event, event.postcode, region.name FROM review LEFT JOIN event ON review.event = event.eid LEFT JOIN region ON event.postcode = region.postcode) AS t GROUP BY t.user, t.name) p JOIN (SELECT s.name, MAX(s.num) AS max_num FROM (SELECT t.user, t.name, COUNT(*) AS num FROM (SELECT review.user, event, event.postcode, region.name FROM review LEFT JOIN event ON review.event = event.eid LEFT JOIN region ON event.postcode = region.postcode) AS t GROUP BY t.user, t.name) AS s GROUP BY s.name) q ON p.name = q.name WHERE p.num = q.max_num));
-- Clarifications: the below lines are all intermidiate steps.
-- -- 1.find all keyword users
-- -- test: t.user, t.word, t.num, t.max_num
-- -- require: t.user
-- SELECT t.user FROM (SELECT p.user, p.word, p.num, q.max_num FROM (SELECT r.user, k.word, COUNT(*) AS num FROM review r LEFT JOIN keyword k ON r.event = k.event GROUP BY r.user, k.word) p JOIN (SELECT t.word, MAX(t.NUM) AS max_num FROM (SELECT r.user, k.word, COUNT(*) AS num FROM review r LEFT JOIN keyword k ON r.event = k.event GROUP BY r.user, k.word) AS t GROUP BY t.word) q ON p.word = q.word) t WHERE t.num = t.max_num
-- -- 2.find all region users
-- -- test: p.user, p.name, p.num, q.max_num
-- -- require: p.user
-- SELECT p.user FROM (SELECT t.user, t.name, COUNT(*) AS num FROM (SELECT review.user, event, event.postcode, region.name FROM review LEFT JOIN event ON review.event = event.eid LEFT JOIN region ON event.postcode = region.postcode) AS t GROUP BY t.user, t.name) p JOIN (SELECT s.name, MAX(s.num) AS max_num FROM (SELECT t.user, t.name, COUNT(*) AS num FROM (SELECT review.user, event, event.postcode, region.name FROM review LEFT JOIN event ON review.event = event.eid LEFT JOIN region ON event.postcode = region.postcode) AS t GROUP BY t.user, t.name) AS s GROUP BY s.name) q ON p.name = q.name WHERE p.num = q.max_num
-- -- 3.mark all keyword users
-- SELECT user.uid, 'keyword' AS badge FROM user WHERE user.uid IN (SELECT t.user FROM (SELECT p.user, p.word, p.num, q.max_num FROM (SELECT r.user, k.word, COUNT(*) AS num FROM review r LEFT JOIN keyword k ON r.event = k.event GROUP BY r.user, k.word) p JOIN (SELECT t.word, MAX(t.NUM) AS max_num FROM (SELECT r.user, k.word, COUNT(*) AS num FROM review r LEFT JOIN keyword k ON r.event = k.event GROUP BY r.user, k.word) AS t GROUP BY t.word) q ON p.word = q.word) t WHERE t.num = t.max_num)
-- -- 4.mark all region users
-- SELECT user.uid, 'region' AS badge FROM user WHERE user.uid IN (SELECT p.user FROM (SELECT t.user, t.name, COUNT(*) AS num FROM (SELECT review.user, event, event.postcode, region.name FROM review LEFT JOIN event ON review.event = event.eid LEFT JOIN region ON event.postcode = region.postcode) AS t GROUP BY t.user, t.name) p JOIN (SELECT s.name, MAX(s.num) AS max_num FROM (SELECT t.user, t.name, COUNT(*) AS num FROM (SELECT review.user, event, event.postcode, region.name FROM review LEFT JOIN event ON review.event = event.eid LEFT JOIN region ON event.postcode = region.postcode) AS t GROUP BY t.user, t.name) AS s GROUP BY s.name) q ON p.name = q.name WHERE p.num = q.max_num)
-- -- 5.combine the above two tables
-- (SELECT user.uid, 'keyword' AS badge FROM user WHERE user.uid IN (SELECT t.user FROM (SELECT p.user, p.word, p.num, q.max_num FROM (SELECT r.user, k.word, COUNT(*) AS num FROM review r LEFT JOIN keyword k ON r.event = k.event GROUP BY r.user, k.word) p JOIN (SELECT t.word, MAX(t.NUM) AS max_num FROM (SELECT r.user, k.word, COUNT(*) AS num FROM review r LEFT JOIN keyword k ON r.event = k.event GROUP BY r.user, k.word) AS t GROUP BY t.word) q ON p.word = q.word) t WHERE t.num = t.max_num)) UNION (SELECT user.uid, 'region' AS badge FROM user WHERE user.uid IN (SELECT p.user FROM (SELECT t.user, t.name, COUNT(*) AS num FROM (SELECT review.user, event, event.postcode, region.name FROM review LEFT JOIN event ON review.event = event.eid LEFT JOIN region ON event.postcode = region.postcode) AS t GROUP BY t.user, t.name) p JOIN (SELECT s.name, MAX(s.num) AS max_num FROM (SELECT t.user, t.name, COUNT(*) AS num FROM (SELECT review.user, event, event.postcode, region.name FROM review LEFT JOIN event ON review.event = event.eid LEFT JOIN region ON event.postcode = region.postcode) AS t GROUP BY t.user, t.name) AS s GROUP BY s.name) q ON p.name = q.name WHERE p.num = q.max_num))
-- 1. steps for finding all keyword user
-- SELECT r.user, k.word, COUNT(*) AS num FROM review r LEFT JOIN keyword k ON r.event = k.event GROUP BY r.user, k.word
-- SELECT t.word, MAX(t.NUM) FROM (SELECT r.user, k.word, COUNT(*) AS num FROM review r LEFT JOIN keyword k ON r.event = k.event GROUP BY r.user, k.word) AS t GROUP BY t.word
-- SELECT p.user, p.word, p.num, q.max_num FROM (SELECT r.user, k.word, COUNT(*) AS num FROM review r LEFT JOIN keyword k ON r.event = k.event GROUP BY r.user, k.word) p JOIN (SELECT t.word, MAX(t.NUM) AS max_num FROM (SELECT r.user, k.word, COUNT(*) AS num FROM review r LEFT JOIN keyword k ON r.event = k.event GROUP BY r.user, k.word) AS t GROUP BY t.word) q ON p.word = q.word
-- SELECT t.user, t.word, t.num, t.max_num FROM (SELECT p.user, p.word, p.num, q.max_num FROM (SELECT r.user, k.word, COUNT(*) AS num FROM review r LEFT JOIN keyword k ON r.event = k.event GROUP BY r.user, k.word) p JOIN (SELECT t.word, MAX(t.NUM) AS max_num FROM (SELECT r.user, k.word, COUNT(*) AS num FROM review r LEFT JOIN keyword k ON r.event = k.event GROUP BY r.user, k.word) AS t GROUP BY t.word) q ON p.word = q.word) t WHERE t.num = t.max_num
-- 2. steps fro finding all region user
-- SELECT review.user, event, event.postcode, region.name FROM review LEFT JOIN event ON review.event = event.eid LEFT JOIN region ON event.postcode = region.postcode
-- SELECT t.user, t.name, COUNT(*) AS num FROM (SELECT review.user, event, event.postcode, region.name FROM review LEFT JOIN event ON review.event = event.eid LEFT JOIN region ON event.postcode = region.postcode) AS t GROUP BY t.user, t.name
-- SELECT s.name, MAX(s.num) AS max_num FROM (SELECT t.user, t.name, COUNT(*) AS num FROM (SELECT review.user, event, event.postcode, region.name FROM review LEFT JOIN event ON review.event = event.eid LEFT JOIN region ON event.postcode = region.postcode) AS t GROUP BY t.user, t.name) AS s GROUP BY s.name
-- SELECT p.user, p.name, p.num, q.max_num FROM (SELECT t.user, t.name, COUNT(*) AS num FROM (SELECT review.user, event, event.postcode, region.name FROM review LEFT JOIN event ON review.event = event.eid LEFT JOIN region ON event.postcode = region.postcode) AS t GROUP BY t.user, t.name) p JOIN (SELECT s.name, MAX(s.num) AS max_num FROM (SELECT t.user, t.name, COUNT(*) AS num FROM (SELECT review.user, event, event.postcode, region.name FROM review LEFT JOIN event ON review.event = event.eid LEFT JOIN region ON event.postcode = region.postcode) AS t GROUP BY t.user, t.name) AS s GROUP BY s.name) q ON p.name = q.name WHERE p.num = q.max_num

-- Query 10
SELECT tl.user AS uid, (tl.l + th.h - ts.s) / tm.m AS si FROM ((select t1.user, count(t2.user) AS L from review t1 left outer join (SELECT p.user, SUM(q.a - p.score) AS L FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE p.score - q.a < 0 GROUP BY p.user) t2 on t1.user = t2.user group by t1.user having count(t2.user) = 0) UNION (SELECT p.user, SUM(q.a - p.score) AS L FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE p.score - q.a < 0 GROUP BY p.user)) AS tl JOIN ((SELECT p.user, SUM(p.score - q.a) AS H FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a - p.score < 0 GROUP BY p.user) UNION (SELECT t1.user, count(t2.user) FROM review t1 LEFT OUTER JOIN (SELECT p.user, SUM(p.score - q.a) AS H FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a - p.score < 0 GROUP BY p.user) t2 ON t1.user = t2.user GROUP BY t1.user HAVING count(t2.user) = 0)) AS th ON tl.user = th.user JOIN ((SELECT p.user, COUNT(*) AS S FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a = CAST(p.score AS DECIMAL) GROUP BY p.user) UNION (SELECT t1.user, count(t2.user) AS L FROM review t1 LEFT OUTER JOIN (SELECT p.user, COUNT(*) AS S FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a = CAST(p.score AS DECIMAL) GROUP BY p.user) t2 ON t1.user = t2.user GROUP BY t1.user HAVING count(t2.user) = 0)) AS ts ON tl.user = ts.user JOIN (SELECT r.user, COUNT(*) AS M FROM review r GROUP BY r.user) AS tm ON tl.user = tm.user ORDER BY si DESC;
-- Clarifications:
-- The below lines are all intermedite steps.
-- -- 1.a
-- SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event
-- -- 2.s-a
-- SELECT p.user, p.event, p.score AS s, q.a AS a, p.score - q.a AS "S-A" FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event
-- -- 3.L
-- SELECT p.user, SUM(q.a - p.score) AS L FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE p.score - q.a < 0 GROUP BY p.user

-- select t1.user, count(t2.user)
-- from (review) t1
-- left outer join (SELECT p.user, SUM(q.a - p.score) AS L FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE p.score - q.a < 0 GROUP BY p.user) t2
-- on t1.user = t2.user
-- group by t1.user
-- having count(t2.user) = 0

-- (select t1.user, count(t2.user) AS L from review t1 left outer join (SELECT p.user, SUM(q.a - p.score) AS L FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE p.score - q.a < 0 GROUP BY p.user) t2 on t1.user = t2.user group by t1.user having count(t2.user) = 0) 
-- UNION 
-- (SELECT p.user, SUM(q.a - p.score) AS L FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE p.score - q.a < 0 GROUP BY p.user)

-- (select t1.user, count(t2.user) AS L from review t1 left outer join (SELECT p.user, SUM(q.a - p.score) AS L FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE p.score - q.a < 0 GROUP BY p.user) t2 on t1.user = t2.user group by t1.user having count(t2.user) = 0) UNION (SELECT p.user, SUM(q.a - p.score) AS L FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE p.score - q.a < 0 GROUP BY p.user)


-- -- 4.H
-- SELECT p.user, SUM(p.score - q.a) AS H FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a - p.score < 0 GROUP BY p.user

-- SELECT t1.user, count(t2.user) AS H FROM review t1 LEFT OUTER JOIN (SELECT p.user, SUM(p.score - q.a) AS H FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a - p.score < 0 GROUP BY p.user) t2 ON t1.user = t2.user GROUP BY t1.user HAVING count(t2.user) = 0

-- (SELECT p.user, SUM(p.score - q.a) AS H FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a - p.score < 0 GROUP BY p.user) UNION (SELECT t1.user, count(t2.user) AS H FROM review t1 LEFT OUTER JOIN (SELECT p.user, SUM(p.score - q.a) AS H FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a - p.score < 0 GROUP BY p.user) t2 ON t1.user = t2.user GROUP BY t1.user HAVING count(t2.user) = 0)

-- -- 5.S
-- SELECT p.user, COUNT(*) AS S FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a = CAST(p.score AS DECIMAL) GROUP BY p.user

-- SELECT t1.user, count(t2.user) AS L FROM review t1 LEFT OUTER JOIN (SELECT p.user, COUNT(*) AS S FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a = CAST(p.score AS DECIMAL) GROUP BY p.user) t2 ON t1.user = t2.user GROUP BY t1.user HAVING count(t2.user) = 0

-- (SELECT p.user, COUNT(*) AS S FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a = CAST(p.score AS DECIMAL) GROUP BY p.user) UNION (SELECT t1.user, count(t2.user) AS L FROM review t1 LEFT OUTER JOIN (SELECT p.user, COUNT(*) AS S FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a = CAST(p.score AS DECIMAL) GROUP BY p.user) t2 ON t1.user = t2.user GROUP BY t1.user HAVING count(t2.user) = 0)


-- -- 6.M
-- SELECT r.user, COUNT(*) AS M FROM review r GROUP BY r.user

-- -- 7. JOIN L, H, S, M
-- SELECT *
-- FROM ((select t1.user, count(t2.user) AS L from review t1 left outer join (SELECT p.user, SUM(q.a - p.score) AS L FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE p.score - q.a < 0 GROUP BY p.user) t2 on t1.user = t2.user group by t1.user having count(t2.user) = 0) UNION (SELECT p.user, SUM(q.a - p.score) AS L FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE p.score - q.a < 0 GROUP BY p.user)) AS tl
-- JOIN ((SELECT p.user, SUM(p.score - q.a) AS H FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a - p.score < 0 GROUP BY p.user) UNION (SELECT t1.user, count(t2.user) FROM review t1 LEFT OUTER JOIN (SELECT p.user, SUM(p.score - q.a) AS H FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a - p.score < 0 GROUP BY p.user) t2 ON t1.user = t2.user GROUP BY t1.user HAVING count(t2.user) = 0)) AS th ON tl.user = th.user
-- JOIN ((SELECT p.user, COUNT(*) AS S FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a = CAST(p.score AS DECIMAL) GROUP BY p.user) UNION (SELECT t1.user, count(t2.user) AS L FROM review t1 LEFT OUTER JOIN (SELECT p.user, COUNT(*) AS S FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a = CAST(p.score AS DECIMAL) GROUP BY p.user) t2 ON t1.user = t2.user GROUP BY t1.user HAVING count(t2.user) = 0)) AS ts ON tl.user = ts.user
-- JOIN (SELECT r.user, COUNT(*) AS M FROM review r GROUP BY r.user) AS tm ON tl.user = tm.user

-- SELECT tl.user AS uid, (tl.l + th.h - ts.s) / tm.m AS si FROM ((select t1.user, count(t2.user) AS L from review t1 left outer join (SELECT p.user, SUM(q.a - p.score) AS L FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE p.score - q.a < 0 GROUP BY p.user) t2 on t1.user = t2.user group by t1.user having count(t2.user) = 0) UNION (SELECT p.user, SUM(q.a - p.score) AS L FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE p.score - q.a < 0 GROUP BY p.user)) AS tl JOIN ((SELECT p.user, SUM(p.score - q.a) AS H FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a - p.score < 0 GROUP BY p.user) UNION (SELECT t1.user, count(t2.user) FROM review t1 LEFT OUTER JOIN (SELECT p.user, SUM(p.score - q.a) AS H FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a - p.score < 0 GROUP BY p.user) t2 ON t1.user = t2.user GROUP BY t1.user HAVING count(t2.user) = 0)) AS th ON tl.user = th.user JOIN ((SELECT p.user, COUNT(*) AS S FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a = CAST(p.score AS DECIMAL) GROUP BY p.user) UNION (SELECT t1.user, count(t2.user) AS L FROM review t1 LEFT OUTER JOIN (SELECT p.user, COUNT(*) AS S FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a = CAST(p.score AS DECIMAL) GROUP BY p.user) t2 ON t1.user = t2.user GROUP BY t1.user HAVING count(t2.user) = 0)) AS ts ON tl.user = ts.user JOIN (SELECT r.user, COUNT(*) AS M FROM review r GROUP BY r.user) AS tm ON tl.user = tm.user ORDER BY si DESC


-- -- 7.FULL OUTER JOIN L H S M
-- SELECT DISTINCT t.user, a.L, b.H, c.S, d.M
-- FROM review t
-- FULL OUTER JOIN (SELECT p.user, SUM(q.a - p.score) AS L FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE p.score - q.a < 0 GROUP BY p.user) a ON t.user = a.user
-- FULL OUTER JOIN (SELECT p.user, SUM(p.score - q.a) AS H FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a - p.score < 0 GROUP BY p.user) b ON t.user = b.user
-- FULL OUTER JOIN (SELECT p.user, COUNT(*) AS S FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a = CAST(p.score AS DECIMAL) GROUP BY p.user) c ON t.user = c.user
-- FULL OUTER JOIN (SELECT r.user, COUNT(*) AS M FROM review r GROUP BY r.user) d ON t.user = d.user

-- SELECT DISTINCT t.user, res1.L, res2.H, res3.S, res4.M
-- FROM review t
-- FULL OUTER JOIN ((select t1.user, count(t2.user) from review t1 left outer join (SELECT p.user, SUM(q.a - p.score) AS L FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE p.score - q.a < 0 GROUP BY p.user) t2 on t1.user = t2.user group by t1.user having count(t2.user) = 0) UNION (SELECT p.user, SUM(q.a - p.score) AS L FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE p.score - q.a < 0 GROUP BY p.user)) res1 ON t.user = res1.user
-- FULL OUTER JOIN ((SELECT p.user, SUM(p.score - q.a) AS H FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a - p.score < 0 GROUP BY p.user) UNION (SELECT t1.user, count(t2.user) FROM review t1 LEFT OUTER JOIN (SELECT p.user, SUM(p.score - q.a) AS H FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a - p.score < 0 GROUP BY p.user) t2 ON t1.user = t2.user GROUP BY t1.user HAVING count(t2.user) = 0)) res2 ON t.user = res2.user
-- FULL OUTER JOIN ((SELECT p.user, COUNT(*) AS S FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a = CAST(p.score AS DECIMAL) GROUP BY p.user) UNION (SELECT t1.user, count(t2.user) FROM review t1 LEFT OUTER JOIN (SELECT p.user, COUNT(*) AS S FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a = CAST(p.score AS DECIMAL) GROUP BY p.user) t2 ON t1.user = t2.user GROUP BY t1.user HAVING count(t2.user) = 0)) res3 ON t.user = res3.user
-- FULL OUTER JOIN (SELECT r.user, COUNT(*) AS M FROM review r GROUP BY r.user) res4 ON t.user = res4.user





-- SELECT DISTINCT t.user, a.L, b.H, c.S, d.M FROM review t FULL OUTER JOIN (SELECT p.user, SUM(q.a - p.score) AS L FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE p.score - q.a < 0 GROUP BY p.user) a ON t.user = a.user FULL OUTER JOIN (SELECT p.user, SUM(p.score - q.a) AS H FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a - p.score < 0 GROUP BY p.user) b ON t.user = b.user FULL OUTER JOIN (SELECT p.user, COUNT(*) AS S FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a = CAST(p.score AS DECIMAL) GROUP BY p.user) c ON t.user = c.user FULL OUTER JOIN (SELECT r.user, COUNT(*) AS M FROM review r GROUP BY r.user) d ON t.user = d.user

-- -- try
-- SELECT p.user, SUM(q.a - p.score) AS L FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE p.score - q.a < 0 GROUP BY p.user

-- SELECT DISTINCT review.user, 0 AS L, 0 AS H, 0 AS S, 0 AS M FROM review


-- SELECT DISTINCT t.user, a.L, b.H, c.S, d.M
-- FROM (SELECT DISTINCT t.user, a.L, b.H, c.S, d.M) t
-- FULL OUTER JOIN (SELECT p.user, SUM(q.a - p.score) AS L FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE p.score - q.a < 0 GROUP BY p.user) a ON t.user = a.user
-- FULL OUTER JOIN (SELECT p.user, SUM(p.score - q.a) AS H FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a - p.score < 0 GROUP BY p.user) b ON t.user = b.user
-- FULL OUTER JOIN (SELECT p.user, COUNT(*) AS S FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a = CAST(p.score AS DECIMAL) GROUP BY p.user) c ON t.user = c.user
-- FULL OUTER JOIN (SELECT r.user, COUNT(*) AS M FROM review r GROUP BY r.user) d ON t.user = d.user

-- SELECT DISTINCT t.user, a.L, b.H, c.S, d.M FROM (SELECT DISTINCT review.user, 0 AS L, 0 AS H, 0 AS S, 0 AS M FROM review) t FULL OUTER JOIN (SELECT p.user, SUM(q.a - p.score) AS L FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE p.score - q.a < 0 GROUP BY p.user) a ON t.user = a.user FULL OUTER JOIN (SELECT p.user, SUM(p.score - q.a) AS H FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a - p.score < 0 GROUP BY p.user) b ON t.user = b.user FULL OUTER JOIN (SELECT p.user, COUNT(*) AS S FROM review p JOIN (SELECT r.event, AVG(CAST(r.score AS DECIMAL)) AS a FROM review r GROUP BY event) q ON p.event = q.event WHERE q.a = CAST(p.score AS DECIMAL) GROUP BY p.user) c ON t.user = c.user FULL OUTER JOIN (SELECT r.user, COUNT(*) AS M FROM review r GROUP BY r.user) d ON t.user = d.user


-- ----------------------------------------- FOR TEST ONLY -----------------------------------------
-- SELECT user.uid FROM user LEFT JOIN review ON user.uid = review.user WHERE review.event IS NULL