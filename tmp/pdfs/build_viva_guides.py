from __future__ import annotations

import html
import subprocess
from pathlib import Path


ROOT = Path(r"C:\Users\thisu\Desktop\SEF\New folder\Smart-Solar-Installation-Grid-Compliance-Platform")
OUT = ROOT / "output" / "pdf"
TMP = ROOT / "tmp" / "pdfs"
EDGE = Path(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe")
OUT.mkdir(parents=True, exist_ok=True)
TMP.mkdir(parents=True, exist_ok=True)


def pair(en: str, si: str, cls: str = "pair") -> str:
    return f'<div class="{cls}"><div class="en">{en}</div><div class="si" lang="si">{si}</div></div>'


def bullets(items: list[tuple[str, str]]) -> str:
    return '<div class="bullets">' + ''.join(pair(f'<span class="dot">•</span>{html.escape(a)}', html.escape(b)) for a, b in items) + '</div>'


def numbered(items: list[tuple[str, str]]) -> str:
    return '<div class="steps">' + ''.join(
        f'<div class="step"><div class="num">{i}</div>{pair(html.escape(a), html.escape(b), "step-pair")}</div>'
        for i, (a, b) in enumerate(items, 1)
    ) + '</div>'


def section(title_en: str, title_si: str, body: str, kicker: str = "") -> str:
    k = f'<div class="kicker">{html.escape(kicker)}</div>' if kicker else ''
    return f'<section>{k}<h2>{html.escape(title_en)}</h2><div class="h2-si" lang="si">{html.escape(title_si)}</div>{body}</section>'


common_architecture = [
    ("React staff portal and Flutter operational app call only the ASP.NET Core public API.", "React staff portal එක සහ Flutter operational app එක call කරන්නේ ASP.NET Core public API එක පමණයි."),
    ("ASP.NET Core owns authentication, role authorization, validation, business rules, persistence, approval and audit logging.", "Authentication, role authorization, validation, business rules, persistence, approval සහ audit logging වල authoritative layer එක ASP.NET Core වේ."),
    ("Entity Framework Core maps the domain entities to PostgreSQL; migrations version the schema.", "Entity Framework Core මගින් domain entities PostgreSQL tables සමඟ map කරන අතර migrations මගින් schema වෙනස්කම් version කරයි."),
    ("ASP.NET calls the internal FastAPI agent service using X-Internal-Key. Clients never call Python directly.", "ASP.NET විසින් X-Internal-Key භාවිතා කර internal FastAPI agent service එක call කරයි. Client apps Python service එක සෘජුව call නොකරයි."),
    ("The system runs without a paid LLM. Planner selection and specialist calculations are deterministic and reviewable; do not claim live LLM reasoning or generative RAG.", "System එක paid LLM එකක් නැතිව ක්‍රියා කරයි. Planner selection සහ specialist calculations deterministic හා review කළ හැකි ඒවාය; live LLM reasoning හෝ generative RAG භාවිතා කරන බව නොකියන්න."),
    ("Durable workflow state and execution summaries are stored in PostgreSQL, so a paused workflow can resume after a service restart.", "Durable workflow state සහ execution summaries PostgreSQL තුළ save කරන නිසා service restart එකකින් පසුවත් paused workflow එක resume කළ හැකිය."),
]


rubric = [
    ("ASP.NET Core API - 10: explain REST routes, DTOs, async services, validation, status codes, authorization and exception handling; be ready to change or debug one endpoint.", "ASP.NET Core API - ලකුණු 10: REST routes, DTOs, async services, validation, status codes, authorization සහ exception handling පැහැදිලි කර endpoint එකක් වෙනස් හෝ debug කිරීමට සූදානම් වන්න."),
    ("PostgreSQL - 10: explain entities, keys, relationships, constraints, indexes, migrations, audit fields and transaction boundaries.", "PostgreSQL - ලකුණු 10: entities, keys, relationships, constraints, indexes, migrations, audit fields සහ transaction boundaries පැහැදිලි කරන්න."),
    ("React - 10: explain routing, hooks/state, protected navigation, API integration, reusable UI, validation and loading/empty/error/success states.", "React - ලකුණු 10: routing, hooks/state, protected navigation, API integration, reusable UI, validation සහ loading/empty/error/success states පැහැදිලි කරන්න."),
    ("Flutter - 10: explain navigation, reusable widgets, API/token handling, responsive layout, validation, state and the device feature used by your component.", "Flutter - ලකුණු 10: navigation, reusable widgets, API/token handling, responsive layout, validation, state සහ ඔබගේ component එකේ device feature එක පැහැදිලි කරන්න."),
    ("Individual agent - 12: prove a distinct responsibility, typed input/output, controlled tools, deterministic validation, errors, security, observability, tests and visible workflow participation.", "Individual agent - ලකුණු 12: වෙනස් responsibility එකක්, typed input/output, controlled tools, deterministic validation, errors, security, observability, tests සහ workflow participation පෙන්වන්න."),
    ("Integration and security - 10: trace one request across both clients, ASP.NET, PostgreSQL and Python; explain JWT, RBAC, internal key, secrets and safe failure.", "Integration සහ security - ලකුණු 10: request එකක් clients, ASP.NET, PostgreSQL සහ Python හරහා trace කර JWT, RBAC, internal key, secrets සහ safe failure පැහැදිලි කරන්න."),
    ("Testing, CI and Git - 8: explain one meaningful test, a failure it prevents, the GitHub Actions steps, your issues/commits/PRs/reviews and how you diagnose CI.", "Testing, CI සහ Git - ලකුණු 8: meaningful test එකක්, එය වැළැක්වෙන failure එක, GitHub Actions steps, ඔබගේ issues/commits/PRs/reviews සහ CI diagnose කරන ආකාරය පැහැදිලි කරන්න."),
]


agent_acceptance = [
    ("Objective: a domain goal enters the workflow and remains traceable.", "Objective: domain goal එක workflow එකට ඇතුළත් වී trace කළ හැකිව පවතී."),
    ("Plan and delegation: PlannerAgent creates typed steps with dependencies, required inputs, allowed tools and human-impact markers.", "Plan සහ delegation: PlannerAgent dependencies, required inputs, allowed tools සහ human-impact markers සහිත typed steps හදයි."),
    ("Distinct agents: SolarSizingAgent, GridComplianceAgent, SafetyGuardrailAgent and EquipmentPricingAgent have different contracts and responsibilities.", "Distinct agents: SolarSizingAgent, GridComplianceAgent, SafetyGuardrailAgent සහ EquipmentPricingAgent වෙනස් contracts සහ responsibilities දරයි."),
    ("Controlled tools: only allow-listed tools are callable; GridCompliance uses ProjectKnowledgeTool and Pricing uses ExchangeRateTool.", "Controlled tools: allow-list කළ tools පමණක් call කළ හැකිය; GridCompliance විසින් ProjectKnowledgeTool සහ Pricing විසින් ExchangeRateTool භාවිතා කරයි."),
    ("Shared state: workflow ID, objective, plan, completed steps, tool/validation results, errors, approval, retry count and outcome are persisted.", "Shared state: workflow ID, objective, plan, completed steps, tool/validation results, errors, approval, retry count සහ outcome persist කරයි."),
    ("Validation: Pydantic/schema checks and independent deterministic business validators run before results are accepted.", "Validation: result accept කිරීමට පෙර Pydantic/schema checks සහ වෙනම deterministic business validators ක්‍රියා කරයි."),
    ("Human approval: engineer approval is a server-enforced pause; the AI cannot approve or reserve stock.", "Human approval: engineer approval එක server-enforced pause එකකි; AI එකට approve කිරීමට හෝ stock reserve කිරීමට නොහැක."),
    ("Observability and safe failure: trace/span/stage/timing, decisions, retries and errors are recorded without storing hidden chain-of-thought.", "Observability සහ safe failure: hidden chain-of-thought save නොකර trace/span/stage/timing, decisions, retries සහ errors record කරයි."),
]


shared_questions = [
    ("Why do both clients use ASP.NET instead of calling PostgreSQL or Python?", "Security and consistency. ASP.NET is the single public gateway that applies identity, roles, validation and business rules before data or agents are reached.", "Clients දෙකම PostgreSQL හෝ Python සෘජුව call නොකරන්නේ ඇයි?", "Security සහ consistency සඳහාය. ASP.NET එකම public gateway එක ලෙස identity, roles, validation සහ business rules enforce කරයි."),
    ("Is this really Agentic AI without an LLM?", "The assignment permits a justified custom orchestration approach. This implementation demonstrates objective-based planning, delegation, controlled tools, durable state, validators, pause/resume, human approval and auditability. It is deterministic; I will not mislabel it as live LLM reasoning.", "LLM එකක් නැතිව මෙය ඇත්තටම Agentic AI ද?", "Assignment එක justified custom orchestration approach එකකට ඉඩ දෙයි. මෙය objective-based planning, delegation, controlled tools, durable state, validators, pause/resume, human approval සහ auditability පෙන්වයි. එය deterministic වන අතර live LLM reasoning ලෙස වැරදි ලෙස හඳුන්වන්නේ නැහැ."),
    ("What is authentication versus authorization?", "Authentication proves who the user is. Authorization checks whether that authenticated role may perform a specific operation.", "Authentication සහ authorization අතර වෙනස කුමක්ද?", "Authentication පරිශීලකයා කවුදැයි තහවුරු කරයි. Authorization එම authenticated role එකට නිශ්චිත ක්‍රියාව කළ හැකිදැයි පරීක්ෂා කරයි."),
    ("What should happen when the AI service is unavailable?", "ASP.NET returns a controlled error or records a safe failure; it must not invent a successful result or bypass validation/approval.", "AI service එක unavailable නම් කුමක් විය යුතුද?", "ASP.NET controlled error එකක් return කිරීම හෝ safe failure එකක් record කිරීම කළ යුතුය; successful result එකක් හදා පෙන්වීම හෝ validation/approval bypass කිරීම නොකළ යුතුය."),
    ("What must you be able to do in the viva?", "Explain, trace, test, make a small change and debug your own component without an external AI assistant.", "Viva එකේ ඔබට කළ හැකි විය යුත්තේ කුමක්ද?", "External AI assistant එකක් නොමැතිව ඔබගේ component එක explain, trace, test, small change සහ debug කිරීමට හැකි විය යුතුය."),
]


roles = [
    {
        "n": 1,
        "slug": "Member-1-Assessment-Solar-Sizing-Viva-Guide-EN-SI",
        "title": "Customer Assessment and Solar Sizing",
        "title_si": "පාරිභෝගික ඇගයීම සහ සූර්ය පද්ධති ප්‍රමාණ නිර්ණය",
        "agent": "SolarSizingAgent",
        "mission": ("Turn a homeowner's named property survey into a validated preliminary solar-size recommendation while preserving ownership, evidence and workflow status.", "Homeownerගේ නම දුන් property survey එක ownership, evidence සහ workflow status සමඟ validate කළ preliminary solar-size recommendation එකක් බවට පත් කිරීම."),
        "paths": ["backend/SolarPlatform.Api/Features/Assessment", "frontend-web/src/features/assessment", "frontend-mobile/lib/features/assessment", "agentic-ai/app/features/assessment", "backend/SolarPlatform.Tests/Features/Assessment"],
        "entities": [("CustomerProfile", "the authenticated homeowner's profile details"), ("SolarSurvey", "project name, address/location, energy use, roof area, grid connection, objective and lifecycle"), ("SolarSurveyImage", "survey evidence metadata and durable file reference")],
        "apis": ["POST /api/surveys", "GET /api/surveys and GET /api/surveys/{id}", "PUT /api/surveys/{id}", "POST /api/surveys/{id}/submit", "DELETE /api/surveys/{id}", "POST /api/surveys/{id}/retry", "POST /api/surveys/{id}/images", "GET /api/surveys/{id}/status", "GET/PUT /api/customer/profile"],
        "features": [
            ("Accept a clear project/survey name so the same customer can distinguish multiple properties or installations.", "එකම customerගේ properties හෝ installations කිහිපයක් වෙනස් කර හඳුනාගැනීමට පැහැදිලි project/survey name එකක් ලබා ගනී."),
            ("Capture address plus latitude/longitude through address search, current location or map pin; reverse geocoding fills the readable address.", "Address search, current location හෝ map pin මගින් address සහ latitude/longitude ලබාගෙන reverse geocoding මගින් කියවිය හැකි address එක පුරවයි."),
            ("Validate electricity usage, roof area and grid connection in client and server layers; the server remains authoritative.", "Electricity usage, roof area සහ grid connection client සහ server layers දෙකේම validate කරන අතර server එක authoritative වේ."),
            ("Save a draft, reopen it, upload evidence, submit it and show sizing/workflow status with clear error states.", "Draft save කර නැවත open කිරීම, evidence upload කිරීම, submit කිරීම සහ sizing/workflow status clear error states සමඟ පෙන්වයි."),
        ],
        "agent_detail": [
            ("Input contract", "validated survey facts: objective, monthly kWh, usable roof area and relevant assumptions"),
            ("Output contract", "recommended kW, panel count, inverter size and explicit assumptions"),
            ("Validation", "independent checks ensure positive values, feasible panel count/inverter sizing and expected limits"),
            ("Permissions", "no external tools, approval authority or database writes"),
            ("Failure", "invalid/missing inputs return a structured safe error; the backend must not persist a fake recommendation"),
        ],
        "demo": [
            ("Log in as homeowner and create a survey with a memorable project name.", "Homeowner ලෙස login වී මතක තබාගත හැකි project name එකක් සහිත survey එකක් හදන්න."),
            ("Choose current location or a map pin and show that both coordinates and readable address are captured.", "Current location හෝ map pin එකක් තෝරා coordinates සහ readable address දෙකම capture වන බව පෙන්වන්න."),
            ("Enter usage, roof area and grid connection; trigger one validation error and correct it.", "Usage, roof area සහ grid connection දමා validation error එකක් trigger කර එය නිවැරදි කරන්න."),
            ("Save the draft, leave the screen, reopen it and prove the data persisted.", "Draft එක save කර screen එකෙන් පිටවී නැවත open කර data persist වී ඇති බව පෙන්වන්න."),
            ("Upload survey evidence, submit, then show SolarSizingAgent output and the workflow trace/status.", "Survey evidence upload කර submit කිරීමෙන් පසු SolarSizingAgent output සහ workflow trace/status පෙන්වන්න."),
            ("Open the same survey from the staff web app to prove shared API and database integration.", "Shared API සහ database integration පෙන්වීමට එම survey එකම staff web app එකෙන් open කරන්න."),
        ],
        "questions": [
            ("How is the recommended capacity calculated?", "Explain the deterministic usage/roof inputs and assumptions used by SolarSizingAgent, then the independent validator. Do not claim an LLM guessed it.", "Recommended capacity එක ගණනය කරන්නේ කෙසේද?", "SolarSizingAgent භාවිතා කරන deterministic usage/roof inputs සහ assumptions, ඉන්පසු independent validator එක පැහැදිලි කරන්න. LLM එකක් guess කළා යැයි නොකියන්න."),
            ("Why store both address and coordinates?", "The address is readable to people; coordinates support maps, technician navigation and distance checks even when text addresses are ambiguous.", "Address සහ coordinates දෙකම save කරන්නේ ඇයි?", "Address එක මිනිසුන්ට කියවිය හැකි අතර coordinates maps, technician navigation සහ distance checks සඳහා නිවැරදි location එක සපයයි."),
            ("How do you prevent one homeowner editing another survey?", "Use the authenticated user ID in the service query and return forbidden/not-found when ownership does not match; never trust a client-supplied owner ID.", "Homeowner කෙනෙකුට වෙනත් කෙනෙකුගේ survey edit කිරීම වළක්වන්නේ කෙසේද?", "Service query එකේ authenticated user ID භාවිතා කර ownership නොගැළපේ නම් forbidden/not-found return කරයි; client-supplied owner ID විශ්වාස නොකරයි."),
            ("What small viva change might be requested?", "Add or change a roof-area/business validation, a DTO field, an empty-state message, or a test for ownership/status transition.", "Viva එකේ ඉල්ලිය හැකි small change එක කුමක්ද?", "Roof-area/business validation එකක්, DTO field එකක්, empty-state message එකක් හෝ ownership/status-transition test එකක් එකතු/වෙනස් කිරීම."),
        ],
        "risks": [
            ("A solar sizing recommendation is preliminary planning, not structural engineering or utility approval.", "Solar sizing recommendation එක preliminary planning සඳහා පමණි; එය structural engineering හෝ utility approval නොවේ."),
            ("Browser geolocation requires permission and often HTTPS; denial must leave manual address/map selection usable.", "Browser geolocation සඳහා permission සහ බොහෝවිට HTTPS අවශ්‍යය; permission deny කළත් manual address/map selection භාවිතා කළ හැකි විය යුතුය."),
        ],
    },
    {
        "n": 2,
        "slug": "Member-2-Field-Operations-Grid-Compliance-Viva-Guide-EN-SI",
        "title": "Field Operations and Grid Compliance",
        "title_si": "ක්ෂේත්‍ර මෙහෙයුම් සහ ජාල අනුකූලතා පරීක්ෂාව",
        "agent": "GridComplianceAgent",
        "mission": ("Move an assigned field visit from navigation and GPS arrival through a recoverable inspection draft, photo evidence, telemetry submission and validated compliance screening.", "Assigned field visit එක navigation සහ GPS arrival සිට recover කළ හැකි inspection draft, photo evidence, telemetry submission සහ validated compliance screening දක්වා ගෙන යාම."),
        "paths": ["backend/SolarPlatform.Api/Features/FieldOperations", "frontend-web/src/features/field-operations", "frontend-mobile/lib/features/field_operations", "agentic-ai/app/features/field_operations", "backend/SolarPlatform.Tests/Features/FieldOperations"],
        "entities": [("FieldJob", "survey, assigned technician, priority, schedule and job status"), ("SiteInspection", "roof/electrical observations and draft/submission data"), ("SiteTelemetry", "measured voltage, frequency, Voc and Isc"), ("SitePhoto", "typed Cloudinary evidence references"), ("ComplianceAssessment", "findings, risk/result and execution reference")],
        "apis": ["GET/POST/PUT /api/field-jobs", "GET /api/field-jobs/technicians", "GET /api/field-jobs/{jobId}/photos", "GET /api/technician/jobs", "POST /api/technician/jobs/{jobId}/check-in", "PUT /api/technician/jobs/{jobId}/inspection", "POST /api/technician/jobs/{jobId}/telemetry", "POST /api/technician/jobs/{jobId}/photos", "POST /api/technician/jobs/{jobId}/submit", "GET /api/technician/jobs/{jobId}/compliance", "GET /api/locations/search and /reverse"],
        "features": [
            ("Engineer assigns an available technician, priority and optional visit date/time using validated, searchable controls.", "Engineer විසින් searchable, validated controls භාවිතා කර available technician, priority සහ optional visit date/time assign කරයි."),
            ("Technician captures a starting location, opens a route to the homeowner coordinates and records site-arrival GPS check-in.", "Technician තම starting location ලබාගෙන homeowner coordinates වෙත route එක open කර site-arrival GPS check-in එක record කරයි."),
            ("Inspection values can be saved as an incomplete draft and restored later without marking compliance complete.", "Incomplete inspection values draft ලෙස save කර පසුව restore කළ හැකි අතර එයින් compliance complete ලෙස mark නොවිය යුතුය."),
            ("Four typed photos - roof, meter, electrical panel and inverter location - are stored in Cloudinary while PostgreSQL stores metadata/URLs.", "Roof, meter, electrical panel සහ inverter location යන typed photos හතර Cloudinary තුළ තබා PostgreSQL තුළ metadata/URLs තබයි."),
            ("Only explicit submission starts compliance evaluation; photo upload alone must never complete compliance.", "Explicit submit කිරීමෙන් පමණක් compliance evaluation ආරම්භ විය යුතුය; photo upload කිරීමෙන් පමණක් compliance complete නොවිය යුතුය."),
        ],
        "agent_detail": [
            ("Input contract", "submitted measurements, inspection facts and the relevant survey/job context"),
            ("Tool", "versioned ProjectKnowledgeTool; read-only, reviewed guidance only, no arbitrary web access"),
            ("Output contract", "structured findings, compliance status, risk and cited screening rules"),
            ("Validation", "DeterministicComplianceValidator checks required readings and thresholds independently"),
            ("Failure", "missing/out-of-range evidence returns correction/safe failure; the agent cannot certify CEB/LECO approval"),
        ],
        "demo": [
            ("As engineer, create an assignment and show validation for missing site/technician or invalid schedule.", "Engineer ලෙස assignment එකක් හදා missing site/technician හෝ invalid schedule validation පෙන්වන්න."),
            ("As technician in Flutter, capture current location and open navigation to the homeowner location.", "Flutter තුළ technician ලෙස current location capture කර homeowner location වෙත navigation open කරන්න."),
            ("Record GPS arrival and show the success tick beside the check-in section.", "GPS arrival record කර check-in section එක අසල success tick එක පෙන්වන්න."),
            ("Enter only part of the inspection, save draft, reopen and prove fields are restored but compliance is not complete.", "Inspection එකේ කොටසක් පමණක් දමා draft save කර නැවත open කර fields restore වුවත් compliance complete නොවන බව පෙන්වන්න."),
            ("Upload four synthetic evidence photos and show the engineer can retrieve them through authorized API delivery.", "Synthetic evidence photos හතර upload කර engineerට authorized API delivery හරහා ඒවා retrieve කළ හැකි බව පෙන්වන්න."),
            ("Submit telemetry explicitly; show GridComplianceAgent, ProjectKnowledgeTool, validator result, trace and correction path for one bad value.", "Telemetry explicit ලෙස submit කර GridComplianceAgent, ProjectKnowledgeTool, validator result, trace සහ bad value එකකට correction path පෙන්වන්න."),
        ],
        "questions": [
            ("Why are draft save and submit separate?", "A draft preserves incomplete field work. Submit is an intentional state transition that requires complete evidence and starts compliance evaluation.", "Draft save සහ submit වෙනම තබන්නේ ඇයි?", "Draft එක incomplete field work සුරකියි. Submit එක complete evidence අවශ්‍ය, compliance evaluation ආරම්භ කරන intentional state transition එකකි."),
            ("Why store images in Cloudinary instead of PostgreSQL?", "Object storage/CDN is suitable for large binaries and hosting durability; PostgreSQL stores searchable metadata and secure references. Access must still be authorized.", "Images PostgreSQL වෙනුවට Cloudinary තුළ තබන්නේ ඇයි?", "Large binary files සහ hosting durability සඳහා object storage/CDN සුදුසුය; PostgreSQL searchable metadata සහ secure references තබයි. Access තවමත් authorize කළ යුතුය."),
            ("What happens if GPS permission is denied?", "Show a clear error, keep the screen usable, allow retry, and never pretend check-in succeeded. Navigation may use known addresses, but arrival verification needs valid coordinates.", "GPS permission deny කළහොත්?", "Clear error එකක් පෙන්වා screen usable තබා retry කිරීමට ඉඩ දී check-in success ලෙස වංචා නොකළ යුතුය. Navigation address මත කළ හැකි නමුත් arrival verification සඳහා valid coordinates අවශ්‍යය."),
            ("What small viva change might be requested?", "Change a telemetry limit, require a missing photo type, add a status transition test, or improve a Flutter validation/error state.", "Viva එකේ small change එක කුමක් විය හැකිද?", "Telemetry limit එකක් වෙනස් කිරීම, missing photo type එකක් require කිරීම, status transition test එකක් හෝ Flutter validation/error state එකක් වැඩිදියුණු කිරීම."),
        ],
        "risks": [
            ("Compliance is project screening against reviewed thresholds; it is not official utility certification.", "Compliance result එක reviewed thresholds වලට එරෙහි project screening එකකි; official utility certification එකක් නොවේ."),
            ("Use synthetic photos until private/authorized Cloudinary delivery is fully verified; do not expose customer evidence through public URLs.", "Private/authorized Cloudinary delivery සම්පූර්ණයෙන් verify කරන තුරු synthetic photos භාවිතා කරන්න; customer evidence public URLs මගින් expose නොකරන්න."),
        ],
    },
    {
        "n": 3,
        "slug": "Member-3-Engineering-Proposals-Approval-Viva-Guide-EN-SI",
        "title": "Engineering Proposal, Safety and Approval",
        "title_si": "ඉංජිනේරු යෝජනාව, ආරක්ෂාව සහ අනුමැතිය",
        "agent": "SafetyGuardrailAgent",
        "mission": ("Prepare a traceable engineering proposal from validated survey and inspection evidence, explain safety risk, enforce human approval and preserve every decision in an audit history.", "Validated survey සහ inspection evidence මත trace කළ හැකි engineering proposal එකක් සකස් කර safety risk පැහැදිලි කිරීම, human approval enforce කිරීම සහ සෑම decision එකක්ම audit history එකක තබා ගැනීම."),
        "paths": ["backend/SolarPlatform.Api/Features/Engineering", "frontend-web/src/features/engineering", "frontend-mobile/lib/features/engineering", "agentic-ai/app/features/engineering", "backend/SolarPlatform.Tests/Features/Engineering"],
        "entities": [("EngineeringProposal", "capacity, recommendation, safety/compliance state and proposal lifecycle"), ("ApprovalAuditLog", "actor, decision, reason and timestamp"), ("proposal status transition rules", "Pending, RevisionRequested, Approved, Rejected/Failed as allowed by the service")],
        "apis": ["GET /api/proposals", "GET /api/proposals/pending", "GET /api/proposals/{id}", "GET /api/proposals/survey/{surveyId}", "POST /api/proposals", "POST /api/proposals/{id}/approve", "POST /api/proposals/{id}/reject", "POST /api/proposals/{id}/revise"],
        "features": [
            ("Engineer reviews customer/project identity, technician assignment, measurements, compliance result and Cloudinary evidence in one detail view.", "Engineer එක detail view එකක customer/project identity, technician assignment, measurements, compliance result සහ Cloudinary evidence review කරයි."),
            ("Proposal generation runs safety guardrails and deterministic proposal validation before an approval action is offered.", "Approval action එක ලබාදීමට පෙර proposal generation එක safety guardrails සහ deterministic proposal validation ක්‍රියා කරයි."),
            ("Approve, reject and request-revision are explicit role-protected actions with reason and audit history.", "Approve, reject සහ request-revision යනු reason සහ audit history සහිත explicit role-protected actions වේ."),
            ("An invalid or incomplete proposal is blocked even if an agent description sounds positive.", "Agent description එක positive වුවත් invalid හෝ incomplete proposal එක block වේ."),
            ("Approved work can create an inventory request; this keeps engineering authorization separate from stock control.", "Approved work එකකට inventory request එකක් හදිය හැකි අතර engineering authorization සහ stock control වෙන්ව තබයි."),
        ],
        "agent_detail": [
            ("Input contract", "proposal capacity, panel/inverter facts, compliance result and safety-relevant inspection evidence"),
            ("Output contract", "structured guardrail result, risks, explanations and recommendations"),
            ("Validation", "DeterministicProposalValidator independently enforces mandatory rules"),
            ("Authority", "the agent advises only; ASP.NET role checks and a human engineer decide approve/reject/revise"),
            ("Failure", "unsafe or incomplete results are rejected or returned for revision and are auditable"),
        ],
        "demo": [
            ("Open a proposal by customer and project name, not only a short GUID.", "Short GUID එකකින් පමණක් නොව customer සහ project name මගින් proposal එක open කරන්න."),
            ("Review compliance, measurements and all technician photos; explain why evidence must precede a decision.", "Compliance, measurements සහ technician photos සියල්ල review කර decision එකකට පෙර evidence අවශ්‍ය ඇයිදැයි පැහැදිලි කරන්න."),
            ("Show SafetyGuardrailAgent output and the separate deterministic validation result.", "SafetyGuardrailAgent output සහ වෙනම deterministic validation result එක පෙන්වන්න."),
            ("Attempt approval as an unauthorized role or with invalid evidence and show the server blocks it.", "Unauthorized role එකකින් හෝ invalid evidence සමඟ approval attempt කර server එක එය block කරන බව පෙන්වන්න."),
            ("Request revision with a reason, then approve a corrected proposal and display the audit timeline.", "Reason එකක් සමඟ revision request කර corrected proposal එක approve කර audit timeline පෙන්වන්න."),
            ("Create the engineer inventory request and show the hand-off to Member 4 without directly changing stock.", "Engineer inventory request එක හදා stock සෘජුව වෙනස් නොකර Member 4 වෙත hand-off එක පෙන්වන්න."),
        ],
        "questions": [
            ("Why can the agent not approve?", "Approval is a high-impact business action. The assignment requires authorized human review, and ASP.NET must enforce it independently of agent output.", "Agent එකට approve කළ නොහැක්කේ ඇයි?", "Approval එක high-impact business action එකකි. Assignment එක authorized human review අවශ්‍ය කරයි; ASP.NET එය agent output එකෙන් ස්වාධීනව enforce කළ යුතුය."),
            ("Why keep an audit log instead of only the latest status?", "The log proves who decided what, when and why; it supports accountability, revision history and debugging.", "Latest status එක පමණක් තබා audit log එකක් තබන්නේ ඇයි?", "කවුද, කුමක්, කවදා, ඇයි යන decision history පෙන්වීම, accountability, revision history සහ debugging සඳහාය."),
            ("How do you handle two engineers deciding concurrently?", "Use database concurrency/state checks so only a valid current status can transition; reject stale/replayed decisions and keep the audit consistent.", "Engineers දෙදෙනෙක් එකවර decision කළහොත්?", "Valid current status එකකට පමණක් transition කිරීමට database concurrency/state checks භාවිතා කර stale/replayed decisions reject කර audit consistency රකියි."),
            ("What small viva change might be requested?", "Add a required revision reason, change an approval guard, add an audit-field assertion, or improve evidence loading/error UI.", "Viva small change එක කුමක් විය හැකිද?", "Required revision reason එකක්, approval guard එකක්, audit-field assertion එකක් හෝ evidence loading/error UI එකක් එකතු/වෙනස් කිරීම."),
        ],
        "risks": [
            ("Never present the safety result as a structural certificate, utility approval or replacement for a licensed engineer.", "Safety result එක structural certificate, utility approval හෝ licensed engineer වෙනුවට භාවිතා කළ හැකි දෙයක් ලෙස නොපෙන්වන්න."),
            ("A UI-disabled button is not security; the API must enforce the role and current lifecycle state.", "UI button disable කිරීම security නොවේ; API එක role සහ current lifecycle state enforce කළ යුතුය."),
        ],
    },
    {
        "n": 4,
        "slug": "Member-4-Inventory-Pricing-Viva-Guide-EN-SI",
        "title": "Inventory, Equipment Pricing and Procurement",
        "title_si": "තොග පාලනය, උපකරණ මිලකරණය සහ ප්‍රසම්පාදනය",
        "agent": "EquipmentPricingAgent",
        "mission": ("Convert an approved, engineer-requested proposal into a validated LKR equipment estimate, then reserve or release stock through safe, transactional and auditable operations.", "Engineer request කළ approved proposal එක validated LKR equipment estimate එකක් බවට පත් කර safe, transactional සහ auditable operations මගින් stock reserve හෝ release කිරීම."),
        "paths": ["backend/SolarPlatform.Api/Features/Inventory", "frontend-web/src/features/inventory", "frontend-mobile/lib/features/inventory", "agentic-ai/app/features/inventory", "backend/SolarPlatform.Tests/Features/Inventory"],
        "entities": [("InventoryItem", "SKU, category, supplier, unit price, stock, reserved quantity, reorder point and status"), ("EquipmentQuote", "proposal, line items, exchange rate, totals, expiry and workflow trace"), ("InventoryReservation", "proposal/quote quantities, state and audit timestamps"), ("Supplier", "equipment source information")],
        "apis": ["GET/POST/PUT/DELETE /api/inventory", "GET /api/inventory/low-stock", "POST /api/inventory/{id}/adjust", "GET/POST /api/inventory/suppliers", "GET /api/inventory/proposals", "POST /api/inventory/proposals/{id}/request", "POST /api/inventory/proposals/{id}/price", "GET /api/inventory/proposals/{id}/equipment", "POST /api/inventory/reserve", "POST /api/inventory/{id}/release", "GET /api/inventory/reservations"],
        "features": [
            ("Catalog UI supports professional search, category/sort filters, low-stock state, availability and clear stock/reserved/available values.", "Catalog UI එක professional search, category/sort filters, low-stock state, availability සහ stock/reserved/available values පැහැදිලිව පෙන්වයි."),
            ("Pricing selection shows customer and project name plus capacity, so staff do not identify work by GUID alone.", "Pricing selection එක customer name, project name සහ capacity පෙන්වන නිසා staffට GUID එකකින් පමණක් job එක හඳුනාගැනීමට අවශ්‍ය නොවේ."),
            ("An engineer inventory request must exist before inventory staff prepare equipment, preserving responsibility boundaries.", "Inventory staff උපකරණ සකස් කිරීමට පෙර engineer inventory request එකක් තිබිය යුතුය; මෙය responsibility boundaries රකියි."),
            ("The quote presents itemized equipment, LKR total, exchange-rate date, expiry and a readable workflow timeline.", "Quote එක itemized equipment, LKR total, exchange-rate date, expiry සහ readable workflow timeline පෙන්වයි."),
            ("Reservation and release update stock atomically; retries are idempotent and availability is rechecked at commit time.", "Reservation සහ release stock atomic ලෙස update කරයි; retries idempotent වන අතර commit වේලාවේ availability නැවත පරීක්ෂා කරයි."),
        ],
        "agent_detail": [
            ("Input contract", "approved capacity/equipment requirements and validated catalog candidates"),
            ("Tool", "allow-listed ExchangeRateTool restricted to the configured provider and USD/LKR with timeout, cache and freshness checks"),
            ("Output contract", "panel/inverter line items, quantities, unit prices, exchange rate and LKR totals"),
            ("Validation", "independent arithmetic, catalog identity, quote freshness and stock availability checks"),
            ("Authority", "agent calculates only; ASP.NET/PostgreSQL transaction performs actual reservation/release"),
        ],
        "demo": [
            ("Show the catalog search/filter/low-stock view and explain stock, reserved and available quantities.", "Catalog search/filter/low-stock view එක පෙන්වා stock, reserved සහ available quantities පැහැදිලි කරන්න."),
            ("Select an approved proposal by customer/project name and show that an engineer request is required.", "Customer/project name මගින් approved proposal එක තෝරා engineer request එක අවශ්‍ය බව පෙන්වන්න."),
            ("Calculate price and inspect ExchangeRateTool input/output, rate date, itemized LKR arithmetic and validators.", "Price calculate කර ExchangeRateTool input/output, rate date, itemized LKR arithmetic සහ validators inspect කරන්න."),
            ("Show one safe failure: stale rate, insufficient stock or unavailable provider.", "Stale rate, insufficient stock හෝ provider unavailable වැනි safe failure එකක් පෙන්වන්න."),
            ("Reserve stock and prove available quantity changes in PostgreSQL; repeat the request to demonstrate idempotency.", "Stock reserve කර PostgreSQL තුළ available quantity වෙනස් වන බව පෙන්වා request එක නැවත කර idempotency පෙන්වන්න."),
            ("Release the reservation and show both inventory restoration and workflow/audit status.", "Reservation release කර inventory restoration සහ workflow/audit status දෙකම පෙන්වන්න."),
        ],
        "questions": [
            ("Why is available stock not the same as stock on hand?", "Available = stock on hand minus active reserved quantity. Reservations prevent the same units being promised twice.", "Available stock සහ stock on hand එකම නොවන්නේ ඇයි?", "Available = stock on hand - active reserved quantity. Reservations නිසා එකම units දෙවරක් promise කිරීම වැළකේ."),
            ("Why recheck stock inside the transaction?", "A quote is only a snapshot. Another user may reserve stock before commit, so the database transaction must recheck and update atomically.", "Transaction තුළ stock නැවත check කරන්නේ ඇයි?", "Quote එක snapshot එකක් පමණි. Commit කිරීමට පෙර වෙනත් user කෙනෙක් stock reserve කළ හැකි නිසා transaction එක තුළ recheck කර atomic update කළ යුතුය."),
            ("What does idempotency protect against?", "Network retries or double-clicks must not create duplicate reservations or subtract stock twice.", "Idempotency මගින් ආරක්ෂා කරන්නේ කුමක්ද?", "Network retries හෝ double-clicks නිසා duplicate reservations හෝ stock දෙවරක් අඩු වීම වළක්වයි."),
            ("What small viva change might be requested?", "Change a reorder threshold, add a filter/validation, reject an expired quote, or add a concurrent reservation test.", "Viva small change එක කුමක් විය හැකිද?", "Reorder threshold එකක්, filter/validation එකක් වෙනස් කිරීම, expired quote reject කිරීම හෝ concurrent reservation test එකක් එකතු කිරීම."),
        ],
        "risks": [
            ("Do not trust agent arithmetic, stale exchange rates or a pre-quote stock snapshot without independent checks.", "Agent arithmetic, stale exchange rates හෝ pre-quote stock snapshot එක independent checks නොමැතිව විශ්වාස නොකරන්න."),
            ("Secrets stay in environment variables and external failures must produce a clear safe state, not a fabricated rate.", "Secrets environment variables තුළ තබා external failures වලදී fabricated rate එකක් නොව clear safe state එකක් ලබාදිය යුතුය."),
        ],
    },
]


CSS = r"""
@page { size: A4; margin: 16mm 15mm 18mm; @bottom-center { content: "SE3090 Viva Guide  •  " counter(page) " / " counter(pages); font: 8pt Arial; color: #667a72; } }
* { box-sizing: border-box; }
body { margin: 0; color: #183b36; font-family: Arial, "Nirmala UI", sans-serif; font-size: 10.2pt; line-height: 1.44; }
.cover { min-height: 258mm; padding: 20mm 16mm; display: flex; flex-direction: column; justify-content: space-between; background: linear-gradient(145deg,#063f4d 0%,#075f70 45%,#68bd38 100%); color:#fff; page-break-after: always; }
.cover .eyebrow { letter-spacing: 2px; text-transform: uppercase; font-weight:700; color:#d8ff74; }
.cover h1 { font-size: 31pt; line-height:1.08; margin: 15mm 0 3mm; }
.cover .si-title { font-family:"Nirmala UI",sans-serif; font-size:18pt; line-height:1.5; color:#eaffdf; }
.cover .agent { margin-top:12mm; padding:5mm; border:1px solid rgba(255,255,255,.45); border-radius:12px; background:rgba(255,255,255,.1); font-size:13pt; }
.cover .note { border-top:1px solid rgba(255,255,255,.35); padding-top:7mm; font-size:9.2pt; color:#eefaf7; }
section { page-break-before: always; }
section:first-of-type { page-break-before: auto; }
.kicker { color:#56a829; font-weight:800; letter-spacing:1.7px; text-transform:uppercase; font-size:8pt; margin-bottom:2mm; }
h2 { font-size:22pt; color:#063f4d; margin:0; line-height:1.14; }
.h2-si { font-family:"Nirmala UI",sans-serif; color:#4e746c; font-size:12.5pt; margin:2mm 0 7mm; }
h3 { color:#075f70; font-size:13pt; margin:7mm 0 2mm; break-after:avoid; }
.pair { border-left:3px solid #75c442; padding:2.4mm 3.5mm; margin:2.5mm 0; background:#f6faf5; border-radius:0 7px 7px 0; break-inside:avoid; }
.pair .en { font-weight:600; color:#173d38; }
.pair .si { font-family:"Nirmala UI",sans-serif; color:#526c67; margin-top:1.4mm; line-height:1.62; }
.dot { color:#63b52f; padding-right:2mm; font-size:13pt; }
.paths { background:#062f39; color:#e8ffef; padding:5mm; border-radius:9px; break-inside:avoid; }
.paths code { display:block; font:8.5pt Consolas,monospace; padding:1.2mm 0; overflow-wrap:anywhere; }
.steps { counter-reset: step; }
.step { display:grid; grid-template-columns:10mm 1fr; gap:3mm; margin:3mm 0; break-inside:avoid; }
.num { width:9mm;height:9mm;border-radius:50%;background:#68bd38;color:white;font-weight:800;display:flex;align-items:center;justify-content:center; }
.step-pair { border-bottom:1px solid #d9e7dd; padding-bottom:3mm; }
.step-pair .en { font-weight:700; }
.step-pair .si { font-family:"Nirmala UI",sans-serif;color:#526c67;margin-top:1mm;line-height:1.6; }
.grid { display:grid; grid-template-columns:1fr 1fr; gap:4mm; }
.card { border:1px solid #cee0d3; border-radius:9px; padding:4mm; break-inside:avoid; }
.card b { color:#075f70; }
.tag { display:inline-block; background:#e8f6df; border:1px solid #b6dba2; color:#397d20; padding:1mm 2.5mm; border-radius:20px; margin:1mm 1mm 1mm 0; font-size:8.7pt; }
.qa { border:1px solid #c8ddd5; border-radius:10px; margin:4mm 0; padding:4mm; break-inside:avoid; }
.q { font-weight:800;color:#063f4d; }
.a { margin-top:1.5mm;color:#274e48; }
.qsi { margin-top:3mm;font-family:"Nirmala UI",sans-serif;font-weight:700;color:#357e2b; }
.asi { margin-top:1mm;font-family:"Nirmala UI",sans-serif;color:#526c67;line-height:1.62; }
.callout { background:#fff5d8;border:1px solid #e6c66b;border-radius:10px;padding:5mm;margin:5mm 0;break-inside:avoid; }
.danger { background:#fff0ec;border-color:#e3a58d; }
.matrix { width:100%; border-collapse:collapse; font-size:8.5pt; }
.matrix th { background:#075f70;color:white;text-align:left;padding:2.5mm; }
.matrix td { border:1px solid #d4e2dc;padding:2.5mm;vertical-align:top; }
.matrix .si { font-family:"Nirmala UI",sans-serif;color:#536e68;line-height:1.55;margin-top:1mm; }
.small { font-size:8.5pt;color:#657b76; }
"""


def qas(items):
    return ''.join(f'<div class="qa"><div class="q">{html.escape(q)}</div><div class="a">{html.escape(a)}</div><div class="qsi" lang="si">{html.escape(qs)}</div><div class="asi" lang="si">{html.escape(ans)}</div></div>' for q,a,qs,ans in items)


def build(role: dict) -> str:
    mission = pair(*role["mission"])
    paths = '<div class="paths">' + ''.join(f'<code>{html.escape(p)}</code>' for p in role["paths"]) + '</div>'
    entity_cards = '<div class="grid">' + ''.join(f'<div class="card"><b>{html.escape(n)}</b><div>{html.escape(d)}</div></div>' for n,d in role["entities"]) + '</div>'
    api_tags = '<div>' + ''.join(f'<span class="tag">{html.escape(x)}</span>' for x in role["apis"]) + '</div>'
    agent_cards = '<div class="grid">' + ''.join(f'<div class="card"><b>{html.escape(k)}</b><div>{html.escape(v)}</div></div>' for k,v in role["agent_detail"]) + '</div>'
    knowledge = [
        ("Know the business purpose, actors, happy path, status changes, validation failures and what is deliberately outside scope.", "Business purpose, actors, happy path, status changes, validation failures සහ scope එකෙන් පිටත දේවල් හොඳින් දැනගන්න."),
        ("Understand the request path from UI event to API controller, DTO, service, EF Core query/transaction, PostgreSQL record, Python contract and response UI.", "UI event සිට API controller, DTO, service, EF Core query/transaction, PostgreSQL record, Python contract සහ response UI දක්වා request path එක තේරුම් ගන්න."),
        ("Memorize names and responsibilities, but understand why each boundary exists; the examiner may change a rule and ask you to modify it.", "Names සහ responsibilities මතක තබාගන්න, නමුත් සෑම boundary එකක්ම ඇයිදැයි තේරුම් ගන්න; examiner rule එකක් වෙනස් කර code modify කිරීමට ඉල්ලා සිටිය හැකිය."),
        ("Keep evidence of your own issues, commits, pull requests, reviews, tests and AI-use log. The guide is not ownership evidence.", "ඔබගේ issues, commits, pull requests, reviews, tests සහ AI-use log evidence තබාගන්න. මෙම guide එක ownership evidence නොවේ."),
    ]
    workflow = [
        ("Homeowner creates a named survey with property, usage, roof and location data.", "Homeowner property, usage, roof සහ location data සමඟ named survey එකක් හදයි."),
        ("PlannerAgent creates the structured plan and SolarSizingAgent returns a validated preliminary design.", "PlannerAgent structured plan එක හදා SolarSizingAgent validated preliminary design එක ලබාදෙයි."),
        ("Engineer assigns a technician; technician navigates, checks in, saves inspection evidence and submits telemetry.", "Engineer technician කෙනෙකු assign කරයි; technician navigate, check-in, inspection evidence save කර telemetry submit කරයි."),
        ("GridComplianceAgent and deterministic checks produce compliance or a correction state.", "GridComplianceAgent සහ deterministic checks compliance හෝ correction state එක ලබාදෙයි."),
        ("SafetyGuardrailAgent analyses proposal risk; an authorized engineer approves, rejects or requests revision.", "SafetyGuardrailAgent proposal risk පරීක්ෂා කර authorized engineer approve, reject හෝ revision request කරයි."),
        ("Engineer requests inventory; EquipmentPricingAgent calculates a validated quote using the exchange-rate tool.", "Engineer inventory request කර EquipmentPricingAgent exchange-rate tool සමඟ validated quote එක ගණනය කරයි."),
        ("Inventory officer reserves stock in an ASP.NET/PostgreSQL transaction and the updated status returns to users.", "Inventory officer ASP.NET/PostgreSQL transaction එකක stock reserve කර updated status users වෙත යවයි."),
    ]
    checklist = [
        ("I can draw the architecture from memory and identify the trust boundary.", "Architecture එක මතකයෙන් ඇඳ trust boundary එක හඳුනාගත හැකිය."),
        ("I can demonstrate my happy path and one safe failure using the same survey/workflow ID.", "එකම survey/workflow ID එක භාවිතා කර happy path එක සහ safe failure එකක් demonstrate කළ හැකිය."),
        ("I can open one controller, service, entity/migration, React screen, Flutter screen, agent and test and explain the important lines.", "Controller, service, entity/migration, React screen, Flutter screen, agent සහ test එක බැගින් open කර වැදගත් lines explain කළ හැකිය."),
        ("I can explain JWT/RBAC, ownership checks, X-Internal-Key, secret storage, validation and safe failure.", "JWT/RBAC, ownership checks, X-Internal-Key, secret storage, validation සහ safe failure explain කළ හැකිය."),
        ("I can make a small rule/UI/test change and rerun the relevant checks without external AI.", "External AI නොමැතිව small rule/UI/test change එකක් කර relevant checks නැවත run කළ හැකිය."),
        ("My GitHub evidence and individual report truthfully match the work I personally understand and performed.", "මගේ GitHub evidence සහ individual report එක මම ඇත්තටම කළ සහ තේරුම් ගත් වැඩ සමඟ සත්‍ය ලෙස ගැළපේ."),
    ]

    body = f'''
    <div class="cover">
      <div><div class="eyebrow">SE3090 • FINAL VIVA PREPARATION • MEMBER {role['n']}</div>
      <h1>{html.escape(role['title'])}</h1><div class="si-title" lang="si">{html.escape(role['title_si'])}</div>
      <div class="agent">Distinct agent contribution: <b>{html.escape(role['agent'])}</b></div></div>
      <div class="note">Bilingual study guide: every English learning point is followed by its Sinhala explanation. Based on the 2026 Assignment 1 specification and the current repository. Verify live behaviour and use only truthful personal contribution evidence.</div>
    </div>
    {section('1. Your ownership boundary', '1. ඔබගේ වගකීම් සීමාව', mission + '<h3>Code areas you must know</h3>' + paths + '<h3>What you own in the product</h3>' + bullets(role['features']), 'START HERE')}
    {section('2. What the assignment will mark', '2. Assignment එකෙන් ලකුණු දෙන කොටස්', pair('The final evaluation is one 10-minute group demonstration plus a 20-minute viva. The total is 30 group marks and 70 individual marks. Every member may be asked to explain, modify, test or debug their own work.', 'Final evaluation එක 10-minute group demonstration එකක් සහ 20-minute viva එකක් වේ. Total ලකුණු 30 group සහ 70 individual වේ. සෑම member කෙනෙකුටම තම වැඩ explain, modify, test හෝ debug කිරීමට ඉල්ලා සිටිය හැකිය.') + bullets(rubric) + '<div class="callout">' + pair('During the final demonstration and viva, external AI assistants, chatbots, copilots and agentic coding tools are not allowed. The submitted application\'s own Agentic AI subsystem must be run.', 'Final demonstration සහ viva අතර external AI assistants, chatbots, copilots සහ agentic coding tools භාවිතා කළ නොහැක. Submit කළ application එකේ Agentic AI subsystem එක run කළ යුතුය.') + '</div>', 'MARKING MAP')}
    {section('3. Integrated architecture you must draw and explain', '3. ඔබ ඇඳ පැහැදිලි කළ යුතු integrated architecture එක', bullets(common_architecture) + '<h3>Complete business journey</h3>' + numbered(workflow), 'SYSTEM VIEW')}
    {section('4. Your backend and database knowledge', '4. ඔබගේ backend සහ database දැනුම', pair('Be able to trace an authenticated request through controller → DTO → service → EF Core → PostgreSQL and back. Explain where validation, authorization and business status checks occur.', 'Authenticated request එක controller → DTO → service → EF Core → PostgreSQL හරහා ගොස් ආපසු එන ආකාරය trace කරන්න. Validation, authorization සහ business status checks සිදුවන ස්ථාන පැහැදිලි කරන්න.') + '<h3>Main entities / domain records</h3>' + entity_cards + '<h3>Important routes</h3>' + api_tags + bullets([('For each route, know the HTTP method, authorized roles, request DTO, success status, validation failure and database effect.', 'සෑම route එකකටම HTTP method, authorized roles, request DTO, success status, validation failure සහ database effect දැනගන්න.'), ('Explain primary/foreign keys, required fields, uniqueness/check constraints, useful indexes, CreatedAt/UpdatedAt and the migration that introduced the schema.', 'Primary/foreign keys, required fields, uniqueness/check constraints, useful indexes, CreatedAt/UpdatedAt සහ schema එක ගෙනා migration එක explain කරන්න.'), ('Use a transaction when multiple writes must succeed or fail together; explain rollback and concurrency for your component.', 'Writes කිහිපයක් එකට succeed හෝ fail විය යුතු විට transaction එකක් භාවිතා කර rollback සහ concurrency explain කරන්න.')]), 'API + DATA')}
    {section('5. React and Flutter knowledge', '5. React සහ Flutter දැනුම', bullets([('React: know the route, protected role navigation, component state/hooks, service call, form validation, responsive layout and loading/empty/error/success states in your feature folder.', 'React: ඔබගේ feature folder එකේ route, protected role navigation, component state/hooks, service call, form validation, responsive layout සහ loading/empty/error/success states දැනගන්න.'), ('Flutter: know screen navigation, model parsing, API call/token usage, reusable widgets, keyboard/scroll behaviour, validation and restoration after refresh/reopen.', 'Flutter: screen navigation, model parsing, API call/token usage, reusable widgets, keyboard/scroll behaviour, validation සහ refresh/reopen පසු restoration දැනගන්න.'), ('Explain why web and mobile have different user purposes but share identity, data and business rules through the same API.', 'Web සහ mobile වල user purposes වෙනස් වුවත් එකම API හරහා identity, data සහ business rules share කරන්නේ ඇයිදැයි explain කරන්න.'), ('Know one accessibility/usability decision: visible labels, 48dp touch targets, focus/error messages, confirmation for destructive actions, readable identifiers and immediate local feedback.', 'Accessibility/usability decision එකක් දැනගන්න: visible labels, 48dp touch targets, focus/error messages, destructive actions සඳහා confirmation, readable identifiers සහ immediate local feedback.')]), 'CLIENTS')}
    {section(f'6. Your distinct agent: {role["agent"]}', f'6. ඔබගේ වෙනම agent එක: {role["agent"]}', agent_cards + '<h3>Minimum assessed workflow - all members must understand</h3>' + bullets(agent_acceptance) + '<div class="callout danger">' + pair('Accurate claim: this is a deterministic custom orchestration using FastAPI, typed Pydantic contracts and selected LangGraph specialist subgraphs. No paid model API is required. Its strength is controlled, testable workflow behaviour; its limitation is no live LLM reasoning or generative RAG.', 'නිවැරදි claim එක: මෙය FastAPI, typed Pydantic contracts සහ selected LangGraph specialist subgraphs භාවිතා කරන deterministic custom orchestration එකකි. Paid model API එකක් අවශ්‍ය නැහැ. එහි ශක්තිය controlled, testable workflow behaviour වන අතර සීමාව live LLM reasoning හෝ generative RAG නොමැති වීමයි.') + '</div>', 'AGENTIC AI • 12 MARKS')}
    {section('7. Your live demonstration script', '7. ඔබගේ live demonstration script එක', numbered(role['demo']) + pair('Rehearse this with seeded/synthetic data and keep the same survey, job, proposal and workflow IDs visible. Prepare both a golden case and one controlled failure.', 'මෙය seeded/synthetic data සමඟ rehearse කර එකම survey, job, proposal සහ workflow IDs පෙනෙන ලෙස තබන්න. Golden case එකක් සහ controlled failure එකක් සූදානම් කරන්න.'), 'DEMO')}
    {section('8. Likely viva questions and strong answers', '8. Viva එකේ ඇසිය හැකි ප්‍රශ්න සහ හොඳ පිළිතුරු', qas(role['questions'] + shared_questions), 'QUESTION BANK')}
    {section('9. Testing, CI, Git and debugging', '9. Testing, CI, Git සහ debugging', bullets([('Unit test pure rules and status transitions; service tests cover authorization/business behaviour; integration tests verify real API/database contracts and transactions.', 'Pure rules සහ status transitions unit test කරන්න; service tests authorization/business behaviour cover කරයි; integration tests real API/database contracts සහ transactions verify කරයි.'), ('For React and Flutter, test form validation, API success/failure, protected navigation, loading/empty/error states and the most important user interaction.', 'React සහ Flutter සඳහා form validation, API success/failure, protected navigation, loading/empty/error states සහ වැදගත් user interaction එක test කරන්න.'), ('For the agent, keep golden-case assertions for plan/agent/tool selection, structured output, validator result, approval enforcement, prompt/tool-input abuse and safe failure.', 'Agent සඳහා plan/agent/tool selection, structured output, validator result, approval enforcement, prompt/tool-input abuse සහ safe failure සඳහා golden-case assertions තබන්න.'), ('Explain CI in order: checkout, runtime setup, restore/install, build/analyze/lint, tests and failure logs. A green badge is evidence only when you understand the steps.', 'CI order එක explain කරන්න: checkout, runtime setup, restore/install, build/analyze/lint, tests සහ failure logs. Steps තේරුම් ගත් විට පමණක් green badge එක evidence වේ.'), ('Debug from evidence: reproduce → inspect browser/mobile and API error → inspect server/agent logs and correlation ID → verify database state → isolate layer → add regression test → fix → rerun focused then broader checks.', 'Evidence මත debug කරන්න: reproduce → browser/mobile සහ API error බලන්න → server/agent logs සහ correlation ID බලන්න → database state verify කරන්න → layer isolate කරන්න → regression test එකක් එකතු කරන්න → fix කරන්න → focused සහ broader checks run කරන්න.')]) + '<h3>Component-specific limitations</h3>' + bullets(role['risks']), 'QUALITY EVIDENCE')}
    {section('10. What to learn, understand and memorize', '10. ඉගෙනගත, තේරුම්ගත සහ මතක තබාගත යුතු දේ', bullets(knowledge) + '<h3>Final readiness checklist</h3>' + bullets(checklist) + '<div class="callout">' + pair('Do not memorize sentences without understanding. Practise explaining each item in your own words, then prove it by opening the code, database record, test or workflow trace.', 'තේරුම් නොගෙන වාක්‍ය මතක තබා නොගන්න. සෑම item එකක්ම ඔබගේම වචනවලින් explain කර පසුව code, database record, test හෝ workflow trace එකෙන් prove කිරීමට පුහුණු වන්න.') + '</div>', 'FINAL REVISION')}
    {section('11. One-page rapid recall', '11. එක් පිටුවක rapid recall', f'''
      <table class="matrix"><tr><th>Prompt</th><th>Your answer</th></tr>
      <tr><td>Owned component</td><td>{html.escape(role['title'])}</td></tr>
      <tr><td>Distinct agent</td><td>{html.escape(role['agent'])}</td></tr>
      <tr><td>Public gateway</td><td>ASP.NET Core Web API</td></tr>
      <tr><td>Database / ORM</td><td>PostgreSQL / Entity Framework Core</td></tr>
      <tr><td>Clients</td><td>React staff web + Flutter homeowner/field mobile</td></tr>
      <tr><td>Agent service</td><td>Internal FastAPI; X-Internal-Key; typed contracts; deterministic orchestration</td></tr>
      <tr><td>Human control</td><td>Engineer approval; inventory reservation remains server transaction</td></tr>
      <tr><td>Never claim</td><td>Live LLM reasoning, generative RAG, utility certification, or work you cannot prove</td></tr>
      </table>
      <h3>Last rehearsal</h3>{numbered([('Explain your component in 60 seconds.', 'ඔබගේ component එක තත්පර 60කින් explain කරන්න.'), ('Trace one request end to end.', 'Request එකක් end-to-end trace කරන්න.'), ('Run one test and explain its assertions.', 'Test එකක් run කර assertions explain කරන්න.'), ('Make one tiny validation change and rerun checks.', 'Tiny validation change එකක් කර checks නැවත run කරන්න.'), ('Show your truthful Git and report evidence.', 'ඔබගේ truthful Git සහ report evidence පෙන්වන්න.')])}
      <p class="small">Source basis: SE3090 Assignment 1 Specification 2026, especially Sections 2-14 and 16-20; current repository feature guides and architecture documents. This study guide does not replace the official specification or personal contribution evidence.</p>
    ''', 'MEMORY SHEET')}
    '''
    return f'<!doctype html><html><head><meta charset="utf-8"><title>{html.escape(role["title"])}</title><style>{CSS}</style></head><body>{body}</body></html>'


for role in roles:
    html_path = TMP / f'{role["slug"]}.html'
    pdf_path = OUT / f'{role["slug"]}.pdf'
    html_path.write_text(build(role), encoding="utf-8")
    cmd = [str(EDGE), "--headless", "--disable-gpu", "--no-pdf-header-footer", f"--print-to-pdf={pdf_path}", html_path.as_uri()]
    completed = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=120)
    if completed.returncode != 0 or not pdf_path.exists():
        raise RuntimeError(f"PDF creation failed for {role['slug']}: {completed.stdout}")
    print(pdf_path)
