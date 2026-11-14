# Google Sheets Tracker Guide: Flaw & Incident Management

## COMP 018 -- Database Administration Midterm Examination

**Target Systems:** CampusSafe (`grp07_campussafedb`) & Park-It
(`grp_parkitdb`)\
**Lead DBA & QA Coordinator:** Group 7 -- Jefferson Orpesa

------------------------------------------------------------------------

## 1. Overview & Purpose

This tracker guide outlines the operational workflow, import procedures,
schema specifications, and status lifecycle governing the cross-group
database administration midterm examination.

Two primary registers coordinate work between the **Designer Group**
(auditors crafting fault designs for the peer system) and the **Owner
Group** (defenders remediating incidents on their home system):

1.  **Flaw Register (`FLAW_REGISTER.csv`)**: Master log of verified
    baseline defects identified during technical auditing.
2.  **Incident Register (`INCIDENT_REGISTER.csv`)**: Lifecycle tracker
    managing incident brief release, investigation progress, root cause
    identification, and verification.

------------------------------------------------------------------------

## 2. Google Sheets Setup & Import Instructions

Follow these steps to establish the collaborative tracking workbook.

### Step 1: Create Spreadsheet

1.  Open Google Sheets (`sheets.new`).
2.  Set the spreadsheet title to
    `COMP018_Midterm_Group07_CampusSafe_Tracker`.

### Step 2: Import Flaw Register Sheet

1.  Rename the first sheet tab to `Flaw Register`.
2.  Navigate to **File \> Import \> Upload** and select
    `midterm/tracker/FLAW_REGISTER.csv`.
3.  Set **Import location** to **Replace current sheet**.
4.  Set **Separator type** to **Comma**.
5.  Click **Import data**.
6.  Format the header: freeze Row 1, bold the header text, and set the
    background fill to Navy Blue (`#1E3A8A`) with white text.

### Step 3: Import Incident Register Sheet

1.  Click **+ (Add Sheet)** and name the tab `Incident Register`.
2.  Navigate to **File \> Import \> Upload** and select
    `midterm/tracker/INCIDENT_REGISTER.csv`.
3.  Set **Import location** to **Replace current sheet**.
4.  Set **Separator type** to **Comma**.
5.  Format the header: freeze Row 1, bold the header text, and set the
    background fill to Dark Slate (`#334155`) with white text.

### Step 4: Configure Data Validation Rules

Apply dropdown data validation to the following tracking columns:

-   **Flaw Register --- `Severity` (Column H):** `Low`, `Medium`,
    `High`, `Critical`.
-   **Flaw Register --- `Owner Status` (Column I):** `Reported`,
    `Verified`, `Under Remediation`, `Resolved`, `Rejected`.
-   **Incident Register --- `Difficulty` (Column H):** `Easy`, `Medium`,
    `Hard`.
-   **Incident Register --- `Status` (Column I):** `Draft`, `In Review`,
    `Ready for Release`, `Released`, `In Investigation`, `Remediated`,
    `Verified`, `Closed`, `PENDING RELEASE`.

------------------------------------------------------------------------

## 3. Data Dictionaries & Column Specifications

### 3.1 Flaw Register Schema (`FLAW_REGISTER.csv`)

  ----------------------------------------------------------------------------------------
  \#             Column Name         Type           Description    Allowed Values / Format
  -------------- ------------------- -------------- -------------- -----------------------
  1              `Flaw ID`           String         Unique flaw    `G<grp>-FLAW-<num>`
                                                    tracking key   (e.g. `G07-FLAW-1`)

  2              `Project`           String         Target         `CampusSafe`, `Park-It`
                                                    database       
                                                    project        

  3              `Reported By`       String         Auditing group `Group 7`,
                                                    identifier     `External Peer Group`

  4              `Area`              String         Database       `Access Control`,
                                                    technical      `Configuration`,
                                                    domain         `Performance`,
                                                                   `Maintenance`,
                                                                   `Disaster Recovery`

  5              `Activity`          String         Aligned COMP   `Activity 3`,
                                                    018 activity   `Activity 4`,
                                                                   `Activity 5`,
                                                                   `Activity 6`

  6              `Description`       String         Technical      Concise prose
                                                    synopsis of    describing the failure
                                                    defect         

  7              `Evidence Link`     String         Relative link  Path to markdown or log
                                                    to repository  file
                                                    evidence       

  8              `Severity`          Enum           Impact         `Low`, `Medium`,
                                                    severity       `High`, `Critical`
                                                    rating         

  9              `Owner Status`      Enum           Current owner  `Reported`, `Verified`,
                                                    remediation    `Under Remediation`,
                                                    state          `Resolved`

  10             `Recommended Fix`   String         High-level DBA SQL command or
                                                    remediation    architectural fix
  ----------------------------------------------------------------------------------------

### 3.2 Incident Register Schema (`INCIDENT_REGISTER.csv`)

  ------------------------------------------------------------------------------------------------------------------
  \#             Column Name          Type           Description    Allowed Values / Format
  -------------- -------------------- -------------- -------------- ------------------------------------------------
  1              `Incident ID`        String         Unique         `G<grp>-INC-<num>` or `OWNER-INC-<num>`
                                                     incident       
                                                     identifier     

  2              `Flaw ID`            String         Associated     Valid `Flaw ID` or `PENDING`
                                                     baseline flaw  
                                                     key            

  3              `Project`            String         Target project `Park-It`, `CampusSafe`
                                                     under incident 

  4              `Designer Group`     String         Group          `Group 7`, `External Designer`
                                                     designing the  
                                                     scenario       

  5              `Variant`            String         Difficulty     `Variant A`, `Variant B`
                                                     variant        
                                                     designation    

  6              `Activity Area`      String         Technical      e.g. `Activity 4 - Privileges`
                                                     domain and     
                                                     activity       

  7              `Incident Brief`     String         Relative path  e.g. `designer/incident-designs/INCIDENT_1.md`
                                                     to user brief  

  8              `Difficulty`         Enum           Assigned       `Easy` (x2), `Medium` (x2), `Hard` (x1)
                                                     difficulty     
                                                     level          

  9              `Status`             Enum           Incident       See Section 4: Status Transition Lifecycle &
                                                     operational    Workflow
                                                     lifecycle      

  10             `Owner Root Cause`   String         Root cause     Technical cause string or `Pending Owner Fix`
                                                     diagnosed by   
                                                     owner          

  11             `Owner Result`       Enum           Verification   `Pending Peer Owner Fix`, `Verified`,
                                                     outcome        `PENDING RELEASE`

  12             `Report Link`        String         Link to answer Relative repository path
                                                     key or dossier 
  ------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

## 4. Status Transition Lifecycle & Workflow

The incident lifecycle follows a strict state machine:

``` mermaid
stateDiagram-v2
    [*] --> Draft
    Draft --> In_Review : Designer audits flaw
    In_Review --> Ready_for_Release : Script tested against sandbox
    Ready_for_Release --> Released : Peer group begins examination
    Released --> In_Investigation : Owner executes Step 1 - 4
    In_Investigation --> Remediated : Owner applies minimal fix (Step 5)
    Remediated --> Verified : Owner runs paired tests (Step 6)
    Verified --> Closed : Evaluated against Master Answer Key
    Closed --> [*]
```

### Transition Gates

1.  **Draft → Ready for Release:** Designer must confirm that the fault
    script executes cleanly, reproduces the symptom, and that the reset
    script restores 100% of the baseline state.
2.  **Released → In Investigation:** Owner opens the dossier, logs the
    observation, and executes the diagnostic query.
3.  **In Investigation → Remediated:** Corrective SQL must be minimal,
    tested on a disposable database, and committed to
    `owner/scripts/corrective-actions/`.
4.  **Remediated → Verified:** Both the positive query and the negative
    security test must pass without error.
5.  **Verified → Closed:** Designer reviews the owner's evidence against
    `ANSWER_KEY.md` and records the final grade.

------------------------------------------------------------------------

## 5. Multi-Group Collaboration & Access Rules

### 5.1 Permission Separation

-   **Group 7 (CampusSafe):** Full Editor access on Designer columns for
    Park-It incidents; Viewer access on Designer Answer Keys of other
    groups.
-   **Peer Group:** Full Editor access on their designated Designer
    rows; Viewer access on CampusSafe Owner dossiers until defense
    completion.

### 5.2 Confidentiality Rule

The `ANSWER_KEY.md` and grading rubrics must remain private to the
Designer Group until the oral defense concludes.

### 5.3 No Unilateral Status Changes

A status cannot be moved to `Verified` without providing the stdout log
link and Git commit hash in the notes column.
