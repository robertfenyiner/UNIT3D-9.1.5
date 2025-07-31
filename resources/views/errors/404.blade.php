<!DOCTYPE html>
<html lang="{{ config('app.locale') }}">
<head>
    <meta charset="UTF-8">
    <title>404 - Torrent no encontrado - {{ config('other.title') }}</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <link rel="shortcut icon" href="{{ url('/favicon.ico?v=' . filemtime(public_path('favicon.ico'))) }}" type="image/x-icon" />
    <link rel="icon" href="{{ url('/favicon.ico?v=' . filemtime(public_path('favicon.ico'))) }}" type="image/x-icon" />
    <style>
        body {
            background: linear-gradient(135deg, #1e1e1e 0%, #2d2d2d 100%);
            color: #ddd;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            text-align: center;
            margin: 0;
            padding: 1rem;
        }

        .container {
            max-width: 800px;
            padding: 2rem;
            background: rgba(45, 45, 45, 0.8);
            border-radius: 15px;
            box-shadow: 0 0 30px rgba(255, 85, 85, 0.3);
            backdrop-filter: blur(10px);
        }

        .logo {
            width: 200px;
            margin-bottom: 1.5rem;
            filter: drop-shadow(0 0 15px #ff5555);
        }

        h1 {
            font-size: 3.5rem;
            margin-bottom: 0.5rem;
            color: #ff5555;
            text-shadow: 0 0 10px rgba(255, 85, 85, 0.5);
        }

        h2 {
            font-size: 1.3rem;
            color: #888;
            margin-bottom: 1.5rem;
        }

        p {
            font-size: 1rem;
            max-width: 600px;
            margin: 0 auto 1.5rem;
            line-height: 1.6;
        }

        .magnet {
            margin: 1.5rem 0;
            background-color: #2d2d2d;
            padding: 1rem 2rem;
            border-radius: 10px;
            font-family: 'Courier New', monospace;
            color: #66ff66;
            font-size: 0.9rem;
            border: 1px solid #444;
        }

        .buttons {
            display: flex;
            gap: 1rem;
            flex-wrap: wrap;
            justify-content: center;
            margin: 2rem 0;
        }

        .btn {
            background: linear-gradient(45deg, #ff5555, #ff3333);
            color: white;
            padding: 0.75rem 1.5rem;
            border: none;
            border-radius: 8px;
            font-size: 1rem;
            cursor: pointer;
            text-decoration: none;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(255, 85, 85, 0.3);
        }

        .btn:hover {
            background: linear-gradient(45deg, #ff3333, #ff1111);
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(255, 85, 85, 0.5);
        }

        .btn-secondary {
            background: linear-gradient(45deg, #555, #333);
        }

        .btn-secondary:hover {
            background: linear-gradient(45deg, #333, #111);
        }

        .dht-log {
            margin-top: 1.5rem;
            background-color: #111;
            padding: 1rem;
            width: 100%;
            max-width: 600px;
            height: 120px;
            overflow: hidden;
            border-radius: 8px;
            font-family: 'Courier New', monospace;
            font-size: 0.9rem;
            color: #66ff66;
            box-shadow: inset 0 0 10px rgba(0, 0, 0, 0.5);
            border: 1px solid #333;
        }

        @media (max-width: 768px) {
            h1 { font-size: 2.5rem; }
            .buttons { flex-direction: column; align-items: center; }
            .btn { width: 200px; }
        }
    </style>
</head>
<body>
    <div class="container">
        <img src="{{ url('/img/logo.png') }}" alt="{{ config('other.title') }}" class="logo">

        <h1>404 - Torrent perdido en la red</h1>
        <h2>Este magnet no tiene *seeders*... 🧲</h2>

        <p>
            El archivo que buscas ha sido eliminado, renombrado o nunca existió.<br>
            Ni siquiera DHT lo ha encontrado...
            @if($exception->getMessage())
                <br><br><strong>Error:</strong> {{ $exception->getMessage() }}
            @endif
        </p>

        <div class="magnet">
            magnet:?xt=urn:btih:4044044044044044044044044044044044044044
        </div>

        <div class="buttons">
            <a href="{{ route('home.index') }}" class="btn">
                <i class="fas fa-home"></i> Volver al tracker
            </a>
            <a href="javascript:location.reload()" class="btn btn-secondary">
                <i class="fas fa-redo"></i> Intentar de nuevo
            </a>
            <a href="{{ route('tickets.create') }}" class="btn btn-secondary">
                <i class="fas fa-bug"></i> Reportar problema
            </a>
        </div>

        <div class="dht-log" id="dht-log">
            [DHT] Inicializando búsqueda de pares...
        </div>
    </div>

    <script>
        const mensajes = [
            "[DHT] Buscando pares...",
            "[DHT] Conectando con nodo 10.7.3.42...",
            "[DHT] Enviando solicitud find_node...",
            "[DHT] Sin respuesta, reintentando...",
            "[DHT] Nodo 78.14.89.202 inalcanzable...",
            "[DHT] Consultando nodo bootstrap...",
            "[DHT] Hash del magnet no encontrado...",
            "[DHT] Aún buscando en la red...",
            "[DHT] 0 seeders detectados...",
            "[DHT] Tiempo de espera agotado...",
            "[DHT] Operación fallida."
        ];

        let i = 0;
        const log = document.getElementById('dht-log');

        const interval = setInterval(() => {
            if (i < mensajes.length) {
                log.innerHTML += `<br>${mensajes[i++]}`;
                log.scrollTop = log.scrollHeight;
            } else {
                clearInterval(interval);
            }
        }, 1200);
    </script>
</body>
</html>
