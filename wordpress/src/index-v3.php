<?php
// Версия 3 - Нерабочая (с ошибкой)
echo "<!DOCTYPE html>
<html>
<head>
    <title>WordPress v3 - Broken</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .error { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <h1>WordPress v3 - Broken Version</h1>
    
    <?php
    // Намеренная ошибка - несуществующая функция
    non_existent_function();
    ?>
    
    <p class='error'>This version contains intentional errors for testing rollback functionality.</p>
</body>
</html>";
?>
