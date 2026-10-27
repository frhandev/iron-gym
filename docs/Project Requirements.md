# Section 1 – Requirements Analysis

**Project:** Iron Gym Membership Management System  
**Course:** Database Management Systems  
**Prepared by:** Muhammed Ferhan  
**Date:** 25th Oct 2026

> **Purpose of this document:** Define what the system will do, who will use it, and what information it will store. Database design decisions should be consistent with these requirements.

## 1.1 System Description

### 1.1.1 Purpose

The purpose of this project is to design a system that can manage a gym's membership, membership packages, trainers, group classes, reservations, and payment operations through a centralized database.
The system aims to ensure that gym operations are tracked systematically, reduce data redundancy, and improve the efficiency of interactions between members and staff.

### 1.1.2 Scope

**In scope (what the system will do):**

- Managing member and staff information.
- Creating and updating membership packages.
- Tracking membership start and end dates.
- Recording membership payments.
- Managing trainer information and group classes.
- Creating session schedules for group classes.
- Allowing members to make reservations for group class sessions.
- Tracking attendance at sessions.
- Generating basic management reports.

**Out of scope (what the system will not do):**

The system will not include online credit card payment processing, biometric access control, personalized nutrition programs, or gym equipment maintenance management.

### 1.1.3 Target Users

The system will be used by gym members, trainers, reception staff, and administrators.

## 1.2 User Roles and Permissions

The system includes four main user roles. Each role can perform different operations according to its assigned permissions.

**Role definitions:**

- **Member:** View personal membership information, browse membership packages, make reservations for group classes, and cancel reservations.
- **Trainer:** View assigned group class sessions and manage attendance records.
- **Receptionist:** Create and update member records, manage memberships, record payments, and monitor reservation statuses.
- **Administrator:** Manage user roles, modify membership packages, manage trainer and session assignments, and view system reports.

A user may have multiple roles. For example, a trainer may also have a member account.

## 1.3 Core Functionalities

The Gym Membership and Management System will provide the following core functionalities:

1. Member Registration: Registering new members' personal and contact information in the system.
2. User Management: Managing user information and roles.
3. Membership Package Management: Creating and updating membership packages, including their duration, fees, and descriptions.
4. Membership Creation: Assigning a membership to a member based on a selected package.
5. Membership Status Tracking: Tracking membership start dates, end dates, and validity statuses.
6. Payment Management: Recording payment amounts, payment dates, and payment methods associated with memberships.
7. Trainer Management: Managing trainer information and responsibilities.
8. Group Class Management: Creating and modifying group class types.
9. Session Scheduling: Defining the dates, times, rooms, and assigned trainers for group class sessions.
10. Reservation Creation: Allowing members to make reservations for available group class sessions.
11. Reservation Cancellation: Allowing members to cancel existing reservations.
12. Capacity Control: Monitoring the occupancy levels of group class sessions.
13. Attendance Tracking: Recording members' attendance at group classes.
14. Reporting: Generating reports on members, memberships, payments, and class attendance.

## 1.4 Business Rules

The following business rules will be applied to ensure data integrity and the correct operation of the system:

- **BR-01**: Each user must have a unique email address. Multiple users cannot be registered with the same email address.
- **BR-02**: A membership's end date must be later than its start date.
- **BR-03**: A member cannot have more than one active membership during overlapping date periods.
- **BR-04**: A recorded payment amount must be greater than zero.
- **BR-05**: Only members with a valid membership on the reservation date may make reservations for group class sessions.
- **BR-06**: A member cannot have more than one reservation record for the same group class session. A canceled reservation may be reactivated.
- **BR-07**: The number of active reservations for a session cannot exceed the session's specified capacity. The session capacity must also not exceed the room's capacity.
- **BR-08**: The same trainer or room cannot be assigned to multiple sessions with overlapping time periods.

These business rules will be incorporated into the database design using appropriate keys, constraints, and, when necessary, transaction or trigger-based controls.

## 1.5 Requirements Classification

### 1.5.1 Functional Requirements

- **FR-01:** The system shall allow user registration information to be created and updated.
- **FR-02:** The system shall enforce operation permissions based on user roles.
- **FR-03:** The system shall support membership package management.
- **FR-04:** The system shall allow memberships to be assigned to members and their statuses to be tracked.
- **FR-05:** The system shall maintain payment records associated with memberships.
- **FR-06:** The system shall support the management of trainers and group class information.
- **FR-07:** The system shall allow session schedules to be created for group classes.
- **FR-08:** The system shall allow eligible members to make and cancel session reservations.
- **FR-09:** The system shall monitor session capacities and attendance records.
- **FR-10:** The system shall be capable of generating basic management reports.

### 1.5.2 Non-Functional Requirements

- **NFR-01** — Security: User access rights shall be restricted according to their roles, and passwords shall be securely hashed before storage.
- **NFR-02** — Data Integrity: Appropriate database constraints, such as PK, FK, UNIQUE, NOT NULL, CHECK, and DEFAULT, shall be implemented.
- **NFR-03** — Performance: Common database queries should be completed within a reasonable time under normal operating conditions.
- **NFR-04** — Reliability: Critical operations, such as payments and reservations, shall be performed in a way that prevents data inconsistencies.
- **NFR-05** — Backup: The system shall support regular database backups and restoration procedures to protect against data loss.
- **NFR-06** — Maintainability and Extensibility: The database design shall support the addition of new membership packages and group class types.
