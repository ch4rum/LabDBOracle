BEGIN EXECUTE IMMEDIATE 'DROP TABLE hr_pruebas_xml PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE hr_departamentos_xml PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN DBMS_XMLSCHEMA.deleteSchema('http://localhost/hr/departamentos.xsd', DBMS_XMLSCHEMA.DELETE_CASCADE_FORCE); EXCEPTION WHEN OTHERS THEN NULL; END;
/

DECLARE
  v_xsd VARCHAR2(4000) := q'[<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified">
  <xs:element name="departamentos">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="departamento" maxOccurs="unbounded">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="empleado" minOccurs="0" maxOccurs="unbounded">
                <xs:complexType>
                  <xs:sequence>
                    <xs:element name="nombre"   type="xs:string"/>
                    <xs:element name="apellido" type="xs:string"/>
                    <xs:element name="salario"  type="xs:decimal"/>
                  </xs:sequence>
                  <xs:attribute name="id" type="xs:positiveInteger" use="required"/>
                </xs:complexType>
              </xs:element>
            </xs:sequence>
            <xs:attribute name="id"     type="xs:positiveInteger" use="required"/>
            <xs:attribute name="nombre" type="xs:string"          use="required"/>
          </xs:complexType>
        </xs:element>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>]';
BEGIN
  DBMS_XMLSCHEMA.registerSchema(
    schemaurl => 'http://localhost/hr/departamentos.xsd',
    schemadoc => v_xsd,
    local     => TRUE,
    gentypes  => FALSE,
    gentables => FALSE,
    options   => DBMS_XMLSCHEMA.REGISTER_BINARYXML);
END;
/

CREATE TABLE hr_departamentos_xml (
  id  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  doc XMLTYPE
) XMLTYPE COLUMN doc STORE AS BINARY XML
  XMLSCHEMA "http://localhost/hr/departamentos.xsd" ELEMENT "departamentos";

CREATE OR REPLACE PROCEDURE insertar_departamentos(p_xml IN CLOB) IS
  v_doc XMLTYPE;
BEGIN
  v_doc := XMLTYPE(p_xml, 'http://localhost/hr/departamentos.xsd');
  v_doc.schemaValidate();
  INSERT INTO hr_departamentos_xml (doc) VALUES (v_doc);
END;
/

CREATE TABLE hr_pruebas_xml (
  caso      VARCHAR2(60),
  resultado VARCHAR2(10),
  detalle   VARCHAR2(600)
);

CREATE OR REPLACE PROCEDURE probar_caso(p_caso IN VARCHAR2, p_xml IN CLOB) IS
  v_err VARCHAR2(600);
BEGIN
  insertar_departamentos(p_xml);
  INSERT INTO hr_pruebas_xml VALUES (p_caso, 'ACEPTADO', NULL);
EXCEPTION WHEN OTHERS THEN
  v_err := SUBSTR(SQLERRM, 1, 600);
  INSERT INTO hr_pruebas_xml VALUES (p_caso, 'RECHAZADO', v_err);
END;
/

BEGIN
  probar_caso('1. XML conforme',
    '<departamentos>
       <departamento id="10" nombre="Administration">
         <empleado id="200">
           <nombre>Jennifer</nombre><apellido>Whalen</apellido><salario>4400</salario>
         </empleado>
       </departamento>
     </departamentos>');
END;
/
BEGIN
  probar_caso('2. Salario no numerico',
    '<departamentos>
       <departamento id="10" nombre="Administration">
         <empleado id="200">
           <nombre>Jennifer</nombre><apellido>Whalen</apellido><salario>mucho</salario>
         </empleado>
       </departamento>
     </departamentos>');
END;
/
BEGIN
  probar_caso('3. Falta atributo nombre',
    '<departamentos>
       <departamento id="10">
         <empleado id="200">
           <nombre>Jennifer</nombre><apellido>Whalen</apellido><salario>4400</salario>
         </empleado>
       </departamento>
     </departamentos>');
END;
/

COMMIT;

SELECT caso, resultado, detalle FROM hr_pruebas_xml;
SELECT id, XMLISVALID(doc) AS conforme FROM hr_departamentos_xml;
SELECT id, XMLSERIALIZE(DOCUMENT doc AS CLOB INDENT SIZE = 2) AS doc FROM hr_departamentos_xml;