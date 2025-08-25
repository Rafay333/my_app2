# MOBILE APP - Software Requirements Specification

## Inventory Types

### Inventory Items Utilization

1. Device Device Acknowledgement Job assignment
2. OBO-I Acknowledgement Job assignment
3. OBO-II Acknowledgement Job assignment
4. Tape Acknowledgement
5. Relay Acknowledgement Job assignment
6. Tie clip Acknowledgement Job assignment
7. Wire thimble Acknowledgement Job assignment
8. Tool bag Acknowledgement Job assignment
9. Tools Acknowledgement Job assignment
10. Cap Acknowledgement Job assignment
11. Uniform Acknowledgement Job assignment

### Inventory
- Inventory from 214/248 is pushed to technicians on their mobile app

### DEVICE
1. Device Receipt acknowledgement
2. Data entry for removed/replaced device
3. Inventory update
4. Removed device dispatch to HO

### Job Task
1. **Installation 248** - Client info, vehicle info, job activity costs, travel costs
2. **Removal 248** - Client info, vehicle info, job activity costs, travel costs
3. **Redo 248** - Client info, vehicle info, job activity costs, travel costs
4. **Removal transfer 248** - Client info, vehicle info, job activity costs, travel costs | Generate Invoice (YIN)
5. **Transfer Installation 248** - Client info, vehicle info, job activity costs, travel costs | Generate Invoice (YIN)
6. **Inspections 248** - Client info, vehicle info, job activity costs, travel costs

### Technician Actions
1. Rejection of assignment/job task
2. Pushed back to Assigner (Tech Ops) 248
3. Acceptance of Job task/assignment

### Pending Jobs
- Addition in Pending Jobs
- Installation of device to be selected from personal inventory maintained in App
- Device Testing through mobile by pushing TESTING button
- Testing OK → Remarks

## DASHBOARD

### Job Completion
- **DONE** → remove from pending jobs
- **Job pending** → reason
- Other items of inventory used in this specific job → drop down of inventory etc.

### Job Complete
- Device number update in 248
- Inventory update in 214
- Forwarded to payment sheet

---

# Software Requirements Specification (SRS)

## 1. Introduction

### 1.1 Purpose

The proposed mobile application will be used by field technicians of a tracking company to manage vehicle tracker installation jobs efficiently. Technicians will receive job invitations from the tech panel and will be able to accept or reject assignments. Upon acceptance, they will get client details and GPS location. The app will record their visit data (location tracking every 10 seconds), allow them to capture vehicle images, test tracking devices remotely, and mark jobs as complete, generating invoices automatically.

### 1.2 Objectives

- Streamline vehicle tracker installations by technicians
- Real-time job assignment and status tracking
- Enhance visibility of technician movements and performance
- Automate invoicing and reporting post job completion

### 1.3 Target Users

- **Technicians**: Install tracker devices, report job status, perform signal testing
- **Admins (via web panel)**: Assign jobs, monitor technician activities, manage client and device data

### 1.4 Scope

This SRS outlines the functional and non-functional requirements of a mobile app that allows technicians to:

- Receive job notifications
- Accept or reject installation tasks
- Navigate to the client's location
- Record live tracking
- Perform pre-installation verification
- Test and install devices
- Mark jobs as completed
- Automatically generate job invoices

### 1.5 Definitions

- **Job**: A scheduled tracker installation task
- **Technician**: A field employee who installs trackers
- **Admin**: Back-office person assigning jobs
- **Signal Testing**: Remote test of device connectivity

## 2. Functional Requirements

### 2.1 User Authentication

- **FR1.1**: Technician shall log in using email/phone and password
- **FR1.2**: Password reset functionality shall be available

### 2.2 Job Notification

- **FR2.1**: Admin sends installation job to technician
- **FR2.2**: App displays Accept and Reject buttons for job notification
- **FR2.3**: If accepted, app shows client location and vehicle details

### 2.3 Location Tracking

- **FR3.1**: App starts location tracking every 10 seconds upon job start
- **FR3.2**: Location data shall be sent to the server

### 2.4 Vehicle Verification

- **FR4.1**: App must allow technician to capture vehicle photos
- **FR4.2**: App must display device serial and model details

### 2.5 Signal Testing

- **FR5.1**: App must include a "Send Test Signal" button
- **FR5.2**: Server will confirm whether device responded correctly

### 2.6 Job Completion

- **FR6.1**: App allows technician to mark job as "Completed"
- **FR6.2**: Upon completion, system generates an invoice automatically

### 2.7 Invoice Generation

- **FR7.1**: Invoice includes technician name, job date/time, client info, and amount

## 3. Non-Functional Requirements

### 3.1 Performance

- App must sync location every 10 seconds with <2s delay
- All server responses must return within 5 seconds

### 3.2 Reliability

- Offline caching of job data if internet is unavailable

### 3.3 Security

- User data must be encrypted
- JWT tokens to be used for authentication

### 3.4 Usability

- App must have intuitive navigation with clear icons and steps

### 3.5 Compatibility

- **Android version**: 8.0+
- **iOS version**: 12+

## 4. System Architecture

### 4.1 Mobile App

- Flutter-based cross-platform UI
- Local DB: SQLite for caching
- Background services for location

### 4.2 Backend

- REST API for login, job details, uploads, tracking
- Admin panel for assigning jobs
- Signal testing via third-party API/device integration

## 5. Data Flow

1. Admin assigns job → Technician gets notification
2. Technician accepts job → Client details and map shown
3. On way → App sends lat/long every 10 seconds
4. At location → Photos taken, signal test sent
5. Job marked done → Invoice auto-generated

## 6. App Flow Examples

### Notification
```
New Task: Install Tracker for Client XYZ
```

### Dashboard
```
XYZ Vehicle Sedan
Location: 123 St
5 km | ETA: 10 min
```

### Location Tracking
```
Updated 10 minutes ago
```

### Vehicle Images
```
[Image capture interface]
```

### Device Testing Status
```
Testing...
Result: Device Working
```

### Job Completion
```
Task: Tracker Installation
Status: Completed
Invoice Generated: 850 PKR
```

## 7. Entity-Relationship Diagram (ERD)

### Entities

#### Technician
- **Attributes**: TechnicianID (PK), Name, Phone, Email

#### Admin
- **Attributes**: AdminID (PK), Name, Email

#### Client
- **Attributes**: ClientID (PK), Name, Address, Phone, VehicleDetails

#### Task
- **Attributes**: TaskID (PK), ClientID (FK), TechnicianID (FK), Status (Pending/Accepted/Rejected/Completed), AssignmentDate

#### Location
- **Attributes**: LocationID (PK), TaskID (FK), Latitude, Longitude, Timestamp

#### Image
- **Attributes**: ImageID (PK), TaskID (FK), ImageURL, UploadDate

#### DeviceTest
- **Attributes**: TestID (PK), TaskID (FK), TestStatus (Working/Not Working), TestDate

#### Invoice
- **Attributes**: InvoiceID (PK), TaskID (FK), Amount, IssueDate, Status (Generated/Sent/Paid)

### Relationships

- **Technician - Task**: One-to-Many (A technician can handle multiple tasks)
- **Admin - Task**: One-to-Many (An admin can assign multiple tasks)
- **Client - Task**: One-to-Many (A client can have multiple tasks)
- **Task - Location**: One-to-Many (A task can have multiple location updates)
- **Task - Image**: One-to-Many (A task can have multiple images)
- **Task - DeviceTest**: One-to-One (A task has one device test)
- **Task - Invoice**: One-to-One (A task generates one invoice)

### ERD Description

- Technician assigns tasks via Admin
- Client is linked to Task for installation assignments
- Task tracks progress with Location updates every 10 seconds
- Image and DeviceTest are associated with Task for verification
- Invoice is generated upon task completion linked to Task

## 8. Budget Estimate

| Component | Estimated Cost (PKR) | Details |
|-----------|---------------------|---------|
| UI/UX Design | 50,000 | Wireframes, prototypes, responsive design for Android/iOS |
| Mobile App Development | 300,000 | Flutter development with all core features |
| Backend Development (API) | 50,000 | ASP.NET MVC APIs, location, image, and signal handling |
| Admin Panel (Web Dashboard) | 50,000 | Job assignment, technician monitoring, invoice records |
| Database Design & Setup | - | SQL Server / PostgreSQL |
| QA & Testing | - | Manual testing, bug fixing, test cases |
| Project Management / Documentation | - | SRS, reports, delivery milestones |

**Total Estimated Budget: 450,000 - 500,000 PKR**