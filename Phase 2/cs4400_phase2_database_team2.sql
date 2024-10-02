-- CS4400: Introduction to Database Systems: Monday, June 10, 2024
-- Simple Cruise Management System Course Project Database TEMPLATE (v0)

-- Team 2
-- Saloni Rath srath34
-- Nisha Shakya nshakya3
-- Nikita Dua ndua31
-- Samreen Farooqi sfarooqui34
-- Sarah Ann T George sgeorge81

-- Directions:
-- Please follow all instructions for Phase II as listed on Canvas.
-- Fill in the team number and names and GT usernames for all members above.
-- Create Table statements must be manually written, not taken from an SQL Dump file.
-- This file must run without error for credit.

/* This is a standard preamble for most of our scripts.  The intent is to establish
a consistent environment for the database behavior. */
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

set @thisDatabase = 'cruise_tracking';
drop database if exists cruise_tracking;
create database if not exists cruise_tracking;
use cruise_tracking;

drop table if exists route;
create table route(
routeID varchar(50) not null,
primary key(routeID)
) engine = innodb;


drop table if exists cruise;
create table cruise(
	cruiseID varchar(50) not null,
    routeID varchar(50) not null,
    cost int not null,
    primary key (cruiseID),
    constraint fk05 foreign key(routeID) references route(routeID)
) engine = innodb;

drop table if exists cruiseline;
create table cruiseline(
cruiselineID varchar(50) not null,
primary key(cruiselineID)
) engine = innodb;

drop table if exists person;
create table person(
personID varchar(50) not null, 
fname varchar(100) not null,
lname varchar(100) not null,
primary key (personID)
) engine = innodb;

drop table if exists crew;
create table crew(
personID varchar(50) not null,
cruiseID varchar(50),
taxID varchar(11),
experience int,
primary key(personID),
key(taxID),
constraint fk02 foreign key(personID) references person(personID),
constraint fk04 foreign key(cruiseID) references cruise(cruiseID)
) engine = innodb;

drop table if exists crew_license;
create table crew_license(
personID varchar(50) not null,
license varchar(100),
primary key(personID, license),
constraint fk01 foreign key(personID) references crew(personID)
) engine = innodb;

drop table if exists passenger;
create table passenger(
personID varchar(50) not null,
funds int not null,
miles int not null,
primary key(personID),
constraint fk03 foreign key(personID) references person(personID)
) engine = innodb;

drop table if exists location;
create table location(
locationID varchar(50) not null,
primary key(locationID)
) engine = innodb;

drop table if exists port;
create table port(
portID varchar(50) not null,
port_name varchar(100) not null,
city varchar(100) not null,
state varchar(100),
country varchar(100) not null,
locationID varchar(50),
primary key(portID),
constraint fk13 foreign key(locationID) references location(locationID)
) engine = innodb;

drop table if exists leg;
create table leg(
legID varchar(50) not null,
distance int not null,
portID_Departure varchar(50) not null,
portID_Arrival varchar(50) not null,
primary key(legID),
constraint fk08 foreign key(portID_Arrival) references port(portID),
constraint fk09 foreign key(portID_Departure) references port(portID)
) engine = innodb;

drop table if exists contains;
create table contains(
routeID varchar(50) not null,
legID varchar(50) not null,
sequence varchar(100) not null,
primary key(routeID, legID, sequence),
constraint fk06 foreign key(routeID) references route(routeID),
constraint fk07 foreign key(legID) references leg(legID)
) engine = innodb;


drop table if exists occupies;
create table occupies(
personID varchar(50) not null,
locationID varchar(50) not null, 
primary key(personID, locationID),
constraint fk10 foreign key(locationID) references location(locationID),
constraint fk11 foreign key(personID) references person(personID)
) engine = innodb;

drop table if exists ship;
create table ship(
ship_name varchar(50) not null,
cruiselineID varchar(50) not null,
speed float not null,
max_cap int not null,
locationID varchar(50),
primary key(ship_name, cruiselineID),
constraint fk12 foreign key(cruiselineID) references cruiseline(cruiselineID),
constraint fk14 foreign key(locationID) references location(locationID)
) engine = innodb;

drop table if exists river;
create table river(
ship_name varchar(50) not null,
cruiselineID varchar(50) not null,
uses_paddles boolean not null,
primary key(ship_name, cruiselineID),
constraint fk15 foreign key(ship_name, cruiselineID) references ship(ship_name, cruiselineID)
) engine = innodb;

drop table if exists booked;
create table booked(
personID varchar(50) not null,
cruiseID varchar(50) not null,
primary key(personID,cruiseID),
constraint fk19 foreign key(personID) references passenger(personID),
constraint fk20 foreign key(cruiseID) references cruise(cruiseID)
) engine = innodb;



drop table if exists ocean_liner;
create table ocean_liner(
ship_name varchar(50) not null,
cruiselineID varchar(50) not null,
lifeboats int not null,
primary key(ship_name, cruiselineID),
constraint fk16 foreign key (ship_name, cruiselineID) references ship(ship_name, cruiselineID)
) engine = innodb;

drop table if exists supports;
create table supports(
cruiseID varchar(50) not null,
ship_name varchar(50) not null,
cruiselineID varchar(50) not null,
progress int not null,
ship_status varchar(100) not null,
next_time time not null,
primary key(cruiseID),
constraint fk17 foreign key (cruiseID) references cruise(cruiseID),
constraint fk18 foreign key (ship_name, cruiselineID) references ship(ship_name, cruiselineID)
) engine = innodb;




INSERT INTO person (personID, fname, lname) VALUES
('p1', 'Jeanne', 'Nelson'),
('p10', 'Lawrence', 'Morgan'),
('p11', 'Sandra', 'Cruz'),
('p12', 'Dan', 'Ball'),
('p13', 'Bryant', 'Figueroa'),
('p14', 'Dana', 'Perry'),
('p15', 'Matt', 'Hunt'),
('p16', 'Edna', 'Brown'),
('p17', 'Ruby', 'Burgess'),
('p18', 'Esther', 'Pittman'),
('p19', 'Doug', 'Fowler'),
('p2', 'Roxanne', 'Byrd'),
('p20', 'Thomas', 'Olson'),
('p21', 'Mona', 'Harrison'),
('p22', 'Arlene', 'Massey'),
('p23', 'Judith', 'Patrick'),
('p24', 'Reginald', 'Rhodes'),
('p25', 'Vincent', 'Garcia'),
('p26', 'Cheryl', 'Moore'),
('p27', 'Michael', 'Rivera'),
('p28', 'Luther', 'Matthews'),
('p29', 'Moses', 'Parks'),
('p3', 'Tanya', 'Nguyen'),
('p30', 'Ora', 'Steele'),
('p31', 'Antonio', 'Flores'),
('p32', 'Glenn', 'Ross'),
('p33', 'Irma', 'Thomas'),
('p34', 'Ann', 'Maldonado'),
('p35', 'Jeffrey', 'Cruz'),
('p36', 'Sonya', 'Price'),
('p37', 'Tracy', 'Hale'),
('p38', 'Albert', 'Simmons'),
('p39', 'Karen', 'Terry'),
('p4', 'Kendra', 'Jacobs'),
('p40', 'Glen', 'Kelley'),
('p41', 'Brooke', 'Little'),
('p42', 'Daryl', 'Nguyen'),
('p43', 'Judy', 'Willis'),
('p44', 'Marco', 'Klein'),
('p45', 'Angelica', 'Hampton'),
('p5', 'Jeff', 'Burton'),
('p6', 'Randal', 'Parks'),
('p7', 'Sonya', 'Owens'),
('p8', 'Bennie', 'Palmer'),
('p9', 'Marlene', 'Warner');

insert into route values
('americas_one'),
('americas_three'),
('americas_two'),
('big_mediterranean_loop'),
('euro_north'),
('euro_south');

insert into cruise values
('rc_10','americas_one',200),
('cn_38','americas_three',200),
('dy_61','americas_two',200),
('nw_20','euro_north',300),
('pn_16','euro_south',400),
('rc_51','big_mediterranean_loop',100);


insert into cruiseline values
('Royal Caribbean'),
('Carnival'),
('Norwegian'),
('MSC'),
('Princess'),
('Celebrity'),
('Disney'),
('Holland America'),
('Costa'),
('P&O Cruises'),
('AIDA'),
('Viking Ocean'),
('Silversea'),
('Regent'),
('Oceania'),
('Seabourn'),
('Cunard'),
('Azamara'),
('Windstar'),
('Hurtigruten'),
('Paul Gauguin Cruises'),
('Celestyal Cruises'),
('Saga Cruises'),
('Ponant'),
('Star Clippers'),
('Marella Cruises');

INSERT INTO crew (personID, cruiseID, taxID, experience) VALUES 
('p1', 'rc_10', '330-12-6907', 31),('p10', 'nw_20', '769-60-1266', 15), ('p11', 'pn_16', '369-22-9505', 22), ('p12', NULL, '680-92-5329', 24), ('p13', 'pn_16', '513-40-4168', 24), ('p14', 'pn_16', '454-71-7847', 13), ('p15', NULL, '153-47-8101', 30), ('p16', 'rc_51', '598-47-5172', 28), ('p17', 'rc_51', '865-71-6800', 36), ('p18', 'rc_51', '250-86-2784', 23), ('p19', NULL, '386-39-7881', 2), ('p2', 'rc_10', '842-88-1257', 9), ('p20', NULL, '522-44-3098', 28), ('p3', 'cn_38', '750-24-7616', 11), ('p4', 'cn_38', '776-21-8098', 24), ('p5', 'dy_61', '933-93-2165', 27), ('p6', 'dy_61', '707-84-4555', 38), ('p7', 'nw_20', '450-25-5617', 13), ('p8', NULL, '701-38-2179', 12), ('p9', 'nw_20', '936-44-6941', 13);

insert into location values
('port_1'),
('port_2'),
('port_3'),
('port_10'),
('port_17'),
('ship_1'),
('ship_5'),
('ship_8'),
('ship_13'),
('ship_20'),
('port_12'),
('port_14'),
('port_15'),
('port_20'),
('port_4'),
('port_16'),
('port_11'),
('port_23'),
('port_7'),
('port_6'),
('port_13'),
('port_21'),
('port_18'),
('port_22'),
('ship_6'),
('ship_25'),
('ship_7'),
('ship_21'),
('ship_24'),
('ship_23'),
('ship_18'),
('ship_26'),
('ship_22');

insert into crew_license (personID, license) VALUES 
('p1', 'ocean_liner'), ('p10', 'ocean_liner'), ('p11', 'ocean_liner'), ('p11', 'river'), ('p12', 'river'), ('p13', 'river'), ('p14', 'ocean_liner'), ('p14', 'river'), ('p15', 'ocean_liner'), ('p15', 'river'), ('p16', 'ocean_liner'), ('p17', 'ocean_liner'), ('p17', 'river'), ('p18', 'ocean_liner'), ('p19', 'ocean_liner'), ('p2', 'ocean_liner'), ('p2', 'river'), ('p20', 'ocean_liner'), ('p3', 'ocean_liner'), ('p4', 'ocean_liner'), ('p4', 'river'), ('p5', 'ocean_liner'), ('p6', 'ocean_liner'), ('p6', 'river'), ('p7', 'ocean_liner'), ('p8', 'river'), ('p9', 'ocean_liner'), ('p9', 'river');

insert into passenger (personID, funds, miles) VALUES ('p21', 700, 771), ('p22', 200, 374), ('p23', 400, 414), ('p24', 500, 292), ('p25', 300, 390), ('p26', 600, 302), ('p27', 400, 470), ('p28', 400, 208), ('p29', 700, 292), ('p30', 500, 686), ('p31', 400, 547), ('p32', 500, 257), ('p33', 600, 564), ('p34', 200, 211), ('p35', 500, 233), ('p36', 400, 293), ('p37', 700, 552), ('p38', 700, 812), ('p39', 400, 541), ('p40', 700, 441), ('p41', 300, 875), ('p42', 500, 691), ('p43', 300, 572), ('p44', 500, 572), ('p45', 500, 663);

INSERT INTO port VALUES ('MIA', 'Port of Miami', 'Miami', 'Florida', 'USA', 'port_1'), ('EGS', 'Port Everglades', 'Fort Lauderdale', 'Florida', 'USA', 'port_2'), ('CZL', 'Port of Cozumel', 'Cozumel', 'Quintana Roo', 'MEX', 'port_3'), ('CNL', 'Port Canaveral', 'Cape Canaveral', 'Florida', 'USA', 'port_4'), ('NSU', 'Port of Nassau', 'Nassau', 'New Providence', 'BHS', NULL), ('BCA', 'Port of Barcelona', 'Barcelona', 'Catalonia', 'ESP', 'port_6'), ('CVA', 'Port of Civitavecchia', 'Civitavecchia', 'Lazio', 'ITA', 'port_7'), ('VEN', 'Port of Venice', 'Venice', 'Veneto', 'ITA', 'port_14'), ('SHA', 'Port of Southampton', 'Southampton', NULL, 'GBR', NULL), ('GVN', 'Port of Galveston', 'Galveston', 'Texas', 'USA', 'port_10'), ('SEA', 'Port of Seattle', 'Seattle', 'Washington', 'USA', 'port_11'), ('SJN', 'Port of San Juan', 'San Juan', 'Puerto Rico', 'USA', 'port_12'), ('NOS', 'Port of New Orleans', 'New Orleans', 'Louisiana', 'USA', 'port_13'), ('SYD', 'Port of Sydney', 'Sydney', 'New South Wales', 'AUS', NULL), ('TMP', 'Port of Tampa Bay', 'Tampa Bay', 'Florida', 'USA', 'port_15'), ('VAN', 'Port of Vancouver', 'Vancouver', 'British Columbia', 'CAN', 'port_16'), ('MAR', 'Port of Marseille', 'Marseille', 'Provence-Alpes-Côte d''Azur', 'FRA', 'port_17'), ('COP', 'Port of Copenhagen', 'Copenhagen', 'Hovedstaden', 'DEN', 'port_18'), ('BRI', 'Port of Bridgetown', 'Bridgetown', 'Saint Michael', 'BRB', NULL), ('PIR', 'Port of Piraeus', 'Piraeus', 'Attica', 'GRC', 'port_20'), ('STS', 'Port of St. Thomas', 'Charlotte Amalie', 'St. Thomas', 'USVI', 'port_21'), ('STM', 'Port of Stockholm', 'Stockholm', 'Stockholm County', 'SWE', 'port_22'), ('LAS', 'Port of Los Angeles', 'Los Angeles', 'California', 'USA', 'port_23');

INSERT INTO LEG (legID, distance, portID_Departure, portID_Arrival) VALUES
('leg_2', 190, 'MIA', 'NSU'),
('leg_1', 792, 'NSU', 'SJN'),
('leg_31', 1139, 'LAS', 'SEA'),
('leg_14', 126, 'SEA', 'VAN'),
('leg_4', 29, 'MIA', 'EGS'),
('leg_47', 185, 'BCA', 'MAR'),
('leg_15', 312, 'MAR', 'CVA'),
('leg_27', 941, 'CVA', 'VEN'),
('leg_33', 855, 'VEN', 'PIR'),
('leg_64', 427, 'STM', 'COP'),
('leg_78', 803, 'COP', 'SHA');


INSERT INTO ship  VALUES
('Symphony of the Seas', 'Royal Caribbean', 22, 6680, 'ship_1'),
('Carnival Vista', 'Carnival', 23, 3934, 'ship_23'),
('Norwegian Bliss', 'Norwegian', 22.5, 4004, 'ship_24'),
('Meraviglia', 'MSC', 22.7, 4488, 'ship_22'),
('Crown Princess', 'Princess', 23, 3080, 'ship_5'),
('Celebrity Edge', 'Celebrity', 22, 2908, 'ship_6'),
('Disney Dream', 'Disney', 23.5, 4000, 'ship_7'),
('MS Nieuw Statendam', 'Holland America', 23, 2666, 'ship_8'),
('Costa Smeralda', 'Costa', 23, 6554, NULL),
('Iona', 'P&O Cruises', 22.6, 5200, NULL),
('AIDAnova', 'AIDA', 21.5, 6600, NULL),
('Viking Orion', 'Viking Ocean', 20, 930, NULL),
('Silver Muse', 'Silversea', 19.8, 596, 'ship_13'),
('Seven Seas Explorer', 'Regent', 19.5, 750, NULL),
('Marina', 'Oceania', 20, 1250, NULL),
('Seabourn Ovation', 'Seabourn', 19, 604, NULL),
('Queen Mary 2', 'Cunard', 30, 2691, NULL),
('Azamara Quest', 'Azamara', 18.5, 686, 'ship_18'),
('Oasis of the Seas', 'Royal Caribbean', 18, 1325, 'ship_25'),
('Wind Surf', 'Windstar', 15, 342, 'ship_20'),
('MS Roald Amundsen', 'Hurtigruten', 15.5, 530, 'ship_21'),
('Paul Gauguin', 'Paul Gauguin Cruises', 18, 332, NULL),
('Celestyal Crystal', 'Celestyal Cruises', 18.5, 1200, NULL),
('Spirit of Discovery', 'Saga Cruises', 21, 999, NULL),
('Le Lyrial', 'Ponant', 16, 264, 'ship_26'),
('Royal Clipper', 'Star Clippers', 17, 227, NULL),
('Marella Explorer', 'Marella Cruises', 21.5, 1924, NULL);

INSERT INTO RIVER  VALUES
('Azamara Quest', 'Azamara', TRUE),
('Wind Surf', 'Windstar', FALSE),
('MS Roald Amundsen', 'Hurtigruten', TRUE),
('Celestyal Crystal', 'Celestyal Cruises', FALSE),
('Le Lyrial', 'Ponant', TRUE),
('Royal Clipper', 'Star Clippers', TRUE);

INSERT INTO BOOKED VALUES ('p21', 'nw_20'), ('p23', 'rc_10'), ('p25', 'rc_10'), ('p37', 'pn_16'), ('p38', 'pn_16');


INSERT INTO SUPPORTS VALUES ('rc_10', 'Symphony of the Seas', 'Royal Caribbean', 1, 'sailing', '08:00:00'), ('cn_38', 'Carnival Vista', 'Carnival', 2, 'sailing', '14:30:00'), ('dy_61', 'Disney Dream', 'Disney', 0, 'docked', '09:30:00'), ('nw_20', 'Norwegian Bliss', 'Norwegian', 2, 'sailing', '11:00:00'), ('pn_16', 'Le Lyrial', 'Ponant', 1, 'sailing', '14:00:00'), ('rc_51', 'Oasis of the Seas', 'Royal Caribbean', 3, 'docked', '11:30:00');

INSERT INTO occupies  VALUES
('p1', 'ship_1'),
('p10', 'ship_24'),
('p13', 'ship_26'),
('p14', 'ship_26'),
('p16', 'ship_25'),
('p16', 'port_14'),
('p17', 'ship_25'),
('p17', 'port_14'),
('p18', 'ship_25'),
('p18', 'port_14'),
('p2', 'ship_1'),
('p21', 'ship_24'),
('p23', 'ship_1'),
('p25', 'ship_1'),
('p3', 'ship_23'),
('p37', 'ship_26'),
('p38', 'ship_26'),
('p4', 'ship_23'),
('p5', 'ship_7'),
('p5', 'port_1'),
('p6', 'ship_7'),
('p6', 'port_1'),
('p7', 'ship_24'),
('p9', 'ship_24');


INSERT INTO contains (routeID, legID, sequence) VALUES
('americas_one', 'leg_2', 1),
('americas_one', 'leg_1', 2),
('americas_three', 'leg_31', 1),
('americas_three', 'leg_14', 2),
('americas_two', 'leg_4', 1),
('big_mediterranean_loop', 'leg_47', 1),
('big_mediterranean_loop', 'leg_15', 2),
('big_mediterranean_loop', 'leg_27', 3),
('big_mediterranean_loop', 'leg_33', 4),
('euro_north', 'leg_64', 1),
('euro_north', 'leg_78', 2),
('euro_south', 'leg_47', 1),
('euro_south', 'leg_15', 2);

INSERT INTO ocean_liner VALUES
('Symphony of the Seas', 'Royal Caribbean', 20),
('Carnival Vista', 'Carnival', 20),
('Norwegian Bliss', 'Norwegian', 15),
('Meraviglia', 'MSC', 20),
('Crown Princess', 'Princess', 20),
('Celebrity Edge', 'Celebrity', 20),
('Disney Dream', 'Disney', 20),
('MS Nieuw Statendam', 'Holland America', 30),
('Iona', 'P&O Cruises', 20),
('AIDAnova', 'AIDA', 35),
('Viking Orion', 'Viking Ocean', 20),
('Silver Muse', 'Silversea', 30),
('Seven Seas Explorer', 'Regent', 20),
('Marina', 'Oceania', 25),
('Seabourn Ovation', 'Seabourn', 20),
('Queen Mary 2', 'Cunard', 40),
('Oasis of the Seas', 'Royal Caribbean', 30),
('Spirit of Discovery', 'Saga Cruises', 2),
('Marella Explorer', 'Marella Cruises', 2);

