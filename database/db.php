
<?php
mysqli_report(MYSQLI_REPORT_OFF);

$conn = new mysqli(
    '127.0.0.1',
    'root',
    '',
    'explore_arunachal',
    3306
);

if ($conn->connect_error) {
    http_response_code(500);
    header('Content-Type: application/json; charset=utf-8');

    echo json_encode([
        'success' => false,
        'error' => 'Database connection failed'
    ], JSON_PRETTY_PRINT);

    exit;
}

$conn->set_charset('utf8mb4');
?>
