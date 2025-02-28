/* PLEASE READ: Text descriptions of all tables at the bottom. */

drop database if exists store_ledger;
create database store_ledger;

use store_ledger;

create table product_category (
	product_category_id        			varchar(4)			not null	primary key,
    product_category_name      			varchar(50) 	    not null
);

create table supplier (
	supplier_id                			int				    not null	primary key		auto_increment,
    supplier_name              			varchar(50)		    not null    unique,
    supplier_contact_email              varchar(100)	    not null,
    supplier_min_price                  decimal(10, 2)	    not null,
    
    check (length(supplier_name) > 0),						-- Enforce the name is not length zero
    check (supplier_contact_email regexp ".+@.+"),			-- Enforce valid email
    check (supplier_min_price > 0)							-- Enforce the minimum price is not negative or zero
);

create table product (
	product_id							int					not null	primary key		auto_increment,
    product_name	            		varchar(50)		    not null,
    product_category_id		            varchar(4)			not null,
    product_supplier_id 	            int,                -- The supplier can be null if deleted
    product_price 			            decimal(10, 2)	    not null,
    product_stock 			            int 			    not null,
    
    check (length(product_name) > 0),						-- Enforce the product name is not blank
    check (product_price > 0),								-- Enforce the minimum price is not negative or zero
    check (product_stock >= 0)								-- Enforce the product stock nnever becomes negative
);

create table order_table (
	order_table_order_id				int 				not null 	primary key		auto_increment,
    order_table_customer_name			varchar(50)			not null,
    order_table_product_id				int 				not null,
    order_table_quantity				int 				not null,
    order_table_price					decimal(10, 2),     -- This will not get the not null tag, because I will set the value with a trigger
    
    check (length(order_table_customer_name) > 0),			-- Enforce the order_table_customer_name is not blank
    check (order_table_quantity > 0),						-- Enforce the order_table_quantity is not negative or zero
    check (order_table_price > 0)							-- Enforce the order_table_price is not negative or zero
);

delimiter //
create trigger before_insert_product
before insert on product
for each row
begin

    declare working_min_price decimal(10, 2);
    declare error_message varchar(500);

    select supplier_min_price 
    into working_min_price
    from supplier
    where supplier_id = NEW.product_supplier_id;

    set error_message = concat("Price ", NEW.product_price, " Is too low");

    if NEW.product_price < working_min_price then
        signal sqlstate '45000'
        set message_text = error_message;
    end if;

end //

delimiter //
create trigger before_insert_order_table
before insert on order_table
for each row
begin

    declare working_single_price decimal(10, 2);

    select product_price
    into working_single_price
    from product
    where product.product_id = NEW.order_table_product_id;

    set NEW.order_table_price = working_single_price * NEW.order_table_quantity;

end //

alter table order_table
add constraint order_table_product_id_fk
foreign key (order_table_product_id)    references 		product(product_id)
on delete cascade;

alter table product
add constraint product_supplier_id_fk
foreign key (product_supplier_id)	references 			supplier(supplier_id)
on delete set null;

alter table product
add constraint product_category_id_fk
foreign key (product_category_id)	references 			product_category(product_category_id)
on delete cascade;

insert into product_category (product_category_id, product_category_name) values 
	("ELEC", "Electronics"),
	("OFCS", "Office and Supplies"),
	("CARH", "Care and Hygiene"),
	("CARA", "Cars and Automotive"),

--  ("CARA", "Cars and Automotive"),
--  This line is invalid, when run I get
--  18:56:18	alter table order_table add constraint order_table_product_id_fk foreign key (order_table_product_id)    references   product(product_id) on delete cascade;  alter table product add constraint product_supplier_id_fk foreign key (product_supplier_id) references    supplier(supplier_id) on delete set null;  alter table product add constraint product_category_id_fk foreign key (product_category_id) references    product_category(product_category_id) on delete cascade;  insert into product_category (product_category_id, product_category_name) values   ("ELEC", "Electronics"),  ("OFCS", "Office and Supplies"),  ("CARH", "Care and Hygiene"),  ("CARA", "Cars and Automotive"),      ("CARA", "Cars and Automotive"),      ("FOOD", "Food and Groceries");  insert into supplier (supplier_name, supplier_contact_email, supplier_min_price) values   ("Dell",        "dell@gmail.com",       100.0),     ("Great Value", "great_val@gmail.com",  1.0),     ("Nintendo",    "nintendo@gmail.com",   300.0),     ("Amazon",      "amazon@gmail.com",     50.0),  --  ("Amazon",      "amazon1@gmail.com",     50.0), --  This line is invalid, when run I get --  Error Code: 1062 Duplicate entry 'Amazon' for key 'supplier.supplier_name'   --  ("Samsung",     "@gmail.com",           100.0), --  This line is invalid, when run I get --  Error Code: 3819 Check constraint 'supplier_chk_2' is violated.          ("Samsung",     "samsung@gmail.com",    100.0),     ("Ford",        "ford@gmail.com",       500.0);  insert into product      (product_name,              product_category_id,    product_supplier_id,    product_price,  product_stock) values     ("Dell All In One",         "ELEC",                 1,                      101.0,          123),     ("Bright Red Tomatos",      "FOOD",                 2,                      5.0,            425),     ("Nintendo Switch",         "ELEC",                 3,                      300.0,          234),     ("Nintendo Wii",            "ELEC",                 3,                      400.0,          734),     ("Amazon Fire TV",          "ELEC",                 4,                      50.0,           24),     ("Samsung Galaxy S23",      "ELEC",                 5,                      800.0,          754),     ("Differential",            "CARH",                 3,                      700.0,          34),     ("Pens and Pencil Pack",    "OFCS",                 2,                      1.0,            234),  --  ("Differential",            "CARH",                 200,                    700.0,          34), --  This line is invalid, when run I get --  Error Code: 1452 Cannot add or update a child row: a foreign key constraint fails (`store_ledger`.`product`, CONSTRAINT `product_supplier_id_fk` FOREIGN KEY (`product_supplier_id`) REFERENCES `supplier` (`supplier_id`) ON DELETE SET NULL)      --  ("Pens and Pencil Pack",    "OFCS",                 2,                      -1.0,            234), --  This line is invalid, when run I get --  Error Code: 1644 Price -1.00 Is too low --  This is a custom error      ("Packs Toothbrush",        "CARH",                 2,                      10.0,           234);  insert into order_table      (order_table_customer_name, order_table_product_id, order_table_quantity) values     ("Stan",                    1,                      20),     ("Nina",                    3,                      5),     ("Lloyd",                   1,                      1),     ("Seth",                    6,                      3),     ("Rachel",                  2,                      4),     ("Clay",                    1,                      3),     ("Desmond",                 3,                      12),     ("Summiya",                 2,                      51), --  ("Clay",                    100,                    46), --  This line is invalid, when run I get --  Error Code: 1452 Cannot add or update a child row: a foreign key constraint fails (`store_ledger`.`order_table`, CONSTRAINT `order_table_product_id_fk` FOREIGN KEY (`order_table_product_id`) REFERENCES `product` (`product_id`) ON DELETE CASCAD...	Error Code: 1062 Duplicate entry 'CARA' for key 'product_category.PRIMARY'	

    ("FOOD", "Food and Groceries");

insert into supplier (supplier_name, supplier_contact_email, supplier_min_price) values 
	("Dell",        "dell@gmail.com",       100.0),
    ("Great Value", "great_val@gmail.com",  1.0),
    ("Nintendo",    "nintendo@gmail.com",   300.0),
    ("Amazon",      "amazon@gmail.com",     50.0),

--  ("Amazon",      "amazon1@gmail.com",     50.0),
--  This line is invalid, when run I get
--  Error Code: 1062 Duplicate entry 'Amazon' for key 'supplier.supplier_name'
 
--  ("Samsung",     "@gmail.com",           100.0),
--  This line is invalid, when run I get
--  Error Code: 3819 Check constraint 'supplier_chk_2' is violated.
    
    ("Samsung",     "samsung@gmail.com",    100.0),
    ("Ford",        "ford@gmail.com",       500.0);

insert into product 
    (product_name,              product_category_id,    product_supplier_id,    product_price,  product_stock) values
    ("Dell All In One",         "ELEC",                 1,                      101.0,          123),
    ("Bright Red Tomatos",      "FOOD",                 2,                      5.0,            425),
    ("Nintendo Switch",         "ELEC",                 3,                      300.0,          234),
    ("Nintendo Wii",            "ELEC",                 3,                      400.0,          734),
    ("Amazon Fire TV",          "ELEC",                 4,                      50.0,           24),
    ("Samsung Galaxy S23",      "ELEC",                 5,                      800.0,          754),
    ("Differential",            "CARH",                 3,                      700.0,          34),
    ("Pens and Pencil Pack",    "OFCS",                 2,                      1.0,            234),

--  ("Differential",            "CARH",                 200,                    700.0,          34),
--  This line is invalid, when run I get
--  Error Code: 1452 Cannot add or update a child row: a foreign key constraint fails (`store_ledger`.`product`, CONSTRAINT `product_supplier_id_fk` FOREIGN KEY (`product_supplier_id`) REFERENCES `supplier` (`supplier_id`) ON DELETE SET NULL)
    
--  ("Pens and Pencil Pack",    "OFCS",                 2,                      -1.0,            234),
--  This line is invalid, when run I get
--  Error Code: 1644 Price -1.00 Is too low
--  This is a custom error

    ("Packs Toothbrush",        "CARH",                 2,                      10.0,           234);

insert into order_table 
    (order_table_customer_name, order_table_product_id, order_table_quantity) values
    ("Stan",                    1,                      20),
    ("Nina",                    3,                      5),
    ("Lloyd",                   1,                      1),
    ("Seth",                    6,                      3),
    ("Rachel",                  2,                      4),
    ("Clay",                    1,                      3),
    ("Desmond",                 3,                      12),
    ("Summiya",                 2,                      51),
--  ("Clay",                    100,                    46),
--  This line is invalid, when run I get
--  Error Code: 1452 Cannot add or update a child row: a foreign key constraint fails (`store_ledger`.`order_table`, CONSTRAINT `order_table_product_id_fk` FOREIGN KEY (`order_table_product_id`) REFERENCES `product` (`product_id`) ON DELETE CASCADE)
    ("Ryley",                   1,                      23),
    ("Caleb",                   3,                      52),
    ("Raymond",                 6,                      12);

SET SQL_SAFE_UPDATES = 0;

-- To show off category deletion
delete from product_category where product_category_id = "OFCS";
delete from supplier where supplier_id = 2;

/*
    TABLE DESCRIPTIONS

    product_category
        product_category_id     : A uniqe ID used to index this table, this is a primary key.
        product_category_name   : The name of the product for this 

    supplier   
        supplier_id             : A uniqe ID used to index this table, this is a primary key.
        supplier_name           : The name of the supplier
        supplier_contact_email  : The email of the supplier. Check rules enforce it is in the format of X @ Y
        supplier_min_price      : The minimum price the supplier will sell
    
        The length of the name must be more than 0, and the min price must be greater than 0.

    product
        product_id              : A uniqe ID used to index this table, this is a primary key.
        product_name            : The name of this product
        product_category_id     : A foreign key that links to product_category.
        product_supplier_id     : A foreign key that links to supplier
        product_price           : The price of this specific product
            - Any time this is inserted into a table, a trigger is called to check the price, and ensure it is not less than the supplier min price.
        product_stock           : How much product there is in stock

        The length of product name, and product price must be more than Zero. Product stock just can't be negative.

    order_table
        I can't use the word "order" as a name, so this will do

        order_table_order_id        : A uniqe ID used to index this table, this is a primary key.
        order_table_customer_name   : The name of the person ordering
        order_table_product_id      : A foreign key that links this column to products
        order_table_quantity        : How many objects were ordered by this person
        order_table_price           : How much money the order was
            - Any time something is appended to the order table, order_table_price is calculated to be (product.product_price * order_table_quantity)

        The length of order_table_customer_name must be more than zero
        order_table_quantity must be more than 0
        order_table_price must be more than 0
*/