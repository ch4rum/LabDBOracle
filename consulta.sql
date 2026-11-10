SELECT XMLSERIALIZE(DOCUMENT
         XMLELEMENT("departamentos",
           XMLAGG(
             XMLELEMENT("departamento",
               XMLATTRIBUTES(d.department_id AS "id", d.department_name AS "nombre"),
               (SELECT XMLAGG(
                         XMLELEMENT("empleado",
                           XMLATTRIBUTES(e.employee_id AS "id"),
                           XMLFOREST(e.first_name AS "nombre",
                                     e.last_name  AS "apellido",
                                     e.salary     AS "salario"))
                         ORDER BY e.employee_id)
                  FROM employees e
                 WHERE e.department_id = d.department_id)
             ) ORDER BY d.department_id
           )
         )
         AS CLOB INDENT SIZE = 2) AS xml
FROM departments d
WHERE d.department_id IN (10, 20, 30);