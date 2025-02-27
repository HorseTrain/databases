drop database if exists store_ledger;
create database store_ledger;

use store_ledger;

create table product_category(
	product_category_category_id        int 			    not null	primary key		auto_increment,
    product_category_category_name      varchar(50) 	    not null
);

create table supplier (
	supplier_supplier_id                int				    not null	primary key		auto_increment,
    supplier_supplier_name              varchar(50)		    not null,
    supplier_contact_email              varchar(100)	    not null,
    supplier_min_price                  decimal(5, 2)	    not null
);

create table product (
    product_product_name	            varchar(50)		    not null,
    product_category_id		            int				    not null,
    product_supplier_id 	            int 			    not null,
    product_price 			            decimal(5, 2)	    not null,
    product_stock 			            int 			    not null,
    
    foreign key (product_supplier_id) references supplier(supplier_supplier_id)
);

create table order_table (
	order_table_order_id				int 				not null 	primary key		auto_increment,
    
)