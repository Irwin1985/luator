# Luator

## Es una pequeña calculadora que hice para aprender el lenguaje de
programación [Lua](https://www.lua.org/).


Al decir **Calculadora** se tiende a pensar en un ejercicio muy simple pero
déjame resumirte todo el proceso que tiene que ejecutarse antes de evaluar
una expresión aritmética como `1 + 2`

## Lexer

También llamado `Analizador léxico`, se encarga de leer uno a uno los
caracteres de entrada y formar pequeñas unidades llamadas `tokens` que serán
la entrada para el siguiente proceso.

**En resumen:** el `Lexer` toma como entrada un montón de caracteres y forma una
colección de token con ellos.

Por ejemplo si el lexer tomase como entrada `1 + 2 - 3 * 4 / 5` produciría los
siguientes tokens:

| Número | Token | Lexema |
| ------ | ----- | ------ |
|   1    | NUMBER | 1 |
|   2    | PLUS | + |
|   3    | NUMBER | 2 |
|   4    | MINUS | - |
|   5    | NUMBER | 3 |
|   6    | MUL | * |
|   7    | NUMBER | 4 |
|   8    | DIV | / |
|   9    | NUMBER | 5 |

## Parser

También llamado `Analizador sintáctico` porque se encarga de aplicar las
reglas gramaticales sobre el stream de token que el `lexer` ha recuperado
del código fuente. Si el stream de tokens no cumple con la gramática de la
calculadora _(o cualquier otra gramática)_ entonces se interrumple el proceso.

**En resumen:** el `Parser` toma como entrada el stream de tokens y genera como
salida un `Árbol de sintaxis abstracta` o `AST`.

Por ejemplo si el lexer provee el stream de tokens de la tabla anterior, el 
`parser` generaría el siguiente `AST`.

								  (-)
								  / \
								 /   \
								/     \
							   /       \
							  (+)      (/)
							  / \      / \ 
							(1) (2)  (*)  5
									 / \
								   (3) (4)

## Intérprete

También llamado `Evaluador` porque se encarga de recorrer todo el `AST` que ha
generado el `Parser` con el objetivo de `Evaluar` el contenido de cada uno de
los `nodos` contenidos en el árbol.

En resumen: el `Evaluador` toma como entrada el `AST` y produce el equivalente
semántico del árbol, es decir, el resultado de la operación.

Por el ejemplo si el Intérprete recibe el `AST` del ejemplo anterior entonces
produciría como salida: `0.6`
