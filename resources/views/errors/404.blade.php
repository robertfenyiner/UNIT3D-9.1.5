<!DOCTYPE html>
<html lang="{{ config('app.locale') }}">
<head>
    <meta charset="UTF-8">
    <title>404 - Torrent no encontrado - {{ config('other.title') }}</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <link rel="shortcut icon" href="{{ url('/favicon.ico?v=' . filemtime(public_path('favicon.ico'))) }}" type="image/x-icon" />
    <link rel="icon" href="{{ url('/favicon.ico?v=' . filemtime(public_path('favicon.ico'))) }}" type="image/x-icon" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
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
            position: relative;
        }

        .matrix-line {
            animation: matrixGlitch 0.3s infinite;
        }

        @keyframes matrixGlitch {
            0% { color: #66ff66; }
            10% { color: #ff0000; transform: translateX(1px); }
            20% { color: #00ffff; transform: translateX(-1px); }
            30% { color: #ffff00; }
            40% { color: #ff00ff; transform: translateX(1px); }
            50% { color: #66ff66; }
            60% { color: #ff0000; transform: translateX(-1px); }
            70% { color: #00ffff; }
            80% { color: #ffff00; transform: translateX(1px); }
            90% { color: #ff00ff; }
            100% { color: #66ff66; transform: translateX(0); }
        }

        .glitch-text {
            position: relative;
            display: inline-block;
        }

        .glitch-text::before,
        .glitch-text::after {
            content: attr(data-text);
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
        }

        .glitch-text::before {
            animation: glitch-1 0.5s infinite;
            color: #ff0000;
            z-index: -1;
        }

        .glitch-text::after {
            animation: glitch-2 0.5s infinite;
            color: #00ffff;
            z-index: -2;
        }

        @keyframes glitch-1 {
            0%, 14%, 15%, 49%, 50%, 99%, 100% { 
                transform: translate(0);
            }
            15%, 49% { 
                transform: translate(-2px, -1px);
            }
        }

        @keyframes glitch-2 {
            0%, 20%, 21%, 62%, 63%, 99%, 100% { 
                transform: translate(0);
            }
            21%, 62% { 
                transform: translate(2px, 1px);
            }
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
            <span class="glitch-text" data-text="[DHT] Inicializando búsqueda de pares...">[DHT] Inicializando búsqueda de pares...</span>
        </div>
    </div>

    <script>
        // Aplicar efecto glitch inmediatamente al texto inicial
        document.addEventListener('DOMContentLoaded', function() {
            const initialGlitch = document.querySelector('.glitch-text');
            if (initialGlitch) {
                // Forzar animación del texto inicial
                setInterval(() => {
                    if (Math.random() > 0.7) {
                        initialGlitch.style.animation = 'none';
                        setTimeout(() => {
                            initialGlitch.style.animation = '';
                        }, 50);
                    }
                }, 1000);
            }
        });

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
            "[DHT] ERROR: Operación fallida."
        ];

        let i = 0;
        const log = document.getElementById('dht-log');

        // Función para crear caracteres aleatorios (efecto Matrix)
        function getRandomChar() {
            const chars = '01234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!@#$%^&*()[]{}|;:,.<>?';
            return chars[Math.floor(Math.random() * chars.length)];
        }

        // Función para aplicar efecto Matrix a un texto
        function matrixEffect(text, element) {
            let iterations = 0;
            
            const interval = setInterval(() => {
                const result = text.split('').map((char, index) => {
                    if (index < iterations) {
                        return text[index];
                    }
                    return getRandomChar();
                }).join('');
                
                element.textContent = result;
                
                if (iterations >= text.length) {
                    clearInterval(interval);
                    // Agregar clase para efecto de glitch ocasional
                    if (Math.random() > 0.6) {
                        element.classList.add('matrix-line');
                        setTimeout(() => {
                            element.classList.remove('matrix-line');
                        }, 500);
                    }
                }
                
                iterations += 0.5;
            }, 30);
        }

        const mainInterval = setInterval(() => {
            if (i < mensajes.length) {
                const newLine = document.createElement('div');
                
                // Aplicar efecto Matrix al mensaje
                matrixEffect(mensajes[i], newLine);
                
                log.appendChild(newLine);
                log.scrollTop = log.scrollHeight;
                i++;
            } else {
                clearInterval(mainInterval);
                
                // Efecto final de error crítico
                setTimeout(() => {
                    const errorLine = document.createElement('div');
                    errorLine.innerHTML = '<span class="glitch-text" data-text="[CRITICAL ERROR] Sistema comprometido">[CRITICAL ERROR] Sistema comprometido</span>';
                    errorLine.style.color = '#ff0000';
                    errorLine.style.fontWeight = 'bold';
                    log.appendChild(errorLine);
                    log.scrollTop = log.scrollHeight;
                }, 1000);
            }
        }, 1200);

        // Efecto de parpadeo ocasional en todo el log
        setInterval(() => {
            if (Math.random() > 0.85) {
                log.style.opacity = '0.3';
                setTimeout(() => {
                    log.style.opacity = '1';
                }, 100);
            }
        }, 2000);
    </script>
</body>
</html>
