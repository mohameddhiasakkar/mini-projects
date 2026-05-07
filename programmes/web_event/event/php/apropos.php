<?php
session_start();

// Database connection
$host = 'localhost';
$db   = 'eventhub';
$user = 'root';
$pass = '';
$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Handle newsletter submission
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['newsletter_submit'])) {
    $email = filter_input(INPUT_POST, 'email', FILTER_SANITIZE_EMAIL);
    
    if (filter_var($email, FILTER_VALIDATE_EMAIL)) {
        // Save to database
        $stmt = $conn->prepare("INSERT INTO newsletter_subscribers (email, subscribed_at) VALUES (?, NOW())");
        $stmt->bind_param("s", $email);
        
        if ($stmt->execute()) {
            $_SESSION['newsletter_message'] = "Thank you for subscribing!";
            $_SESSION['newsletter_status'] = "success";
        } else {
            $_SESSION['newsletter_message'] = "You're already subscribed!";
            $_SESSION['newsletter_status'] = "info";
        }
        $stmt->close();
    } else {
        $_SESSION['newsletter_message'] = "Please enter a valid email address";
        $_SESSION['newsletter_status'] = "error";
    }
    
    header("Location: apropos.php");
    exit();
}

// User authentication
if (!isset($_SESSION['user_id'])) {
    header("Location: login.php");
    exit();
}

// Get user info
$stmt = $conn->prepare("SELECT email FROM users WHERE id = ?");
$stmt->bind_param("i", $_SESSION['user_id']);
$stmt->execute();
$result = $stmt->get_result();
$user = $result->fetch_assoc();
$stmt->close();

// Generate initials
$initials = '';
if (isset($user['email'])) {
    $parts = explode('@', $user['email']);
    $nameParts = explode('.', $parts[0]);
    foreach ($nameParts as $part) {
        $initials .= strtoupper(substr($part, 0, 1));
    }
    $initials = substr($initials, 0, 2);
}

$conn->close();
?>