# Team Contributions

## Smart Solar Installation & Grid Compliance Platform

**Module:** SE3090 – Software Engineering Frameworks

**Group:** 2026-AI-17

---

## 1. Contribution Overview

The Smart Solar Installation & Grid Compliance Platform was developed collaboratively by four group members.

The project combines:

- ASP.NET Core 8 API
- PostgreSQL / Entity Framework Core
- React staff web application
- Flutter homeowner and technician application
- FastAPI and LangGraph internal agentic services
- Automated testing and integration
- Security, authentication and authorization
- Technical documentation and project evidence

Each member is responsible for a primary business area while also contributing across the API, database, frontend, agentic workflow, testing, integration, Git/GitHub and documentation.

The four primary business areas are:

1. Customer Assessment & Solar Sizing
2. Field Operations & Grid Compliance
3. Engineering Proposals & Approval
4. Equipment Pricing & Inventory

---

# 2. Team Members

| Member | Student ID | Primary Responsibility |
|---|---|---|
| Member 1 – `Herath H.M.T.P` | `IT24103586` | Customer Assessment & Solar Sizing |
| Member 2 – `Perera K.V.N` | `IT24103554` | Field Operations & Grid Compliance |
| Member 3 – `Kulathunga K.M.T.J` | `IT24100209` | Engineering Proposals & Approval |
| Member 4 – `W.A.N.Anjana` | `IT24300116` | Equipment Pricing & Inventory |

> **Note:** Names, student IDs and contribution descriptions should reflect the actual work performed by each member.

---

# 3. Member 1 — Customer Assessment & Solar Sizing

**Member:** `Herath H.M.T.P`  
**Student ID:** `IT24103586`

### Primary Responsibility

Customer assessment, solar survey workflow and solar sizing.

### Contributions

- Worked on customer profile and solar assessment functionality.
- Implemented or enhanced relevant ASP.NET Core API endpoints.
- Worked with customer profile, solar survey and workflow data.
- Contributed to PostgreSQL database entities, relationships and persistence.
- Developed or enhanced relevant React survey functionality.
- Developed or enhanced Flutter homeowner survey, photo and status functionality.
- Worked on the `SolarSizingAgent`.
- Contributed to coordination between the API and internal agentic services.
- Improved validation of customer objectives and solar-sizing inputs.
- Added or updated automated tests for the implemented functionality.
- Contributed to integration testing across the API, frontend and agentic workflow.
- Documented the implemented functionality and development decisions.

### Demonstration / Viva Evidence

The member should be able to demonstrate:

**Customer input → solar assessment → preliminary calculation → validation → persisted result**

---

# 4. Member 2 — Field Operations & Grid Compliance

**Member:** `Perera K.V.N`  
**Student ID:** `IT24103554`

### Primary Responsibility

Field operations, technician workflow and grid-compliance screening.

### Contributions

- Worked on field-job assignment and technician workflows.
- Implemented or enhanced relevant ASP.NET Core API endpoints.
- Worked with field-job, site-inspection and site-telemetry data.
- Contributed to PostgreSQL database entities and relationships.
- Developed or enhanced React staff dispatch and inspection-review functionality.
- Developed or enhanced Flutter technician functionality.
- Worked with device location and camera/gallery functionality.
- Worked on the `GridComplianceAgent`.
- Improved validation and handling of missing or out-of-range inspection values.
- Contributed to authorization and permission-denial handling.
- Added or updated automated API, database, UI or agent tests.
- Contributed to integration testing and device verification.
- Documented the field-operation and compliance workflow.

### Demonstration / Viva Evidence

The member should be able to demonstrate:

**Job assignment → technician check-in → inspection/measurements → compliance screening → validated result**

The member should also explain why the compliance screening is **not utility certification**.

---

# 5. Member 3 — Engineering Proposals & Approval

**Member:** `Kulathunga K.M.T.J`  
**Student ID:** `IT24100209`

### Primary Responsibility

Engineering proposals, safety review and approval workflow.

### Contributions

- Worked on proposal creation and lifecycle APIs.
- Implemented or enhanced approve, reject and revision workflows.
- Worked with proposal, approval and lifecycle records.
- Contributed to PostgreSQL persistence and audit records.
- Developed or enhanced the React engineer workspace.
- Developed or enhanced Flutter proposal/status functionality.
- Worked on the `SafetyGuardrailAgent`.
- Contributed to safety validation and deterministic checks.
- Improved handling of proposal revisions and workflow recovery.
- Tested unauthorized approval attempts.
- Tested stale, invalid or concurrent approval scenarios where applicable.
- Added or updated automated tests.
- Contributed to API, frontend and agent integration.
- Documented the approval and safety-review workflow.

### Demonstration / Viva Evidence

The member should be able to demonstrate:

**Proposal creation → safety checks → engineer review → approve/reject/revise → persisted audit history**

The member should explain that the agent **cannot approve a proposal** and that final approval is performed by an authorized engineer.

---

# 6. Member 4 — Equipment Pricing & Inventory

**Member:** `W.A.N.Anjana`  
**Student ID:** `IT24300116`

### Primary Responsibility

Equipment catalog, pricing, stock management and reservation.

### Contributions

- Worked on equipment catalog and inventory APIs.
- Implemented or enhanced supplier, quote, reservation and release workflows.
- Worked with inventory, quotation and reservation database records.
- Contributed to PostgreSQL transactions and data integrity.
- Developed or enhanced React inventory and pricing screens.
- Developed or enhanced Flutter equipment-status functionality.
- Worked on the `EquipmentPricingAgent`.
- Integrated the controlled exchange-rate pricing workflow.
- Contributed to USD/LKR exchange-rate validation and freshness checks.
- Worked on stock availability and reservation validation.
- Tested reservation replay/idempotency and stock release behaviour.
- Contributed to transaction rollback and concurrency testing.
- Added or updated automated tests.
- Contributed to API, frontend, database and agent integration.
- Documented the inventory and pricing workflow.

### Demonstration / Viva Evidence

The member should be able to demonstrate:

**Approved proposal → equipment selection → price calculation → availability check → reservation → release**

The member should explain exchange-rate validation, stock rechecking, transaction handling and idempotency.

---

# 7. Shared Team Contributions

All four members contributed to the overall development and integration of the platform.

Shared activities include:

- Requirements analysis and system planning.
- System architecture discussions.
- API and component integration.
- Database design discussions.
- Frontend and backend integration.
- Agentic workflow integration.
- Functional testing.
- Integration testing.
- Debugging and issue resolution.
- Security and authorization testing.
- Git and GitHub collaboration.
- Code review and peer review.
- Technical documentation.
- README maintenance.
- Assignment evidence preparation.
- Demonstration preparation.
- Final system verification.

---

# 8. Cross-Layer Contribution

Each member's primary area includes work across multiple technical layers rather than being limited to a single technology.

| Layer | Member 1 | Member 2 | Member 3 | Member 4 |
|---|---|---|---|---|
| ASP.NET Core API | ✓ | ✓ | ✓ | ✓ |
| PostgreSQL / EF Core | ✓ | ✓ | ✓ | ✓ |
| React | ✓ | ✓ | ✓ | ✓ |
| Flutter | ✓ | ✓ | ✓ | ✓ |
| Agentic AI | Solar Sizing | Compliance | Safety | Pricing |
| Testing | ✓ | ✓ | ✓ | ✓ |
| Integration | ✓ | ✓ | ✓ | ✓ |
| Documentation | ✓ | ✓ | ✓ | ✓ |
| Git / GitHub | ✓ | ✓ | ✓ | ✓ |

The table represents the intended cross-layer contribution structure. Each check should correspond to actual work that can be demonstrated through the repository, implementation, tests, documentation or viva.

---

# 9. Agent Contributions

The project contains four primary domain specialists:

| Agent | Primary Domain | Responsible Member |
|---|---|---|
| `SolarSizingAgent` | Preliminary solar system sizing | Member 1 |
| `GridComplianceAgent` | Grid/compliance screening | Member 2 |
| `SafetyGuardrailAgent` | Safety and proposal checks | Member 3 |
| `EquipmentPricingAgent` | Equipment pricing and availability | Member 4 |

`PlannerAgent` acts as an additional coordinator for the workflow.

The current implementation uses deterministic specialist logic and validation rather than a hosted large language model. Agent outputs are validated before being accepted by the business workflow.

---

# 10. Testing & Quality Contributions

Each member is responsible for testing the functionality associated with their contribution.

Testing activities include:

- Unit testing
- API testing
- Database/integration testing
- React testing
- Flutter testing
- Agent workflow testing
- Validation testing
- Authorization testing
- Negative/error-path testing
- Integration testing
- Idempotency and transaction testing where applicable

The project includes automated tests across the backend, Python agentic services, React frontend and Flutter application.

---

# 11. Git & Collaboration

Git and GitHub are used for source-code management and collaboration.

Each member is expected to:

- Work on genuine assigned tasks.
- Create meaningful commits for their own work.
- Use branches where appropriate.
- Participate in pull requests/code reviews.
- Review another member's work.
- Test changes before integration.
- Resolve integration issues collaboratively.
- Maintain documentation related to their contribution.

The repository history should remain an accurate record of development. Existing commits are not rewritten or backdated to artificially change authorship.

---

# 12. Individual Evidence

Each member should maintain evidence for their own contribution, including where applicable:

- Relevant Git commits
- Branches and pull requests
- Issues/tasks
- Source-code changes
- Test cases
- Screenshots
- API evidence
- Database evidence
- Agent workflow evidence
- Frontend/mobile evidence
- Documentation changes
- Integration/debugging evidence

Each member should also be able to explain, test, modify and debug their contribution during the viva.

---

# 13. Contribution Verification

The contribution descriptions in this document should be supported by actual project evidence.

For each member, the following should be identifiable:

1. What functionality they worked on.
2. Which files/components they changed.
3. Which tests they added or modified.
4. Which integration work they performed.
5. Which Git/GitHub activity represents their work.
6. What they can demonstrate during the viva.

Contribution claims should describe actual work performed by the member and should not be created retrospectively to manufacture Git history.

---

# 14. Final Team Declaration

We confirm that the contribution descriptions provided in this document represent the work performed by the respective group members during the development of the project.

Where work was performed collaboratively, it is identified as a shared contribution.

Each member is responsible for understanding and being able to demonstrate the functionality attributed to them.

---

## Group

**SE3090 – Software Engineering Frameworks**  
**Group 2026-AI-17**

| Member | Name | Student ID |
|---|---|---|
| Member 1 | `Herath H.M.T.P` | `IT24103586` | 
| Member 2 | `Perera K.V.N` | `IT24103554` | 
| Member 3 | `Kulathunga K.M.T.J` | `IT24100209` |
| Member 4 | `W.A.N.Anjana` | `IT24300116` | 

**Date:** `[30/09/2026]`
