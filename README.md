
# Tarea 1
## CC5308 - Administración de Sistemas Linux

### Modo de juego

Primero hay que asegurarse de que los scripts sean ejecutables, para esto, se puede ejecutar el siguiente comando:
```bash
chmod +x board.sh controller.sh game.sh
```

Luego, opcionalmente se puede configurar donde se creará el tablero mediante una variable de entorno, pero no es necesario ya que si no se hace se utilizará `./board` por defecto:
```bash
export BOARD_DIR='./alt_board'
```

Finalmente, se puede ejecutar el juego, pasando los parametros de creación del tablero y el modo de juego como argumentos en la linea de comando:
```bash
./game.sh <depth> <width> <files> <mode>
```

Es necesario que los 4 archivos de la tarea (board.sh, controller.sh, game.sh y common.sh) se encuentren en el working directory de la shell, de no ser así el juego no va a funcionar.

### Detalles de implementación

El nombramiento de los directorios se hace con números enteros consecutivos comenzando por el 1, mientras que los nombres de los archivos se generan con 10 caracteres aleatorios, luego se llenan con un número aleatorio, entre 100 y 300, de caracteres aleatorios, y se realiza el post-procesado que corresponda.

Todo lo correspondiente al estado del juego se almacena en el sub-directorio `.meta/` dentro del directorio del tablero, esto incluye el modo de juego actual y las variables que correspondan a cada modo, como las llaves de ssl o la passphrase de encriptación.

Por otro lado, la firma de cada archivo se guarda como un archivos oculo en el mismo directo del archivo original, utlizando el mismo nombre pero con un punto al inicio y la extensión `.sig`, por ejemplo, el archivo `board/1/2/3/abcde` tendría su firma en `board/1/2/3/.abcde.sig`, esto solo aplica al modo de juego 'signed', para detalles de implementación se puede revisar la función `_signature_path` en `common.sh`.


