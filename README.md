# Instrucciones

Empieza por ejecutar ``loadkeys es`` para cargar la configuración de teclado.

## Descarga y Ejecución

```
pacman -Sy git
git clone https://github.com/Roboron3042/archinstall
cd archinstall
./1-prepare.sh
```

El resto de instrucciones están contenidas en el script.

## Conexi

Si no tienes conexión a Internet, deberás configurar el Wi-Fi antes.
```
iwctl device list
iwctl station DISPOSITIVO scan
iwctl station DISPOSITIVO get-networks
iwctl station DISPOSITIVO connect SSID
```

