<?php
// Версия 2 - Улучшенный интерфейс
echo "<!DOCTYPE html>
<html>
<head>
    <title>WordPress v2 - Enhanced</title>
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 0; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .header { 
            background: rgba(255,255,255,0.1); 
            backdrop-filter: blur(10px);
            color: white; 
            padding: 30px; 
            text-align: center; 
            border-radius: 15px;
            margin-bottom: 30px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
        }
        .content { 
            background: rgba(255,255,255,0.95); 
            padding: 30px; 
            border-radius: 15px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
        }
        .footer { 
            text-align: center; 
            color: rgba(255,255,255,0.8); 
            margin-top: 40px;
            padding: 20px;
        }
        h1 { font-size: 2.5em; margin: 0; }
        h2 { color: #333; border-bottom: 2px solid #0073aa; padding-bottom: 10px; }
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>🚀 WordPress v2 - Enhanced</h1>
            <p>Modern design with gradient background</p>
        </div>
        <div class='content'>
            <h2>Welcome to Enhanced WordPress</h2>
            <p>This version features a modern glass-morphism design with smooth gradients.</p>
            <p>Version: v2.0.0</p>
            <p>New features: Responsive design, Modern UI, Better user experience</p>
        </div>
        <div class='footer'>
            <p>Powered by WordPress CI/CD Pipeline | Enhanced Edition</p>
        </div>
    </div>
</body>
</html>";
?>
