<!DOCTYPE html>
<html lang="{{ config('app.locale') }}">
<head>
    <meta charset="UTF-8">
    <title>503 - Tracker en Mantenimiento - {{ config('other.title') }}</title>
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
            box-shadow: 0 0 30px rgba(255, 165, 0, 0.3);
            backdrop-filter: blur(10px);
        }

        .logo {
            width: 200px;
            margin-bottom: 1.5rem;
            filter: drop-shadow(0 0 15px #ffa500);
        }

        h1 {
            font-size: 3.5rem;
            margin-bottom: 0.5rem;
            color: #ffa500;
            text-shadow: 0 0 10px rgba(255, 165, 0, 0.5);
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

        .status-bar {
            margin: 1.5rem 0;
            background-color: #2d2d2d;
            padding: 1rem 2rem;
            border-radius: 10px;
            font-family: 'Courier New', monospace;
            color: #ffa500;
            font-size: 0.9rem;
            border: 1px solid #444;
        }

        .countdown {
            font-size: 1.2rem;
            color: #ffa500;
            margin: 1rem 0;
            font-weight: bold;
        }

        .buttons {
            display: flex;
            gap: 1rem;
            flex-wrap: wrap;
            justify-content: center;
            margin: 2rem 0;
        }

        .btn {
            background: linear-gradient(45deg, #ffa500, #ff8c00);
            color: white;
            padding: 0.75rem 1.5rem;
            border: none;
            border-radius: 8px;
            font-size: 1rem;
            cursor: pointer;
            text-decoration: none;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(255, 165, 0, 0.3);
        }

        .btn:hover {
            background: linear-gradient(45deg, #ff8c00, #ff7700);
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(255, 165, 0, 0.5);
        }

        .maintenance-log {
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
            color: #ffa500;
            box-shadow: inset 0 0 10px rgba(0, 0, 0, 0.5);
            border: 1px solid #333;
            position: relative;
        }

        .maintenance-line {
            animation: maintenanceGlow 2s infinite;
        }

        @keyframes maintenanceGlow {
            0%, 100% { color: #ffa500; }
            50% { color: #ffcc00; text-shadow: 0 0 5px #ffa500; }
        }

        .progress-bar {
            width: 100%;
            height: 20px;
            background-color: #333;
            border-radius: 10px;
            margin: 1rem 0;
            overflow: hidden;
        }

        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #ffa500, #ffcc00);
            border-radius: 10px;
            animation: progressPulse 2s infinite;
            width: 0%;
        }

        @keyframes progressPulse {
            0%, 100% { opacity: 0.7; }
            50% { opacity: 1; }
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

        <h1>503 - Tracker en Mantenimiento</h1>
        <h2>Mejorando los servidores... 🔧</h2>

        <p>
            Estamos realizando mantenimiento programado para mejorar tu experiencia.<br>
            Los seeders están tomando un descanso temporal...
        </p>

        <div class="status-bar">
            STATUS: Actualizando base de datos de torrents...
        </div>

        <div class="countdown" id="countdown">
            ⏱️ Regresa en unos minutos...
        </div>

        <div class="progress-bar">
            <div class="progress-fill" id="progress"></div>
        </div>

        <div class="buttons">
            <a href="{{ route('home.index') }}" class="btn">
                🏠 Volver al inicio
            </a>
            <a href="javascript:location.reload()" class="btn">
                🔄 Verificar estado
            </a>
        </div>

        <div class="maintenance-log" id="maintenance-log">
            <div class="maintenance-line">[SYSTEM] Iniciando mantenimiento programado...</div>
        </div>
    </div>

    <script>
        const mensajesMantenimiento = [
            "[SYSTEM] Deteniendo servicios de tracker...",
            "[DB] Optimizando base de datos...",
            "[CACHE] Limpiando caché de torrents...",
            "[SEARCH] Reindexando motor de búsqueda...",
            "[PEERS] Actualizando tabla de peers...",
            "[SYSTEM] Aplicando parches de seguridad...",
            "[API] Reiniciando servicios API...",
            "[TRACKER] Recalibrando announce...",
            "[SYSTEM] Finalizando mantenimiento..."
        ];

        let messageIndex = 0;
        const log = document.getElementById('maintenance-log');
        const progressBar = document.getElementById('progress');
        let progress = 0;

        // Función para simular progreso
        function updateProgress() {
            if (progress < 100) {
                progress += Math.random() * 5;
                if (progress > 100) progress = 100;
                progressBar.style.width = progress + '%';
            }
        }

        // Función para agregar mensajes de mantenimiento
        function addMaintenanceMessage() {
            if (messageIndex < mensajesMantenimiento.length) {
                const newLine = document.createElement('div');
                newLine.textContent = mensajesMantenimiento[messageIndex];
                newLine.className = 'maintenance-line';
                
                log.appendChild(newLine);
                log.scrollTop = log.scrollHeight;
                messageIndex++;
                
                // Actualizar progreso
                updateProgress();
            } else {
                // Reiniciar ciclo
                messageIndex = 0;
                progress = 0;
                log.innerHTML = '<div class="maintenance-line">[SYSTEM] Iniciando mantenimiento programado...</div>';
            }
        }

        // Actualizar mensajes cada 2 segundos
        setInterval(addMaintenanceMessage, 2000);

        // Actualizar progreso más frecuentemente
        setInterval(updateProgress, 500);

        // Countdown dinámico
        function updateCountdown() {
            const messages = [
                "⏱️ Regresa en unos minutos...",
                "🔧 Optimizando rendimiento...",
                "⚡ Casi terminamos...",
                "🚀 Preparando la experiencia...",
                "⏱️ Regresa en unos minutos..."
            ];
            
            let countdownIndex = 0;
            const countdownElement = document.getElementById('countdown');
            
            setInterval(() => {
                countdownElement.textContent = messages[countdownIndex];
                countdownIndex = (countdownIndex + 1) % messages.length;
            }, 3000);
        }

        updateCountdown();
    </script>
</body>
</html>
