<?php
session_start();

// Redirect to login if not authenticated
if (!isset($_SESSION['user_id'])) {
    header("Location: login.php");
    exit();
}

// Database connection
$host = 'localhost';
$db   = 'eventhub';
$user = 'root';
$pass = '';

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Get user info
$stmt = $conn->prepare("SELECT * FROM users WHERE id = ?");
$stmt->bind_param("i", $_SESSION['user_id']);
$stmt->execute();
$result = $stmt->get_result();
$user = $result->fetch_assoc();
$stmt->close();

// Get initials for avatar
$initials = '';
if (isset($user['email'])) {
    $parts = explode('@', $user['email']);
    $nameParts = explode('.', $parts[0]);
    foreach ($nameParts as $part) {
        $initials .= strtoupper(substr($part, 0, 1));
    }
    $initials = substr($initials, 0, 2);
}

// Handle form submissions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['update_profile'])) {
        // Handle profile update
        $name = $_POST['name'];
        $email = $_POST['email'];
        $bio = $_POST['bio'];
        
        $update_stmt = $conn->prepare("UPDATE users SET name = ?, email = ?, bio = ? WHERE id = ?");
        $update_stmt->bind_param("sssi", $name, $email, $bio, $_SESSION['user_id']);
        $update_stmt->execute();
        $update_stmt->close();
        
        // Refresh user data
        $stmt = $conn->prepare("SELECT * FROM users WHERE id = ?");
        $stmt->bind_param("i", $_SESSION['user_id']);
        $stmt->execute();
        $result = $stmt->get_result();
        $user = $result->fetch_assoc();
        $stmt->close();
        
        $success_message = "Profile updated successfully!";
    } elseif (isset($_POST['change_password'])) {
        // Handle password change
        $current_password = $_POST['current_password'];
        $new_password = $_POST['new_password'];
        $confirm_password = $_POST['confirm_password'];
        
        // Verify current password
        if (password_verify($current_password, $user['password'])) {
            if ($new_password === $confirm_password) {
                $hashed_password = password_hash($new_password, PASSWORD_DEFAULT);
                $update_stmt = $conn->prepare("UPDATE users SET password = ? WHERE id = ?");
                $update_stmt->bind_param("si", $hashed_password, $_SESSION['user_id']);
                $update_stmt->execute();
                $update_stmt->close();
                $success_message = "Password changed successfully!";
            } else {
                $error_message = "New passwords don't match!";
            }
        } else {
            $error_message = "Current password is incorrect!";
        }
    } elseif (isset($_POST['update_notifications'])) {
        // Handle notification preferences
        $email_notifications = isset($_POST['email_notifications']) ? 1 : 0;
        $push_notifications = isset($_POST['push_notifications']) ? 1 : 0;
        $event_reminders = isset($_POST['event_reminders']) ? 1 : 0;
        
        $update_stmt = $conn->prepare("UPDATE users SET email_notifications = ?, push_notifications = ?, event_reminders = ? WHERE id = ?");
        $update_stmt->bind_param("iiii", $email_notifications, $push_notifications, $event_reminders, $_SESSION['user_id']);
        $update_stmt->execute();
        $update_stmt->close();
        
        $success_message = "Notification preferences updated!";
    }
}

$conn->close();
?>
