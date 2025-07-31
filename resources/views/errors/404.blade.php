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
            overflow: hidden;
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
            justify-content: center;
            min-height: 100vh;
            padding: 2rem;
            position: relative;
            z-index: 10;
        }

        .header {
            text-align: center;
            margin-bottom: 2rem;
        }

        .error-code {
            font-size: 8rem;
            font-weight: bold;
            color: #ff4444;
            text-shadow: 
                0 0 10px #ff4444,
                0 0 20px #ff4444,
                0 0 40px #ff4444,
                0 0 80px #ff4444;
            animation: glow-pulse 2s ease-in-out infinite alternate;
            margin-bottom: 1rem;
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
            font-size: 1.5rem;
            color: #ffaa00;
            margin-bottom: 0.5rem;
            animation: flicker 3s infinite;
        }

        .subtitle {
            font-size: 1rem;
            color: #888;
            margin-bottom: 2rem;
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
            padding: 1.5rem;
            width: 100%;
            max-width: 800px;
            box-shadow: 
                0 0 20px rgba(255, 68, 68, 0.5),
                inset 0 0 20px rgba(255, 68, 68, 0.1);
            position: relative;
            overflow: hidden;
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

        /* Área de búsqueda DHT */
        .dht-search {
            background: #111;
            padding: 1rem;
            border-radius: 4px;
            margin-bottom: 1.5rem;
            border: 1px solid #333;
            min-height: 200px;
            overflow-y: auto;
            font-size: 0.9rem;
            line-height: 1.4;
        }

        .search-line {
            margin-bottom: 0.3rem;
            animation: typewriter 0.5s ease-out;
        }

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

        /* Información del magnet */
        .magnet-info {
            background: #1a1a1a;
            border: 1px solid #ff4444;
            border-radius: 4px;
            padding: 1rem;
            margin: 1.5rem 0;
        }

        .magnet-hash {
            font-family: 'Courier New', monospace;
            color: #ffaa00;
            word-break: break-all;
            background: #000;
            padding: 0.5rem;
            border-radius: 3px;
            border: 1px solid #333;
            margin: 0.5rem 0;
        }

        /* Estadísticas DHT */
        .dht-stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 1rem;
            margin: 1.5rem 0;
        }

        .stat-item {
            background: rgba(255, 68, 68, 0.1);
            border: 1px solid #ff4444;
            border-radius: 4px;
            padding: 1rem;
            text-align: center;
        }

        .stat-value {
            font-size: 2rem;
            font-weight: bold;
            color: #ff4444;
            display: block;
        }

        .stat-label {
            font-size: 0.8rem;
            color: #888;
            margin-top: 0.5rem;
        }

        /* Botones de acción */
        .action-buttons {
            display: flex;
            gap: 1rem;
            justify-content: center;
            flex-wrap: wrap;
            margin-top: 2rem;
        }

        .btn {
            background: linear-gradient(45deg, #ff4444, #ff6666);
            color: white;
            border: none;
            padding: 0.8rem 1.5rem;
            border-radius: 4px;
            font-family: 'Courier New', monospace;
            font-size: 0.9rem;
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
            animation: progress-pulse 2s ease-in-out infinite;
            width: 0%;
        }

        @keyframes progress-pulse {
            0%, 100% { opacity: 0.8; }
            50% { opacity: 1; }
        }

        /* Responsive */
        @media (max-width: 768px) {
            .error-code { font-size: 4rem; }
            .container { padding: 1rem; }
            .action-buttons { flex-direction: column; align-items: center; }
            .btn { width: 200px; }
            .dht-stats { grid-template-columns: 1fr 1fr; }
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
            </div>

            <div class="dht-stats">
                <div class="stat-item">
                    <span class="stat-value" id="nodes-contacted">0</span>
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
                    <span class="stat-value" id="timeout">30</span>
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
        let searchProgress = 0;
        let nodesContacted = 0;
        let timeout = 30;
        
        const dhtMessages = [
            { type: 'info', text: '[DHT] Connecting to bootstrap nodes...', delay: 800 },
            { type: 'success', text: '[DHT] Connected to 4.4.4.4:6881', delay: 1200 },
            { type: 'info', text: '[DHT] Sending find_node query...', delay: 1500 },
            { type: 'warning', text: '[DHT] Node 192.168.1.1:6881 timeout', delay: 2000 },
            { type: 'success', text: '[DHT] Response from 8.8.8.8:6881', delay: 2500 },
            { type: 'info', text: '[DHT] Sending get_peers query...', delay: 3000 },
            { type: 'warning', text: '[DHT] No peers returned for infohash', delay: 3800 },
            { type: 'info', text: '[DHT] Querying additional nodes...', delay: 4500 },
            { type: 'warning', text: '[DHT] Node 176.32.98.166:6881 unreachable', delay: 5200 },
            { type: 'info', text: '[DHT] Expanding search radius...', delay: 6000 },
            { type: 'warning', text: '[DHT] All bootstrap nodes exhausted', delay: 7000 },
            { type: 'error', text: '[DHT] SEARCH FAILED: Hash not found in DHT', delay: 8000 },
            { type: 'error', text: '[DHT] ERROR: Torrent may be dead or removed', delay: 8500 }
        ];

        function updateProgress(percent) {
            const progressBar = document.getElementById('search-progress');
            progressBar.style.width = percent + '%';
            searchProgress = percent;
        }

        function updateStats() {
            document.getElementById('nodes-contacted').textContent = nodesContacted;
            document.getElementById('timeout').textContent = timeout;
        }

        function addLogMessage(message, type) {
            const log = document.getElementById('dht-log');
            const line = document.createElement('div');
            line.className = `search-line ${type}`;
            line.textContent = message;
            log.appendChild(line);
            log.scrollTop = log.scrollHeight;
        }

        function simulateDHTSearch() {
            let messageIndex = 0;
            
            function processNextMessage() {
                if (messageIndex < dhtMessages.length) {
                    const msg = dhtMessages[messageIndex];
                    
                    setTimeout(() => {
                        addLogMessage(msg.text, msg.type);
                        
                        // Update progress
                        const progress = ((messageIndex + 1) / dhtMessages.length) * 100;
                        updateProgress(progress);
                        
                        // Update nodes contacted
                        if (msg.type === 'success' || msg.type === 'warning') {
                            nodesContacted++;
                            updateStats();
                        }
                        
                        // Update timeout countdown
                        if (messageIndex > 5) {
                            timeout = Math.max(0, 30 - Math.floor((messageIndex - 5) * 3));
                            updateStats();
                        }
                        
                        messageIndex++;
                        processNextMessage();
                    }, msg.delay);
                }
            }
            
            processNextMessage();
        }

        // Screen flicker effect
        function addScreenFlicker() {
            setInterval(() => {
                if (Math.random() > 0.92) {
                    document.body.style.filter = 'brightness(1.2) contrast(1.1)';
                    setTimeout(() => {
                        document.body.style.filter = '';
                    }, 100);
                }
            }, 2000);
        }

        // Terminal text cursor effect
        function addCursorEffect() {
            const cursor = document.createElement('span');
            cursor.innerHTML = '█';
            cursor.style.color = '#ff4444';
            cursor.style.animation = 'blink 1s infinite';
            
            const style = document.createElement('style');
            style.textContent = `
                @keyframes blink {
                    0%, 50% { opacity: 1; }
                    51%, 100% { opacity: 0; }
                }
            `;
            document.head.appendChild(style);
            
            setInterval(() => {
                const log = document.getElementById('dht-log');
                const lastLine = log.lastElementChild;
                if (lastLine && !lastLine.querySelector('span')) {
                    lastLine.appendChild(cursor.cloneNode(true));
                }
            }, 500);
        }

        // Initialize everything when page loads
        document.addEventListener('DOMContentLoaded', function() {
            updateProgress(0);
            updateStats();
            
            setTimeout(() => {
                simulateDHTSearch();
            }, 1000);
            
            addScreenFlicker();
            addCursorEffect();
        });
    </script>
</body>
</html>
