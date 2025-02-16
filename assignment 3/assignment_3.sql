drop database if exists enrollment_data;
create database enrollment_data;

use enrollment_data;

create table semesters (
	semester_id 			int 		primary key,
    semester_name 			varchar(50) not null,
    semester_date_start		date 		not null,
    semester_date_end		date 		not null
);

create table divisions (
	division_id 			int 		primary key,
    division_name			varchar(50) not null
);

create table majors (
	major_id 				int 		primary key,
    major_name 				varchar(50) not null,
    major_division_id		int 		not null,
    
    foreign key (major_division_id) references divisions(division_id)
);

create table students (
	student_id				int 		primary key,
    student_first_name		varchar(50) not null,
    student_last_name		varchar(50) not null,
    student_major_id		int 		not null,
    
	foreign key (student_major_id) references majors(major_id)
);

create table instructors (
	instructor_id			int 		primary key,
    instructor_first_name 	varchar(50) not null,
    instructor_last_name 	varchar(50) not null,
    instructor_division_id  int not null,
    
    foreign key (instructor_division_id) references divisions(division_id)
);

create table courses (
	course_id				int 			primary key,
	course_year				int 			not null,
    course_major_id			int 			not null,
    course_semester_id		int 			not null,
    course_number			int 			not null,
	course_name				varchar(50) 	not null,   
    course_description 		varchar(1000) 	not null,
    
    foreign key (course_semester_id) 	references semesters(semester_id),
    foreign key (course_major_id) 		references majors(major_id)
);

-- An enrollment will reference another table called "course list". These are created via query
create table enrollments (
	enrollment_id 			int 			auto_increment primary key,
    enrollment_student_id   int 			not null,
    enrollment_date 		date 			not null,
    
    foreign key (enrollment_student_id) 	references students(student_id)
);

insert into divisions (division_id, division_name) values 
	(0, "Buisness and Computer Science"),
    (1, "Humanities"),
    (2, "Physical, Life, Movement & Sport Sciences"),
    (3, "Social Sciences"),
    (4, "Teacher Education & Mathematics Division");
    
insert into majors (major_id, major_name, major_division_id) values
	(0, "Computer Science", 0),
    (1, "Mathmatics", 4),
    (2, "Communications", 3),
    (3, "Cyber Security", 0),
    (4, "Chemistry", 2);
    
insert into semesters (semester_id, semester_name, semester_date_start, semester_date_end) values 
	(0 ,"Spring", '0000-01-17', '0000-05-17'),
	(1 ,"Summer", '0000-06-17', '0000-8-17'),
	(2 ,"Fall", '0000-8-23', '0000-12-17');

insert into courses (course_id, course_year, course_major_id, course_semester_id, course_number, course_name, course_description) values 
	(0, 3, 0, 0, 311,"Data Structures And Algorithms",	"This course talks about datastructures and algorithms."),
	(1, 1, 0, 1, 101, "Computer Science Seminar",		"This course introduces students to computer science."),
	(2, 2, 0, 0, 211, "Computer Programming",			"This course introduces students to C/C++, and all of its fine quirks."),
    (3, 1, 0, 2, 250, "Intro to buisness", 				"This course introduces students to buisness"),
    (4, 4, 4, 2, 358, "Complex Chemistry",				"This is complex chemistry");

set @current_student_id = 0;
set @current_instructor_id = 0;

delimiter //

create procedure create_instructor(first_name varchar(50), last_name varchar(50), division_id int)
    begin
    
    declare create_class_list_command varchar(1000);
    
    insert into instructors (instructor_id, instructor_first_name, instructor_last_name, instructor_division_id) values
		(@current_instructor_id, first_name, last_name, division_id);
        
	set @create_class_list_command = concat("create table instructor_", @current_instructor_id, "_course_list (course_id int, year_taught date, foreign key(course_id) references courses(course_id));" );
    
    prepare command from @create_class_list_command;
    execute command;
    deallocate prepare command;
    
    set @current_instructor_id = @current_instructor_id + 1;
    
    end //

delimiter //

create function get_student_course_table_name(student_id int) returns varchar(1000)
	deterministic
    begin
    
		declare result varchar(1000);
        set @result = concat("student_course_table_", student_id);
        
        return @result;
    
    end //

delimiter //

create procedure enroll_student(first_name varchar(50), last_name varchar(50), major_id int)
	begin
    
	declare course_table_name varchar(1000);
    declare course_table_generator varchar(1000);
    
    set @course_table_name = get_student_course_table_name(@current_student_id);
    set @course_table_generator = concat("create table ", @course_table_name, " (course_id int, foreign key (course_id) references courses(course_id));");
    
    prepare command from @course_table_generator;
    execute command;
    deallocate prepare command;
	
    insert into students (student_id, student_first_name, student_last_name, student_major_id) values
		(@current_student_id, first_name, last_name, major_id);
        
	insert into enrollments (enrollment_student_id, enrollment_date) values (@current_student_id, curdate());
        
    set @current_student_id = @current_student_id + 1;
    
    end //
    
delimiter //

create procedure create_instructor_view(instructor_id int)
	begin
    
    declare generated_code varchar(1000);
    declare instructor_table_name varchar(1000);
    declare instructor_name varchar(1000);
    
    set @instructor_first_name = (select instructor_first_name from instructors limit 1 offset instructor_id);
    set @instructor_last_name = (select instructor_last_name from instructors limit 1 offset instructor_id);
    
    set @instructor_table_name = concat("instructor_", instructor_id, "_course_list");

    set @generated_code = concat(
		"create view ",@instructor_first_name,"_",@instructor_last_name,"_id_",instructor_id,"_view as ",
		"select ",
			"courses.course_name					as course_name, ",
            "courses.course_year					as course_year, ",
            "courses.course_number 					as course_number, ",
            "semesters.semester_name				as semester, ",
			@instructor_table_name,".year_taught 	as year_taught ",
		"from ",@instructor_table_name," ",
        "join courses on ",@instructor_table_name,".course_id = courses.course_id ",
        "join semesters on ", @instructor_table_name,".course_id = courses.course_id;" );
    
    prepare command from @generated_code;
    execute command;
    deallocate prepare command;
    
    end //

    
call create_instructor("Samuel", "Long", 0);    
call create_instructor("Mike", "Owens", 1);    
call create_instructor("Nina", "Peterson", 2);
call create_instructor("Lloyd", "Mataka", 3);    
call create_instructor("Rachel", "Jametown", 2);    
call create_instructor("Heather", "Moon", 2);

insert into instructor_0_course_list (course_id, year_taught) values 
	(2, "2005-01-24"),
    (3, "2006-01-24"),
    (4, "2007-01-24"),
    (1, "2008-01-24"),
    (4, "2009-01-24"),
    (2, "2010-01-24"),
	(3, "2005-01-24"),
    (4, "2006-01-24"),
    (1, "2007-01-24"),
    (2, "2008-01-24"),
    (3, "2009-01-24"),
    (1, "2010-01-24");
    
insert into instructor_1_course_list (course_id, year_taught) values 
	(1, "2005-01-24"),
    (2, "2006-01-24"),
    (3, "2007-01-24"),
    (1, "2008-01-24"),
    (2, "2009-01-24"),
    (3, "2010-01-24"),
	(1, "2005-01-24"),
    (2, "2006-01-24"),
    (3, "2007-01-24"),
    (1, "2008-01-24"),
    (2, "2009-01-24"),
    (1, "2010-01-24");
    
insert into instructor_2_course_list (course_id, year_taught) values 
	(1, "2005-01-24"),
    (3, "2006-01-24"),
    (4, "2007-01-24"),
    (1, "2008-01-24"),
    (2, "2009-01-24"),
    (3, "2010-01-24"),
	(4, "2005-01-24"),
    (1, "2006-01-24"),
    (2, "2007-01-24"),
    (3, "2008-01-24"),
    (1, "2009-01-24"),
    (2, "2010-01-24");
    
insert into instructor_3_course_list (course_id, year_taught) values 
	(1, "2005-01-24"),
    (3, "2006-01-24"),
    (4, "2007-01-24"),
    (2, "2008-01-24"),
    (3, "2009-01-24"),
    (4, "2010-01-24"),
	(1, "2005-01-24"),
    (2, "2006-01-24"),
    (3, "2007-01-24"),
    (2, "2008-01-24"),
    (3, "2009-01-24"),
    (1, "2010-01-24");
    
insert into instructor_4_course_list (course_id, year_taught) values 
	(2, "2005-01-24"),
    (3, "2006-01-24"),
    (2, "2007-01-24"),
    (3, "2008-01-24"),
    (1, "2009-01-24"),
    (2, "2010-01-24"),
	(3, "2005-01-24"),
    (4, "2006-01-24"),
    (2, "2007-01-24"),
    (3, "2008-01-24"),
    (1, "2009-01-24"),
    (2, "2010-01-24");

-- This is not handwritten right here. I am teaching my little brother C++, and I saw it as the perfect oppertunity to
-- teach bim by writing a random name generator with him LOL. He would not leave me alone until i gave him credit in
-- this comment.
call enroll_student("kolo","leila",1);
call enroll_student("cordel","minny",3);
call enroll_student("gilton","lucina",1);
call enroll_student("vastola","nicoline",3);
call enroll_student("gehlhausen","erma",3);
call enroll_student("ploetz","ethel",2);
call enroll_student("gaulden","cissiee",3);
call enroll_student("fiscel","rowena",1);
call enroll_student("boudreau","linnea",2);
call enroll_student("broddy","vickie",3);
call enroll_student("abshier","philipa",2);
call enroll_student("knoll","marissa",3);
call enroll_student("beacher","maurene",3);
call enroll_student("canfield","dorry",1);
call enroll_student("sloter","lucienne",0);
call enroll_student("kubick","iolande",0);
call enroll_student("margarita","cicely",1);
call enroll_student("nellis","dell",0);
call enroll_student("diederichs","haleigh",2);
call enroll_student("simien","vere",1);

insert into student_course_table_0 values (0),(4),(2),(1),(3);
insert into student_course_table_1 values (2),(4),(0),(3),(1);
insert into student_course_table_2 values (3),(4),(1),(2),(0);
insert into student_course_table_3 values (1),(3),(4),(2),(0);
insert into student_course_table_4 values (0),(4),(3),(2),(1);
insert into student_course_table_5 values (2),(1),(0),(4),(3);
insert into student_course_table_6 values (1),(0),(3),(4),(2);
insert into student_course_table_7 values (4),(3),(0),(1),(2);
insert into student_course_table_8 values (1),(3),(2),(0),(4);
insert into student_course_table_9 values (1),(2),(3),(0),(4);
insert into student_course_table_10 values (1),(3),(0),(4),(2);
insert into student_course_table_11 values (0),(3),(1),(4),(2);
insert into student_course_table_12 values (2),(1),(4),(3),(0);
insert into student_course_table_13 values (3),(0),(4),(2),(1);
insert into student_course_table_14 values (4),(2),(0),(3),(1);
insert into student_course_table_15 values (2),(3),(4),(1),(0);
insert into student_course_table_16 values (2),(1),(0),(3),(4);
insert into student_course_table_17 values (1),(2),(0),(3),(4);
insert into student_course_table_18 values (2),(4),(0),(1),(3);
insert into student_course_table_19 values (1),(3),(0),(4),(2);

call create_instructor_view(0);
call create_instructor_view(1);
call create_instructor_view(2);
call create_instructor_view(3);
call create_instructor_view(4);

create view student_view as
select
	students.student_id			as student_id,
    students.student_first_name as student_first_name,
    students.student_last_name 	as student_last_name,
    majors.major_name 			as student_major
from students
join majors on students.student_major_id = majors.major_id;

create view instructor_view as
select
	instructors.instructor_id 			as instructor_id,
    instructors.instructor_first_name 	as instructor_first_name,
    divisions.division_name 			as division
from instructors
join divisions on instructors.instructor_division_id = divisions.division_id;

create view course_view as
select
	courses.course_id 					as course_id,
    courses.course_name					as course_name,
    courses.course_year					as course_year,
    majors.major_name 					as course_major,
    courses.course_number 				as course_number,
    semesters.semester_name 			as course_semester,
    courses.course_description 			as course_description
from courses
join majors on courses.course_major_id = majors.major_id
join semesters on courses.course_semester_id = semesters.semester_id;

create view enrollment_view as
select
	enrollments.enrollment_id 			as enrollment_id,
    students.student_first_name 		as enrollment_student_first_name,
    students.student_last_name 			as enrollment_student_last_name,
    enrollments.enrollment_date			as enrollment_date
from enrollments
join students on enrollments.enrollment_student_id = students.student_id;
    
-- select * from student_view;
-- select * from instructor_view;    
-- select * from course_view;
-- select * from enrollment_view;