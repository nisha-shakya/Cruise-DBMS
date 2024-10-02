-- CS4400: Introduction to Database Systems: Monday, July 1, 2024
-- Simple Cruise Management System Course Project Stored Procedures [TEMPLATE] (v0)
-- Views, Functions & Stored Procedures

/* This is a standard preamble for most of our scripts.  The intent is to establish
a consistent environment for the database behavior. */
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

set @thisDatabase = 'cruise_tracking';
use cruise_tracking;
-- -----------------------------------------------------------------------------
-- stored procedures and views
-- -----------------------------------------------------------------------------
/* Standard Procedure: If one or more of the necessary conditions for a procedure to
be executed is false, then simply have the procedure halt execution without changing
the database state. Do NOT display any error messages, etc. */

-- [_] supporting functions, views and stored procedures
-- -----------------------------------------------------------------------------
/* Helpful library capabilities to simplify the implementation of the required
views and procedures. */
-- -----------------------------------------------------------------------------
drop function if exists leg_time;
delimiter //
create function leg_time (ip_distance integer, ip_speed integer)
	returns time reads sql data
begin
	declare total_time decimal(10,2);
    declare hours, minutes integer default 0;
    set total_time = ip_distance / ip_speed;
    set hours = truncate(total_time, 0);
    set minutes = truncate((total_time - hours) * 60, 0);
    return maketime(hours, minutes, 0);
end //
delimiter ;

-- [1] add_ship()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new ship.  A new ship must be sponsored
by an existing cruiseline, and must have a unique name for that cruiseline. 
A ship must also have a non-zero seat capacity and speed. A ship
might also have other factors depending on it's type, like paddles or some number
of lifeboats.  Finally, a ship must have a new and database-wide unique location
since it will be used to carry passengers. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_ship;
delimiter //
create procedure add_ship (in ip_cruiselineID varchar(50), in ip_ship_name varchar(50),
	in ip_max_capacity integer, in ip_speed integer, in ip_locationID varchar(50),
    in ip_ship_type varchar(100), in ip_uses_paddles boolean, in ip_lifeboats integer)
sp_main: begin

if ip_cruiselineID is null or ip_cruiselineID not in (select cruiselineID from cruiseline) then leave sp_main;
end if;

if ip_ship_name is null or ip_ship_name in (select ship_name from ship where cruiselineID = ip_cruiselineID ) then leave sp_main;
end if;

if ip_max_capacity = 0 or ip_speed = 0 then leave sp_main;
end if;

if ip_locationID in (select locationID from location) then leave sp_main;
end if;

insert into location values (ip_locationID);
insert into ship values (ip_cruiselineID, ip_ship_name, ip_max_capacity, ip_speed, ip_locationID, 
    ip_ship_type , ip_uses_paddles, ip_lifeboats);

end //
delimiter ;


-- [2] add_port()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new port.  A new port must have a unique
identifier along with a new and database-wide unique location if it will be used
to support ship arrivals and departures.  A port may have a longer, more
descriptive name.  An airport must also have a city, state, and country designation. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_port;
delimiter //
create procedure add_port (in ip_portID char(3), in ip_port_name varchar(200),
    in ip_city varchar(100), in ip_state varchar(100), in ip_country char(3), in ip_locationID varchar(50))
sp_main: begin
	if ip_locationID in (select locationID from location) 
    then leave sp_main;
    end if;
    
	if ip_portID in (select portID from ship_port) 
    then leave sp_main;
    end if;
    
	insert into location values(ip_locationID);
    insert into ship_port values(ip_portID, ip_port_name, ip_city, ip_state, ip_country, ip_locationID);
end //
delimiter ;



-- [3] add_person()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new person.  A new person must reference a unique
identifier along with a database-wide unique location used to determine where the
person is currently located: either at a port, on a ship, or both, at any given
time.  A person must have a first name, and might also have a last name.

A person can hold a crew role or a passenger role (exclusively).  As crew,
a person must have a tax identifier to receive pay, and an experience level.  As a
passenger, a person will have some amount of rewards miles, along with a
certain amount of funds needed to purchase cruise packages. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_person;
delimiter //
create procedure add_person (in ip_personID varchar(50), in ip_first_name varchar(100),
    in ip_last_name varchar(100), in ip_locationID varchar(50), in ip_taxID varchar(50),
    in ip_experience integer, in ip_miles integer, in ip_funds integer)
sp_main: begin

-- if personid not unique dont add 
if ip_personID is null or ip_personID in (select personID from person) then leave sp_main;
end if;
-- if fname null dont add
if ip_first_name is null then leave sp_main;
end if;

-- if its both crew and passenger dont add
if (ip_taxID is null or ip_experience is null) and (ip_miles is null or ip_funds is null) then leave sp_main;
end if;

if ip_locationID is null or ip_locationID not in (select locationID from location )then leave sp_main;
end if;

insert into person values (ip_personID, ip_first_name, ip_last_name);

if ip_locationID is not null and ip_locationID in (select locationID from location )then insert into person_occupies values (ip_personID, ip_locationID);
end if;

if ip_taxID is not null and ip_experience is not null then insert into crew values (ip_personID, ip_taxID, ip_experience, null);
end if; 

if ip_miles is not null and ip_funds is not null then insert into passenger values (ip_personID, ip_miles, ip_funds);
end if;

end //
delimiter ;



-- [4] grant_or_revoke_crew_license()
-- -----------------------------------------------------------------------------
/* This stored procedure inverts the status of a crew member's license.  If the license
doesn't exist, it must be created; and, if it already exists, then it must be removed. */
-- -----------------------------------------------------------------------------
drop procedure if exists grant_or_revoke_crew_license;
delimiter //
create procedure grant_or_revoke_crew_license (in ip_personID varchar(50), in ip_license varchar(100))
sp_main: begin
	if ip_personID in (select personID from licenses where personID = ip_personID and license = ip_license) then
    delete from licenses where personID = ip_personID and license = ip_license;
 
    else
		if ip_personID not in (select personID from licenses where personID = ip_personID and license = ip_license) and 
		ip_personID in (select personID from crew) then
		insert into licenses values (ip_personID, ip_license);
        end if;
	end if;

end //
delimiter ;

-- [5] offer_cruise()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new cruise.  The cruise can be defined before
a ship has been assigned for support, but it must have a valid route.  And
the ship, if designated, must not be in use by another cruise.  The cruise
can be started at any valid location along the route except for the final stop,
and it will begin docked.  You must also include when the cruise will
depart along with its cost. */
-- -----------------------------------------------------------------------------
drop procedure if exists offer_cruise;
delimiter //
create procedure offer_cruise (in ip_cruiseID varchar(50), in ip_routeID varchar(50),
    in ip_support_cruiseline varchar(50), in ip_support_ship_name varchar(50), in ip_progress integer,
    in ip_next_time time, in ip_cost integer)
sp_main: begin


declare status varchar(100);
set status = 'docked';

if ip_cruiseID in (select cruiseID from cruise) then leave sp_main;
end if;

if ip_routeID is null or ip_routeID not in (select routeID from route) then leave sp_main;
end if; 

if ip_support_ship_name is not null and ip_support_ship_name in (select support_ship_name from cruise) then leave sp_main;
end if; 

if ip_support_ship_name is not null and   ip_support_ship_name not in (select ship_name from ship where ship_name = ip_support_ship_name and cruiselineID = ip_support_cruiseline) 
then leave sp_main;
end if;

if ip_progress in (select max(sequence) from route_path where routeID = ip_routeID) then leave sp_main;
end if;

insert into cruise values (ip_cruiseID, ip_routeID, ip_support_cruiseline, ip_support_ship_name, ip_progress, status, ip_next_time, ip_cost);

end //
delimiter ;

-- [6] cruise_arriving()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for a cruise arriving at the next port
along its route.  The status should be updated, and the next_time for the cruise 
should be moved 8 hours into the future to allow for the passengers to disembark 
and sight-see for the next leg of travel.  Also, the crew of the cruise should receive 
increased experience, and the passengers should have their rewards miles updated. 
Everyone on the cruise must also have their locations updated to include the port of 
arrival as one of their locations, (as per the scenario description, a person's location 
when the ship docks includes the ship they are on, and the port they are docked at). */
-- -----------------------------------------------------------------------------
drop procedure if exists cruise_arriving;
delimiter //
create procedure cruise_arriving (in ip_cruiseID varchar(50))
sp_main: begin
declare curr_leg varchar(50);
declare curr_p int;
declare arr_port char(3);
declare arr_loc varchar(50);
declare ship_loc varchar(50);

-- check if cruise is valid 
if ip_cruiseID is null or ip_cruiseID not in (select cruiseID from cruise) then leave sp_main;
end if ;

-- check if cruise is already docked 
if (select ship_status from cruise where cruiseID = ip_cruiseID) like 'docked' then leave sp_main;
end if;

-- update docked and time 
update cruise set ship_status = 'docked' where cruiseID = ip_cruiseID;
update cruise set next_time = date_add(next_time, interval 8 hour) where cruiseID = ip_cruiseID;

-- increase crew experience
update crew set experience = experience + 1 where assigned_to = ip_cruiseID;

-- find the current leg of the cruise
select progress into curr_p from cruise where cruiseID =ip_cruiseID;
select legID into curr_leg from route_path where sequence = curr_p and routeID = (select routeID from cruise where cruiseID = ip_cruiseID);

-- update the miles of the passenger using the distance travelled by the current cruise
update passenger set miles = miles + (select distance from leg where legID = curr_leg) where personID in (select personID from passenger_books where cruiseID = ip_cruiseID);


-- find the location ID of the arriving port 
select arrival into arr_port from leg where legID = curr_leg;
select locationID into arr_loc from ship_port where portID = arr_port;

-- add new port for passenger and crew
insert into person_occupies(personID, locationID)
select personID, arr_loc 
from passenger_books
where cruiseID = ip_cruiseID;

-- add new port for passenger and crew
insert into person_occupies(personID, locationID)
select personID, arr_loc 
from crew
where assigned_to = ip_cruiseID;

end //
delimiter ;



-- [7] cruise_departing()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for a cruise departing from its current
port towards the next port along its route.  The time for the next leg of
the cruise must be calculated based on the distance and the speed of the ship. The progress
of the ship must also be incremented on a successful departure, and the status must be updated.
We must also ensure that everyone, (crew and passengers), are back on board. 
If the cruise cannot depart because of missing people, then the cruise must be delayed 
for 30 minutes. You must also update the locations of all the people on that cruise,
so that their location is no longer connected to the port the cruise departed from, 
(as per the scenario description, a person's location when the ship sets sails only includes 
the ship they are on and not the port of departure). */
-- -----------------------------------------------------------------------------
drop procedure if exists cruise_departing;
delimiter //
create procedure cruise_departing (in ip_cruiseID varchar(50))
sp_main: begin
    declare curr_leg varchar(50);
    declare curr_p int;
    declare ship_loc varchar(50);
    declare curr_dist int;
    declare curr_speed float;
    declare departure_p char(3);
    declare curr_nexttime float;

    -- cruise is valid or not
    if ip_cruiseID is null or ip_cruiseID not in (select cruiseID from cruise) then leave sp_main;
    end if;

    -- check is ship is docked
    if (select ship_status from cruise where cruiseID = ip_cruiseID) like 'sailing' then leave sp_main;
    end if;

    -- get ship locationID
    select locationID into ship_loc
    from cruise c 
    join ship s on c.support_cruiseline = s.cruiselineID and c.support_ship_name = s.ship_name
    where cruiseID = ip_cruiseID;

    -- check if count match
    if ( (select count(personID) 
        from passenger_books
        where cruiseID = ip_cruiseID
    ) + (select count(personID) 
        from crew 
        where assigned_to = ip_cruiseID) <> (select count(*)
        from person_occupies 
        where locationID = ship_loc)) then
        update cruise set next_time = date_add(next_time, interval 30 minute) where cruiseID = ip_cruiseID;
        leave sp_main;
    end if;

    -- update status and progress
    update cruise set ship_status = 'sailing' where cruiseID = ip_cruiseID;
    update cruise set progress = progress + 1 where cruiseID = ip_cruiseID;

    -- get current leg
    select progress into curr_p from cruise where cruiseID = ip_cruiseID;
    select legID into curr_leg from route_path where sequence = curr_p and routeID = (select routeID from cruise where cruiseID = ip_cruiseID);
    select distance into curr_dist from leg where legID = curr_leg;

    -- get speed
    select speed into curr_speed
	from cruise c 
    join ship s on c.support_cruiseline = s.cruiselineID and c.support_ship_name = s.ship_name
    where cruiseID = ip_cruiseID;

    -- calculate the next time
  set curr_nexttime = curr_dist / curr_speed;
 update cruise set next_time = date_add(next_time, interval curr_nexttime hour) where cruiseID = ip_cruiseID;

-- 	select leg_time(curr_dist, curr_speed) into curr_nexttime;
--     update cruise set next_time = addtime(next_time, curr_nextime) where cruiseID = ip_cruiseID;
    

    -- get the departure port
    select departure into departure_p from leg where legID = curr_leg;

    -- remove location assignments from the departure port
    delete from person_occupies 
    where personID in (select personID from passenger_books where cruiseID = ip_cruiseID) 
    and locationID = (select locationID from ship_port where  portID = departure_p);

    delete from  person_occupies 
    where personID in (select personID from crew where  assigned_to = ip_cruiseID) 
    and locationID = (select locationID from ship_port where  portID = departure_p);
end //
delimiter ;


-- [8] person_boards()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the location for people, (crew and passengers), 
getting on a in-progress cruise at its current port.  The person must be at the same port as the cruise,
and that person must either have booked that cruise as a passenger or been assigned
to it as a crew member. The person's location cannot already be assigned to the ship
they are boarding. After running the procedure, the person will still be assigned to the port location, 
but they will also be assigned to the ship location. */
-- -----------------------------------------------------------------------------
drop procedure if exists person_boards;
delimiter //
create procedure person_boards (in ip_personID varchar(50), in ip_cruiseID varchar(50))
sp_main: begin

	declare curr_port varchar(50);
    declare p_loc varchar(50);
    declare ship_ID varchar(50);
    declare curr_leg varchar(50);
    declare curr_p int;
    declare departure_p char(3);
    declare d_loc varchar(50);
    
    if ip_cruiseID is null or ip_cruiseID not in (select  cruiseID from cruise) then leave sp_main;
     end if;
    

    if  ip_personID is null or  ip_personID not in  (select personID from person) then leave sp_main;
    end if;
    
    -- check if cruise is already docked 
    if (select ship_status from cruise where cruiseID = ip_cruiseID) like 'sailing' then leave sp_main;
     end if;

    -- Get the ship locationID
    select locationID into ship_ID
    from cruise c 
    join ship s on c.support_cruiseline = s.cruiselineID and c.support_ship_name = s.ship_name
    where cruiseID = ip_cruiseID;
    
    -- get current leg
    select progress into curr_p from cruise where cruiseID = ip_cruiseID;
    
    -- get portID
    if curr_p = 0 then
        select legID into curr_leg from route_path where sequence = 1 and routeID = (select routeID from cruise where cruiseID = ip_cruiseID);
        select departure into departure_p from leg where legID = curr_leg;
        select locationID into d_loc from ship_port where portID = departure_p;
    else
        select legID into curr_leg from route_path where sequence = curr_p and routeID = (select routeID from cruise where cruiseID = ip_cruiseID);
        select arrival into departure_p from leg where legID = curr_leg;
        select locationID into d_loc from ship_port where portID = departure_p;
    end if;
        
    -- check if person already at current port
    IF d_loc not in (select locationID from person_occupies where personID = ip_personID) then leave sp_main;
    end if;
	
    -- check if the person a booked passenger or assigned crew
    if ip_personID not in (select personID from passenger_books where cruiseID = ip_cruiseID) 
       and ip_personID not in (select personID from crew where assigned_to = ip_cruiseID) then leave sp_main;
     end if;
            
    -- check if already in ship
    if ship_ID in (select locationID from person_occupies where personID = ip_personID) then leave sp_main;
    end if;
	
    insert into  person_occupies values(ip_personID, ship_ID);
end //
delimiter ;



-- [9] person_disembarks()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the location for people, (crew and passengers), 
getting off a cruise at its current port.  The person must be on the ship supporting 
the cruise, and the cruise must be docked at a port. The person should no longer be
assigned to the ship location, and they will only be assigned to the port location. */
-- -----------------------------------------------------------------------------
drop procedure if exists person_disembarks;
delimiter //
create procedure person_disembarks (in ip_personID varchar(50), in ip_cruiseID varchar(50))
sp_main: begin
declare curr_port varchar(50);
    declare p_loc varchar(50);
    declare ship_ID varchar(50);
    declare curr_leg varchar(50);
    declare curr_p int;
    declare departure_p char(3);
    declare d_loc varchar(50);
    
    if ip_cruiseID is null or  ip_cruiseID not in (select cruiseID from cruise) then leave sp_main;
    end if;
    
    if ip_personID is null or ip_personID not in (select  personID from person) then leave sp_main;
   end if;
    
    -- check if cruise is already docked 
    IF (select  ship_status from cruise where cruiseID = ip_cruiseID) = 'sailing' then leave sp_main;
    end if;
    
    -- get the ship locationID
    select locationID into ship_ID
    from cruise c 
   join ship s on c.support_cruiseline = s.cruiselineID and c.support_ship_name = s.ship_name
    where cruiseID = ip_cruiseID;
    
    -- get current leg 
    select progress into curr_p from cruise where cruiseID = ip_cruiseID;
    
    if curr_p = 0 then
        select legID into curr_leg from route_path where sequence = 1 and routeID = (select routeID from cruise where cruiseID = ip_cruiseID);
        select departure into departure_p from leg where legID = curr_leg;
        select locationID into d_loc from ship_port where portID = departure_p;
    else
        select legID into curr_leg from route_path where sequence = curr_p and routeID = (select routeID from cruise where cruiseID = ip_cruiseID);
        select arrival into departure_p from leg where legID = curr_leg;
        select locationID into d_loc from ship_port where portID = departure_p;
    end if;
    
    if ship_ID not in (select locationID from person_occupies where personID = ip_personID) then
        leave sp_main;
    end if;

    -- delete ship location
    delete from person_occupies where personID = ip_personID and locationID = ship_ID;
    
    -- if person not already added then added
    if d_loc not in  (select  locationID from person_occupies where personID = ip_personID) then
        insert into person_occupies (personID, locationID) values (ip_personID, d_loc);
    end if ;
 
end //
delimiter ;


-- [10] assign_crew()
-- -----------------------------------------------------------------------------
/* This stored procedure assigns a crew member as part of the cruise crew for a given
cruise.  The crew member being assigned must have a license for that type of ship,
and must be at the same location as the cruise's first port. Also, the cruise must not 
already be in progress. Also, a crew member can only support one cruise (i.e. one ship) at a time. */
-- -----------------------------------------------------------------------------
drop procedure if exists assign_crew;
delimiter //
create procedure assign_crew (in ip_cruiseID varchar(50), ip_personID varchar(50))
sp_main: 
 begin
	declare type_ship varchar(100);
    declare route_type varchar(50);
	declare first_port char(3);
    declare first_leg varchar(50);
    declare crew_location varchar(50);

	-- check if cruise is valid and person ID is crew not passenger
	if ip_personID in (select personID from passenger) then leave sp_main;
	end if;
	if ip_personID not in (select personID from crew where personID = ip_personID) then leave sp_main;
	end if;
    if ip_cruiseID not in (select cruiseID from cruise) then leave sp_main;
	end if;
    
    -- check if progress of cruise is 0
	if (select progress from cruise where cruiseID = ip_cruiseID) <> 0 then leave sp_main;
	end if;

	-- check if the crew has not been already assigned a cruise
	if (select assigned_to from crew where personID = ip_personID) is not null then leave sp_main;
	end if;
	
    -- find out ship type of the cruise and license type of the crew
    select ship_type into type_ship
    from cruise  join ship on support_cruiseline = cruiselineID and support_ship_name = ship_name 
    where cruiseID = ip_cruiseID;
    
    -- if ship type and license type dont match then dont assign
    if type_ship not in (select license from licenses where personID = ip_personID) then leave sp_main;
    end if;
    
    -- finding out the first port of the cruise 
    select routeID into route_type from cruise where cruiseID = ip_cruiseID;
	
    select legID into first_leg
    from route_path 
    where routeID = route_type
    order by sequence 
    limit 1; 

	select departure into first_port
    from leg 
    where legID = first_leg;
    
	select locationID into crew_location
    from person_occupies
    where personID = ip_personID and locationID like '%port%'
    limit 1;
    
	if crew_location <> (select locationID from ship_port where portID = first_port) then leave sp_main;
    end if;
    
    -- every check above was succesful then add
    update crew set assigned_to = ip_cruiseID where personID = ip_personID;
    
end //
delimiter ;

-- [11] recycle_crew()
-- -----------------------------------------------------------------------------
/* This stored procedure releases the crew assignments for a given cruise. The
cruise must have ended, and all passengers must have disembarked. */
-- -----------------------------------------------------------------------------
drop procedure if exists recycle_crew;
delimiter //
create procedure recycle_crew (in ip_cruiseID varchar(50))
sp_main: begin

	declare max_sequence int;
    declare ship_location varchar(50);
    
    if (select ship_status from cruise where cruiseID = ip_cruiseID) = 'sailing' then leave sp_main;
    end if;
    
	select max(sequence) into max_sequence
	from cruise c join route_path r on c.routeID = r.routeID 
	where cruiseID = ip_cruiseID;

	if (select progress from cruise where cruiseID = ip_cruiseID) <> max_sequence then leave sp_main;
	end if;
    
    select locationID into ship_location
	from cruise c join ship s on support_cruiseline = cruiselineID and support_ship_name = ship_name
	where cruiseID = ip_cruiseID;

	if (select count(*) from passenger p join person_occupies po on p.personID = po.personID where locationID = ship_location) > 0 then leave sp_main;
	end if;
    
	update crew
    set assigned_to = null
    where assigned_to = ip_cruiseID;
end //
delimiter ;

-- [12] retire_cruise()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a cruise that has ended from the system.  The
cruise must be docked, and either be at the start its route, or at the
end of its route.  And the cruise must be empty - no crew or passengers. */
-- -----------------------------------------------------------------------------
drop procedure if exists retire_cruise;
delimiter //
create procedure retire_cruise (in ip_cruiseID varchar(50))
sp_main:
begin

declare max_sequence int;
declare ship_location varchar(50);

if (select ship_status from cruise where cruiseID = ip_cruiseID) = 'sailing' then leave sp_main;
end if; 

select max(sequence) into max_sequence
from cruise c join route_path r on c.routeID = r.routeID 
where cruiseID = ip_cruiseID;

if (select progress from cruise where cruiseID = ip_cruiseID) <> 0 and (select progress from cruise where cruiseID = ip_cruiseID) <> max_sequence then leave sp_main;
end if;

select locationID into ship_location
from cruise c join ship s on support_cruiseline = cruiselineID and support_ship_name = ship_name
where cruiseID = ip_cruiseID;

if (select count(*) from person_occupies where locationID = ship_location) > 0 then leave sp_main;
end if;

delete from cruise where cruiseID = ip_cruiseID;

end //
delimiter ;

-- [13] cruises_at_sea()
-- -----------------------------------------------------------------------------
/* This view describes where cruises that are currently sailing are located. */
-- -----------------------------------------------------------------------------
create or replace view cruises_at_sea (departing_from, arriving_at, num_cruises,
	cruise_list, earliest_arrival, latest_arrival, ship_list) as
select departure, arrival, count(*), group_concat(cruiseID), min(next_time), max(next_time), group_concat(locationID)
from cruise c join ship on support_ship_name = ship_name and support_cruiseline = cruiselineID
join route_path r on c.routeID = r.routeID
join leg l on r.legID = l.legID
where ship_status = 'sailing' and progress = sequence
group by departure, arrival;

-- [14] cruises_docked()
-- -----------------------------------------------------------------------------
/* This view describes where cruises that are currently docked are located. */
-- -----------------------------------------------------------------------------
create or replace view cruises_docked (departing_from, num_cruises,
	cruise_list, earliest_departure, latest_departure, ship_list) as 
select departure, count(*), group_concat(cruiseID), min(next_time) as earliest_arrival, max(next_time) as latest_arrival,  group_concat(locationID)
from cruise c join ship s on support_cruiseline = s.cruiselineID and support_ship_name = ship_name
join route_path r on c.routeID = r.routeID
join leg l on r.legID = l.legID
where ship_status = 'docked' and progress = sequence - 1 and  progress <> (

select max(sequence)
from route_path p
where r.routeID = p.routeID)
group by departure
order by departure;



-- [15] people_at_sea()
-- -----------------------------------------------------------------------------
/* This view describes where people who are currently at sea are located. */
-- -----------------------------------------------------------------------------
create or replace view people_at_sea (departing_from, arriving_at, num_ships,
	ship_list, cruise_list, earliest_arrival, latest_arrival, num_crew,
	num_passengers, num_people, person_list) as
select 
    l.departure, l.arrival, count(distinct s.locationID), group_concat(distinct s.locationID), group_concat(distinct c.cruiseID) ,
    min(c.next_time), max(c.next_time), count(distinct cr.personID) , count(distinct po.personID) - count(distinct cr.personID) ,
    count(distinct po.personID),
   group_concat(distinct po.personID order by length(po.personID), po.personID asc) 
from cruise c join ship s on c.support_ship_name = s.ship_name and c.support_cruiseline = s.cruiselineID
join route_path rp on c.routeID = rp.routeID
join  leg l on rp.legID = l.legID
join person_occupies po on s.locationID = po.locationID
left join crew cr on po.personID = cr.personID
where c.ship_status = 'sailing' and sequence = progress 
group by l.departure, l.arrival;


-- [16] people_docked()
-- -----------------------------------------------------------------------------
/* This view describes where people who are currently docked are located. */
-- -----------------------------------------------------------------------------
create or replace view people_docked (departing_from, ship_port, port_name,
	city, state, country, num_crew, num_passengers, num_people, person_list) as
select 
    departure, sp.locationID, port_name, city, state, country,
    count(distinct cr.personID) as num_crew,
    count(distinct po.personID) - count(distinct cr.personID) as num_passengers,
    count(distinct po.personID) as num_people,
    group_concat(distinct po.personID order by length(po.personID), po.personID asc) as person_list
from cruise c 
join ship s on support_cruiseline = s.cruiselineID and support_ship_name = ship_name
join route_path r on c.routeID = r.routeID
join leg l on r.legID = l.legID
join ship_port sp on l.departure = sp.portID
left join person_occupies po on sp.locationID = po.locationID
left join crew cr on po.personID = cr.personID
where ship_status = 'docked' 
    and progress = sequence - 1 
    and progress <> (
        select max(sequence)
        from route_path p
        where r.routeID = p.routeID
    )
    and (
        cr.personID is null
        OR cr.assigned_to = c.cruiseID
    )
group by 
    departure;
    

-- [17] route_summary()
-- -----------------------------------------------------------------------------
/* This view describes how the routes are being utilized by different cruises. */
-- -----------------------------------------------------------------------------
create or replace view route_summary (route, num_legs, leg_sequence, route_length,
	num_cruises, cruise_list, port_sequence) as
select r.routeID, count(distinct r.legID ), group_concat(distinct r.legID order by sequence), sum(distinct distance), 
count(distinct cruiseID), group_concat(distinct cruiseID), group_concat(distinct concat(departure, '->', arrival) order by sequence)
    from route_path r left join leg l on r.legID = l.legID
    join cruise c on r.routeID = c.routeID
    group by routeID;


-- [18] alternative_ports()
-- -----------------------------------------------------------------------------
/* This view displays ports that share the same country. */
-- -----------------------------------------------------------------------------
create or replace view alternative_ports (country, num_ports,
	port_code_list, port_name_list) as
select country, count(portID) as 'num_ports', group_concat(portID order by portID asc) as 'port_code_list', group_concat(port_name order by portID asc) as 'port_name_list'
from ship_port
group by country
order by country;