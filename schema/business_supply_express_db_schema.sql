/* This is a standard preamble for most of our scripts.  The intent is to establish
a consistent environment for the database behavior. */
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

set @thisDatabase = 'business_supply';
drop database if exists business_supply;
create database if not exists business_supply;
use business_supply;

-- Define the database structures


CREATE TABLE user (
username VARCHAR(40),
address VARCHAR(500) NOT NULL, 
birthdate DATE NOT NULL,
first_name VARCHAR(100) NOT NULL,
last_name VARCHAR(100) NOT NULL,
PRIMARY KEY(username) 
);
	
CREATE TABLE employee (
taxID CHAR(11),
username VARCHAR(40) NOT NULL,
hired DATE,
salary INT,
experience INT, 
PRIMARY KEY(taxID),
FOREIGN KEY (username) REFERENCES user(username)
);


CREATE TABLE owner (
username VARCHAR(40),
PRIMARY KEY (username),
FOREIGN KEY (username) REFERENCES user(username)
);

CREATE TABLE product (
barcode VARCHAR(100),
iname VARCHAR(100),
weight INT NOT NULL, 
PRIMARY KEY(barcode)
);

CREATE TABLE driver (
licenseID VARCHAR(40),
taxID CHAR(11), 
successful_trips INT, 
license_type VARCHAR(100) NOT NULL, 
PRIMARY KEY(licenseID), 
FOREIGN KEY (taxID) REFERENCES employee(taxID)
);



CREATE TABLE worker (
taxID CHAR(11),
PRIMARY KEY (taxID),
FOREIGN KEY (taxID) REFERENCES employee(taxID)
);


CREATE TABLE location(
label VARCHAR(40) NOT NULL,
x_coord INT NOT NULL, 
y_coord INT NOT NULL,
space INT, 
PRIMARY KEY(label)
);

CREATE TABLE service (
id CHAR(3),
name VARCHAR(100) NOT NULL,
label VARCHAR(40) NOT NULL,
manager VARCHAR(40) UNIQUE, 
PRIMARY KEY (id),
FOREIGN KEY (label) REFERENCES location(label),
FOREIGN KEY (manager) REFERENCES user(username)
);

CREATE TABLE van (
tag VARCHAR(40), 
id CHAR(3),
capacity INT NOT NULL, 
sales INT NOT NULL, 
fuel INT NOT NULL, 
van_owner CHAR(3) NOT NULL,
controller VARCHAR(40),
parks_at VARCHAR(100) NOT NULL,
PRIMARY KEY(tag, id),
FOREIGN KEY (id) REFERENCES service(id), 
FOREIGN KEY (van_owner) REFERENCES service(id),
FOREIGN KEY (controller) REFERENCES driver(licenseID),
FOREIGN KEY (parks_at) REFERENCES location(label)
);

CREATE TABLE business(
name VARCHAR(40),
rating INT NOT NULL,  
spent INT NOT NULL, 
label VARCHAR(40) UNIQUE NOT NULL, 
PRIMARY KEY(name),
FOREIGN KEY (label) REFERENCES location(label)
);

CREATE TABLE work_for(
worker CHAR(11) NOT NULL,
service CHAR(3) NOT NULL,
FOREIGN KEY (worker) REFERENCES worker(taxID),
FOREIGN KEY(service) REFERENCES service(ID)
);

CREATE TABLE fund (
owner VARCHAR(40),
business VARCHAR(40),
invested INT NOT NULL,
date DATE NOT NULL,
PRIMARY KEY (owner, business),
FOREIGN KEY (owner) REFERENCES owner(username), 
FOREIGN KEY (business) REFERENCES business(name)
);

CREATE TABLE contain (
product VARCHAR(40), 
van_tag VARCHAR(40) NOT NULL, 
van_id CHAR(3) NOT NULL,
price INT NOT NULL, 
quantity INT NOT NULL,
PRIMARY KEY (product, van_tag, van_id), 
FOREIGN KEY (product) REFERENCES product(barcode),
FOREIGN KEY (van_tag, van_ID) REFERENCES van(tag, id)  
);



INSERT INTO USER VALUES
('agarcia7', '710 Living Water Drive', '1966-10-29', 'Alejandro', 'Garcia'),
('awilson5', '220 Peachtree Street', '1963-11-11', 'Aaron', 'Wilson'),
('bsummers4', '5105 Dragon Star Circle', '1976-02-09', 'Brie', 'Summers'),
('cjordan5', '77 Infinite Stars Road', '1966-06-05', 'Clark', 'Jordan'),
('ckann5', '64 Knights Square Trail', '1972-09-01', 'Carrot', 'Kann'),
('csoares8', '706 Living Stone Way', '1965-09-03', 'Claire', 'Soares'),
('echarles19', '22 Peachtree Street', '1974-05-06', 'Ella', 'Charles'),
('eross10', '22 Peachtree Street', '1975-04-02', 'Erica', 'Ross'),
('fprefontaine6', '10 Hitch Hikers Lane', '1961-01-28', 'Ford', 'Prefontaine'),
('hstark16', '53 Tanker Top Lane', '1971-10-27', 'Harmon', 'Stark'),
('jstone5', '101 Five Finger Way', '1961-01-06', 'Jared', 'Stone'),
('lrodriguez5', '360 Corkscrew Circle', '1975-04-02', 'Lina', 'Rodriguez'),
('mrobot1', '10 Autonomy Trace', '1988-11-02', 'Mister', 'Robot'),
('mrobot2', '10 Clone Me Circle', '1988-11-02', 'Mister', 'Robot'),
('rlopez6', '8 Queens Route', '1999-09-03', 'Radish', 'Lopez'),
('sprince6', '22 Peachtree Street', '1968-06-15', 'Sarah', 'Prince'),
('tmccall5', '360 Corkscrew Circle', '1973-03-19', 'Trey', 'McCall');

INSERT INTO EMPLOYEE VALUES
('999-99-9999', 'agarcia7', '2019-03-17', 41000, 24),
('111-11-1111', 'awilson5', '2020-03-15', 46000, 9),
('000-00-0000', 'bsummers4', '2018-12-06', 35000, 17),
('640-81-2357', 'ckann5', '2019-08-03', 46000, 27),
('888-88-8888', 'csoares8', '2019-02-25', 57000, 26),
('777-77-7777', 'echarles19', '2021-01-02', 27000, 3),
('444-44-4444', 'eross10', '2020-04-17', 61000, 10),
('121-21-2121', 'fprefontaine6', '2020-04-19', 20000, 5),
('555-55-5555', 'hstark16', '2018-07-23', 59000, 20),
('222-22-2222', 'lrodriguez5', '2019-04-15', 58000, 20),
('101-01-0101', 'mrobot1', '2015-05-27', 38000, 8),
('010-10-1010', 'mrobot2', '2015-05-27', 38000, 8),
('123-58-1321', 'rlopez6', '2017-02-05', 64000, 51),
('333-33-3333', 'tmccall5', '2018-10-17', 33000, 29);

INSERT INTO OWNER VALUES
('cjordan5'),
('jstone5'),
('sprince6');

INSERT INTO PRODUCT VALUES
('gc_4C6B9R', 'glass cleaner', 4),
('pn_2D7Z6C', 'pens', 5),
('sd_6J5S8H', 'screwdrivers', 4),
('pt_16WEF6', 'paper towels', 6),
('st_2D4E6L', 'shipping tape', 3),
('hm_5E7L23M', 'hammer', 3);

INSERT INTO DRIVER VALUES
('610623', '999-99-9999', 38, 'CDL'),
('314159', '111-11-1111', 41, 'commercial'),
('411911', '000-00-0000', 35, 'private'),
('343563', '888-88-8888', 7, 'commercial'),
('657483', '121-21-2121', 2, 'private'),
('287182', '222-22-2222', 67, 'CDL'),
('101010', '101-01-0101', 18, 'CDL'),
('235711', '123-58-1321', 58, 'private');

INSERT INTO WORKER VALUES
('640-81-2357'),
('777-77-7777'),
('444-44-4444'),
('555-55-5555'),
('333-33-3333'),
('010-10-1010');

INSERT INTO LOCATION VALUES
('airport', 5, -6, 15),
('downtown', -4, -3, 10),
('springs', 7, 10, 8),
('buckhead', 7, 10, 8),
('avalon', 2, 15, 12),
('mercedes', -8, 5, NULL),
('highlands', 2, 1, 7),
('southside', 1, -16, 5),
('midtown', 2, 1, 7),
('plaza', -4, -3, 10);

INSERT INTO SERVICE VALUES
('mbm', 'Metro Business Movers', 'southside', 'hstark16'),
('lcc', 'Local Commerce Couriers', 'plaza', 'eross10'),
('pbl', 'Pro Business Logistics', 'avalon', 'echarles19');

INSERT INTO VAN VALUES
('1', 'mbm', 6, 0, 100, 'mbm', '657483', 'southside'),
('5', 'mbm', 7, 100, 27, 'mbm', '657483', 'buckhead'),
('8', 'mbm', 8, 0, 100, 'mbm', '411911', 'southside'),
('11', 'mbm', 10, 0, 25, 'mbm', NULL, 'southside'),
('16', 'mbm', 5, 40, 17, 'mbm', '657483', 'southside'),
('1', 'lcc', 9, 0, 100, 'lcc', '314159', 'airport'),
('2', 'lcc', 7, 0, 75, 'lcc', NULL, 'plaza'),
('3', 'pbl', 5, 50, 100, 'pbl', '610623', 'avalon'),
('7', 'pbl', 5, 100, 53, 'pbl', '610623', 'avalon'),
('8', 'pbl', 6, 0, 100, 'pbl', '610623', 'highlands'),
('11', 'pbl', 6, 0, 90, 'pbl', NULL, 'avalon');

INSERT INTO BUSINESS VALUES
('Aircraft Electrical Svc', 5, 10, 'airport'),
('Homestead Insurance', 5, 30, 'downtown'),
('Jones and Associates', 3, 0, 'springs'),
('Prime Solutions', 4, 30, 'buckhead'),
('Innovative Ventures', 4, 0, 'avalon'),
('Blue Horizon Enterprises', 4, 10, 'mercedes'),
('Peak Performance Group', 5, 20, 'highlands'),
('Summit Strategies', 2, 0, 'southside'),
('Elevate Consulting', 5, 30, 'midtown'),
('Pinnacle Partners', 4, 10, 'plaza');

INSERT INTO WORK_FOR VALUES
('640-81-2357', 'lcc'),
('777-77-7777', 'pbl'),
('444-44-4444', 'lcc'),
('555-55-5555', 'mbm'),
('333-33-3333', 'mbm'),
('010-10-1010', 'pbl');

INSERT INTO FUND VALUES
('jstone5', 'Jones and Associates', 20, '2022-10-25'),
('sprince6', 'Blue Horizon Enterprises', 10, '2022-03-06'),
('jstone5', 'Peak Performance Group', 30, '2022-09-08'),
('jstone5', 'Elevate Consulting', 5, '2022-07-25');

INSERT INTO CONTAIN VALUES
('pn_2D7Z6C', '3', 'pbl', 28, 2),
('pn_2D7Z6C', '5', 'mbm', 30, 1),
('pt_16WEF6', '1', 'lcc', 20, 5),
('pt_16WEF6', '8', 'mbm', 18, 4),
('st_2D4E6L', '1', 'lcc', 23, 3),
('st_2D4E6L', '11', 'mbm', 19, 3),
('st_2D4E6L', '1', 'mbm', 27, 6),
('hm_5E7L23M', '2', 'lcc', 14, 7),
('hm_5E7L23M', '3', 'pbl', 15, 2),
('hm_5E7L23M', '5', 'mbm', 17, 4);

