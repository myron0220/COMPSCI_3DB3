connect to cs3db3;

DROP TABLE subscriber;
DROP TABLE friend_of;
DROP TABLE person;
DROP TABLE film;
DROP TABLE review;
DROP TABLE video_review;
DROP TABLE text_review;
DROP TABLE reaction;
DROP TABLE thread_r;
DROP TABLE review_r;
DROP TABLE role_as;
DROP VIEW film_info;


CREATE TABLE subscriber (
   username VARCHAR(255) NOT NULL,
   number INT NOT NULL,
   email VARCHAR(255) NOT NULL,
   hash VARCHAR(512) NOT NULL,
   salt VARCHAR(512) NOT NULL,
   PRIMARY KEY (username, number)
);

CREATE TABLE friend_of (
	fname VARCHAR(255) NOT NULL,
	fnumber INT NOT NULL,
	tname VARCHAR(255) NOT NULL,
	tnumber INT NOT NULL,
	PRIMARY KEY (fname, fnumber, tname, tnumber),
	FOREIGN KEY (fname, fnumber) REFERENCES subscriber(username, number),
	FOREIGN KEY (tname, tnumber) REFERENCES subscriber(username, number)
);

CREATE TABLE person (
	id INT NOT NULL PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	birthday DATE
);

CREATE TABLE film (
	title VARCHAR(255) NOT NULL,
	year INT NOT NULL,
	creator INT NOT NULL REFERENCES person(id),
	duration VARCHAR(255) NOT NULL,
	budget DECIMAL(20,2) NOT NULL,
	PRIMARY KEY (title, year, creator)
);

CREATE TABLE review(
	uname VARCHAR(255) NOT NULL,
	unumber INT NOT NULL,
	revision INT NOT NULL DEFAULT 0,
	ftitle VARCHAR(255) NOT NULL,
	fyear INT NOT NULL,
	fcreator INT NOT NULL,
	score INT NOT NULL,
	timestamp TIMESTAMP NOT NULL,
	FOREIGN KEY (ftitle, fyear, fcreator) REFERENCES film(title, year, creator),
	PRIMARY KEY (uname, unumber, revision, ftitle, fyear, fcreator),
	CONSTRAINT is_score_in_range CHECK(NOT (score < 0 OR score > 10))
);

CREATE TABLE video_review(
	uname VARCHAR(255) NOT NULL,
	unumber INT NOT NULL,
	revision INT NOT NULL DEFAULT 0,
	ftitle VARCHAR(255) NOT NULL,
	fyear INT NOT NULL,
	fcreator INT NOT NULL,
	video BLOB NOT NULL,
	FOREIGN KEY (uname, unumber, revision, ftitle, fyear, fcreator) REFERENCES review(uname, unumber, revision, ftitle, fyear, fcreator),
	PRIMARY KEY (uname, unumber, revision, ftitle, fyear, fcreator)
);

CREATE TABLE text_review(
	uname VARCHAR(255) NOT NULL,
	unumber INT NOT NULL,
	revision INT NOT NULL DEFAULT 0,
	ftitle VARCHAR(255) NOT NULL,
	fyear INT NOT NULL,
	fcreator INT NOT NULL,
	description CLOB NOT NULL,
	FOREIGN KEY (uname, unumber, revision, ftitle, fyear, fcreator) REFERENCES review(uname, unumber, revision, ftitle, fyear, fcreator),
	PRIMARY KEY (uname, unumber, revision, ftitle, fyear, fcreator)
);

CREATE TABLE reaction(
	id INT NOT NULL PRIMARY KEY,
	byuname VARCHAR(255) NOT NULL,
	byunumber INT NOT NULL,
	title VARCHAR(255) NOT NULL,
	content CLOB NOT NULL,
	FOREIGN KEY (byuname, byunumber) REFERENCES subscriber(username, number)
);

CREATE TABLE thread_r(
	id INT NOT NULL PRIMARY KEY,
	onid INT NOT NULL,
	FOREIGN KEY (id) REFERENCES reaction(id),
	FOREIGN KEY (onid) REFERENCES reaction(id)
);

CREATE TABLE review_r(
	id INT NOT NULL PRIMARY KEY,
	uname VARCHAR(255) NOT NULL,
	unumber INT NOT NULL,
	revision INT NOT NULL DEFAULT 0,
	ftitle VARCHAR(255) NOT NULL,
	fyear INT NOT NULL,
	fcreator INT NOT NULL,
	FOREIGN KEY (id) REFERENCES reaction(id),
	FOREIGN KEY (uname, unumber, revision, ftitle, fyear, fcreator) REFERENCES review(uname, unumber, revision, ftitle, fyear, fcreator)
);

CREATE TABLE role_as(
	pid INT NOT NULL,
	ftitle VARCHAR(255) NOT NULL,
	fyear INT NOT NULL,
	fcreator INT NOT NULL,
	role VARCHAR(20) NOT NULL,
	FOREIGN KEY (pid) REFERENCES person(id),
	FOREIGN KEY (ftitle, fyear, fcreator) REFERENCES film(title, year, creator),
	PRIMARY KEY (pid, ftitle, fyear, fcreator)
);

CREATE VIEW film_info 
AS (SELECT f.title, f.year, f.duration, f.budget, f.creator AS creator_name FROM film f);

-- because multi-table check is NOT supported by DB2, it was writed down in the report part.

TERMINATE;

