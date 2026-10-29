
<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

require_once 'db.php';

// Read search parameters from URL
$place = trim($_GET['place'] ?? $_GET['q'] ?? '');
$type  = strtolower(trim($_GET['type'] ?? 'all'));

// Allowed database tables
$allowedTables = [
    'places',
    'locations',
    'hotels',
    'local_foods',
    'medical_facilities',
    'police_stations',
    'restaurants',
    'tourist_destinations',
    'transport',
    'travel_costs'
];

try {
    // Validate requested table
    if ($type !== 'all' && !in_array($type, $allowedTables, true)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'Invalid type',
            'allowed_types' => $allowedTables
        ], JSON_PRETTY_PRINT);
        exit;
    }

    $tables = ($type === 'all') ? $allowedTables : [$type];
    $results = [];
    $errors = [];

    foreach ($tables as $table) {
        // Skip tables that do not exist
        $check = $conn->query(
            "SHOW TABLES LIKE '" .
            $conn->real_escape_string($table) . "'"
        );

        if (!$check || $check->num_rows === 0) {
            continue;
        }

        // Get columns for this table
        $columnResult = $conn->query(
            "SHOW COLUMNS FROM `$table`"
        );

        if (!$columnResult) {
            $errors[$table] = 'Could not read table columns';
            continue;
        }

        $columns = [];
        while ($column = $columnResult->fetch_assoc()) {
            $columns[] = $column['Field'];
        }

        if (!$columns) {
            continue;
        }

        // Build a search across all columns
        $where = '';
        $params = [];
        $paramTypes = '';

        if ($place !== '') {
            $conditions = [];

            foreach ($columns as $column) {
                $conditions[] = "CAST(`$column` AS CHAR) LIKE ?";
                $params[] = '%' . $place . '%';
                $paramTypes .= 's';
            }

            $where = ' WHERE (' . implode(' OR ', $conditions) . ')';
        }

        $sql = "SELECT * FROM `$table`" .
               $where . " LIMIT 100";

        $stmt = $conn->prepare($sql);

        if (!$stmt) {
            $errors[$table] = 'Could not prepare search query';
            continue;
        }

        if ($place !== '') {
            $stmt->bind_param($paramTypes, ...$params);
        }

        if (!$stmt->execute()) {
            $errors[$table] = 'Search query failed';
            $stmt->close();
            continue;
        }

        $result = $stmt->get_result();
        $rows = [];

        while ($row = $result->fetch_assoc()) {
            $rows[] = $row;
        }

        $results[$table] = $rows;
        $stmt->close();
    }

    $total = 0;
    foreach ($results as $rows) {
        $total += count($rows);
    }

    echo json_encode([
        'success' => true,
        'search' => [
            'place' => $place,
            'type' => $type
        ],
        'total_results' => $total,
        'results' => $results,
        'errors' => (object) $errors
    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
    http_response_code(500);

    echo json_encode([
        'success' => false,
        'error' => 'Internal server error'
    ], JSON_PRETTY_PRINT);
}
?>
