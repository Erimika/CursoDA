DROP DATABASE IF EXISTS transactions;
CREATE DATABASE transactions;
USE transactions;
    -- Creamos la tabla company
    CREATE TABLE IF NOT EXISTS company (
        id VARCHAR(15) PRIMARY KEY,
        company_name VARCHAR(255),
        phone VARCHAR(15),
        email VARCHAR(100),
        country VARCHAR(100),
        website VARCHAR(255)
    );
    -- Creamos la tabla transaction
    CREATE TABLE IF NOT EXISTS transaction (
        id VARCHAR(255) PRIMARY KEY,
        credit_card_id VARCHAR(15) REFERENCES credit_card(id),
        company_id VARCHAR(15), 
        user_id INT REFERENCES user(id),
        lat FLOAT,
        longitude FLOAT,
        timestamp TIMESTAMP,
        amount DECIMAL(10, 2),
        declined BOOLEAN,
        FOREIGN KEY (company_id) REFERENCES company(id) 
    );

-- Cargar los datos 
-- SOURCE dades_introduir_sprint2.sql;
-- ----------------------------------------------------
-- CONSULTAS
-- ----------------------------------------------------
-- NIVEL 1.2 JOINS
-- -- 1. Paises con ventas
 SELECT DISTINCT c.country as Paises
 FROM company c
 LEFT JOIN transaction t
	ON c.id = t.company_id
    WHERE t.declined = 0;
    
-- -- 2. Cantidad de paises con ventas
 SELECT COUNT(DISTINCT c.country) as Cantidad_paises
 FROM company c
 LEFT JOIN transaction t
	ON c.id = t.company_id
    WHERE t.declined = 0;
    
 -- -- 3. Empresa con cantidad mas grande de ventas
SELECT DISTINCT c.company_name as Nombre, AVG(amount) as Media_ventas
 FROM company c
 LEFT JOIN transaction t
	ON c.id = t.company_id
GROUP BY Nombre
ORDER BY Media_ventas DESC
LIMIT 1;

-- NIVEL 1.3 SUBQUERIES
-- -- 1. Transacciones realizadas por empresas de Alemania
SELECT t.id as Transacciones_Alemania
FROM transaction t 
WHERE EXISTS (
	SELECT c.id
    FROM company c
    WHERE t.company_id = c.id 
    AND country = "Germany"
    );
    
-- -- 2. Empresas con transacciones con amount superior a la media 
SELECT c.company_name as Empresa
FROM company c 
WHERE EXISTS (
	SELECT t.company_id
    FROM transaction t 
    WHERE t.company_id = c.id
    AND amount > (
		SELECT AVG(amount)
        FROM transaction t 
        )
	);
    
-- -- 3. Empresas sin transacciones registradas
SELECT c.company_name as Empresa
FROM company c
WHERE NOT EXISTS(
	SELECT 1
    FROM transaction t 
    WHERE t.company_id = c.id
    );
    
-- NIVEL 2
-- -- 1. Cinco dias con más ingresos por ventas
SELECT suma_ventas.dias as Dias, MAX(suma_ventas.Ventas) as max_ventas, c.company_name as Empresa
FROM (
	SELECT SUM(t.amount) as Ventas, t.company_id, DATE(t.timestamp) as dias, t.declined
    FROM transaction t 
    GROUP BY 2,3,4
    ) suma_ventas
JOIN company c
ON c.id = suma_ventas.company_id 
WHERE suma_ventas.declined = 0
GROUP BY 3,1
ORDER BY 2 DESC
LIMIT 5;

-- -- 2. Media de cantidad de ventas por pais
SELECT c.country as Pais, ROUND(AVG(Ventas)) as Media_ventas
FROM company c 
JOIN (
	SELECT t.company_id, COUNT(*) as Ventas
	FROM transaction t
    GROUP BY 1
    ) sub 
ON c.id = sub.company_id
GROUP BY 1
ORDER BY 2 DESC;

-- -- 3. Listado de transacciones hechas por empresas en el mismo pais que Non Institute
-- Listado aplicando JOIN y subconsultas.
SELECT c.company_name as Empresa, t.id as Transacciones
FROM transaction t
JOIN company c 
ON c.id = t.company_id
WHERE c.country = (
	SELECT c.country
    FROM company c
    WHERE company_name = 'Non Institute'
    )
AND c.company_name != 'Non Institute';

-- Listado aplicando únicamente subconsultas.
SELECT (SELECT c.company_name
	FROM company c 
    WHERE c.id=t.company_id) as Empresa, t.id as Transacciones
FROM transaction t
WHERE ( SELECT c.country 
	FROM company c 
    WHERE c.id = t.company_id) = (
		SELECT c.country
		FROM company c
		WHERE company_name = 'Non Institute'
		)
AND (SELECT c.company_name
	FROM company c 
    WHERE c.id = t.company_id) != 'Non Institute'
    ;
    
-- NIVEL 3
-- -- 1. Datos de las empresas con transacciones entre 350 y 400 €, realizadas en dias concretos.
SELECT c.company_name as Empresa, c.phone as Telefono, c.country as Pais, t.timestamp as Dia, t.amount as Cantidad
FROM company c
JOIN transaction t
ON c.id=t.company_id
WHERE t.id IN (
	SELECT t.id
    FROM transaction t 
	WHERE DATE(t.timestamp) IN ('2015-04-29','2018-07-20','2024-03-13')
    )
AND t.amount BETWEEN 350 AND 400
ORDER BY 5 DESC;

-- -- 2. Empresas con 400 transacciones o menos.
SELECT c.company_name as Empresa, COUNT(t.id) as Transacciones
FROM transaction t 
JOIN company c 
ON c.id=t.company_id
GROUP BY 1
HAVING COUNT(t.id) <= 400
;
