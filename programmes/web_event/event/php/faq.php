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
$stmt = $conn->prepare("SELECT email FROM users WHERE id = ?");
$stmt->bind_param("i", $_SESSION['user_id']);
$stmt->execute();
$result = $stmt->get_result();
$user = $result->fetch_assoc();
$stmt->close();
$conn->close();

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
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FAQ - EventHub</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }

        :root {
            --primary-dark: #1e3a8a;
            --primary: #3b82f6;
            --primary-light: #93c5fd;
            --accent: #facc15;
            --accent-dark: #eab308;
            --white: #ffffff;
            --gray-light: #f3f4f6;
            --gray: #9ca3af;
            --dark: #1f2937;
        }

        body {
            background: linear-gradient(135deg, var(--primary-dark), var(--primary));
            color: var(--white);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            font-size: 16px;
        }

        .container {
            width: 100%;
            max-width: 1200px;
            padding: 0 20px;
            margin: 0 auto;
        }

        .navbar {
            width: 100%;
            display: flex;
            justify-content: space-between;
            align-items: center;
            background-color: rgba(30, 64, 175, 0.9);
            padding: 15px 30px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            position: sticky;
            top: 0;
            z-index: 1000;
            backdrop-filter: blur(5px);
        }

        .navbar-left {
            display: flex;
            align-items: center;
        }

        .navbar-left img {
            height: 40px;
            margin-right: 10px;
        }

        .navbar-left .brand-name {
            font-weight: bold;
            font-size: 1.2rem;
            color: var(--accent);
        }

        .navbar-center {
            display: flex;
            gap: 5px;
        }

        .navbar-center a {
            color: var(--white);
            text-decoration: none;
            margin: 0 15px;
            font-size: 16px;
            text-transform: uppercase;
            font-weight: 500;
            padding: 8px 12px;
            border-radius: 20px;
            transition: all 0.3s ease;
        }

        .navbar-center a:hover {
            color: var(--accent);
            background-color: rgba(255, 255, 255, 0.1);
        }

        .navbar-center a.active {
            color: var(--dark);
            background-color: var(--accent);
        }

        .navbar-right {
            display: flex;
            align-items: center;
            gap: 15px;
            position: relative;
        }

        .create-btn {
            background-color: var(--accent);
            border: none;
            padding: 10px 20px;
            border-radius: 20px;
            font-size: 14px;
            font-weight: bold;
            cursor: pointer;
            transition: all 0.3s ease;
            color: var(--dark);
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .create-btn:hover {
            background-color: var(--accent-dark);
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        }

        .user-profile {
            display: flex;
            align-items: center;
            gap: 10px;
            cursor: pointer;
            padding: 8px 15px;
            border-radius: 20px;
            transition: all 0.3s ease;
        }

        .user-profile:hover {
            background-color: rgba(255, 255, 255, 0.1);
        }

        .user-avatar {
            width: 32px;
            height: 32px;
            border-radius: 50%;
            background-color: var(--accent);
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            color: var(--dark);
        }

        .user-name {
            font-weight: 500;
        }

        .dropdown-menu {
            position: absolute;
            top: 100%;
            right: 0;
            background-color: rgba(30, 64, 175, 0.95);
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
            padding: 10px 0;
            min-width: 180px;
            z-index: 1001;
            display: none;
            backdrop-filter: blur(5px);
        }

        .dropdown-menu.show {
            display: block;
            animation: fadeIn 0.2s ease-in-out;
        }

        .dropdown-menu a {
            color: var(--white);
            text-decoration: none;
            padding: 10px 20px;
            display: block;
            transition: all 0.3s ease;
        }

        .dropdown-menu a:hover {
            background-color: rgba(255, 255, 255, 0.1);
            color: var(--accent);
        }

        .dropdown-menu i {
            margin-right: 10px;
            width: 20px;
            text-align: center;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(-10px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .mobile-menu-toggle {
            display: none;
            background: none;
            border: none;
            color: var(--white);
            font-size: 1.5rem;
            cursor: pointer;
        }

        /* FAQ Page Specific Styles */
        .page-header {
            text-align: center;
            margin: 50px 0 30px;
            animation: fadeIn 0.8s ease-in-out;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(-20px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .page-title {
            font-size: 2.5rem;
            color: var(--accent);
            margin-bottom: 10px;
            text-shadow: 1px 1px 3px rgba(0, 0, 0, 0.2);
        }

        .page-description {
            font-size: 1.2rem;
            opacity: 0.9;
            max-width: 800px;
            margin: 0 auto 40px;
        }

        .faq-container {
            max-width: 900px;
            margin: 0 auto 60px;
        }

        .faq-categories {
            display: flex;
            justify-content: center;
            margin-bottom: 30px;
            flex-wrap: wrap;
            gap: 10px;
        }

        .faq-category {
            padding: 10px 20px;
            background-color: rgba(30, 64, 175, 0.6);
            border-radius: 20px;
            cursor: pointer;
            transition: all 0.3s ease;
        }

        .faq-category.active {
            background-color: var(--accent);
            color: var(--dark);
            font-weight: bold;
        }

        .faq-category:hover:not(.active) {
            background-color: rgba(30, 64, 175, 0.8);
        }

        .faq-list {
            background-color: rgba(255, 255, 255, 0.05);
            border-radius: 15px;
            overflow: hidden;
            box-shadow: 0 6px 12px rgba(0, 0, 0, 0.1);
        }

        .faq-item {
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
        }

        .faq-item:last-child {
            border-bottom: none;
        }

        .faq-question {
            padding: 20px;
            font-size: 1.1rem;
            font-weight: 500;
            cursor: pointer;
            display: flex;
            justify-content: space-between;
            align-items: center;
            transition: all 0.3s ease;
        }

        .faq-question:hover {
            background-color: rgba(255, 255, 255, 0.05);
        }

        .faq-question i {
            transition: all 0.3s ease;
        }

        .faq-question.active i {
            transform: rotate(180deg);
        }

        .faq-question.active {
            background-color: rgba(255, 255, 255, 0.1);
        }

        .faq-answer {
            padding: 0 20px;
            max-height: 0;
            overflow: hidden;
            transition: all 0.3s ease;
            background-color: rgba(0, 0, 0, 0.1);
        }

        .faq-answer.active {
            padding: 20px;
            max-height: 500px;
        }

        .faq-answer p {
            margin-bottom: 15px;
            line-height: 1.6;
        }

        .faq-answer p:last-child {
            margin-bottom: 0;
        }

        .contact-section {
            text-align: center;
            background-color: rgba(30, 64, 175, 0.6);
            padding: 40px;
            border-radius: 15px;
            margin: 40px auto;
            max-width: 800px;
        }

        .contact-title {
            font-size: 1.5rem;
            margin-bottom: 20px;
            color: var(--accent);
        }

        .contact-description {
            margin-bottom: 30px;
            max-width: 600px;
            margin-left: auto;
            margin-right: auto;
        }

        .contact-options {
            display: flex;
            justify-content: center;
            gap: 20px;
            flex-wrap: wrap;
        }

        .contact-option {
            background-color: rgba(255, 255, 255, 0.1);
            padding: 20px;
            border-radius: 10px;
            width: 200px;
            transition: all 0.3s ease;
        }

        .contact-option:hover {
            transform: translateY(-5px);
            background-color: rgba(255, 255, 255, 0.15);
        }

        .contact-option i {
            font-size: 2rem;
            color: var(--accent);
            margin-bottom: 15px;
        }

        .contact-option h4 {
            margin-bottom: 10px;
            font-size: 1.1rem;
        }

        .contact-option p {
            font-size: 0.9rem;
            opacity: 0.8;
        }

        .search-container {
            position: relative;
            max-width: 600px;
            margin: 0 auto 40px;
        }

        .search-bar {
            width: 100%;
            padding: 15px 20px 15px 50px;
            border: none;
            border-radius: 30px;
            font-size: 16px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
            transition: all 0.3s ease;
            color: var(--dark);
        }

        .search-bar:focus {
            outline: none;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.25);
        }

        .search-icon {
            position: absolute;
            left: 20px;
            top: 50%;
            transform: translateY(-50%);
            color: var(--gray);
        }

        .footer {
            width: 100%;
            background-color: rgba(30, 64, 175, 0.9);
            margin-top: 60px;
            padding: 40px 20px;
            backdrop-filter: blur(5px);
        }

        .footer-content {
            display: flex;
            flex-wrap: wrap;
            justify-content: space-between;
            max-width: 1200px;
            margin: 0 auto;
            gap: 30px;
        }

        .footer-column {
            flex: 1;
            min-width: 250px;
        }

        .footer-title {
            font-size: 1.2rem;
            margin-bottom: 20px;
            color: var(--accent);
            position: relative;
            display: inline-block;
        }

        .footer-title::after {
            content: '';
            position: absolute;
            left: 0;
            bottom: -8px;
            width: 40px;
            height: 3px;
            background-color: var(--accent);
            border-radius: 2px;
        }

        .footer-links {
            list-style: none;
        }

        .footer-links li {
            margin-bottom: 10px;
        }

        .footer-links a {
            color: var(--white);
            text-decoration: none;
            transition: all 0.3s ease;
            opacity: 0.8;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .footer-links a:hover {
            opacity: 1;
            color: var(--accent);
        }

        .social-links {
            display: flex;
            gap: 15px;
            margin-top: 20px;
        }

        .social-link {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background-color: rgba(255, 255, 255, 0.1);
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--white);
            transition: all 0.3s ease;
        }

        .social-link:hover {
            background-color: var(--accent);
            color: var(--dark);
            transform: translateY(-3px);
        }

        .newsletter-form {
            display: flex;
            margin-top: 15px;
        }

        .newsletter-input {
            flex: 1;
            padding: 10px 15px;
            border: none;
            border-radius: 20px 0 0 20px;
            font-size: 14px;
        }

        .newsletter-btn {
            background-color: var(--accent);
            border: none;
            padding: 10px 15px;
            border-radius: 0 20px 20px 0;
            color: var(--dark);
            font-weight: bold;
            cursor: pointer;
            transition: all 0.3s ease;
        }

        .newsletter-btn:hover {
            background-color: var(--accent-dark);
        }

        .copyright {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid rgba(255, 255, 255, 0.1);
            font-size: 0.9rem;
            color: var(--gray-light);
            opacity: 0.7;
        }

        @media (max-width: 768px) {
            .navbar-center {
                display: none;
                position: absolute;
                top: 70px;
                left: 0;
                width: 100%;
                background-color: rgba(30, 64, 175, 0.95);
                flex-direction: column;
                padding: 20px;
                box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
                backdrop-filter: blur(5px);
            }

            .navbar-center.show {
                display: flex;
            }

            .navbar-center a {
                margin: 10px 0;
                width: 100%;
                text-align: center;
            }

            .mobile-menu-toggle {
                display: block;
            }

            .navbar-right .user-name {
                display: none;
            }

            .dropdown-menu {
                right: 15px;
            }

            .contact-options {
                flex-direction: column;
                align-items: center;
            }

            .contact-option {
                width: 100%;
                max-width: 300px;
            }
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="navbar-left">
            <img src="/api/placeholder/40/40" alt="Logo">
            <span class="brand-name">EventHub</span>
        </div>
        <button class="mobile-menu-toggle" id="mobileMenuToggle">
            <i class="fas fa-bars"></i>
        </button>
        <div class="navbar-center" id="navMenu">
            <a href="message.php">News</a>
            <a href="faq.php" class="active">FAQ</a>
            <a href="aide.php">Help</a>
            <a href="apropos.php">About Us</a>
        </div>
        <div class="navbar-right">
            <button class="create-btn">
                <i class="fas fa-plus"></i>
                <a href="create.php">Create</a>
            </button>
            <div class="user-profile" id="userProfile">
                <div class="user-avatar"><?= $initials ?></div>
                <span class="user-name"><?= htmlspecialchars(explode('@', $user['email'])[0]) ?></span>
                <i class="fas fa-chevron-down"></i>
                <div class="dropdown-menu" id="dropdownMenu">
                    <a href="logout.php"><i class="fas fa-sign-out-alt"></i> Log Out</a>
                    <a href="settings.php"><i class="fas fa-cog"></i> Settings</a>
                </div>
            </div>
        </div>
    </nav>

    <main class="container">
        <div class="page-header">
            <h1 class="page-title">Frequently Asked Questions</h1>
            <p class="page-description">Find answers to the most commonly asked questions about our event platform.</p>
        </div>

        <div class="search-container">
            <i class="fas fa-search search-icon"></i>
            <input type="text" class="search-bar" placeholder="Search the FAQ...">
        </div>

        <div class="faq-container">
            <div class="faq-categories">
                <div class="faq-category active" data-category="general">General</div>
                <div class="faq-category" data-category="reservation">Bookings</div>
                <div class="faq-category" data-category="payment">Payments</div>
                <div class="faq-category" data-category="organizer">Organizers</div>
                <div class="faq-category" data-category="account">Account</div>
            </div>

            <div class="faq-list">
                <!-- General Category -->
                <div class="faq-item general-item">
                    <div class="faq-question">
                        <span>How can I find events near me?</span>
                        <i class="fas fa-chevron-down"></i>
                    </div>
                    <div class="faq-answer">
                        <p>To find events near you, you can:</p>
                        <p>1. Use the search bar on the homepage and enter your city or zip code.</p>
                        <p>2. Enable geolocation in your browser to automatically show you nearby events.</p>
                        <p>3. Filter results by distance to refine your search.</p>
                    </div>
                </div>

                <div class="faq-item general-item">
                    <div class="faq-question">
                        <span>How do I create an EventHub account?</span>
                        <i class="fas fa-chevron-down"></i>
                    </div>
                    <div class="faq-answer">
                        <p>Creating an EventHub account is simple and free. Click the "Sign Up" button in the top right corner of the homepage and follow the instructions.</p>
                        <p>You can register with your email address, or use your Google, Facebook or Apple accounts for faster login.</p>
                        <p>Once registered, you can customize your profile, follow your favorite events and receive personalized recommendations.</p>
                    </div>
                </div>

                <div class="faq-item general-item">
                    <div class="faq-question">
                        <span>How do I cancel my booking and get a refund?</span>
                        <i class="fas fa-chevron-down"></i>
                    </div>
                    <div class="faq-answer">
                        <p>To cancel a booking:</p>
                        <p>1. Log in to your account and go to "My Tickets" in your profile.</p>
                        <p>2. Select the booking you want to cancel and click "Cancel".</p>
                        <p>3. Follow the instructions to complete the cancellation.</p>
                        <p>Refund policies vary by event and organizer. The policy that applies to your ticket is shown at purchase and in your booking confirmation. Some events offer full refunds up to a certain date, while others may offer partial refunds or credits for future events.</p>
                    </div>
                </div>

                <div class="faq-item general-item">
                    <div class="faq-question">
                        <span>How can I contact an event organizer?</span>
                        <i class="fas fa-chevron-down"></i>
                    </div>
                    <div class="faq-answer">
                        <p>You can contact an organizer in several ways:</p>
                        <p>1. On the event page, scroll to the "Organizer" section where you'll find a "Contact" button.</p>
                        <p>2. If you've already purchased a ticket, you can message the organizer from the "My Tickets" section of your profile.</p>
                        <p>3. Some organizers also list their contact details in the event description.</p>
                        <p>We always encourage communication through our platform to ensure security and tracking of exchanges.</p>
                    </div>
                </div>

                <div class="faq-item general-item">
                    <div class="faq-question">
                        <span>What should I do if an event is canceled or postponed?</span>
                        <i class="fas fa-chevron-down"></i>
                    </div>
                    <div class="faq-answer">
                        <p>If an event is canceled or postponed:</p>
                        <p>1. You'll automatically receive an email notification and an in-app notification.</p>
                        <p>2. For canceled events, refunds are usually automatic according to the organizer's policy.</p>
                        <p>3. For postponed events, you'll typically have the choice to keep your ticket for the new date or request a refund.</p>
                        <p>4. If you haven't received information within 48 hours of the cancellation or postponement announcement, contact our customer service.</p>
                    </div>
                </div>

                <div class="faq-item general-item">
                    <div class="faq-question">
                        <span>How do I become an event organizer on EventHub?</span>
                        <i class="fas fa-chevron-down"></i>
                    </div>
                    <div class="faq-answer">
                        <p>To become an organizer and create your own events:</p>
                        <p>1. Log in to your account or create one if you don't have one.</p>
                        <p>2. Click the "Create" button in the navigation bar.</p>
                        <p>3. Follow the steps to set up your organizer profile and provide the necessary information.</p>
                        <p>4. Once your organizer profile is approved, you can create and manage your events from your dashboard.</p>
                        <p>We offer different packages for organizers depending on the size and frequency of your events. For more information, visit our "Become an Organizer" page.</p>
                    </div>
                </div>

                <!-- Reservation Category -->
                <div class="faq-item reservation-item" style="display: none;">
                    <div class="faq-question">
                        <span>How do I book a ticket for an event?</span>
                        <i class="fas fa-chevron-down"></i>
                    </div>
                    <div class="faq-answer">
                        <p>To book a ticket for an event:</p>
                        <p>1. Search for the event you're interested in via the search bar or by browsing our categories.</p>
                        <p>2. Select the event and click "Book" or "Buy Tickets".</p>
                        <p>3. Choose the type and number of tickets you want.</p>
                        <p>4. Complete your personal information and proceed to payment.</p>
                        <p>5. You'll receive your ticket by email and it will also be available in the "My Tickets" section of your account.</p>
                    </div>
                </div>

                <div class="faq-item reservation-item" style="display: none;">
                    <div class="faq-question">
                        <span>Can I transfer my tickets to someone else?</span>
                        <i class="fas fa-chevron-down"></i>
                    </div>
                    <div class="faq-answer">
                        <p>Yes, you can transfer your tickets to another person in most cases:</p>
                        <p>1. Go to "My Tickets" in your account.</p>
                        <p>2. Select the ticket you want to transfer.</p>
                        <p>3. Click "Transfer" and enter the recipient's email address.</p>
                        <p>Note that some events may have restrictions on ticket transfers. These restrictions will be clearly indicated at the time of purchase.</p>
                    </div>
                </div>

                <!-- Payment Category -->
                <div class="faq-item payment-item" style="display: none;">
                    <div class="faq-question">
                        <span>What payment methods do you accept?</span>
                        <i class="fas fa-chevron-down"></i>
                    </div>
                    <div class="faq-answer">
                        <p>We accept several payment methods to make your purchases easier:</p>
                        <p>• Credit/debit cards (Visa, Mastercard, American Express)</p>
                        <p>• PayPal</p>
                        <p>• Apple Pay and Google Pay (on compatible devices)</p>
                        <p>• Bank transfers (for certain events)</p>
                        <p>Payment method availability may vary depending on your country and the selected event.</p>
                    </div>
                </div>

                <div class="faq-item payment-item" style="display: none;">
                    <div class="faq-question">
                        <span>How do I get an invoice for my purchase?</span>
                        <i class="fas fa-chevron-down"></i>
                    </div>
                    <div class="faq-answer">
                        <p>To get an invoice:</p>
                        <p>1. Log in to your EventHub account.</p>
                        <p>2. Go to "My Orders" or "Purchase History".</p>
                        <p>3. Find the relevant order and click "View Details".</p>
                        <p>4. Click "Download Invoice" or "Request Invoice".</p>
                        <p>For business purchases, you can add your billing information before completing your purchase. If you need a specific invoice for your company, contact our customer service.</p>
                    </div>
                </div>

                <!-- Organizer Category -->
                <div class="faq-item organizer-item" style="display: none;">
                    <div class="faq-question">
                        <span>What are EventHub's service fees?</span>
                        <i class="fas fa-chevron-down"></i>
                    </div>
                    <div class="faq-answer">
                        <p>Our service fees vary by event type and package:</p>
                        <p>• Essential Package: 5% + $0.99 per ticket sold</p>
                        <p>• Professional Package: 3.5% + $0.75 per ticket sold</p>
                        <p>• Premium Package: 2.5% + $0.50 per ticket sold (annual commitment required)</p>
                        <p>Free events are not subject to service fees. Additional fees may apply for certain advanced features or custom services.</p>
                        <p>Visit our "Pricing" page for more details and to compare packages.</p>
                    </div>
                </div>

                <div class="faq-item organizer-item" style="display: none;">
                    <div class="faq-question">
                        <span>When will I get paid for my ticket sales?</span>
                        <i class="fas fa-chevron-down"></i>
                    </div>
                    <div class="faq-answer">
                        <p>The payment schedule depends on your package and history with EventHub:</p>
                        <p>• New organizers: Payments are issued 7 days after the event.</p>
                        <p>• Established organizers: Payments may be issued 3 days after the event.</p>
                        <p>• Premium organizers: Option for weekly payments available, even before the event.</p>
                        <p>You can track your sales and payments in real time in your organizer dashboard. Payments are made by bank transfer to the account you specified.</p>
                    </div>
                </div>

                <!-- Account Category -->
                <div class="faq-item account-item" style="display: none;">
                    <div class="faq-question">
                        <span>How do I update my personal information?</span>
                        <i class="fas fa-chevron-down"></i>
                    </div>
                    <div class="faq-answer">
                        <p>To update your personal information:</p>
                        <p>1. Log in to your EventHub account.</p>
                        <p>2. Click on your avatar or username in the top right corner of the screen.</p>
                        <p>3. Select "Account Settings" from the dropdown menu.</p>
                        <p>4. Go to the "Personal Information" section.</p>
                        <p>5. Edit the information you want to change and click "Save".</p>
                        <p>Note that some changes, like your name or date of birth, may require additional verification for security reasons.</p>
                    </div>
                </div>

                <div class="faq-item account-item" style="display: none;">
                    <div class="faq-question">
                        <span>How do I deactivate or delete my account?</span>
                        <i class="fas fa-chevron-down"></i>
                    </div>
                    <div class="faq-answer">
                        <p>If you want to deactivate or delete your account:</p>
                        <p>1. Log in to your account.</p>
                        <p>2. Go to "Account Settings".</p>
                        <p>3. Scroll to the "Privacy & Security" section.</p>
                        <p>4. Click "Deactivate My Account" or "Delete My Account".</p>
                        <p>Deactivation puts your account on pause, allowing you to reactivate it later. Deletion is permanent and all your personal data will be erased in accordance with our privacy policy.</p>
                        <p>Note that if you have active tickets or are organizing upcoming events, you'll need to resolve these commitments before you can delete your account.</p>
                    </div>
                </div>
            </div>
        </div>

        <div class="contact-section">
            <h3 class="contact-title">Didn't find an answer to your question?</h3>
            <p class="contact-description">Our support team is available to help. Choose your preferred contact method.</p>
            
            <div class="contact-options">
                <div class="contact-option">
                    <i class="fas fa-comments"></i>
                    <h4>Live Chat</h4>
                    <p>Chat with an agent in real time</p>
                </div>
                <div class="contact-option">
                    <i class="fas fa-envelope"></i>
                    <h4>Email</h4>
                    <p>Response within 24 hours</p>
                </div>
                <div class="contact-option">
                    <i class="fas fa-phone-alt"></i>
                    <h4>Phone</h4>
                    <p>Mon-Fri, 9am-6pm</p>
                </div>
            </div>
        </div>
    </main>

    <footer class="footer">
        <div class="footer-content">
            <div class="footer-column">
                <h4 class="footer-title">About</h4>
                <ul class="footer-links">
                    <li><a href="#"><i class="fas fa-info-circle"></i> Our Story</a></li>
                    <li><a href="#"><i class="fas fa-users"></i> Our Team</a></li>
                    <li><a href="#"><i class="fas fa-briefcase"></i> Careers</a></li>
                    <li><a href="#"><i class="fas fa-newspaper"></i> News</a></li>
                </ul>
            </div>
            <div class="footer-column">
                <h4 class="footer-title">Support</h4>
                <ul class="footer-links">
                    <li><a href="#"><i class="fas fa-question-circle"></i> Help Center</a></li>
                    <li><a href="#"><i class="fas fa-ticket-alt"></i> Contact Support</a></li>
                    <li><a href="#"><i class="fas fa-book"></i> Guides</a></li>
                    <li><a href="#"><i class="fas fa-shield-alt"></i> Safety</a></li>
                </ul>
            </div>
            <div class="footer-column">
                <h4 class="footer-title">Legal</h4>
                <ul class="footer-links">
                    <li><a href="#"><i class="fas fa-lock"></i> Privacy</a></li>
                    <li><a href="#"><i class="fas fa-file-contract"></i> Terms of Use</a></li>
                    <li><a href="#"><i class="fas fa-cookie"></i> Cookies</a></li>
                </ul>
                <div class="social-links">
                    <a href="#" class="social-link"><i class="fab fa-facebook-f"></i></a>
                    <a href="#" class="social-link"><i class="fab fa-twitter"></i></a>
                    <a href="#" class="social-link"><i class="fab fa-instagram"></i></a>
                    <a href="#" class="social-link"><i class="fab fa-linkedin-in"></i></a>
                </div>
            </div>
            <div class="footer-column">
                <h4 class="footer-title">Newsletter</h4>
                <p>Get the latest news and special offers directly to your inbox.</p>
                <form class="newsletter-form">
                    <input type="email" placeholder="Your email" class="newsletter-input" required>
                    <button type="submit" class="newsletter-btn"><i class="fas fa-paper-plane"></i></button>
                </form>
            </div>
        </div>
        <div class="copyright">
            &copy; 2025 EventHub. All rights reserved.
        </div>
    </footer>

    <script>
        // Mobile menu toggle
        const mobileMenuToggle = document.getElementById('mobileMenuToggle');
        const navMenu = document.getElementById('navMenu');
        
        mobileMenuToggle.addEventListener('click', function() {
            navMenu.classList.toggle('show');
        });

        // Dropdown menu functionality
        const userProfile = document.getElementById('userProfile');
        const dropdownMenu = document.getElementById('dropdownMenu');

        userProfile.addEventListener('click', function(e) {
            e.stopPropagation();
            dropdownMenu.classList.toggle('show');
        });

        // Close dropdown when clicking elsewhere
        document.addEventListener('click', function() {
            dropdownMenu.classList.remove('show');
        });

        // Prevent dropdown from closing when clicking inside it
        dropdownMenu.addEventListener('click', function(e) {
            e.stopPropagation();
        });

        // FAQ toggle
        document.querySelectorAll('.faq-question').forEach(question => {
            question.addEventListener('click', function() {
                // Toggle active class on question
                this.classList.toggle('active');
                
                // Toggle active class on answer
                const answer = this.nextElementSibling;
                answer.classList.toggle('active');
            });
        });

        // FAQ categories
        document.querySelectorAll('.faq-category').forEach(category => {
            category.addEventListener('click', function() {
                // Remove active class from all categories
                document.querySelectorAll('.faq-category').forEach(cat => {
                    cat.classList.remove('active');
                });
                
                // Add active class to clicked category
                this.classList.add('active');
                
                // Get the category to show
                const categoryToShow = this.getAttribute('data-category');
                
                // Hide all FAQ items first
                document.querySelectorAll('.faq-item').forEach(item => {
                    item.style.display = 'none';
                });
                
                // Show items for the selected category
                if (categoryToShow === 'general') {
                    document.querySelectorAll('.general-item').forEach(item => {
                        item.style.display = 'block';
                    });
                } else if (categoryToShow === 'reservation') {
                    document.querySelectorAll('.reservation-item').forEach(item => {
                        item.style.display = 'block';
                    });
                } else if (categoryToShow === 'payment') {
                    document.querySelectorAll('.payment-item').forEach(item => {
                        item.style.display = 'block';
                    });
                } else if (categoryToShow === 'organizer') {
                    document.querySelectorAll('.organizer-item').forEach(item => {
                        item.style.display = 'block';
                    });
                } else if (categoryToShow === 'account') {
                    document.querySelectorAll('.account-item').forEach(item => {
                        item.style.display = 'block';
                    });
                }
            });
        });

        // Initialize with General category shown
        document.querySelectorAll('.general-item').forEach(item => {
            item.style.display = 'block';
        });
    </script>
</body>
</html>