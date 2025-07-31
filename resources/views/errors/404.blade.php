<!DOCTYPE html>
<html lang="{{ config('app.locale') }}">
<head>
    <meta charset="UTF-8">
    <title>404 - DHT Search Failed - {{ config('other.title') }}</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <link rel="shortcut icon" href="{{ url('/favicon.ico?v=' . filemtime(public_path('favicon.ico'))) }}" type="image/x-icon" />
    <link rel="icon" href="{{ url('/favicon.ico?v=' . filemtime(public_path('favicon.ico'))) }}" type="image/x-icon" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            background: linear-gradient(135deg, #0a0a0a 0%, #1a1a1a 50%, #0a0a0a 100%);
            color: #ff4444;
            font-family: 'Courier New', monospace;
            min-height: 100vh;
            overflow-x: hidden;
            overflow-y: auto;
            position: relative;
        }

        /* Efecto de líneas de escaneo de fondo */
        body::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: repeating-linear-gradient(
                0deg,
                transparent,
                transparent 2px,
                rgba(255, 68, 68, 0.03) 2px,
                rgba(255, 68, 68, 0.03) 4px
            );
            pointer-events: none;
            animation: scanlines 0.1s linear infinite;
        }

        @keyframes scanlines {
            0% { transform: translateY(0); }
            100% { transform: translateY(4px); }
        }

        .container {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: flex-start;
            min-height: 100vh;
            padding: 1rem;
            position: relative;
            z-index: 10;
        }

        .header {
            text-align: center;
            margin-bottom: 1.5rem;
        }

        .error-code {
            font-size: 6rem;
            font-weight: bold;
            color: #ff4444;
            text-shadow: 
                0 0 10px #ff4444,
                0 0 20px #ff4444,
                0 0 40px #ff4444,
                0 0 80px #ff4444;
            animation: glow-pulse 2s ease-in-out infinite alternate;
            margin-bottom: 0.5rem;
        }

        @keyframes glow-pulse {
            from {
                text-shadow: 
                    0 0 10px #ff4444,
                    0 0 20px #ff4444,
                    0 0 40px #ff4444,
                    0 0 80px #ff4444;
            }
            to {
                text-shadow: 
                    0 0 5px #ff4444,
                    0 0 10px #ff4444,
                    0 0 20px #ff4444,
                    0 0 40px #ff4444;
            }
        }

        .status-line {
            font-size: 1.2rem;
            color: #ffaa00;
            margin-bottom: 0.3rem;
            animation: flicker 3s infinite;
        }

        .subtitle {
            font-size: 0.9rem;
            color: #888;
            margin-bottom: 1.5rem;
        }

        @keyframes flicker {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.8; }
            75% { opacity: 0.9; }
        }

        /* Panel principal estilo terminal */
        .terminal-panel {
            background: rgba(0, 0, 0, 0.9);
            border: 2px solid #ff4444;
            border-radius: 8px;
            padding: 1rem;
            width: 100%;
            max-width: 900px;
            box-shadow: 
                0 0 20px rgba(255, 68, 68, 0.5),
                inset 0 0 20px rgba(255, 68, 68, 0.1);
            position: relative;
            overflow: hidden;
            margin-bottom: 1rem;
        }

        .terminal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding-bottom: 1rem;
            border-bottom: 1px solid #ff4444;
            margin-bottom: 1rem;
        }

        .terminal-title {
            color: #ff4444;
            font-weight: bold;
            font-size: 1.2rem;
        }

        .terminal-controls {
            display: flex;
            gap: 0.5rem;
        }

        .terminal-btn {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            border: 1px solid #333;
        }

        .btn-close { background: #ff4444; }
        .btn-minimize { background: #ffaa00; }
        .btn-maximize { background: #44ff44; }

        /* Animaciones CSS puras para evitar problemas de CSP */
        .dht-search {
            background: #111;
            padding: 0.8rem;
            border-radius: 4px;
            margin-bottom: 1rem;
            border: 1px solid #333;
            min-height: 150px;
            max-height: 200px;
            overflow-y: auto;
            font-size: 0.8rem;
            line-height: 1.3;
            position: relative;
            transition: all 0.3s ease;
        }

        .dht-search::after {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255, 68, 68, 0.1), transparent);
            animation: scanning 3s linear infinite;
        }

        @keyframes scanning {
            0% { left: -100%; }
            100% { left: 100%; }
        }

        .dht-search::-webkit-scrollbar {
            width: 6px;
        }

        .dht-search::-webkit-scrollbar-track {
            background: #222;
        }

        .dht-search::-webkit-scrollbar-thumb {
            background: #ff4444;
            border-radius: 3px;
        }

        .search-line {
            margin-bottom: 0.3rem;
            animation: typewriter 0.5s ease-out, fadeIn 1s ease-in;
            transition: all 0.3s ease;
            opacity: 1;
            transform: translateX(0);
        }

        /* Simulación de escritura progresiva */
        .search-line:nth-child(1) { animation-delay: 0.5s; }
        .search-line:nth-child(2) { animation-delay: 1.5s; }
        .search-line:nth-child(3) { animation-delay: 2.5s; }
        .search-line:nth-child(4) { animation-delay: 3.5s; }
        .search-line:nth-child(5) { animation-delay: 4.5s; }
        .search-line:nth-child(6) { animation-delay: 5.5s; }
        .search-line:nth-child(7) { animation-delay: 6.5s; }
        .search-line:nth-child(8) { animation-delay: 7.5s; }
        .search-line:nth-child(9) { animation-delay: 8.5s; }
        .search-line:nth-child(10) { animation-delay: 9.5s; }
        .search-line:nth-child(11) { animation-delay: 10.5s; }
        .search-line:nth-child(12) { animation-delay: 11.5s; }
        .search-line:nth-child(13) { animation-delay: 12.5s; }

        .search-line.error {
            color: #ff4444;
            font-weight: bold;
        }

        .search-line.warning {
            color: #ffaa00;
        }

        .search-line.info {
            color: #44aaff;
        }

        .search-line.success {
            color: #44ff44;
        }

        @keyframes typewriter {
            from { opacity: 0; transform: translateX(-10px); }
            to { opacity: 1; transform: translateX(0); }
        }

        @keyframes fadeIn {
            0% { opacity: 0; }
            100% { opacity: 1; }
        }

        /* Barra de progreso animada automáticamente */
        .progress-bar {
            height: 100%;
            background: linear-gradient(90deg, #ff4444, #ffaa00, #ff4444);
            animation: progress-fill 13s ease-out forwards, progress-pulse 2s ease-in-out infinite;
            width: 0%;
        }

        @keyframes progress-fill {
            0% { width: 0%; }
            20% { width: 15%; }
            40% { width: 35%; }
            60% { width: 60%; }
            80% { width: 85%; }
            100% { width: 100%; }
        }

        /* Estadísticas que se actualizan automáticamente */
        .stat-value {
            font-size: 2rem;
            font-weight: bold;
            color: #ff4444;
            display: block;
            transition: all 0.3s ease;
            animation: countUp 13s ease-out forwards;
        }

        #nodes-contacted { animation: countUpNodes 13s ease-out forwards; }
        #timeout { animation: countDownTimeout 13s ease-out forwards; }

        @keyframes countUpNodes {
            0% { transform: scale(1); }
            20% { transform: scale(1.1); }
            21% { transform: scale(1); }
            40% { transform: scale(1.1); }
            41% { transform: scale(1); }
            60% { transform: scale(1.1); }
            61% { transform: scale(1); }
            80% { transform: scale(1.1); }
            81% { transform: scale(1); }
            100% { transform: scale(1); }
        }

        @keyframes countDownTimeout {
            0% { color: #ff4444; }
            80% { color: #ffaa00; }
            90% { color: #ff4444; font-size: 1.7rem; }
            100% { color: #ff4444; font-size: 1.5rem; }
        }

        /* Cursor terminal parpadeante */
        .terminal-cursor {
            color: #ff4444;
            animation: blink 1s infinite;
            font-weight: bold;
        }

        @keyframes blink {
            0%, 50% { opacity: 1; }
            51%, 100% { opacity: 0; }
        }

        /* Información del magnet */
        .magnet-info {
            background: #1a1a1a;
            border: 1px solid #ff4444;
            border-radius: 4px;
            padding: 0.8rem;
            margin: 1rem 0;
        }

        .magnet-hash {
            font-family: 'Courier New', monospace;
            color: #ffaa00;
            word-break: break-all;
            background: #000;
            padding: 0.4rem;
            border-radius: 3px;
            border: 1px solid #333;
            margin: 0.3rem 0;
            font-size: 0.8rem;
        }

        /* Estadísticas DHT */
        .dht-stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
            gap: 0.8rem;
            margin: 1rem 0;
        }

        .stat-item {
            background: rgba(255, 68, 68, 0.1);
            border: 1px solid #ff4444;
            border-radius: 4px;
            padding: 0.8rem;
            text-align: center;
        }

        .stat-value {
            font-size: 1.5rem;
            font-weight: bold;
            color: #ff4444;
            display: block;
            transition: all 0.3s ease;
        }

        .stat-label {
            font-size: 0.7rem;
            color: #888;
            margin-top: 0.3rem;
        }

        /* Botones de acción */
        .action-buttons {
            display: flex;
            gap: 0.8rem;
            justify-content: center;
            flex-wrap: wrap;
            margin-top: 1rem;
            margin-bottom: 2rem;
        }

        .btn {
            background: linear-gradient(45deg, #ff4444, #ff6666);
            color: white;
            border: none;
            padding: 0.6rem 1.2rem;
            border-radius: 4px;
            font-family: 'Courier New', monospace;
            font-size: 0.8rem;
            cursor: pointer;
            text-decoration: none;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(255, 68, 68, 0.3);
            border: 1px solid #ff4444;
        }

        .btn:hover {
            background: linear-gradient(45deg, #ff6666, #ff8888);
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(255, 68, 68, 0.5);
        }

        .btn-secondary {
            background: linear-gradient(45deg, #333, #555);
            border: 1px solid #666;
        }

        .btn-secondary:hover {
            background: linear-gradient(45deg, #555, #777);
            box-shadow: 0 6px 20px rgba(100, 100, 100, 0.3);
        }

        /* Progress bar para búsqueda */
        .search-progress {
            background: #222;
            height: 6px;
            border-radius: 3px;
            overflow: hidden;
            margin: 1rem 0;
            border: 1px solid #333;
        }

        .progress-bar {
            height: 100%;
            background: linear-gradient(90deg, #ff4444, #ffaa00, #ff4444);
            animation: progress-fill 13s ease-out forwards, progress-pulse 2s ease-in-out infinite;
            width: 0%;
        }

        @keyframes progress-pulse {
            0%, 100% { opacity: 0.8; }
            50% { opacity: 1; }
        }

        /* Responsive */
        @media (max-width: 768px) {
            .container {
                padding: 0.5rem;
            }
            
            .error-code { 
                font-size: 3.5rem;
                margin-bottom: 0.3rem;
            }
            
            .status-line {
                font-size: 1rem;
                margin-bottom: 0.2rem;
            }
            
            .subtitle {
                font-size: 0.8rem;
                margin-bottom: 1rem;
            }
            
            .terminal-panel {
                padding: 0.8rem;
                max-width: 100%;
            }
            
            .terminal-title {
                font-size: 1rem;
            }
            
            .dht-search {
                padding: 0.6rem;
                min-height: 120px;
                max-height: 150px;
                font-size: 0.7rem;
                line-height: 1.2;
            }
            
            .magnet-info {
                padding: 0.6rem;
                margin: 0.8rem 0;
            }
            
            .magnet-hash {
                padding: 0.3rem;
                font-size: 0.7rem;
            }
            
            .dht-stats { 
                grid-template-columns: 1fr 1fr;
                gap: 0.5rem;
                margin: 0.8rem 0;
            }
            
            .stat-item {
                padding: 0.6rem;
            }
            
            .stat-value {
                font-size: 1.2rem;
            }
            
            .stat-label {
                font-size: 0.6rem;
            }
            
            .action-buttons { 
                flex-direction: column; 
                align-items: center;
                gap: 0.6rem;
                margin-top: 0.8rem;
                margin-bottom: 1rem;
            }
            
            .btn { 
                width: 180px;
                padding: 0.8rem 1rem;
                font-size: 0.8rem;
            }
            
            .search-line {
                font-size: 0.7rem;
                margin-bottom: 0.2rem;
            }
        }

        @media (max-width: 480px) {
            .error-code { 
                font-size: 2.8rem;
            }
            
            .status-line {
                font-size: 0.9rem;
            }
            
            .subtitle {
                font-size: 0.7rem;
            }
            
            .terminal-panel {
                padding: 0.6rem;
            }
            
            .dht-search {
                padding: 0.5rem;
                min-height: 100px;
                max-height: 120px;
                font-size: 0.65rem;
            }
            
            .dht-stats { 
                grid-template-columns: 1fr;
                gap: 0.4rem;
            }
            
            .stat-value {
                font-size: 1rem;
            }
            
            .btn { 
                width: 160px;
                padding: 0.7rem 0.8rem;
                font-size: 0.75rem;
            }
        }

        /* Ajustes para pantallas grandes */
        @media (min-width: 1200px) {
            .container {
                padding: 2rem;
            }
            
            .error-code {
                font-size: 7rem;
            }
            
            .terminal-panel {
                max-width: 1000px;
                padding: 1.5rem;
            }
            
            .dht-search {
                min-height: 180px;
                max-height: 220px;
                font-size: 0.9rem;
            }
            
            .stat-value {
                font-size: 1.8rem;
            }
            
            .btn {
                padding: 0.8rem 1.4rem;
                font-size: 0.9rem;
            }
        }

        /* Efectos adicionales de animación */
        .terminal-panel {
            animation: terminalGlow 4s ease-in-out infinite alternate;
        }

        @keyframes terminalGlow {
            0% { 
                box-shadow: 0 0 20px rgba(255, 68, 68, 0.5), inset 0 0 20px rgba(255, 68, 68, 0.1);
            }
            100% { 
                box-shadow: 0 0 30px rgba(255, 68, 68, 0.7), inset 0 0 25px rgba(255, 68, 68, 0.15);
            }
        }

        /* Efecto de matriz de fondo */
        body::after {
            content: '';
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-image: 
                radial-gradient(circle at 20% 50%, rgba(255, 68, 68, 0.03) 0%, transparent 50%),
                radial-gradient(circle at 80% 20%, rgba(255, 68, 68, 0.03) 0%, transparent 50%),
                radial-gradient(circle at 40% 80%, rgba(255, 68, 68, 0.03) 0%, transparent 50%);
            pointer-events: none;
            animation: matrixFloat 8s ease-in-out infinite;
            z-index: 1;
        }

        @keyframes matrixFloat {
            0%, 100% { 
                transform: translateY(0px) rotate(0deg);
                opacity: 0.3;
            }
            50% { 
                transform: translateY(-10px) rotate(1deg);
                opacity: 0.1;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="error-code">404</div>
            <div class="status-line">DHT SEARCH FAILED</div>
            <div class="subtitle">Torrent not found in distributed hash table</div>
        </div>

        <div class="terminal-panel">
            <div class="terminal-header">
                <div class="terminal-title">
                    <i class="fas fa-terminal"></i> LAT-TEAM DHT Client v2.1.5
                </div>
                <div class="terminal-controls">
                    <div class="terminal-btn btn-close"></div>
                    <div class="terminal-btn btn-minimize"></div>
                    <div class="terminal-btn btn-maximize"></div>
                </div>
            </div>

            <div class="magnet-info">
                <strong>Requested Hash:</strong>
                <div class="magnet-hash" id="target-hash">
                    @if($exception->getMessage())
                        {{ substr(md5($exception->getMessage()), 0, 40) }}
                    @else
                        {{ substr(md5(request()->path()), 0, 40) }}
                    @endif
                </div>
            </div>

            <div class="search-progress">
                <div class="progress-bar" id="search-progress"></div>
            </div>

            <div class="dht-search" id="dht-log">
                <div class="search-line info">[DHT] Initializing distributed hash table search...</div>
                <div class="search-line info">[DHT] Connecting to bootstrap nodes...</div>
                <div class="search-line success">[DHT] Connected to 4.4.4.4:6881</div>
                <div class="search-line info">[DHT] Sending find_node query...</div>
                <div class="search-line warning">[DHT] Node 192.168.1.1:6881 timeout</div>
                <div class="search-line success">[DHT] Response from 8.8.8.8:6881</div>
                <div class="search-line info">[DHT] Sending get_peers query...</div>
                <div class="search-line warning">[DHT] No peers returned for infohash</div>
                <div class="search-line info">[DHT] Querying additional nodes...</div>
                <div class="search-line warning">[DHT] Node 176.32.98.166:6881 unreachable</div>
                <div class="search-line info">[DHT] Expanding search radius...</div>
                <div class="search-line warning">[DHT] All bootstrap nodes exhausted</div>
                <div class="search-line error">[DHT] SEARCH FAILED: Hash not found in DHT</div>
                <div class="search-line error">[DHT] ERROR: Torrent may be dead or removed</div>
                <span class="terminal-cursor">█</span>
            </div>

            <div class="dht-stats">
                <div class="stat-item">
                    <span class="stat-value" id="nodes-contacted">8</span>
                    <div class="stat-label">Nodes Contacted</div>
                </div>
                <div class="stat-item">
                    <span class="stat-value" id="peers-found">0</span>
                    <div class="stat-label">Peers Found</div>
                </div>
                <div class="stat-item">
                    <span class="stat-value" id="seeders">0</span>
                    <div class="stat-label">Seeders</div>
                </div>
                <div class="stat-item">
                    <span class="stat-value" id="timeout">0</span>
                    <div class="stat-label">Timeout (s)</div>
                </div>
            </div>
        </div>

        <div class="action-buttons">
            <a href="{{ route('home.index') }}" class="btn">
                <i class="fas fa-home"></i> Return to Tracker
            </a>
            <a href="javascript:location.reload()" class="btn btn-secondary">
                <i class="fas fa-redo"></i> Retry Search
            </a>
            <a href="{{ route('tickets.create') }}" class="btn btn-secondary">
                <i class="fas fa-bug"></i> Report Issue
            </a>
        </div>
    </div>

    <script>
        // Efectos adicionales solo si no hay problemas de CSP
        document.addEventListener('DOMContentLoaded', function() {
            // Efecto de parpadeo de pantalla ocasional
            setInterval(function() {
                if (Math.random() > 0.97) {
                    document.body.style.filter = 'brightness(1.2) contrast(1.1)';
                    setTimeout(function() {
                        document.body.style.filter = '';
                    }, 80);
                }
            }, 2000);
            
            // Efecto glitch en el código de error
            setInterval(function() {
                if (Math.random() > 0.98) {
                    var errorCode = document.querySelector('.error-code');
                    if (errorCode) {
                        errorCode.style.textShadow = '2px 2px #00ffff, -2px -2px #ff00ff';
                        setTimeout(function() {
                            errorCode.style.textShadow = '0 0 10px #ff4444, 0 0 20px #ff4444, 0 0 40px #ff4444, 0 0 80px #ff4444';
                        }, 100);
                    }
                }
            }, 2000);
        });
    </script>
</body>
</html>
