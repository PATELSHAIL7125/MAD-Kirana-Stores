# SOFTWARE REQUIREMENTS SPECIFICATION

**Smart Kirana – Kirana Store Billing & Khata App**

**Smart Retail Management System**

**Document Type**	Software Requirements Specification (IEEE 830)  
**Project Name**	Smart Kirana – Kirana Store App

**Course / Department**	IT366 – Mobile Application Development  
**Guide Name**	Sagar Patel  
**College Name**	CSPIT  
**Academic Year**	2025–2026  
**Date**	

---

## CERTIFICATE

This is to certify that the project entitled “Smart Kirana – Kirana Store App” has been successfully completed by the following student(s) under the guidance of Sagar M. Patel, in partial fulfillment of the requirements for the Semester 6 Mobile Application Development (IT366) course during the academic year 2025–2026.

**Project Team:**

| Sr. No. | Student Name | Enrollment No. |
| :--- | :--- | :--- |
| 1 | Shail Patel | [Your Enrollment No.] |

The work presented in this project is original and has not been submitted elsewhere. The project has been developed, tested, and deployed successfully. All the requirements specified in this Software Requirements Specification (SRS) document have been implemented and verified.


**Internal Guide**  
Sagar M. Patel	

**Head of Department**  
Purvi M. Prajapati

**Date:** _________________     **Place:** _________________

---

## ACKNOWLEDGMENT

I would like to express my sincere gratitude to everyone who contributed to the successful completion of this project.

First and foremost, I am deeply grateful to my project guide, Prof. Sagar M. Patel, for his invaluable guidance, constant encouragement, and constructive feedback throughout the entire duration of this project. His expertise in mobile application development and software engineering played a pivotal role in shaping the quality and direction of this work.

I sincerely thank Dr. Purvi M. Prajapati, Head of the Department of Information Technology Engineering at CSPIT, for providing the necessary academic infrastructure, resources, and a stimulating environment that made this project possible.

I am also deeply thankful to the faculty members of CSPIT for providing the necessary academic support, resources, and learning environment required for the successful completion of this work. The knowledge gained during coursework played a crucial role in understanding key concepts such as mobile UI design, POS building, local database management, and authentication mechanisms.

I would also like to acknowledge the open-source community, especially contributors to Flutter, Firebase, and related database tools, whose documentation greatly supported this project.

Finally, I extend my heartfelt thanks to my family and friends whose unwavering support and encouragement were a constant source of motivation throughout this journey.

Shail Patel  
Enrollment No.: [Your Enrollment No.]  
CSPIT – IT

---

## ABSTRACT

In the modern retail environment, local Kirana stores often rely on manual ledgers and traditional billing methods, which lead to calculation errors, misplaced records, and inefficient inventory management. 

Smart Kirana (MAD Kirana Stores) is a comprehensive mobile-based solution that enables store owners to digitally manage billing, inventory, and customer ledgers (Khata). The application is developed using Flutter for a cross-platform, responsive UI, integrating Firebase for secure backend operations and real-time syncing.

The system supports complete CRUD operations for product inventory, an interactive Point of Sale (POS) screen for fast billing, and an integrated Khata system for managing customer credit and payments. It provides a structured, scalable solution tailored to local retail businesses.

The application is designed to be highly intuitive, ensuring that store owners with minimal technical expertise can operate the software effectively. By automating calculations, digitalizing receipts, and maintaining an organized digital ledger, Smart Kirana significantly reduces manual effort and improves store profitability.

This SRS document defines the functional and non-functional requirements, system design, database structure, and UI/UX of the Smart Kirana app, which provides a modern digital infrastructure for local retail businesses.

**Keywords**  
Kirana Store System, Retail Billing App, POS System, Khata Ledger, Mobile Application, Flutter, Firebase Authentication, Inventory Management, CRUD Operations, Financial Reports, Customer Management, UI/UX Design

---

## TABLE OF CONTENTS

1. [INTRODUCTION](#1-introduction)
2. [OVERALL DESCRIPTION](#2-overall-description)
3. [FUNCTIONAL REQUIREMENTS](#3-functional-requirements)
4. [NON-FUNCTIONAL REQUIREMENTS](#4-non-functional-requirements)
5. [SYSTEM DESIGN & ARCHITECTURE](#5-system-design--architecture)
6. [DATABASE DESIGN](#6-database-design)
7. [USER INTERFACE DESIGN](#7-user-interface-design)
8. [FUTURE ENHANCEMENTS](#8-future-enhancements)
9. [CONCLUSION](#9-conclusion)
10. [REFERENCES](#10-references)

---

## 1. INTRODUCTION

### 1.1 Background
Local grocery and Kirana stores form the backbone of the retail ecosystem. However, most of these stores still rely heavily on pen-and-paper ledgers to maintain daily sales, track inventory, and record customer credit (Khata). These traditional methods are prone to data loss, physical damage, calculation errors, and make auditing exceptionally difficult.
With the widespread adoption of smartphones, there is an immense opportunity to digitize local retail operations. Bringing billing, inventory control, and customer management into a unified mobile application ensures better financial transparency and saves hours of manual accounting time.

Smart Kirana addresses this need by providing an all-in-one digital toolkit specifically tailored to the workflow of a Kirana store. Utilizing Flutter, it delivers a fast and robust user experience.

### 1.2 Problem Statement
The following critical challenges motivate the development of Smart Kirana:
- Reliance on paper-based billing and physical Khata books that can be easily lost or ruined.
- High margin of error in manual daily sales calculation.
- Lack of real-time visibility into out-of-stock or fast-moving inventory.
- Difficulty in effectively tracking pending customer dues and managing partial payments.
- Time-consuming end-of-day reconciliation.
- Absence of a digital record and reliable data export capabilities for financial planning.

### 1.3 Project Objectives
Smart Kirana is designed to achieve the following primary objectives:
1. Develop a fast, intuitive Point of Sale (POS) billing screen.
2. Provide a robust Inventory management system (CRUD operations for products).
3. Implement a digital Khata book to manage customer credit, partial payments, and history.
4. Enhance data security and account management using Firebase Authentication.
5. Generate actionable insights through daily/monthly sales reports.
6. Support receipt sharing capability (e.g., via WhatsApp).
7. Ensure the UI is easy enough to be used by store staff without special training.
8. Support robust Settings, including password changes and CSV data export.

### 1.4 Scope
The application is intended to operate as a centralized dashboard for retail merchants. It handles everything from authenticating the business owner, managing their shop's inventory, facilitating quick checkout for buyers via multiple payment models (Cash, Online, Khata), and recording these transactions. It stores its records on a secure backend and provides analytics tracking to the user.

### 1.5 Document Conventions

| Term / Abbreviation | Definition |
| :--- | :--- |
| SRS | Software Requirements Specification |
| POS | Point of Sale – the screen where checkout occurs |
| Khata | Digital ledger used to track reliable customers' credits/debts |
| Flutter | Cross-platform mobile app development framework by Google |
| Firebase | Cloud backend platform for authentication and real-time database |
| CRUD | Create, Read, Update, Delete |
| UI / UX | User Interface / User Experience |

---

## 2. OVERALL DESCRIPTION

### 2.1 Product Perspective
Smart Kirana is a standalone mobile application designed using a client-server architecture. The frontend is built utilizing Flutter, enabling fluid animations and a responsive grid/list layout. Firebase services facilitate secure user sessions and rapid synchronization of store data. Features are grouped logically into distinct modules such as Billing, Inventory, Khata, and Reports.

### 2.2 Product Features Summary

| Feature | Category | Description |
| :--- | :--- | :--- |
| **Authentication** | Security | Store owners securely register/login and access their custom settings |
| **POS Billing** | Core | Simple interface to search, add items to cart, and generate a final bill with multiple payment options |
| **Inventory Management** | Core | Add, edit, or delete items, adjust stock count, and manage pricing info |
| **Khata (Ledger)** | Core | Track customers, review active credits, log partial/complete payments |
| **Sales Reports** | Analytics | View summaries of daily or monthly sales and category-wise performance |
| **Data Export** | Utility | Export ledgers and sales records to CSV |

### 2.3 User Classes and Characteristics
**Kirana Store Owners / Cashiers (Primary Users):**
- Fast-paced environment requiring minimum taps to complete a transaction.
- Needs accurate tracking of customer debts (Khata).
- Requires simple, readable dashboards to understand today’s revenue.
- Basic smartphone literacy.

### 2.4 Operating Environment
- **Platform:** Android 6.0+ (iOS optional based on build).
- **Framework:** Flutter (Dart).
- **Backend:** Firebase (Auth, Firestore).
- **Network Requirements:** Internet connection needed for initial auth and real-time cloud-sync.

### 2.5 Design and Implementation Constraints
- The UI must comfortably support long lists of items.
- Must execute billing calculations instantaneously without delay.
- Requires network connection for initial configuration and backup.

### 2.6 Assumptions and Dependencies
- Users possess an Android smartphone.
- Stores have inventory that can be categorically arranged.
- Third-party packages (e.g., CSV parsers, Charting libraries tools) continue to be maintained.

---

## 3. FUNCTIONAL REQUIREMENTS

### 3.1 User Authentication Module
- **FR-AUTH-01:** Allow store owners to register using email/password.
- **FR-AUTH-02:** Authenticate users efficiently and maintain a secure session.
- **FR-AUTH-03:** Provide options to change passwords via the settings screen, mandating re-authentication.
- **FR-AUTH-04:** Securely log users out of their dashboard.

### 3.2 Billing (POS) Module
- **FR-BIL-01:** Provide a responsive checkout cart allowing users to add/remove items and adjust quantities.
- **FR-BIL-02:** Calculate order totals instantly, incorporating potential discounts.
- **FR-BIL-03:** Support multiple checkout methods: Cash, Online (UPI/QR), and Khata (Credit).
- **FR-BIL-04:** Allow generation and sharing of the final bill receipt.

### 3.3 Inventory Management Module
- **FR-INV-01:** Allow the merchant to create a new product entry (Name, price, stock).
- **FR-INV-02:** Allow reading/searching the entire product list visually.
- **FR-INV-03:** Update existing stock details or pricing at any time.
- **FR-INV-04:** Delete discontinued items safely from the database.

### 3.4 Khata (Customer Ledger) Module
- **FR-KHA-01:** Let users add distinct customer profiles to track store credit.
- **FR-KHA-02:** View pending balances per customer.
- **FR-KHA-03:** Allow the entry of full or partial payments, immediately updating the remaining balance.

### 3.5 Reports and Analytics Module
- **FR-REP-01:** Calculate out end-of-day sales totals dynamically.
- **FR-REP-02:** Visualize data using charts for intuitive trend analysis.

### 3.6 Settings & Export Module
- **FR-SET-01:** Update primary business detailing (Shop Name, Owner).
- **FR-SET-02:** Export local ledger and product data into highly portable CSV files for offline usage or tax reporting.

---

## 4. NON-FUNCTIONAL REQUIREMENTS

### 4.1 Performance
- **Speed:** Screen transitions and cart calculations must execute in under 1 second.
- **Concurrency:** Data handling logic must correctly deal with simultaneous asynchronous calls without crashing.

### 4.2 Security
- **Data Protection:** Business data separated uniquely per authenticated UID.
- **Integrity:** Protection against accidental Khata erasures to prevent financial mismatch over customer debt.

### 4.3 Usability
- Designed utilizing a highly accessible "Emerald Green" and White palette reminiscent of fresh retail imagery.
- Uses large, distinct touch targets (buttons) to accommodate fast, error-free tapping at the shop counter.

### 4.4 Reliability
- Resists crashing on ill-formatted user inputs. Form validations should exist across product additions and user profiles.

### 4.5 Maintainability
- Enforces strict BLoC / Provider / Repository logic layering to allow for rapid bug fixing and modular feature additions down the line.

---

## 5. SYSTEM DESIGN & ARCHITECTURE

### 5.1 Architecture Overview
Smart Kirana separates internal logic into distinct layers, primarily adhering to a Model-View-ViewModel (MVVM) or similar repository-driven architecture enabled by Flutter.
- **Presentation Layer (UI):** Built fully in Flutter, utilizing dynamic widget trees.
- **Business Logic Layer:** Translates user events into backend calls to update stocks or log bills.
- **Data Layer:** Cloud Firestore coupled tightly to data model classes for seamless serialization.

### 5.2 API / Backend Architecture
Uses Firebase ecosystem integrations:
- `FirebaseAuth` for issuing tokens.
- Firestore as a NoSQL document database, allowing offline persistence and snapshot-based real-time UI updates.

### 5.3 Data Flow — Billing Process
1. Merchant presses "Add to Cart" on the POS screen. UI State updates.
2. Merchant initiates checkout on the selected items.
3. If Khata is selected, a customer is linked.
4. Business logic calculates final integer amounts, and the API calls Firestore to decrement the associated stock levels.
5. The transaction record is generated and successful result displays.

---

## 6. DATABASE DESIGN

### 6.1 Overview
The app relies on a NoSQL document structure via Firebase Firestore. Collections are usually nested under the authenticated user's `uid` to strictly partition one store's data from another.

### 6.2 Users Collection (`/users/{uid}`)
| Field | Type | Description |
| :--- | :--- | :--- |
| shopName | String | Registered name of the Kirana Store |
| email | String | Store owner email |
| ownerName | String | Name of proprietor |
| createdAt | Timestamp | Registration date |

### 6.3 Inventory / Products Collection (`/users/{uid}/products/{product_id}`)
| Field | Type | Description |
| :--- | :--- | :--- |
| name | String | Product Name |
| price | Number | Retail selling price |
| stock | Number | Current available quantity |
| category | String | E.g., Dairy, Spices, Cleaning |

### 6.4 Transactions / Bills Collection (`/users/{uid}/bills/{bill_id}`)
| Field | Type | Description |
| :--- | :--- | :--- |
| totalAmount | Number | Final generated bill amount |
| items | Array | Objects containing bought items + qtys |
| paymentMethod | String | Cash / Online / Khata |
| timestamp | Timestamp | When bill occurred |

### 6.5 Customers (Khata) Collection (`/users/{uid}/customers/{customer_id}`)
| Field | Type | Description |
| :--- | :--- | :--- |
| name | String | Customer identity |
| phone | String | Customer contact |
| pendingDue | Number | Current outstanding credit amount |

---

## 7. USER INTERFACE DESIGN

### 7.1 Design Principles
- **Modern Minimalist Aesthetics**: Embraces a fresh retail look utilizing Emerald Green (`#2ECC71`) accents over clean white spaces.
- **Prominent POS Flow**: Navigation explicitly tailored around bringing the user to checkout as fast as possible.
- **Quick Actions**: Critical tools (Add Product, View Khata) are surfaced immediately.

### 7.2 Screen Inventory and Descriptions

**7.2.1 Authentication Screens**
Clean forms ensuring fast onboarding. Supports registering the store profile.

**7.2.2 Dashboard (Home)**
A high-level view exhibiting key metrics (Today's Sale) and acting as a springboard using "Quick Actions" for navigation to Billing, Inventory, and Khata.

**7.2.3 Inventory Viewer & Add/Edit Layout**
A scrollable grid or list rendering existing stock. Toggling to edit launches a straightforward card-based form to safely input naming and pricing numbers.

**7.2.4 POS / Billing Cart**
An interactive cart overlay where merchants rapidly update quantities, apply final payment methodology blocks, and confirm a checkout.

**7.2.5 Payment Flow & Receipt**
Confirmation cards handling split logic (Cash vs Khata) culminating in a visual receipt ready to be transferred to the buyer.

**7.2.6 Khata Screens**
A dedicated ledger space showing a directory of known customers with color-coded "To Receive" flags. Clicking one drills down into specific past credit interactions.

**7.2.7 Reports & Analytics**
A visually rich graphical presentation summarizing income metrics.

**7.2.8 Settings Screen**
Houses essential account configurations: altering store identity, toggling passcodes, and initiating the crucial "Export Datasets to CSV" function.

---

## 8. FUTURE ENHANCEMENTS

### 8.1 WhatsApp Integration
Future updates could build on receipt-sharing to automatically message PDF invoices or Khata reminder notifications directly to customers' WhatsApp numbers.

### 8.2 Barcode Scanners
Implement a view tapping into the device camera to read UPC borders, instantaneously assigning items to the cart rather than searching.

### 8.3 Multi-Staff Logins
Offering Role-Based Access Control limits cashier power vs owner power (e.g., cashiers cannot view monthly net summaries).

### 8.4 Low-Stock Automated Alerts
Local push notifications that warn the merchant when specific product levels dip below a configurable threshold.

---

## 9. CONCLUSION
The Smart Kirana application comprehensively modernizes the day-to-day operations of an independent grocery store. By uniting an intuitive Point-of-Sale with a sophisticated local ledger (Khata) and real-time inventory oversight, it eliminates common manual redundancies and accounting errors.

Leveraging the performant Flutter UI engine mapped to Firebase's reliable real-time database architecture provides merchants a fast, scalable, and beautifully designed digital ecosystem. The project effectively demonstrates structural mobile programming, database integration, UI flow optimization, and secure state management, resulting in a ready-for-market retail product.

---

## 10. REFERENCES
1. Flutter Team. (2024). Flutter Documentation. Google LLC. https://flutter.dev/docs
2. Firebase Team. (2024). Firebase Documentation: Authentication and Firestore. Google LLC. https://firebase.google.com/docs
3. Gamma, E., Helm, R., Johnson, R., & Vlissides, J. (1994). Design Patterns: Elements of Reusable Object-Oriented Software. Addison-Wesley.
4. Google. (2024). Material Design 3 Guidelines. https://m3.material.io
5. IEEE. (1998). IEEE Std 830-1998: IEEE Recommended Practice for Software Requirements Specifications.
