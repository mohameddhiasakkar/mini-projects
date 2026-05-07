<?php
/*
-- SQL Setup (run once if you haven't already) ---------------------------
CREATE DATABASE eventhub;

USE eventhub;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL
);
-------------------------------------------------------------------------
*/

session_start();

// Database connection
$host = 'localhost';
$db   = 'eventhub';
$user = 'root';  // adjust as needed
$pass = '';      // adjust as needed

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$message = "";

// Handle signup POST
if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $email           = trim($_POST["email"]);
    $password        = $_POST["password"];
    $confirmPassword = $_POST["confirm_password"];

    if ($password !== $confirmPassword) {
        $message = "Passwords do not match.";
    } else {
        // Check if email already exists
        $stmt = $conn->prepare("SELECT id FROM users WHERE email = ?");
        $stmt->bind_param("s", $email);
        $stmt->execute();
        $stmt->store_result();
        
        if ($stmt->num_rows > 0) {
            $message = "Email is already registered.";
        } else {
            // Insert new user
            $hash = password_hash($password, PASSWORD_DEFAULT);
            $insert = $conn->prepare("INSERT INTO users (email, password) VALUES (?, ?)");
            $insert->bind_param("ss", $email, $hash);
            
            if ($insert->execute()) {
                // Redirect to login page after successful signup
                header("Location: login.php");
                exit();
            } else {
                $message = "Signup failed. Please try again.";
            }
            $insert->close();
        }
        $stmt->close();
    }
}

$conn->close();
?>
