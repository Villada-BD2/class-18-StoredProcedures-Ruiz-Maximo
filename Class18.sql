/*
Write a function that returns the amount of copies of a film in a store in sakila-db. 
Pass either the film id or the film name and the store id.
 */

#Act 1

DELIMITER //

CREATE FUNCTION copias_en_tienda(
    p_film_id INT,
    p_store_id INT
)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_copias INT;

    SELECT COUNT(*)
    INTO v_copias
    FROM inventory
    WHERE film_id = p_film_id
      AND store_id = p_store_id;

    RETURN v_copias;
END //

DELIMITER ;

#Cant de copias tienda 1
SELECT copias_en_tienda(1, 1);

#Muestro la cant de copias
SELECT copias_en_tienda(1, 2) AS total_copias;


#Act 2
/*
Write a stored procedure with an output parameter that contains a list of customer first and last names 
separated by ";", that live in a certain country. 
You pass the country it gives you the list of people living there. 
USE A CURSOR, do not use any aggregation function (ike CONTCAT_WS.
 */

DELIMITER //

CREATE PROCEDURE clientes_por_pais(
    IN p_country VARCHAR(50),
    OUT p_customer_list TEXT
)
BEGIN
    DECLARE v_nombre VARCHAR(45);
    DECLARE v_apellido VARCHAR(45);
    DECLARE v_hecho BOOLEAN DEFAULT FALSE;

    DECLARE customer_cursor CURSOR FOR
        SELECT c.nombre, c.apellido
        FROM customer AS c
        INNER JOIN address AS a
            ON c.address_id = a.address_id
        INNER JOIN city AS ci
            ON a.city_id = ci.city_id
        INNER JOIN country AS co
            ON ci.country_id = co.country_id
        WHERE co.country = p_country
        ORDER BY c.apellido, c.nombre;

    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET v_hecho = TRUE;

    SET p_customer_list = '';

    OPEN customer_cursor;

    read_loop: LOOP
        FETCH customer_cursor
        INTO v_nombre, v_apellido;

        IF v_hecho THEN
            LEAVE read_loop;
        END IF;

        IF p_customer_list = '' THEN
            SET p_customer_list =
                CONCAT(v_nombre, ' ', v_apellido);
        ELSE
            SET p_customer_list = CONCAT(
                p_customer_list,
                ';',
                v_nombre,
                ' ',
                v_apellido
            );
        END IF;
    END LOOP;

    CLOSE customer_cursor;
END //

DELIMITER ;



#ACt 3

/*
Review the function inventory_in_stock and the procedure film_in_stock explain the code, 
write usage examples.
 */

SHOW CREATE FUNCTION inventory_in_stock;

#El codigo es:

CREATE FUNCTION inventory_in_stock(
    p_inventory_id INT
)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
	#Declara variables
    DECLARE v_rentals INT;
    DECLARE v_out INT;
	
	#Cuenta todas las filas en rental filtrnado por el id del inventario y guarda eso en v_rentals(variable antes definida)
    SELECT COUNT(*)
    INTO v_rentals
    FROM rental
    WHERE inventory_id = p_inventory_id;

	#Si no tiene rentas seria de q está disponible, entonces devuelve true.
    IF v_rentals = 0 THEN
        RETURN TRUE;
    END IF;

	
	#Se revisa si es que existe un alquiler q no tenga fecha de devolucion
    SELECT COUNT(rental_id)
    INTO v_out
    FROM inventory
    LEFT JOIN rental USING (inventory_id) #Este using seria lo mismo q hacer unir las 2 tablas por el inventory_id
    WHERE inventory.inventory_id = p_inventory_id
      AND rental.return_date IS NULL;

	
	#Esto seria de que si existe un alquiler que está pendiente, q devuelva false
    IF v_out > 0 THEN
        RETURN FALSE;
    ELSE
    	#Si no, devuelve true.
        RETURN TRUE;
    END IF;
END;


#Query para ver los resultados llamando a la funcion
SELECT
    inventory_id,
    inventory_in_stock(inventory_id) AS disponible
FROM inventory
LIMIT 10;


#Ver procedimiento
SHOW CREATE PROCEDURE film_in_stock;


#codigo del procedimiento
CREATE PROCEDURE film_in_stock(
    IN p_film_id INT,
    IN p_store_id INT,
    OUT p_film_count INT
)
READS SQL DATA
BEGIN
	#Esto hace varias cosas:
	#Primero busca las copias de la peli q pasamos.
	#Segundo filtra las copias q pertenecen a la tienda.
	#Tercero ejecuta la funcion de antes para que queden solamente las copias que estan disponibles.
    SELECT inventory_id
    FROM inventory
    WHERE film_id = p_film_id
      AND store_id = p_store_id
      AND inventory_in_stock(inventory_id);

	
	#Esto agarra el numero de filas q devolvio el select y lo guarda en p_film_count q seria lo q va a devolver la funcion
    SELECT FOUND_ROWS()
    INTO p_film_count;
END;


CALL film_in_stock(1, 1, @count);

SELECT @count AS copias_disponibles;
