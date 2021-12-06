-- courses per specialization
select p.program_assignment, count(p.program_assignment) as courses_count from programs p group by p.program_assignment;


-- semester count per specialization
select p.program_assignment, p.program_course_rev_ref as semester, count(p.program_course_rev_ref) as courses_count from programs p group by p.program_assignment, p.program_course_rev_ref order by p.program_assignment, p.program_course_rev_ref asc;


-- get all session types
select distinct(s.session_type) from sessions s;


-- get all room name
select distinct(s.session_room) from sessions s where s.session_room is not null ;


-- per intake, count of sessions and per year
select s.session_population_period, count(s.*),  from sessions s where s.session_population_year = 2021 group by s.session_population_period;


-- sessions per month [range]
select s.* from sessions s where s.session_date >= '2020-09-01' and s.session_date < '2020-10-01';


-- sessions handled by teachers [not duplicate]
select distinct(s.session_prof_ref) from sessions s;


-- started session count of the particular year intake
select s.session_population_period, count(s.*) from sessions s where s.session_population_year = 2021 group by s.session_population_period;


-- insert population for all specilization
insert into populations (population_code, population_year, population_period) select p.population_code as pcode, max(p.population_year) as pyear, 'FALL' as intake from populations p group by p.population_code;


-- order by teacher's level 
select t.* from teachers t order by t.teacher_study_level asc


-- get all teachers from contacts table
select c.* from contacts c left join teachers t on c.contact_email = t.teacher_contact_ref where t.teacher_contact_ref is not null;


-- get all students from contacts table
select c.* from contacts c left join students s on c.contact_email = s.student_contact_ref where s.student_contact_ref is not null;


-- get all students from contacts table and where newyork students
select c.* from contacts c left join students s on c.contact_email = s.student_contact_ref where s.student_contact_ref is not null and c.contact_city  ilike 'los angeles';


-- get all students from contacts table and where birthday is on november
select c.* from contacts c left join students s on c.contact_email = s.student_contact_ref where s.student_contact_ref is not null and date_part('month', c.contact_birthdate::date) = 11;

-- calculate age from dob 
SELECT contact_first_name, date_part('year',age(contact_birthdate)) as contact_age,* FROM contacts;


-- add age column to contacts
alter table contacts add column contact_age integer NULL;

-- calculate age from dob and insert in col contact_age
update 
  contacts as c1 
set 
  contact_age = (
    SELECT 
      date_part(
        'year', 
        age(contact_birthdate)
      ) as c_age 
    FROM 
      contacts as c2 
    where 
      c1.contact_email = c2.contact_email
  );
 
 
-- avg student age
select 
  avg(c.contact_age) as student_avg_age 
from 
  students as s 
  left join contacts as c on c.contact_email = s.student_contact_ref
 
-- get students population in each year
select student_population_year_ref, count(1) from students group by student_population_year_ref;


-- get students population in each program
select student_population_code_ref, count(1) from students group by student_population_code_ref;
  

-- students count who completed the diploma in particular year according to the specilization
select s.student_population_code_ref, count(*) from students s where s.student_enrollment_status ='completed' and s.student_population_year_ref =2021 group by s.student_population_code_ref;


/* avg grade for SE students*/
select 
  avg(g.grade_score) as avg_grade, 
  pop.population_code as population 
from 
  grades as g 
  inner join programs as p on g.grade_course_code_ref = p.program_course_code_ref 
  inner join populations as pop on pop.population_code = p.program_assignment 
where 
  pop.population_code = 'SE' 
group by 
  pop.population_code


/* All student average grade*/
Select cont.contact_first_name, cont.contact_last_name, stud.student_epita_email, avg(g.grade_score)
from students stud
  inner join contacts cont
  on cont.contact_email = stud.student_contact_ref
  
  inner join grades g
  on stud.student_epita_email = g.grade_student_epita_email_ref

group by cont.contact_first_name, cont.contact_last_name, stud.student_epita_email


/* attendance percentage for a student */
select 
  (sum_atten / total_atten :: float)* 100 attendance_percentage, 
  res.attendance_student_ref, 
  res.attendance_course_ref, 
  res.attendance_population_year_ref 
from 
  (
    select 
      count(1) as total_atten, 
      sum(s.attendance_presence) as sum_atten, 
      s.attendance_student_ref, 
      s.attendance_course_ref, 
      s.attendance_population_year_ref 
    from 
      attendance as s 
    where 
      s.attendance_student_ref = 'albina.glick@epita.fr' 
    group by 
      s.attendance_student_ref, 
      s.attendance_course_ref, 
      s.attendance_population_year_ref
  ) res 
order by 
  attendance_percentage


/* list the course tought by teacher */
select 
  distinct con.contact_first_name, 
  con.contact_last_name, 
  sess.session_course_ref 
from 
  teachers tea 
  inner join contacts con on con.contact_email = tea.teacher_contact_ref 
  inner join sessions sess on tea.teacher_epita_email = sess.session_prof_ref


-- find the teachers who are not giving any courses
select 
  s.student_epita_email 
from 
  students as s 
where 
  s.student_epita_email not in (
    select 
      g.grade_student_epita_email_ref 
    from 
      grades as g
  )

/* 
 * find the SE students details with grades
 */
select 
  con.contact_first_name, 
  con.contact_last_name, 
  stud.student_population_code_ref, 
  grad.grade_course_code_ref as course_name, 
  grad.grade_score 
from 
  grades grad 
  inner join students stud on grad.grade_student_epita_email_ref = stud.student_epita_email 
  inner join contacts con on stud.student_contact_ref = con.contact_email 
where 
  student_population_code_ref = 'SE'

  
/*
 * list of teacher who attend the total session 
 */
select 
  con.contact_first_name, 
  con.contact_last_name, 
  tea.teacher_contact_ref, 
  count(session_prof_ref) 
from 
  teachers tea 
  inner join contacts con on con.contact_email = tea.teacher_contact_ref 
  inner join sessions sess on tea.teacher_epita_email = sess.session_prof_ref 
group by 
  con.contact_first_name, 
  con.contact_last_name, 
  tea.teacher_contact_ref 
order by 
  count

  

/*
 * find the teachers who are not in any session
 */
  
SELECT 
  c.contact_first_name, 
  c.contact_last_name, 
  t.teacher_epita_email 
from 
  contacts as c 
  inner join teachers as t on c.contact_email = t.teacher_contact_ref 
  LEFT OUTER JOIN sessions as s ON t.teacher_epita_email = s.session_prof_ref 
WHERE 
  s.session_prof_ref IS NULL


/*
 * find students who are not graded
 */
  
-- SOLUTION NUMBER 1
SELECT 
  a.student_epita_email, 
  b.grade_score 
FROM 
  students a 
  LEFT JOIN grades b ON a.student_epita_email = b.grade_student_epita_email_ref 
WHERE 
  b.grade_score IS NULL

-- SOLUTION NUMBER 2
SELECT 
  s.student_epita_email 
FROM 
  students as s 
WHERE 
  NOT EXISTS (
    SELECT 
      * 
    FROM 
      grades as g 
    WHERE 
      s.student_epita_email = g.grade_student_epita_email_ref
  )
  
-- SOLUTION NUMBER 3
SELECT 
  s.student_epita_email 
FROM 
  students as s 
  LEFT OUTER JOIN grades as g ON (
    s.student_epita_email = g.grade_student_epita_email_ref
  ) 
WHERE 
  g.grade_student_epita_email_ref IS NULL


/*
 * find the student with most absents TOP 10
 */
select 
  count(a.attendance_student_ref) as absents, 
  c.contact_first_name, 
  c.contact_last_name 
from 
  contacts as c 
  left join students as s on s.student_contact_ref = c.contact_email 
  left join attendance as a on s.student_epita_email = a.attendance_student_ref 
where 
  a.attendance_presence = 1 
group by 
  c.contact_first_name, 
  c.contact_last_name 
order by 
  absents ASC 
limit 
  10

  
/*
 * find the course with most absents
 */
SELECT 
  b.course_name, 
  count(a.attendance_presence) absences 
FROM 
  attendance a 
  LEFT JOIN courses b ON a.attendance_course_ref = b.course_code 
WHERE 
  attendance_presence = 0 
GROUP BY 
  a.attendance_course_ref, 
  b.course_name 
ORDER BY 
  Absences DESC 
LIMIT 
  1;

 
/*
 * avg session duration for a course
 */
select 
  avg(
    EXTRACT(
      EPOCH 
      FROM 
        TO_TIMESTAMP(session_end_time, 'HH24:MI:SS'):: TIME - TO_TIMESTAMP(
          session_start_time, 'HH24:MI:SS'
        ):: TIME
    )/ 3600
  ) as duration 
from 
  sessions as s 
  left join courses as c on c.course_code = s.session_course_ref 
where 
  c.course_code = 'DT_RDBMS'


--Note: Need to set foreign keys for session.session_course_ref , session.session_course_rev_ref with course table 






New codes


-- Get all enrolled students for a specific period,program,year ?
select s.* from students s where s.student_population_period_ref ='SPRING' and s.student_population_code_ref = 'SE' and s.student_population_year_ref =2021;

-- Get number of enrolled students for a specific period,program,year
select count(s.student_enrollment_status) from students s where s.student_population_period_ref ='SPRING' and s.student_population_code_ref = 'SE' and s.student_population_year_ref =2021;

-- Get All defined exams for a course from grades table
select distinct(g.grade_exam_type_ref) from grades g where g.grade_course_code_ref ='SE_ADV_JAVA';

-- Get all grades for a student
select  g.grade_score from grades g where g.grade_student_epita_email_ref ='viva.toelkes@epita.fr';

-- Get all grades for a specific Exam
select g.grade_score from grades g where g.grade_exam_type_ref = 'Project';


-- Get students Ranks in an Exam for a course
-- solution 1 per intake & year
select rank() over(order by g.grade_score desc), g.grade_score from students s right join grades g 
on s.student_epita_email = g.grade_student_epita_email_ref where g.grade_student_epita_email_ref is not null and s.student_population_year_ref =2021 and s.student_population_period_ref ='SPRING' and g.grade_course_code_ref ='SE_ADV_JAVA' and g.grade_exam_type_ref ='Project';

-- solution 2 general
select rank() over(order by g.grade_score desc), g.grade_score from grades g where  g.grade_course_code_ref ='SE_ADV_JAVA' and g.grade_exam_type_ref ='Project';

-- Get students Ranks in all exams for a course
-- solution 1 per intake & year
select rank() over(order by g.grade_score desc), g.grade_score from students s right join grades g on s.student_epita_email = g.grade_student_epita_email_ref where g.grade_student_epita_email_ref is not null and s.student_population_year_ref =2021 and s.student_population_period_ref ='SPRING' and g.grade_course_code_ref ='SE_ADV_JAVA';

-- solution 2 general
select rank() over(order by g.grade_score desc), g.grade_score from grades g where  g.grade_course_code_ref ='SE_ADV_JAVA';

-- Get students Rank in all exams in all courses
-- solution 1 per intake & year
select rank() over(order by g.grade_score desc), g.grade_score from students s right join grades g on s.student_epita_email = g.grade_student_epita_email_ref where g.grade_student_epita_email_ref is not null and s.student_population_year_ref =2021 and s.student_population_period_ref ='SPRING';

-- solution 2 general
select rank() over(order by g.grade_score desc), g.grade_score from grades g;

-- Get all courses for one program
select p.program_course_code_ref from programs p where p.program_assignment ='SE';

-- Get courses in common between 2 programs
SELECT distinct(program_course_code_ref) program_assignment FROM programs where program_assignment = 'SE'
intersect
SELECT distinct(program_course_code_ref) program_assignment FROM programs where program_assignment = 'AIs'

-- Get all programs following a certain course
select p.program_assignment from programs p where p.program_course_code_ref = 'DT_RDBMS';

-- get course with the biggest duration
-- solution 1
select c.* from courses c order by c.duration desc limit 1;

-- solution 2
select c.* from courses c where c.duration = (select max(c2.duration) from courses c2);

-- get courses with the same duration 
select * from courses c where c.duration in (select c2.duration from courses c2 group by c2.duration having count(c2.duration) > 1) order by c.duration asc


-- Get all sessions for a specific course
-- solution 1
select s.* from sessions s where s.session_course_ref ='DT_RDBMS';

-- solution 2
select s.* from sessions s where s.session_course_ref ='DT_RDBMS' and s.session_population_year =2020 and s.session_population_period ='FALL';

-- Get all session for a certain period
select s.* from sessions s where s.session_date  >= '2021-01-04' and s.session_date  <= '2021-01-31';


-- Get one student attendance sheet
select a.attendance_course_ref, a.attendance_session_date_ref, a.attendance_session_start_time, a.attendance_session_end_time,
case when a.attendance_presence = 1 then 'Present'
  else 'Absent' 
end as marksheet
from attendance a where a.attendance_student_ref = 'jamal.vanausdal@epita.fr'

-- Get one student summary of attendance
select
  total_attendance, 
  sum_attendance,
  (sum_attendance / total_attendance :: float)* 100 attendance_percentage, 
  res.attendance_student_ref, 
  res.attendance_course_ref, 
  res.attendance_population_year_ref 
from 
  (
    select 
      count(1) as total_attendance, 
      sum(s.attendance_presence) as sum_attendance, 
      s.attendance_student_ref, 
      s.attendance_course_ref, 
      s.attendance_population_year_ref 
    from 
      attendance as s 
    where 
      s.attendance_student_ref = 'albina.glick@epita.fr' 
    group by 
      s.attendance_student_ref, 
      s.attendance_course_ref, 
      s.attendance_population_year_ref
  ) res 
order by 
  attendance_percentage
  

-- Get student with most absences
  select * from (select attendance_student_ref , count(attendance_presence) from attendance where attendance_presence = 0 group by attendance_student_ref) as OP1 order by OP1.count desc limit 1;
  
-- Get all exams for a specific Course
select e.exam_type from courses c right join exams e on e.exam_course_code = c.course_code where e.exam_course_code is not null and c.course_code  = 'DT_RDBMS';


-- Get all Grades for a specific Student
select grade_score from grades where grade_student_epita_email_ref = 'simona.morasca@epita.fr'

-- Get the students with the top 5 scores for specific course
select OP4.contact_first_name,OP4.contact_last_name,OP4.grade_score from
((select OP2.student_contact_ref , OP2.grade_score from
((select grade_student_epita_email_ref ,grade_score from grades where grade_course_code_ref = 'CS_DATA_PRIV' order by grade_score desc limit 5) as OP1
left join students on OP1.grade_student_epita_email_ref = students.student_epita_email) as OP2) as OP3
left join contacts on OP3.student_contact_ref = contacts.contact_email) as OP4

-- Get the students with the top 5 scores for specific course per rank
select grade_student_epita_email_ref , rank () over (partition by grade_course_rev_ref order by grade_score desc ) FROM grades where grade_course_code_ref = 'SE_ADV_JS' limit 5

-- Get the Class average for a course
select 
  avg(
    EXTRACT(
      EPOCH 
      FROM 
        TO_TIMESTAMP(session_end_time, 'HH24:MI:SS'):: TIME - TO_TIMESTAMP(
          session_start_time, 'HH24:MI:SS'
        ):: TIME
    )/ 3600
  ) as duration 
from 
  sessions as s 
  left join courses as c on c.course_code = s.session_course_ref 
where 
  c.course_code = 'DT_RDBMS'
  
  
-- Get a student full report of grades and attendances
  
-- Get a student full report of grades ,ranks per course  and attendances
  
  
  
  
  
  
  
  
  
  




