# UberMotor Frontend

Frontend Flutter de **UberMotor** (moto-ride). Replica la arquitectura y
prácticas de **Comanda** (`app-front-comanda`): feature-first + capas.

## Estructura

```
lib/
├── main.dart               # _Portero: decide home según tipo_usuario
├── core/                   # theme, network, config, navigation
├── features/
│   ├── auth/               # login/registro (3 perfiles)
│   ├── conductor/          # home, saldo, viajes disponibles, recarga
│   ├── cliente/            # pedir viaje
│   └── admin/              # shell + dashboard + paquetes
├── models/                 # sesion, conductor, viaje, paquete
├── providers/              # auth, conductor (ChangeNotifier)
└── services/               # auth, conductor, viaje, cliente
```

## Regla de negocio (saldo prepago diario)

- Paquetes: 2 soles = 5 carreras | 4 soles = 10 carreras | 8 soles = 20 carreras.
- El saldo es por día, no acumulable.
- Cliente cancela → se devuelve la carrera. Conductor rechaza 3 → -1 saldo.
- Tarifa mínima 3 soles (Yape/efectivo al conductor).

Detalle en `docs/analisis_modelo.md` del repo backend.
