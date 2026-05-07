<?php
// Connect to the database
$host = 'localhost';
$db   = 'eventhub';
$user = 'root';  // adjust if needed
$pass = '';      // adjust if needed

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Check if form was submitted
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['email'])) {
    $email = trim($_POST['email']);

    // Validate email format
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        die("Invalid email address.");
    }

    // Insert into newsletter table (create table if it doesn’t exist)
    $stmt = $conn->prepare("INSERT INTO newsletter_subscribers (email) VALUES (?)");
    if ($stmt) {
        $stmt->bind_param("s", $email);
        if ($stmt->execute()) {
            echo "Thank you for subscribing!";
        } else {
            echo "Error: You may already be subscribed.";
        }
        $stmt->close();
    } else {
        echo "Error preparing statement: " . $conn->error;
    }
} else {
    echo "No email received.";
}

$conn->close();
?>
