<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Create Event - EventHub</title>
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

        .mobile-menu-toggle {
            display: none;
            background: none;
            border: none;
            color: var(--white);
            font-size: 1.5rem;
            cursor: pointer;
        }

        /* Create Event Page Specific Styles */
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

        .create-container {
            max-width: 900px;
            margin: 0 auto 60px;
            background-color: rgba(255, 255, 255, 0.05);
            border-radius: 15px;
            padding: 40px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        }

        .form-step {
            display: none;
            animation: fadeIn 0.5s ease-in-out;
        }

        .form-step.active {
            display: block;
        }

        .form-header {
            margin-bottom: 30px;
            text-align: center;
        }

        .form-title {
            font-size: 1.8rem;
            color: var(--accent);
            margin-bottom: 10px;
        }

        .form-subtitle {
            opacity: 0.8;
            font-size: 1rem;
        }

        .form-group {
            margin-bottom: 25px;
        }

        .form-label {
            display: block;
            margin-bottom: 10px;
            font-weight: 500;
            font-size: 1.1rem;
        }

        .form-control {
            width: 100%;
            padding: 12px 15px;
            border: none;
            border-radius: 8px;
            background-color: rgba(255, 255, 255, 0.1);
            color: var(--white);
            font-size: 16px;
            transition: all 0.3s ease;
        }

        /* Fix for select options visibility */
        .form-control option {
            background-color: var(--primary-dark);
            color: var(--white);
        }

        .form-control:focus {
            outline: none;
            background-color: rgba(255, 255, 255, 0.15);
            box-shadow: 0 0 0 2px var(--accent);
        }

        .form-control::placeholder {
            color: var(--gray);
        }

        textarea.form-control {
            min-height: 120px;
            resize: vertical;
        }

        .form-row {
            display: flex;
            gap: 20px;
        }

        .form-col {
            flex: 1;
        }

        .file-upload {
            position: relative;
            display: inline-block;
            width: 100%;
        }

        .file-upload-input {
            position: absolute;
            left: 0;
            top: 0;
            opacity: 0;
            width: 100%;
            height: 100%;
            cursor: pointer;
        }

        .file-upload-label {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 30px;
            border: 2px dashed rgba(255, 255, 255, 0.3);
            border-radius: 8px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s ease;
        }

        .file-upload-label:hover {
            border-color: var(--accent);
            background-color: rgba(255, 255, 255, 0.05);
        }

        .file-upload-icon {
            font-size: 2.5rem;
            color: var(--accent);
            margin-bottom: 15px;
        }

        .file-upload-text {
            font-size: 0.9rem;
            opacity: 0.8;
        }

        .preview-image {
            max-width: 100%;
            max-height: 200px;
            margin-top: 15px;
            border-radius: 8px;
            display: none;
        }

        .ticket-option {
            background-color: rgba(255, 255, 255, 0.05);
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 15px;
            transition: all 0.3s ease;
        }

        .ticket-option:hover {
            background-color: rgba(255, 255, 255, 0.1);
        }

        .ticket-option-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
        }

        .ticket-option-title {
            font-weight: 500;
            font-size: 1.1rem;
        }

        .remove-ticket {
            background: none;
            border: none;
            color: var(--gray);
            font-size: 1.2rem;
            cursor: pointer;
            transition: all 0.3s ease;
        }

        .remove-ticket:hover {
            color: #ff4d4d;
        }

        .add-ticket {
            display: flex;
            align-items: center;
            gap: 10px;
            background: none;
            border: none;
            color: var(--accent);
            font-weight: 500;
            cursor: pointer;
            padding: 10px 15px;
            border-radius: 8px;
            transition: all 0.3s ease;
        }

        .add-ticket:hover {
            background-color: rgba(250, 204, 21, 0.1);
        }

        .form-actions {
            display: flex;
            justify-content: space-between;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid rgba(255, 255, 255, 0.1);
        }

        .btn {
            padding: 12px 25px;
            border-radius: 8px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.3s ease;
            border: none;
            font-size: 1rem;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .btn-primary {
            background-color: var(--accent);
            color: var(--dark);
        }

        .btn-primary:hover {
            background-color: var(--accent-dark);
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        }

        .btn-secondary {
            background-color: rgba(255, 255, 255, 0.1);
            color: var(--white);
        }

        .btn-secondary:hover {
            background-color: rgba(255, 255, 255, 0.2);
        }

        .btn-outline {
            background: none;
            border: 1px solid var(--accent);
            color: var(--accent);
        }

        .btn-outline:hover {
            background-color: rgba(250, 204, 21, 0.1);
        }

        .progress-bar {
            display: flex;
            justify-content: space-between;
            position: relative;
            margin-bottom: 40px;
        }

        .progress-bar::before {
            content: '';
            position: absolute;
            top: 50%;
            left: 0;
            right: 0;
            height: 2px;
            background-color: rgba(255, 255, 255, 0.1);
            z-index: 1;
            transform: translateY(-50%);
        }

        .progress-step {
            position: relative;
            z-index: 2;
            display: flex;
            flex-direction: column;
            align-items: center;
            width: 25%;
        }

        .progress-step-number {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background-color: rgba(255, 255, 255, 0.1);
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            margin-bottom: 10px;
            transition: all 0.3s ease;
        }

        .progress-step.active .progress-step-number {
            background-color: var(--accent);
            color: var(--dark);
        }

        .progress-step.completed .progress-step-number {
            background-color: var(--accent-dark);
            color: var(--dark);
        }

        .progress-step.completed .progress-step-number::after {
            content: '\f00c';
            font-family: 'Font Awesome 6 Free';
            font-weight: 900;
        }

        .progress-step-label {
            font-size: 0.9rem;
            text-align: center;
            opacity: 0.7;
        }

        .progress-step.active .progress-step-label {
            opacity: 1;
            font-weight: 500;
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

            .form-row {
                flex-direction: column;
                gap: 0;
            }

            .form-col {
                margin-bottom: 20px;
            }

            .form-actions {
                flex-direction: column-reverse;
                gap: 15px;
            }

            .btn {
                width: 100%;
                justify-content: center;
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
            <a href="faq.php">FAQ</a>
            <a href="aide.php">Help</a>
            <a href="apropos.php">About Us</a>
        </div>
        <div class="navbar-right">
            <button class="create-btn">
                <i class="fas fa-plus"></i>
                Create
            </button>
            <div class="user-profile">
                <div class="user-avatar">FF</div>
                <span class="user-name">Freaky-Faidi</span>
                <i class="fas fa-chevron-down"></i>
            </div>
        </div>
    </nav>

    <main class="container">
        <div class="page-header">
            <h1 class="page-title">Create Your Event</h1>
            <p class="page-description">Fill in the details below to create and publish your event on EventHub</p>
        </div>

        <div class="create-container">
            <div class="progress-bar">
                <div class="progress-step active" data-step="1">
                    <div class="progress-step-number">1</div>
                    <div class="progress-step-label">Basic Info</div>
                </div>
                <div class="progress-step" data-step="2">
                    <div class="progress-step-number">2</div>
                    <div class="progress-step-label">Details</div>
                </div>
                <div class="progress-step" data-step="3">
                    <div class="progress-step-number">3</div>
                    <div class="progress-step-label">Tickets</div>
                </div>
                <div class="progress-step" data-step="4">
                    <div class="progress-step-number">4</div>
                    <div class="progress-step-label">Publish</div>
                </div>
            </div>

            <!-- Step 1: Basic Information -->
            <div class="form-step active" id="step-1">
                <div class="form-header">
                    <h2 class="form-title">Basic Information</h2>
                    <p class="form-subtitle">Tell us about your event</p>
                </div>

                <div class="form-group">
                    <label for="event-name" class="form-label">Event Name*</label>
                    <input type="text" id="event-name" class="form-control" placeholder="What's your event called?" required>
                </div>

                <div class="form-group">
                    <label for="event-type" class="form-label">Event Type*</label>
                    <select id="event-type" class="form-control" required>
                        <option value="">Select event type</option>
                        <option value="concert">Concert</option>
                        <option value="festival">Festival</option>
                        <option value="sports">Sports</option>
                        <option value="games">Games</option>
                    </select>
                </div>

                <div class="form-group">
                    <label class="form-label">Event Image*</label>
                    <div class="file-upload">
                        <input type="file" id="event-image" class="file-upload-input" accept="image/*">
                        <label for="event-image" class="file-upload-label">
                            <i class="fas fa-cloud-upload-alt file-upload-icon"></i>
                            <span class="file-upload-text">Click to upload or drag and drop</span>
                            <span class="file-upload-text">PNG, JPG (Max. 5MB)</span>
                        </label>
                        <img id="image-preview" class="preview-image" src="#" alt="Preview">
                    </div>
                </div>

                <div class="form-actions">
                    <button class="btn btn-secondary" disabled>Back</button>
                    <button class="btn btn-primary next-step" data-next="2">Continue</button>
                </div>
            </div>

            <!-- Step 2: Event Details -->
            <div class="form-step" id="step-2">
                <div class="form-header">
                    <h2 class="form-title">Event Details</h2>
                    <p class="form-subtitle">Add more information about your event</p>
                </div>

                <div class="form-row">
                    <div class="form-col">
                        <div class="form-group">
                            <label for="event-date" class="form-label">Date*</label>
                            <input type="date" id="event-date" class="form-control" required>
                        </div>
                    </div>
                    <div class="form-col">
                        <div class="form-group">
                            <label for="start-time" class="form-label">Start Time*</label>
                            <input type="time" id="start-time" class="form-control" required>
                        </div>
                    </div>
                    <div class="form-col">
                        <div class="form-group">
                            <label for="end-time" class="form-label">End Time*</label>
                            <input type="time" id="end-time" class="form-control" required>
                        </div>
                    </div>
                </div>

                <div class="form-group">
                    <label for="event-location" class="form-label">Location*</label>
                    <input type="text" id="event-location" class="form-control" placeholder="Venue name or address" required>
                </div>

                <div class="form-group">
                    <label for="event-description" class="form-label">Description*</label>
                    <textarea id="event-description" class="form-control" placeholder="Tell attendees what your event is about..." required></textarea>
                </div>

                <div class="form-actions">
                    <button class="btn btn-secondary prev-step" data-prev="1">Back</button>
                    <button class="btn btn-primary next-step" data-next="3">Continue</button>
                </div>
            </div>

            <!-- Step 3: Tickets -->
            <div class="form-step" id="step-3">
                <div class="form-header">
                    <h2 class="form-title">Ticket Options</h2>
                    <p class="form-subtitle">Set up your ticket types and pricing</p>
                </div>

                <div id="ticket-options">
                    <div class="ticket-option">
                        <div class="ticket-option-header">
                            <div class="ticket-option-title">General Admission</div>
                            <button class="remove-ticket" style="display: none;"><i class="fas fa-times"></i></button>
                        </div>
                        <div class="form-row">
                            <div class="form-col">
                                <div class="form-group">
                                    <label for="ticket-name-1" class="form-label">Ticket Name*</label>
                                    <input type="text" id="ticket-name-1" class="form-control" value="General Admission" required>
                                </div>
                            </div>
                            <div class="form-col">
                                <div class="form-group">
                                    <label for="ticket-price-1" class="form-label">Price*</label>
                                    <input type="number" id="ticket-price-1" class="form-control" min="0" step="0.01" placeholder="0.00" required>
                                </div>
                            </div>
                            <div class="form-col">
                                <div class="form-group">
                                    <label for="ticket-quantity-1" class="form-label">Quantity*</label>
                                    <input type="number" id="ticket-quantity-1" class="form-control" min="1" value="100" required>
                                </div>
                            </div>
                        </div>
                        <div class="form-group">
                            <label for="ticket-description-1" class="form-label">Description (Optional)</label>
                            <textarea id="ticket-description-1" class="form-control" placeholder="What's included in this ticket?"></textarea>
                        </div>
                    </div>
                </div>

                <button id="add-ticket" class="add-ticket">
                    <i class="fas fa-plus"></i>
                    Add Another Ticket Type
                </button>

                <div class="form-actions">
                    <button class="btn btn-secondary prev-step" data-prev="2">Back</button>
                    <button class="btn btn-primary next-step" data-next="4">Continue</button>
                </div>
            </div>

            <!-- Step 4: Review and Publish -->
            <div class="form-step" id="step-4">
                <div class="form-header">
                    <h2 class="form-title">Review and Publish</h2>
                    <p class="form-subtitle">Almost there! Review your event details before publishing</p>
                </div>

                <div class="form-group">
                    <div id="event-preview" style="background-color: rgba(255, 255, 255, 0.05); padding: 20px; border-radius: 8px;">
                        <h3 style="color: var(--accent); margin-bottom: 15px;">Event Preview</h3>
                        <div id="preview-name" style="font-size: 1.5rem; font-weight: bold; margin-bottom: 10px;"></div>
                        <div id="preview-date-time" style="margin-bottom: 10px;"></div>
                        <div id="preview-location" style="margin-bottom: 15px;"></div>
                        <div id="preview-description" style="margin-bottom: 20px; opacity: 0.9;"></div>
                        
                        <h4 style="color: var(--accent); margin-bottom: 10px;">Tickets</h4>
                        <div id="preview-tickets"></div>
                    </div>
                </div>

                <div class="form-group">
                    <label for="event-terms" class="form-label" style="display: flex; align-items: flex-start; gap: 10px; cursor: pointer;">
                        <input type="checkbox" id="event-terms" style="margin-top: 5px;">
                        <span>I confirm that the event details are correct and I agree to the <a href="#" style="color: var(--accent);">EventHub Terms and Conditions</a></span>
                    </label>
                </div>

                <div class="form-actions">
                    <button class="btn btn-secondary prev-step" data-prev="3">Back</button>
                    <button class="btn btn-primary" id="publish-event" disabled>
                        <i class="fas fa-paper-plane"></i>
                        Publish Event
                    </button>
                </div>
            </div>
        </div>
    </main>

    <footer class="footer">
        <div class="footer-content container">
            <div class="footer-column">
                <h3 class="footer-title">EventHub</h3>
                <p style="margin-bottom: 20px; opacity: 0.8; line-height: 1.6;">
                    Creating unforgettable experiences and connecting people through events.
                </p>
                <div class="social-links">
                    <a href="#" class="social-link"><i class="fab fa-facebook-f"></i></a>
                    <a href="#" class="social-link"><i class="fab fa-twitter"></i></a>
                    <a href="#" class="social-link"><i class="fab fa-instagram"></i></a>
                    <a href="#" class="social-link"><i class="fab fa-linkedin-in"></i></a>
                </div>
            </div>
            <div class="footer-column">
                <h3 class="footer-title">Quick Links</h3>
                <ul class="footer-links">
                    <li><a href="#"><i class="fas fa-angle-right"></i> Browse Events</a></li>
                    <li><a href="#"><i class="fas fa-angle-right"></i> Create Event</a></li>
                    <li><a href="#"><i class="fas fa-angle-right"></i> Pricing</a></li>
                    <li><a href="#"><i class="fas fa-angle-right"></i> Features</a></li>
                    <li><a href="#"><i class="fas fa-angle-right"></i> Success Stories</a></li>
                </ul>
            </div>
            <div class="footer-column">
                <h3 class="footer-title">Resources</h3>
                <ul class="footer-links">
                    <li><a href="#"><i class="fas fa-angle-right"></i> Help Center</a></li>
                    <li><a href="#"><i class="fas fa-angle-right"></i> Event Planning Guide</a></li>
                    <li><a href="#"><i class="fas fa-angle-right"></i> Blog</a></li>
                    <li><a href="#"><i class="fas fa-angle-right"></i> Developer API</a></li>
                    <li><a href="#"><i class="fas fa-angle-right"></i> Contact Support</a></li>
                </ul>
            </div>
            <div class="footer-column">
                <h3 class="footer-title">Subscribe</h3>
                <p style="margin-bottom: 15px; opacity: 0.8; line-height: 1.6;">
                    Get the latest event trends and planning tips in your inbox.
                </p>
                <form class="newsletter-form">
                    <input type="email" class="newsletter-input" placeholder="Your email address" required>
                    <button type="submit" class="newsletter-btn"><i class="fas fa-paper-plane"></i></button>
                </form>
            </div>
        </div>
        <div class="copyright container">
            <p>&copy; 2025 EventHub. All rights reserved.</p>
        </div>
    </footer>

    <script>
        // Mobile menu toggle
        const mobileMenuToggle = document.getElementById('mobileMenuToggle');
        const navMenu = document.getElementById('navMenu');
        
        mobileMenuToggle.addEventListener('click', () => {
            navMenu.classList.toggle('show');
        });
        
        // Form step navigation
        const steps = document.querySelectorAll('.form-step');
        const progressSteps = document.querySelectorAll('.progress-step');
        const nextButtons = document.querySelectorAll('.next-step');
        const prevButtons = document.querySelectorAll('.prev-step');
        
        nextButtons.forEach(button => {
            button.addEventListener('click', () => {
                const currentStep = parseInt(button.dataset.next) - 1;
                const nextStep = parseInt(button.dataset.next);
                
                // Basic validation before proceeding
                if (validateStep(currentStep)) {
                    steps[currentStep].classList.remove('active');
                    steps[nextStep - 1].classList.add('active');
                    
                    progressSteps[currentStep].classList.add('completed');
                    progressSteps[nextStep - 1].classList.add('active');
                }
            });
        });
        
        prevButtons.forEach(button => {
            button.addEventListener('click', () => {
                const currentStep = Array.from(steps).findIndex(step => step.classList.contains('active'));
                const prevStep = parseInt(button.dataset.prev);
                
                steps[currentStep].classList.remove('active');
                steps[prevStep - 1].classList.add('active');
                
                progressSteps[currentStep].classList.remove('active');
                progressSteps[prevStep - 1].classList.add('active');
                progressSteps[prevStep - 1].classList.remove('completed');
            });
        });
        
        // Image upload preview
        const imageInput = document.getElementById('event-image');
        const imagePreview = document.getElementById('image-preview');
        
        imageInput.addEventListener('change', function() {
            const file = this.files[0];
            if (file) {
                const reader = new FileReader();
                reader.onload = function(e) {
                    imagePreview.src = e.target.result;
                    imagePreview.style.display = 'block';
                }
                reader.readAsDataURL(file);
            }
        });
        
        // Add ticket functionality
        const addTicketBtn = document.getElementById('add-ticket');
        const ticketOptions = document.getElementById('ticket-options');
        let ticketCount = 1;
        
        addTicketBtn.addEventListener('click', () => {
            ticketCount++;
            const newTicket = document.createElement('div');
            newTicket.className = 'ticket-option';
            newTicket.innerHTML = `
                <div class="ticket-option-header">
                    <div class="ticket-option-title">New Ticket Type</div>
                    <button class="remove-ticket"><i class="fas fa-times"></i></button>
                </div>
                <div class="form-row">
                    <div class="form-col">
                        <div class="form-group">
                            <label for="ticket-name-${ticketCount}" class="form-label">Ticket Name*</label>
                            <input type="text" id="ticket-name-${ticketCount}" class="form-control" placeholder="VIP, Early Bird, etc." required>
                        </div>
                    </div>
                    <div class="form-col">
                        <div class="form-group">
                            <label for="ticket-price-${ticketCount}" class="form-label">Price*</label>
                            <input type="number" id="ticket-price-${ticketCount}" class="form-control" min="0" step="0.01" placeholder="0.00" required>
                        </div>
                    </div>
                    <div class="form-col">
                        <div class="form-group">
                            <label for="ticket-quantity-${ticketCount}" class="form-label">Quantity*</label>
                            <input type="number" id="ticket-quantity-${ticketCount}" class="form-control" min="1" value="50" required>
                        </div>
                    </div>
                </div>
                <div class="form-group">
                    <label for="ticket-description-${ticketCount}" class="form-label">Description (Optional)</label>
                    <textarea id="ticket-description-${ticketCount}" class="form-control" placeholder="What's included in this ticket?"></textarea>
                </div>
            `;
            ticketOptions.appendChild(newTicket);
            
            // Show remove button for the first ticket type
            if (ticketCount === 2) {
                document.querySelector('.remove-ticket').style.display = 'block';
            }
            
            // Add event listener to the remove button
            const removeButtons = document.querySelectorAll('.remove-ticket');
            removeButtons.forEach(button => {
                button.addEventListener('click', (e) => {
                    e.target.closest('.ticket-option').remove();
                    ticketCount--;
                    if (ticketCount === 1) {
                        document.querySelector('.remove-ticket').style.display = 'none';
                    }
                });
            });
        });
        
        // Preview functionality
        const termsCheckbox = document.getElementById('event-terms');
        const publishBtn = document.getElementById('publish-event');
        
        // Enable publish button when terms are accepted
        termsCheckbox.addEventListener('change', function() {
            publishBtn.disabled = !this.checked;
        });
        
        // Populate preview section
        nextButtons.forEach(button => {
            if (button.dataset.next === "4") {
                button.addEventListener('click', () => {
                    const eventName = document.getElementById('event-name').value;
                    const eventDate = document.getElementById('event-date').value;
                    const startTime = document.getElementById('start-time').value;
                    const endTime = document.getElementById('end-time').value;
                    const eventLocation = document.getElementById('event-location').value;
                    const eventDescription = document.getElementById('event-description').value;
                    
                    // Format date and time
                    const formattedDate = new Date(eventDate).toLocaleDateString('en-US', {
                        weekday: 'long',
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric'
                    });
                    
                    document.getElementById('preview-name').textContent = eventName;
                    document.getElementById('preview-date-time').innerHTML = `<i class="far fa-calendar-alt" style="margin-right: 8px;"></i>${formattedDate}, ${formatTime(startTime)} - ${formatTime(endTime)}`;
                    document.getElementById('preview-location').innerHTML = `<i class="fas fa-map-marker-alt" style="margin-right: 8px;"></i>${eventLocation}`;
                    document.getElementById('preview-description').textContent = eventDescription;
                    
                    // Display ticket information
                    const previewTickets = document.getElementById('preview-tickets');
                    previewTickets.innerHTML = '';
                    
                    const ticketElements = document.querySelectorAll('.ticket-option');
                    ticketElements.forEach((ticket, index) => {
                        const ticketNumber = index + 1;
                        const ticketName = document.getElementById(`ticket-name-${ticketNumber}`).value;
                        const ticketPrice = document.getElementById(`ticket-price-${ticketNumber}`).value;
                        const ticketQuantity = document.getElementById(`ticket-quantity-${ticketNumber}`).value;
                        
                        const ticketDiv = document.createElement('div');
                        ticketDiv.style.marginBottom = '10px';
                        ticketDiv.style.padding = '10px';
                        ticketDiv.style.backgroundColor = 'rgba(255, 255, 255, 0.05)';
                        ticketDiv.style.borderRadius = '4px';
                        
                        ticketDiv.innerHTML = `
                            <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
                                <strong>${ticketName}</strong>
                                <span>${formatCurrency(ticketPrice)}</span>
                            </div>
                            <div style="font-size: 0.9rem; opacity: 0.8;">
                                Quantity: ${ticketQuantity}
                            </div>
                        `;
                        
                        previewTickets.appendChild(ticketDiv);
                    });
                });
            }
        });
        
        // Publish event functionality
        publishBtn.addEventListener('click', () => {
            alert('Your event has been published successfully!');
            // Here you would typically submit the form data to your backend
            // For demonstration, we're just showing an alert
            window.location.href = 'index.html'; // Redirect to home page
        });
        
        // Helper functions
        function validateStep(stepIndex) {
            // Basic validation logic here
            // This is a simplified version
            return true;
        }
        
        function formatTime(timeString) {
            const [hour, minute] = timeString.split(':');
            let period = 'AM';
            let hour12 = parseInt(hour);
            
            if (hour12 >= 12) {
                period = 'PM';
                if (hour12 > 12) {
                    hour12 -= 12;
                }
            }
            if (hour12 === 0) {
                hour12 = 12;
            }
            
            return `${hour12}:${minute} ${period}`;
        }
        
        function formatCurrency(amount) {
            return '$' + parseFloat(amount).toFixed(2);
        }
    </script>
</body>
</html>