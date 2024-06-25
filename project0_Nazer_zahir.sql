create or replace PACKAGE employee1_pkg AS
    -- global variable for all column names
    -- global variables to store variables by datatype
    -- 

    FUNCTION get_next_employee_id RETURN NUMBER;

    FUNCTION is_employee_exists (p_employee_id in employees.employee_id%type) return boolean;

    CURSOR cur_employees_by_depid(p_dept_id employees.department_id%type) is
        select employee_id,last_name,salary,department_id
        from employees
        where department_id = p_dept_id;

    CURSOR cur_employees_all is 
        select employee_id, last_name, job_id,salary,department_id from employees;
    PROCEDURE add_employee(
        p_first_name        IN employees.first_name%TYPE,
        p_last_name         IN employees.last_name%TYPE,
        p_email             IN employees.email%TYPE,
        p_phone_number      IN employees.phone_number%TYPE,
        p_hire_date         IN employees.hire_date%TYPE,
        p_job_id            in employees.job_id%TYPE,
        p_salary            IN employees.salary%TYPE,
        p_commission_pct    IN employees.commission_pct%TYPE,
        p_manager_id        IN employees.manager_id%TYPE,
        p_department_id     IN employees.department_id%TYPE
    );

    PROCEDURE update_employee(
        -- same as add but has employee_id as parameter
        p_employee_id       in employees.employee_id%TYPE,
        p_first_name        IN employees.first_name%TYPE,
        p_last_name         IN employees.last_name%TYPE,
        p_email             IN employees.email%TYPE,
        p_phone_number      IN employees.phone_number%TYPE,
        p_hire_date         IN employees.hire_date%TYPE,
        p_job_id            in employees.job_id%type,
        p_salary            IN employees.salary%TYPE,
        p_commission_pct    IN employees.commission_pct%TYPE,
        p_manager_id        IN employees.manager_id%TYPE,
        p_department_id     IN employees.department_id%TYPE
    );

    PROCEDURE update_salary(
    --might need to update salary often so it has its own procedure
    p_employee_id IN employees.employee_id%type,
    p_new_salary  IN employees.salary%type 
    );

    PROCEDURE delete_employee( p_employee_id in employees.employee_id%type);

    PROCEDURE read_all_employees;
    PROCEDURE read_employees_by_department_id(p_dept_id in employees.department_id%type);
    PROCEDURE update_smart_update(
    -- update statement that updates a column value based off column name and employee_id
    -- able to choose the column name and its value rather than remembering the name of each update procedure
    /*
        downside:
            not practical
            not secure
            someone can use comments to detroy your db
        upside:
            it looks cool
    */
    
    
        p_employee_id in employees.employee_id%type,
        p_col_name in varchar2,
        p_col_value in varchar2
        );
END EMPLOYEE1_PKG;


create or replace PACKAGE BODY employee1_pkg AS

    FUNCTION get_next_employee_id RETURN NUMBER IS
    --returns the max emp_id +1
    -- ensures consisitency while giving up customization
        v_next_empid number;
    BEGIN
        SELECT NVL(MAX(employee_id),1)
        INTO v_next_empid
        FROM EMPLOYEES;
        v_next_empid:= v_next_empid + 1;
        DBMS_OUTPUT.PUT_LINE('next id = ' || v_next_empid);
        RETURN v_next_empid;
    END get_next_employee_id;
    
    
    PROCEDURE add_employee(
        --insert user into employees table
        --auto generates employee_id
        p_first_name        IN employees.first_name%TYPE,
        p_last_name         IN employees.last_name%TYPE,
        p_email             IN employees.email%TYPE,
        p_phone_number      IN employees.phone_number%TYPE,
        p_hire_date         IN employees.hire_date%TYPE,
        p_job_id            in employees.job_id%type,
        p_salary            IN employees.salary%TYPE,
        p_commission_pct    IN employees.commission_pct%TYPE,
        p_manager_id        IN employees.manager_id%TYPE,
        p_department_id     IN employees.department_id%TYPE
    ) IS
    --fetch and stores next employee id
    v_next_empid number;
    BEGIN
        v_next_empid := employee1_pkg.get_next_employee_id;
        INSERT INTO employees(employee_id,first_name,last_name,email,
            phone_number,hire_date,job_id,salary,commission_pct,
            manager_id,department_id)

        VALUES (v_next_empid,p_first_name, p_last_name,p_email,p_phone_number,
            p_hire_date,p_job_id,p_salary,p_commission_pct,p_manager_id,p_department_id
        );
            DBMS_OUTPUT.PUT_LINE('Employee Id: ' ||v_next_empid|| 'First Name: ' || p_first_name || ', ' ||
                         'Last Name: ' || p_last_name || ', ' ||
                         'Email: ' || p_email || ', ' ||
                         'Phone Number: ' || p_phone_number || ', ' ||
                         'Hire Date: ' || TO_CHAR(p_hire_date, 'DD-MON-YYYY') || ', ' ||
                         'Job ID: ' || p_job_id || ', ' ||
                         'Salary: ' || p_salary || ', ' ||
                         'Commission Pct: ' || p_commission_pct || ', ' ||
                         'Manager ID: ' || p_manager_id || ', ' ||
                         'Department ID: ' || p_department_id);
            DBMS_OUTPUT.PUT_LINE('Insert successful');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Duplicate value encountered');
        WHEN VALUE_ERROR THEN
            dbms_output.put_line('ERROR:value error. ');
        when others then
            dbms_output.put_line('alt error');
    end add_employee;
    PROCEDURE update_smart_update(
    -- update statement that updates a column value based off column name and employee_id
    -- able to choose the column name and its value rather than remembering the name of each update procedure
    /*
        downside:
            not practical
            not secure
            someone can use comments to detroy your db
        upside:
            it looks cool
    */
    
    
        p_employee_id in employees.employee_id%type,
        p_col_name in varchar2,
        p_col_value in varchar2
        ) is
        v_sql_statement varchar2(9999);
        v_col_name varchar2(50);
        v_col_value varchar2(100);
    BEGIN
        --:='email';
        --p_col_value:='abc@gmail.com';
        
        -- removes any case sensitivity
        v_col_name:= lower(p_col_name);
        v_col_value:=lower(replace(p_col_value,'--',''));
        dbms_output.put_line('variables: '||v_col_name ||', '|| v_col_value);
        --p_col_name:= lower(p_col_name);
        --check if input column name matches
        --note: column names can be replaced with global variable that contains all column names.
        if  v_col_name not in ('first_name','last_name', 'email','job_id','phone_number','salary','commission_pct','manager_id','department_id') then
            dbms_output.put_line('Invalid column name');
            return;
        end if;
        
        --removes any potential comments from your input
        --maybe add a trigger that logs the user who may have called this function with comments in their inputs. THEY MUST BE WATCHED/SUPERVISED.
        
        --create a sql statement. concat the dynamic values
        v_sql_statement:= 'update employees set ' ||v_col_name || ' = ';
    
        --check and convert the column datatype accordingly    
        if v_col_name in ('salary','commission_pct','manager_id','department_id') then
            dbms_output.put_line('you chose a number. converting value to a number...');
             v_sql_statement := v_sql_statement || 'TO_NUMBER(''' || v_col_value || ''')';
        elsif v_col_name like 'hire_date'
            then
             v_sql_statement := v_sql_statement || 'TO_DATE(''' || v_col_value || ''', ''DD-MON-YYYY'')';
            dbms_output.put_line('you chose a date. converting value to a date...');
        else
            if v_col_name='job_id'then
            v_col_value:=upper(v_col_value);
            end if;
            dbms_output.put_line('this is a varchar. converting to varchar...');
             v_sql_statement := v_sql_statement || '''' || v_col_value || '''';
        end if;
        v_sql_statement := v_sql_statement || ' WHERE employee_id = ' || p_employee_id;
        dbms_output.put_line(v_sql_statement);
        execute immediate v_sql_statement;
    exception
        WHEN INVALID_NUMBER THEN
            DBMS_OUTPUT.PUT_LINE('Invalid number format');
        WHEN VALUE_ERROR THEN
            DBMS_OUTPUT.PUT_LINE('Value error encountered');
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No employee found with the given ID.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('An unexpected error occurred: ' || SQLERRM);
    end update_smart_update;
         
    PROCEDURE update_employee(
    --updates on the record level
        p_employee_id       in employees.employee_id%type,
        p_first_name        IN employees.first_name%TYPE,
        p_last_name         IN employees.last_name%TYPE,
        p_email             IN employees.email%TYPE,
        p_phone_number      IN employees.phone_number%TYPE,
        p_hire_date         IN employees.hire_date%TYPE,
        p_job_id            in employees.job_id%type,
        p_salary            IN employees.salary%TYPE,
        p_commission_pct    IN employees.commission_pct%TYPE,
        p_manager_id        IN employees.manager_id%TYPE,
        p_department_id     IN employees.department_id%TYPE
        )IS
    BEGIN
        UPDATE employees
        SET
            employee_id     = p_employee_id,
            first_name      = p_first_name,
            last_name       = p_last_name,
            email           = p_email,
            phone_number    = p_phone_number,
            hire_date       = p_hire_date,
            job_id          = p_job_id,
            salary          = p_salary,
            commission_pct  = p_commission_pct,
            manager_id      = p_manager_id,
            department_id   = p_department_id
        WHERE employee_id   = p_employee_id;

        IF SQL%ROWCOUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Id #'||p_employee_id||  ' not found.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('ID #' || P_EMPLOYEE_ID|| ' updated.');
        END IF;
    END update_employee;

    PROCEDURE update_salary(
    --might need to update salary often so it has its own procedure
        p_employee_id IN employees.employee_id%type,
        p_new_salary  IN employees.salary%type 
        )IS
        BEGIN
            UPDATE EMPLOYEES
            SET
            salary = p_new_salary
            where employee_id = p_employee_id;

        END update_salary;
    PROCEDURE delete_employee(
        p_employee_id in employees.employee_id%type
    )IS
    BEGIN
        DELETE FROM EMPLOYEES
        WHERE employee_id = p_employee_id;
    END delete_employee;

    FUNCTION is_employee_exists (p_employee_id in employees.employee_id%type) return boolean
    is
    v_count number;
    begin
        select count(*)
        into v_count
        from employees
        where employee_id = p_employee_id;
        if sql%found then
            dbms_output.put_line('record exists. Returns True');
        else
           dbms_output.put_line('record does not exist. Returns False');
        end if;
    return v_count>0;
    end is_employee_exists;


    PROCEDURE read_all_employees IS
        v_emp_id employees.employee_id%type;
        v_last_name employees.last_name%type;
        v_salary employees.salary%type;
        v_job_id employees.job_id%type;
        v_department_id employees.department_id%type;
    BEGIN
        OPEN cur_employees_all;
        LOOP
            FETCH cur_employees_all into 
                --employee_id, last_name, job_id,salary,department_id
                v_emp_id,v_last_name,v_job_id,v_salary,v_department_id;
            EXIT WHEN cur_employees_all%notfound;
            DBMS_OUTPUT.PUT_LINE('ID: ' || v_emp_id || ', Name: ' || v_last_name ||
                            ', Job ID: ' || v_job_id || ', Salary: ' || v_salary ||'Department id: '||v_department_id);
            END LOOP;            
        CLOSE cur_employees_all;
    end read_all_employees;
    PROCEDURE read_employees_by_department_id(p_dept_id in employees.department_id%type)is
        CURSOR cur_employee is
            select employee_id,last_name,salary,job_id
            from employees
            where department_id = p_dept_id;
        
        v_employee_id       employees.employee_id%type;
        v_last              employees.last_name%type;
        v_salary            employees.salary%type;
        v_job_id            employees.job_id%type;
    BEGIN
        OPEN cur_employee;
        LOOP
            FETCH cur_employee INTO v_employee_id,v_last,v_salary,v_job_id;
            EXIT WHEN cur_employee%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE('ID: ' || v_employee_id || ' lname: ' || v_last||' salary: '|| v_salary|| ' job_id:'||v_job_id);
        END LOOP;
        CLOSE cur_employee;
    exception
        when others then
        dbms_output.put_line('error');
    
    end read_employees_by_department_id;
        
    

END employee1_pkg;
--end
--empid,first,last,email,phone_number,hire_date,job_id,salary,commission_pct_manager_id,department_id
--
/*
        p_first_name        IN employees.first_name%TYPE,
        p_last_name         IN employees.last_name%TYPE,
        p_email             IN employees.email%TYPE,
        p_phone_number      IN employees.phone_number%TYPE,
        p_hire_date         IN employees.hire_date%TYPE,
        p_job_id            in employees.job_id%TYPE,
        p_salary            IN employees.salary%TYPE,
        p_commission_pct    IN employees.commission_pct%TYPE,
        p_manager_id        IN employees.manager_id%TYPE,
        p_department_id     IN employees.department_id%TYPE
        */
set serveroutput on;
select * from employees order by employee_id desc;
--execute employee1_pkg.delete_employee();
EXECUTE employee1_pkg.add_employee('John','Doe','johndoe@johndoe.com','1234567890','03-JUN-24', 'HR_REP',700,0,105,10);
EXECUTE employee1_pkg.add_employee('Alice','Bob','AliceBob123@gmail.com','1231231231','25-DEC-99', 'IT_PROG',15000,0,null,10);
EXECUTE employee1_pkg.add_employee('Nazer','Zahir','timmothylikespears1@apple.com','9999999999','03-JUN-24', 'IT_PROG',4000,0,200,10);
EXECUTE employee1_pkg.add_employee('Celino','Barnes','celino.barnes@injuryattorneys.com','8008888888','03-JUN-24', 'SA_MAN',700,0,null,10);


--updates
execute employee1_pkg.update_employee(217,'John','Deer','johndeer@johndoe.com','1234567890','03-JUN-24', 'HR_REP',701,0,105,10);
execute employee1_pkg.update_employee(217,'John','Adams','johnadams@johndoe.com','1234567890','03-JUN-24', 'AD_VP',701,0,105,10);

--execute employee1_pkg.update_smart_update(217,'email','johnad--ams@apple.co-m--');
execute employee1_pkg.update_smart_update(217,'last_name',''appleseed');
select * from employees order by employee_id desc;

execute employee1_pkg.read_all_employees;
execute employee1_pkg.read_employees_by_department_id(10);


--create views


CREATE OR REPLACE VIEW employee_salary_percentile AS
SELECT
    employee_id,
    first_name,
    last_name,
    job_id,
    department_id,
    salary,
    ROUND(PERCENT_RANK() OVER (ORDER BY salary),2) AS salary_percentile
           
FROM 
    employees
order by salary;
CREATE OR REPLACE VIEW employee_salary_percentile_by_job AS
SELECT
    employee_id,
    first_name,
    last_name,
    job_id,
    salary,
    ROUND(PERCENT_RANK() OVER (PARTITION BY job_id ORDER BY salary),2) AS salary_percentile
FROM 
    employees
ORDER BY JOB_ID,salary;

SELECT * from employee_salary_percentile;
select * from employee_salary_percentile_by_job;