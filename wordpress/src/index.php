<?php
// Определяем версию из ConfigMap
$version = getenv('APP_VERSION') ?: 'v1';

// Загружаем соответствующую версию
if ($version === 'v2') {
    include 'index-v2.php';
} elseif ($version === 'v3') {
    include 'index-v3.php';
} else {
    include 'index-v1.php';
}
?>
