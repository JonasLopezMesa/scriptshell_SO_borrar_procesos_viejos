#!/bin/sh
#COLOCAR TODOS LOS USUARIOS EN UN VECTOR======================================================================================================================================
ps aux | tr -s " " " " > usuarios #mete en el archivo usuarios todos los procesos y borra las repeticiones de espacios que hay
u1=`cut -d" " -f1 usuarios | sort -n -k1 -t" "`; #mete en la variable u1 todos los nombres de usuarios que estan logeados en ese momento, y los ordena por nombre
usuarios=( `echo $u1 | tr '\n' ' ' `) #guarda en un vector todos los usuarios aunque esten repetidos
wc -l `find . -iname "usuarios"` > nume #Cuenta el número de procesos que está ejecutando el sistema y lo guarda en el fichero nume
num=`cut -d . -f1 nume`; #se almacena el número de procesos que está ejecutando el sistema en la variable num (11)
#COMPARAR EL VECTOR PARA SACAR TODOS LOS USUARIOS Y METERLOS EN OTRO VECTOR===================================================================================================
for(( a=0; a<=(num-1); a++ )); do #se itera tantas veces como procesos haya
    h[a]=" "; #se le da a la variable h el valor " " (19)
done
im="0"
i="1"
b=${h[i]}; #se almacena h[] que es " " en b
for(( i=1; i<=(num-1); i++ )); do #se itera para todos los procesos
    a=${usuarios[i]}; #se guarda en la variable a el primer usuario
    if [ "$b" != "$a" ]; then #se compara si b es distinto de a
        im="$im+1"; #si es distinto se incrementa im
        b=$a; #se guarda a en b
        h[im]=$b; #se guarda b en el vector h, al final h contiene todos los usuarios, sin repeticiones
    fi 
done
#BUSCAR EL PROCESO QUE MAS TIEMPO HA ESTADO EJECUTANDOSE POR CADA USUARIO. Y EL NÚMERO DE PROCESOS POR USUARIO.===============================================================
i="1" #declaración de variables para iteraciones
r="1"
l=" "
tc="1"
while [ "${h[i]}" != "$l" ]; do #mientras h devuelva el nombre de un usuario
    ps -U "${h[i]}" | tr -s " " " " > lista1 #se almacena en lista1 todos los procesos que está ejecutando h[i]
    wc -l `find . -iname "lista1"` > procesos1 #se cuenta el número de procesos que está ejecutando h[i]
    p1=`cut -d . -f1 procesos1`; #se almacena en la variable p1.
    p1=`expr $p1 - 1`; #se resta uno para descontar la cabecera
    numero[r]=$p1; #se guarda en numero[r] que representará el número de procesos por usuario
    r=$r+1 #incrementa r 
    tiempototales=0 #define una variable que almacenará
    for tiempos in $(ps -U "${h[i]}" | tr -s ' ' '%' | cut -d'%' -f4 | sort | tr -s '%' ' ') #ordena todos los tiempos de todos los procesos de los usuarios de menor a mayor
        do
        minutos=`echo $tiempos |cut -d":" -f1` #almacena los minutos de esos tiempos en minutos
            if [ "$minutos" != "TIME" ] && [ "$minutos" != "/*" ]; then #para evitar errores, si minutos no es TIME ni cualquier cosa que empieze por / hace lo siguiente
                segundos=`echo $tiempos |cut -d":" -f2 |cut -d"." -f1` #almacena en segundos los segundos de ese tiempo
                segundos2=`echo $tiempos |cut -d":" -f2 |cut -d"." -f2` #almacena en segundos2 los decimales de ese segundo
                ttot=$tiempototales #almacena en ttot los tiempos totales
                tiempototales=`expr $ttot + $minutos "*" 60 + $segundos + $segundos2 "/" 100` #almacena en tiempototales la suma de todos los segundos
            fi
    done
    antiguo=`ps -u "${h[i]}" -f | tr -s ' ' '%' | cut -d'%' -f5 | sort | tr -s '%' ' ' | cut -d" " -f1` #ordena de más antiguo a menos antiguo todos los procesos y muestra 
                                                                                                        #solo la hora que se ejecutó el proceso
    if [ "$antiguo" != "STIME" ]; then #para evitar errores, si antiguo no es STIME, hace lo siguiente
        ant1=( `echo $antiguo | tr '\n' ' ' `) #almacena en ant1 la antiguedad de todos los procesos de ese usuario
        echo "$tiempototales\t\t${numero[i]}\t\t${ant1[0]}\t${h[i]}" $endl >> Archivo #vuelca en Archivo toda la información: el tiempo total, el número de procesos, el 
                                                                                        #proceso mas viejo, y el nombre del usuario
    else #sino, hace lo mismo, pero almacenando el siguiente de ant1 para que no muestre STIME
        ant1=( `echo $antiguo | tr '\n' ' ' `)
        echo "$tiempototales\t\t${numero[i]}\t\t${ant1[1]}\t\t${h[i]}" $endl >> Archivo
    fi
    i=$i+1
done
echo "Tiempo total   Nº de Procesos\tAntiguo\tNombre de usuario" $endl
sort -n -r Archivo #muestra todos los procesos ordenados de los que mas tiempo de CPU han consumido a los que menos tiempo de CPU han cosumido
#AVISAR AL USUARIO QUE SE HA PASADO DEL LÍMITE DE PROCESOS.===================================================================================================================
if [ "$1" == "-inf" ];then #si el primer parámetro es -inf
    i="1"
    l=" "
    while [ "${h[i]}" != "$l" ]; do #mientras haya usuarios que mostrar
        nu=${numero[i]};
        if (( "$nu" > "$2" ));then #si el número de procesos es mayor que el segundo parámetro, se hace lo siguiente
            echo HAS SUPERADO EL LÍMITE DE $2 PROCESOS QUE PODÍAS TENER. | write "${h[i]}" #se envía una señal al usuario que ha sobrepasado el límite
        fi
        i=$i+1
    done
fi
#MATAR PROCESOS DE FORMA ALEATORIA SI SE HA PASADO DE UN RANGO DETERMINADO.===================================================================================================
if [ "$1" == "-Kill" ];then #si el primer parámetro es -Kill
    i="1"
    l=" "
    while [ "${h[i]}" != "$l" ]; do #mientras haya usuarios que mostrar
        if [ "${h[i]}" != "root" ];then #si el usuario no es root, para que no haya fallos grandes (apagarse el equipo, etc)
            x="0"
            nu2=${numero[i]}; #almacenamos el número de procesos de ese usuario en nu2
            pid=$(ps -U "${h[i]}" | tr -s ' ' '%' | cut -d '%' -f2 | tr -s '%' ' '| sort -R ) #almacenamos en pid todos pos PID de los procesos que ejecuta ese usuario
            killed=( `echo $pid | tr '\n' ' ' `) #se almacena en el vector killed los procesos uno a uno de ese usuario
            while [ "$nu2" -ge "$2" ]; do #mientras el usuario esté sobrepasando el límite de procesos
                kill -9 ${killed[x]} #se mata a un proceso
                ((nu2--))
                echo se han borrado "$x" procesos del usuario "${h[i]}"
                ((x++))
            done
        else
            echo EL USUARIO ES ROOT Y NO ES CONVENIENTE BORRAR PROCESOS DE ROOT ALEATORIAMENTE
        fi
        ((i++))
    done
fi
rm Archivo procesos1 lista1 nume usuarios #se borran los archivos usados.
