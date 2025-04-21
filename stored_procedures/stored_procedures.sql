set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

use business_supply;
-- -----------------------------------------------------------------------------
-- stored procedures and views
-- -----------------------------------------------------------------------------
/* Standard Procedure: If one or more of the necessary conditions for a procedure to
be executed is false, then simply have the procedure halt execution without changing
the database state. Do NOT display any error messages, etc. */

-- [1] add_owner()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new owner.  A new owner must have a unique
username. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_owner;
delimiter //
create procedure add_owner (in ip_username varchar(40), in ip_first_name varchar(100),
	in ip_last_name varchar(100), in ip_address varchar(500), in ip_birthdate date)
sp_main: begin
    -- ensure new owner has a unique username
	if exists (select 1 from business_owners where username = ip_username) then
        leave sp_main;
    end if;
	insert into users (username, first_name, last_name, address, birthdate) values
    (ip_username , ip_first_name, ip_last_name , ip_address, ip_birthdate);
    -- Insert the new owner
    insert into business_owners (username)
    values (ip_username);
end //
delimiter ;

-- [2] add_employee()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new employee without any designated driver or
worker roles.  A new employee must have a unique username and a unique tax identifier. */
-- -----------------------------------------------------------------------------

drop procedure if exists add_employee;
delimiter //
create procedure add_employee (in ip_username varchar(40), in ip_first_name varchar(100),
	in ip_last_name varchar(100), in ip_address varchar(500), in ip_birthdate date,
    in ip_taxID varchar(40), in ip_hired date, in ip_employee_experience integer,
    in ip_salary integer)
sp_main: begin

	-- check cases
	if exists (select 1 from employees where username = ip_username) then
        leave sp_main;
    end if;
    
    if exists (select 1 from employees where taxID = ip_taxID) then
		leave sp_main;
	end if;
    
    -- Insert new employee into users
	insert into users (username, first_name, last_name, address, birthdate) values
    (ip_username , ip_first_name, ip_last_name , ip_address, ip_birthdate);
    
    -- Insert the new employee into employees
    insert into employees (username, taxID, hired, experience, salary)
    values (ip_username, ip_taxID, ip_hired, ip_employee_experience, ip_salary);
    
end //
delimiter ;

-- [3] add_driver_role()
-- -----------------------------------------------------------------------------
/* This stored procedure adds the driver role to an existing employee.  The
employee/new driver must have a unique license identifier. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_driver_role;

delimiter //
create procedure add_driver_role (in ip_username varchar(40), in ip_licenseID varchar(40),
	in ip_license_type varchar(40), in ip_driver_experience integer)
sp_main: begin
    -- ensure new driver has a unique license identifier
    if exists (select 1 from drivers where licenseID = ip_licenseID) then
		leave sp_main;
	end if;
    
    -- ensure employee exists and is not a worker
    
    IF EXISTS (SELECT 1 FROM workers WHERE username = ip_username) THEN
		LEAVE sp_main; 
    END IF;
    if exists (select 1 from employees where username = ip_username) then
    insert into drivers (username, licenseID, license_type, successful_trips)
    values (ip_username, ip_licenseID, ip_license_type, ip_driver_experience);

	end if;
    
end //
delimiter ;

-- [4] add_worker_role()
-- -----------------------------------------------------------------------------
/* This stored procedure adds the worker role to an existing employee. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_worker_role;
delimiter //
create procedure add_worker_role (in ip_username varchar(40))
sp_main: begin
    -- ensure worker is not a driver
    if exists (select 1 from drivers where username = ip_username) then
        leave sp_main;
    end if;

    -- ensure they are an employee
    if not exists (select 1 from employees where username = ip_username) then
        leave sp_main;
    end if;

    -- ensure they are not already a worker
    if exists (select 1 from workers where username = ip_username) then
        leave sp_main;
    end if;
    
	insert into workers values (ip_username);

end //
delimiter ;

-- [5] add_product()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new product.  A new product must have a
unique barcode. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_product;
delimiter //
create procedure add_product (in ip_barcode varchar(40), in ip_name varchar(100),
	in ip_weight integer)
sp_main: begin
	-- ensure new product doesn't already exist
    if exists (select 1 from products where barcode = ip_barcode) then
		leave sp_main;
	end if;
    insert into products (barcode, iname, weight)
    values (ip_barcode, ip_name, ip_weight);
end //
delimiter ;

-- [6] add_van()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new van.  A new van must be assigned 
to a valid delivery service and must have a unique tag.  Also, it must be driven
by a valid driver initially (i.e., driver works for the same service). And the van's starting
location will always be the delivery service's home base by default. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_van;
delimiter //
create procedure add_van (in ip_id varchar(40), in ip_tag integer, in ip_fuel integer,
	in ip_capacity integer, in ip_sales integer, in ip_driven_by varchar(40))
sp_main: begin
    DECLARE ip_location varchar(40);

	-- ensure new van doesn't already exist
    if exists (select 1 from vans where id = ip_id and tag = ip_tag) then
		leave sp_main;
	end if;
    
    -- ensure that the delivery service exists
    if not exists (select 1 from delivery_services where id = ip_id) then
		leave sp_main;
	end if;
    
    IF ((SELECT COUNT(*) FROM vans WHERE located_at = ip_location) >= 
		(SELECT space FROM locations WHERE label = ip_location)) THEN
		LEAVE sp_main;
	END IF;
        
	SELECT home_base INTO ip_location FROM delivery_services where id = ip_id;
    
    -- ensure that a valid driver will control the van
    
    if exists (select 1 from vans v
           where v.driven_by = ip_driven_by and v.id != ip_id) then
			leave sp_main;
	end if;
    if exists (select 1 from drivers d where d.username = ip_driven_by) then
		-- adding van
        insert into vans (id, tag, fuel, capacity, sales, driven_by, located_at)
        values (ip_id, ip_tag, ip_fuel, ip_capacity, ip_sales, ip_driven_by, ip_location);
	end if;
end //
delimiter ;

-- [7] add_business()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new business.  A new business must have a
unique (long) name and must exist at a valid location, and have a valid rating.
And a resturant is initially "independent" (i.e., no owner), but will be assigned
an owner later for funding purposes. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_business;
delimiter //
create procedure add_business (in ip_long_name varchar(40), in ip_rating integer,
	in ip_spent integer, in ip_location varchar(40))
sp_main: begin
	-- ensure new business doesn't already exist
	if exists (select 1 from businesses where long_name = ip_long_name) then
		leave sp_main;
	end if;
    -- ensure that the location is valid
    if not exists (select 1 from locations where label = ip_location) then
		leave sp_main;
	end if;
    -- ensure that the rating is valid (i.e., between 1 and 5 inclusively)
    if (ip_rating > 5 or ip_rating < 1) then
		leave sp_main;
	end if;
    -- adding
	insert into businesses (long_name, rating, spent, location)
    values (ip_long_name, ip_rating, ip_spent, ip_location);
end //
delimiter ;

-- [8] add_service()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new delivery service.  A new service must have
a unique identifier, along with a valid home base and manager. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_service;
delimiter //
create procedure add_service (in ip_id varchar(40), in ip_long_name varchar(100),
	in ip_home_base varchar(40), in ip_manager varchar(40))
sp_main: begin
	-- ensure new delivery service doesn't already exist
    if exists (select 1 from delivery_services where id = ip_id) then
		leave sp_main;
	end if;
    -- ensure that the home base location is valid
    if not exists (select 1 from locations where label = ip_home_base) then
		leave sp_main;
	end if;
    -- ensure that the manager is valid
    if not exists (select 1 from workers where username = ip_manager) then
		leave sp_main;
	end if;
    
    if exists (select 1 from delivery_services where manager = ip_manager) then
		leave sp_main;
	end if;
    
    -- adding
	insert into delivery_services (id, long_name, home_base, manager)
    values (ip_id, ip_long_name, ip_home_base, ip_manager);
    
end //
delimiter ;

-- [9] add_location()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new location that becomes a new valid van
destination.  A new location must have a unique combination of coordinates. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_location;
delimiter //
create procedure add_location (in ip_label varchar(40), in ip_x_coord integer,
	in ip_y_coord integer, in ip_space integer)
sp_main: begin
	-- ensure new location doesn't already exist
    if exists (select 1 from locations where label = ip_label) then
		leave sp_main;
	end if;
    
    -- ensure that the coordinate combination is distinct
    if exists (select 1 from locations where (x_coord, y_coord) = (ip_x_coord, ip_y_coord)) then
		leave sp_main;
	end if;
    
    if ip_space < 0 then leave sp_main; end if;
    
    insert into locations (label, x_coord, y_coord, space)
    values (ip_label, ip_x_coord, ip_y_coord, ip_space);
    
end //
delimiter ;

-- [10] start_funding()
-- -----------------------------------------------------------------------------
/* This stored procedure opens a channel for a business owner to provide funds
to a business. The owner and business must be valid. */
-- -----------------------------------------------------------------------------
drop procedure if exists start_funding;
delimiter //
create procedure start_funding (in ip_owner varchar(40), in ip_amount integer, in ip_long_name varchar(40), in ip_fund_date date)
sp_main: begin
	-- ensure the owner and business are valid 
    if not exists (select 1 from businesses where long_name = ip_long_name) then
		leave sp_main;
	end if;
    
    if not exists (select 1 from business_owners where username = ip_owner) then
		leave sp_main;
	end if;
    
    insert into fund (username, invested, invested_date, business)
    values (ip_owner, ip_amount, ip_fund_date, ip_long_name);
    
end //
delimiter ;

-- [11] hire_employee()
-- -----------------------------------------------------------------------------
/* This stored procedure hires a worker to work for a delivery service.
If a worker is actively serving as manager for a different service, then they are
not eligible to be hired.  Otherwise, the hiring is permitted. */
-- -----------------------------------------------------------------------------
drop procedure if exists hire_employee;
delimiter //
create procedure hire_employee (in ip_username varchar(40), in ip_id varchar(40))
sp_main: begin

    if exists (select 1 from work_for where username = ip_username and id = ip_id) then
		leave sp_main;
	end if;
    
    if not exists (select 1 from employees where username = ip_username) then
		leave sp_main;
	end if;
    
    if not exists (select 1 from delivery_services where id = ip_id) then
		leave sp_main;
	end if;
    
    if exists (select 1 from delivery_services where manager = ip_username and id != ip_id) then
		leave sp_main;
	end if;
    
    insert into work_for
    values (ip_username, ip_id);

end //
delimiter ;

-- [12] fire_employee()
-- -----------------------------------------------------------------------------
/* This stored procedure fires a worker who is currently working for a delivery
service.  The only restriction is that the employee must not be serving as a manager 
for the service. Otherwise, the firing is permitted. */
-- -----------------------------------------------------------------------------
drop procedure if exists fire_employee;
delimiter //
create procedure fire_employee (in ip_username varchar(40), in ip_id varchar(40))
sp_main: begin
	-- ensure that the employee is currently working for the service
    if not exists (select 1 from work_for where (username, id) = (ip_username, ip_id)) then
		leave sp_main;
	end if;
    
    -- ensure that the employee isn't an active manager
    if exists (select 1 from delivery_services where manager = ip_username) then
		leave sp_main;
	end if;
	
    -- delete from workers where
    -- username = ip_username;
    
    delete from work_for
    where username = ip_username and id = ip_id;
    
end //
delimiter ;

-- [13] manage_service()
-- -----------------------------------------------------------------------------
/* This stored procedure appoints a worker who is currently hired by a delivery
service as the new manager for that service.  The only restrictions is that
the worker must not be working for any other delivery service. Otherwise, the appointment 
to manager is permitted.  The current manager is simply replaced. */
-- -----------------------------------------------------------------------------
drop procedure if exists manage_service;
delimiter //
create procedure manage_service (in ip_username varchar(40), in ip_id varchar(40))
sp_main: begin
    -- ensure that the employee isn't working for any other services
    if exists (select 1 from work_for where username = ip_username and id != ip_id)
    then 
		leave sp_main;
    end if;
    
	-- ensure that the employee is currently working for the service
    if exists (select 1 from work_for where username = ip_username and id = ip_id)
    then
		UPDATE delivery_services SET manager = ip_username WHERE id = ip_id;
	end if;
end //
delimiter ;

-- [14] takeover_van()
-- -----------------------------------------------------------------------------
/* This stored procedure allows a valid driver to take control of a van owned by 
the same delivery service. The current controller of the van is simply relieved 
of those duties. */
-- -----------------------------------------------------------------------------
drop procedure if exists takeover_van;
delimiter //
create procedure takeover_van (in ip_username varchar(40), in ip_id varchar(40),
	in ip_tag integer)
sp_main: begin
	-- ensure that the driver is not driving for another service
    if exists (select 1 from vans where driven_by = ip_username and id != ip_id)
    then 
		leave sp_main;
    end if;
	-- ensure that the selected van is owned by the same service
    if exists (select 1 from vans where id = ip_id and tag = ip_tag)
    then
    -- ensure that the employee is a valid driver
		if exists (select 1 from drivers where username = ip_username) 
        then
		UPDATE vans SET driven_by = ip_username WHERE id = ip_id and tag = ip_tag;
		else
			leave sp_main;
		end if;
    else
		leave sp_main;
	end if;
end //
delimiter ;


-- [15] load_van()
-- -----------------------------------------------------------------------------
/* This stored procedure allows us to add some quantity of fixed-size packages of
a specific product to a van's payload so that we can sell them for some
specific price to other businesses.  The van can only be loaded if it's located
at its delivery service's home base, and the van must have enough capacity to
carry the increased number of items.

The change/delta quantity value must be positive, and must be added to the quantity
of the product already loaded onto the van as applicable.  And if the product
already exists on the van, then the existing price must not be changed. */
-- -----------------------------------------------------------------------------
drop procedure if exists load_van;
delimiter //
create procedure load_van (in ip_id varchar(40), in ip_tag integer, in ip_barcode varchar(40),
	in ip_more_packages integer, in ip_price integer)
sp_main: begin
	declare volume integer;
    select sum(quantity) into volume from contain where id = ip_id and tag = ip_tag group by id and tag;
	if not exists (select 1 from vans where id = ip_id and tag = ip_tag) then 	-- ensure that the van being loaded is owned by the service
		leave sp_main;
	end if;
	if not exists (select 1 from products where barcode = ip_barcode) then 	-- ensure that the product is valid
		leave sp_main;
	end if;
	if (select home_base from delivery_services where id = ip_id ) != (select located_at from vans where id = ip_id and tag = ip_tag) then     
    -- ensure that the van is located at the service home base
    	leave sp_main;
	end if;
    
	if ip_more_packages <= 0 then	
-- ensure that the quantity of new packages is greater than zero
		leave sp_main;
	end if;
	
    if (ip_more_packages) > (select capacity from vans where id = ip_id and tag = ip_tag) then
					-- ensure that the van has sufficient capacity to carry the new packages
		leave sp_main;
	end if;
    
	if exists (select 1 from contain where id = ip_id and tag = ip_tag and barcode = ip_barcode) then
		UPDATE contain SET quantity = quantity + ip_more_packages WHERE id = ip_id and tag = ip_tag and barcode = ip_barcode;
	else
		INSERT INTO contain(id, tag, barcode, quantity, price) VALUES (ip_id, ip_tag, ip_barcode, ip_more_packages, ip_price);
		    -- add more of the product to the van

	end if;

end //
delimiter ;



-- [16] refuel_van()
-- -----------------------------------------------------------------------------
/* This stored procedure allows us to add more fuel to a van. The van can only
be refueled if it's located at the delivery service's home base. */
-- -----------------------------------------------------------------------------
drop procedure if exists refuel_van;
delimiter //
create procedure refuel_van (in ip_id varchar(40), in ip_tag integer, in ip_more_fuel integer)
sp_main: begin
	-- ensure that the van being switched is valid and owned by the service
    if exists (select 1 from vans where id = ip_id and tag = ip_tag)
    then
		-- ensure that the van is located at the service home base
        if ((select located_at from vans where id = ip_id and tag = ip_tag) = 
        (select home_base from delivery_services where id = ip_id) ) then
			UPDATE vans SET fuel = fuel + ip_more_fuel WHERE id = ip_id and tag = ip_tag;
		else
			leave sp_main;
		end if;
	end if;
end //
delimiter ;

-- [17] drive_van()
-- -----------------------------------------------------------------------------
/* This stored procedure allows us to move a single van to a new
location (i.e., destination). This will also update the respective driver's 
experience and van's fuel. The main constraints on the van(s) being able to 
move to a new  location are fuel and space.  A van can only move to a destination
if it has enough fuel to reach the destination and still move from the destination
back to home base.  And a van can only move to a destination if there's enough
space remaining at the destination. */
-- -----------------------------------------------------------------------------
drop function if exists fuel_required;
delimiter //
create function fuel_required (ip_departure varchar(40), ip_arrival varchar(40))
	returns integer reads sql data
begin
	if (ip_departure = ip_arrival) then return 0;
    else return (select 1 + truncate(sqrt(power(arrival.x_coord - departure.x_coord, 2) + power(arrival.y_coord - departure.y_coord, 2)), 0) as fuel
		from (select x_coord, y_coord from locations where label = ip_departure) as departure,
        (select x_coord, y_coord from locations where label = ip_arrival) as arrival);
	end if;
end //
delimiter ;


drop procedure if exists drive_van;
delimiter //
create procedure drive_van (in ip_id varchar(40), in ip_tag integer, in ip_destination varchar(40))
sp_main: begin
    -- ensure that the van exists
    if not exists (select 1 from vans where id = ip_id and tag = ip_tag) then
        leave sp_main;
    end if;
    
    -- ensure that the destination is a valid location
    if not exists (select 1 from locations where label = ip_destination) then
        leave sp_main;
    end if;
    
    -- ensure that the van isn't already at the destination
    if exists (select 1 from vans where id = ip_id and tag = ip_tag and located_at = ip_destination) then
        leave sp_main;
    end if;
    
    -- ensure the van is being driven by someone
    if exists (select 1 from vans where id = ip_id and tag = ip_tag and driven_by is null) then
        leave sp_main;
    end if;
    
    -- ensure that the van has enough fuel to reach the destination and back to home base
    if (
        (select fuel from vans where id = ip_id and tag = ip_tag) <
        (
            fuel_required(
                (select located_at from vans where id = ip_id and tag = ip_tag),
                ip_destination
            ) +
            fuel_required(
                ip_destination,
                (select home_base from delivery_services where id = ip_id)
            )
        )
    ) then
        leave sp_main;
    end if;
    
    -- ensure that the destination has enough space remaining
    if (
        (select space from locations where label = ip_destination) is not null and
        (
            (select count(*) from vans where located_at = ip_destination) >=
            (select space from locations where label = ip_destination)
        )
    ) then
        leave sp_main;
    end if;
    
    -- update the van's location and fuel
    update vans
    set fuel = fuel - fuel_required(
                    (select located_at where id = ip_id and tag = ip_tag),
                    ip_destination
                ),
        located_at = ip_destination
    where id = ip_id and tag = ip_tag;
    
    -- update the driver's successful trips
    update drivers
    set successful_trips = successful_trips + 1
    where username = (select driven_by from vans where id = ip_id and tag = ip_tag);
    
end //
delimiter ;


-- [18] purchase_product()
-- -----------------------------------------------------------------------------
/* This stored procedure allows a business to purchase products from a van
at its current location.  The van must have the desired quantity of the product
being purchased.  And the business must have enough money to purchase the
products.  If the transaction is otherwise valid, then the van and business
information must be changed appropriately.  Finally, we need to ensure that all
quantities in the payload table (post transaction) are greater than zero. */
-- -----------------------------------------------------------------------------
drop procedure if exists purchase_product;
delimiter //
create procedure purchase_product (in ip_long_name varchar(40), in ip_id varchar(40),
	in ip_tag integer, in ip_barcode varchar(40), in ip_quantity integer)
sp_main: begin
	declare number_items int;
    declare item_price int;
    
	-- ensure that the business is valid
    if not exists (select 1 from businesses where long_name = ip_long_name ) then
		leave sp_main;
	end if;

    
	-- ensure that the van is valid and exists at the business's location
    if not exists (select 1 from vans where id = ip_id and tag = ip_tag) then
		leave sp_main;
	end if;
	
    -- ensure that the van is valid and exists at the business's location
	if ip_id not in (select id from vans where ip_id = id and ip_tag = tag) then leave sp_main; end if;
    
    if (select located_at from vans where id = ip_id and tag = ip_tag) 
    != (select location from businesses where long_name = ip_long_name) then
		leave sp_main;
	end if;
    
    select quantity, price into number_items, item_price 
	from contain
	where id = ip_id and tag = ip_tag and barcode = ip_barcode;
    
	select coalesce(number_items, 0) into number_items;
	select coalesce(item_price, 0) into item_price;

    -- ensure that the van has enough of the requested product
    if number_items < ip_quantity then
		leave sp_main;
	end if;
	
    
	UPDATE contain SET quantity = quantity - ip_quantity WHERE id = ip_id and tag = ip_tag and barcode = ip_barcode;
	-- update the van's payload
    
    UPDATE vans SET sales = sales + ( item_price * ip_quantity)
    WHERE id = ip_id and tag = ip_tag;
	
    -- update the monies spent and gained for the van and business
    UPDATE businesses set spent = 
    spent + ( item_price * ip_quantity) 
    where long_name = ip_long_name;
    
    DELETE FROM contain WHERE quantity = 0;
    -- ensure all quantities in the contain table are greater than zero
	
end //
delimiter ;

-- [19] remove_product()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a product from the system.  The removal can
occur if, and only if, the product is not being carried by any vans. */
-- -----------------------------------------------------------------------------
drop procedure if exists remove_product;
delimiter //
create procedure remove_product (in ip_barcode varchar(40))
sp_main: begin
	-- ensure that the product exists
    if exists (select 1 from products where barcode = ip_barcode)
    then
		    -- ensure that the product is not being carried by any vans
		if exists (select 1 from contain where barcode = ip_barcode) then
			leave sp_main;
		else
			DELETE FROM products WHERE barcode = ip_barcode;
		end if;
    end if;
end //
delimiter ;

-- [20] remove_van()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a van from the system.  The removal can
occur if, and only if, the van is not carrying any products.*/
-- -----------------------------------------------------------------------------
drop procedure if exists remove_van;
delimiter //
create procedure remove_van (in ip_id varchar(40), in ip_tag integer)
sp_main: begin
	-- ensure that the van exists
    if exists (select 1 from vans where id = ip_id and tag = ip_tag) then
		    -- ensure that the van is not carrying any products
		if exists (select 1 from contain where id = ip_id and tag = ip_tag) then
			leave sp_main;
		else
			DELETE FROM vans where id = ip_id and tag = ip_tag;
        end if;
    end if;
end //
delimiter ;

-- [21] remove_driver_role()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a driver from the system.  The removal can
occur if, and only if, the driver is not controlling any vans.  
The driver's information must be completely removed from the system. */
-- -----------------------------------------------------------------------------
drop procedure if exists remove_driver_role;
delimiter //
create procedure remove_driver_role (in ip_username varchar(40))
sp_main: begin
	-- ensure that the driver exists
    if exists (select 1 from drivers where username = ip_username) then
		if exists (select 1 from vans where driven_by = ip_username) then
			leave sp_main;
		else
			DELETE FROM users where username = ip_username;
		end if;
    end if;
    -- ensure that the driver is not controlling any vans
    -- remove all remaining information
end //
delimiter ;


-- [22] display_owner_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of an owner.
For each owner, it includes the owner's information, along with the number of
businesses for which they provide funds and the number of different places where
those businesses are located.  It also includes the highest and lowest ratings
for each of those businesses, as well as the total amount of debt based on the
monies spent purchasing products by all of those businesses. And if an owner
doesn't fund any businesses then display zeros for the highs, lows and debt. */
-- -----------------------------------------------------------------------------
create or replace view display_owner_view as
select bo.username, u.first_name, u.last_name, u.address, 
count(long_name) as num_businesses, 
count(DISTINCT location) as num_places, 
COALESCE(max(rating), 0) as highest_rating,
COALESCE(min(rating), 0) as lowest_rating,
COALESCE(sum(spent), 0) as total_spent
from business_owners bo
join users u
on bo.username = u.username
left join fund f 
on bo.username = f.username
left join businesses b
on f.business = b.long_name
group by bo.username, u.first_name, u.last_name, u.address, u.birthdate;

-- [23] display_employee_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of an employee.
For each employee, it includes the username, tax identifier, salary, hiring date and
experience level, along with license identifier and driving experience (if applicable,
'n/a' if not), and a 'yes' or 'no' depending on the manager status of the employee. */
-- -----------------------------------------------------------------------------
create or replace view display_employee_view as
select e.username as 'username', taxID, salary, hired, experience as employee_experience, 
COALESCE(d.licenseID, 'n/a') as licenseID, 
COALESCE(d.successful_trips, 'n/a') as driving_experience,
IF(ds.manager is not null, 'yes', 'no') as manager_status
from employees e left join drivers d on e.username = d.username
left join delivery_services ds on e.username = ds.manager;


-- [24] display_driver_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of a driver.
For each driver, it includes the username, licenseID and driving experience, along
with the number of vans that they are controlling. */
-- -----------------------------------------------------------------------------
create or replace view display_driver_view as
select d.username, d.licenseID, d.successful_trips, count(v.tag) as num_vans from drivers d
left join vans v on d.username = v.driven_by group by d.username, d.licenseID, d.successful_trips;

-- [25] display_location_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of a location.
For each location, it includes the label, x- and y- coordinates, along with the
name of the business or service at that location, the number of vans as well as 
the identifiers of the vans at the location (sorted by the tag), and both the 
total and remaining capacity at the location. */
-- -----------------------------------------------------------------------------
create or replace view display_location_view as
SELECT 
    l.label AS label,
    GROUP_CONCAT(DISTINCT COALESCE(b.long_name, d.long_name)) AS long_name,
    l.x_coord AS x_coord,
    l.y_coord AS y_coord,
    l.space AS space,
    COUNT(v.id) AS num_vans,
    GROUP_CONCAT(v.id, v.tag) AS van_ids,
    COALESCE(l.space - COUNT(v.id), 0) AS remaining_capacity
FROM 
    locations l
left JOIN 
    businesses b ON l.label = b.location
LEFT JOIN
	delivery_services d on l.label = d.home_base
inner JOIN 
    vans v ON l.label = v.located_at
GROUP BY 
    l.label, l.x_coord, l.y_coord, l.space
HAVING 
    COUNT(v.id) > 0;


-- [26] display_product_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of the products.
For each product that is being carried by at least one van, it includes a list of
the various locations where it can be purchased, along with the total number of packages
that can be purchased and the lowest and highest prices at which the product is being
sold at that location. */
-- -----------------------------------------------------------------------------
create or replace view display_product_view as

SELECT 
    p.iname AS product_name,
    l.label AS location_label,
    SUM(c.quantity) AS total_packages,
    MIN(c.price) AS lowest_price,
    MAX(c.price) AS highest_price
FROM 
    products p
JOIN 
    contain c ON p.barcode = c.barcode
JOIN 
    vans v ON c.id = v.id AND c.tag = v.tag
JOIN 
    locations l ON v.located_at = l.label
GROUP BY 
    p.barcode, p.iname, l.label;

-- [27] display_service_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of a delivery
service.  It includes the identifier, name, home base location and manager for the
service, along with the total sales from the vans.  It must also include the number
of unique products along with the total cost and weight of those products being
carried by the vans. */
-- -----------------------------------------------------------------------------
create or replace view display_service_view as
SELECT 
    ds.id AS service_id,
    ds.long_name AS long_name,
    ds.home_base AS home_base,
    ds.manager AS manager,
    (SELECT SUM(v2.sales)
     FROM vans v2
     WHERE v2.id = ds.id) AS revenue,
    COUNT(DISTINCT c.barcode) AS products_carried,
    SUM(c.price * c.quantity) AS total_cost,
    SUM(p.weight * c.quantity) AS total_weight
FROM 
    delivery_services ds
left JOIN 
    vans v ON ds.id = v.id
left JOIN 
    contain c ON v.id = c.id AND v.tag = c.tag
left JOIN 
    products p ON c.barcode = p.barcode
GROUP BY 
    ds.id, ds.long_name, ds.home_base, ds.manager;
    
    

