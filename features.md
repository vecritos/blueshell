# Blueshellctl Module & Feature Backlog

## 1. Bootstrapping & Setup  
- **1.a Initial Setup**  
  - 1.a.1 Remove OEM packages  
  - 1.a.2 Create local user account  
  - 1.a.3 Bypass login screen  
  - 1.a.4 Forced reboot to login screen  
- **1.b Registry Hardening**  
  - 1.b.1 LSA / Credential theft protection  
  - 1.b.2 UAC Hardening  
  - 1.b.3 Disable USB Storage (USBSTOR)  
  - 1.b.4 Device installation restrictions  
  - 1.b.5 PowerShell lockdown  
  - 1.b.6 Disable Windows Script Host  
  - 1.b.7 SMB hardening  
  - 1.b.8 RDP disable  
  - 1.b.9 Disable Autorun/Autoplay  
  - 1.b.10 Event log hardening and anti-tamper  
  - 1.b.11 Disable legacy boot behavior  
- **1.c Network Hardening**  
  - 1.c.1 Configure firewall defaults  
  - 1.c.2 Setup rclone firewall port toggle  
  - 1.c.3 Network context profiles (default, inspect, paranoid, secure notes)  

## 2. Blueshellctl CLI & Core Management
- **2.a Command Dispatch**  
  - 2.a.1 Bootstrap commands  
  - 2.a.2 Rclone install, configure, open/close ports  
  - 2.a.3 Log scraping and inspection  
  - 2.a.4 User management  
  - 2.a.5 Monitoring (Sysmon install, removal)  
  - 2.a.6 Sandboxing commands (browser, WSL)  
  - 2.a.7 Registry hardening invoke  
  - 2.a.8 Firewall commands  
- **2.b Bootstrap Status & Reset**  
  - 2.b.1 Blueshellctl bootstrap state tracking
  - 2.b.2 Forced reset and fresh pull of blueshellctl repo
  - 2.b.3 Network kill during bootstrap  

## 3. Backup & Sync Integration  
- **3.a Rclone Integration**  
  - 3.a.1 Install rclone in WSL environment  
  - 3.a.2 Configured default Google Drive backend  
  - 3.a.3 .rclone-filter rules for mounted blocks (e.g. ignore `/secret` folders)  
  - 3.a.4 Startup sync triggered on block mount  
  - 3.a.5 Firewall port toggle controlled via blueshellctl

## 4. Sandboxing & Isolation  
- **4.a Windows Sandbox & AppLocker**  
  - 4.a.1 Enable Windows Sandbox feature  
  - 4.a.2 Configure AppLocker policies (future)  
- **4.b Browser Sandboxing**  
  - 4.b.1 Launch Edge in sandboxed, InPrivate mode  
- **4.c WSL Sandboxing & Networking**  
  - 4.c.1 Multiple network contexts (default, inspect, paranoid)  
  - 4.c.2 Proxy hops and multi-hop routing in paranoid mode  
  - 4.c.3 Network restrictions for inspect and secure_notes modes  

## 5. Monitoring & Logging  
- 5.a Sysmon Installation & Removal  
- 5.b Log Scraping  
- 5.c Interactive Log Inspection & Secure Shredding  
- 5.d Firewall Logging & Readonly toggle based on connectivity  

## 6. Device & User Management  
- 6.a Local User Creation & Configuration  
- 6.b Device Registration Bypass & Local-only Login Setup  
- 6.c USB Device Hardening  
  - 6.c.1 Disable USB storage via registry  
  - 6.c.2 Device installation restrictions  

## 7. Security Enhancements  
- 7.a TPM Validation & Secure Boot Check (planned)  
- 7.b Disk Encryption Setup (planned)  
- 7.c Integrity & Boundary Checks on Commands  
- 7.d User Permission Management (planned)  

## 8. Utilities & Helpers  
- 8.a Constants & Configuration File (URLs, hardcoded values)  
- 8.b Network Adapter Enable/Disable Helpers  
- 8.c Script Logging & Error Handling  
- 8.d Command Line Helpers for blueshellctl

