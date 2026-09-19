# Smart Solar: දේශන න්‍යාය සහ ව්‍යාපෘතිය පිළිබඳ වාර්තාව

2026 සැප්තැම්බර් 19 • සිංහල වාර්තාව • ඉංග්‍රීසි වාර්තාව සමඟ භාවිත කරන්න

## 1. ප්‍රධාන නිගමනය

මෙම ව්‍යාපෘතිය තුළ frameworks, React, C#, ASP.NET, relational databases සහ authorization පිළිබඳ දේශනවල බොහෝ මූලික සංකල්ප දැනටමත් යොදා ඇත. අඩු වූ ප්‍රායෝගික කොටස් කිහිපයක් මෙම සංශෝධනයෙන් එක් කර පරීක්ෂා කර ඇත. ඔබගේ ඉල්ලීම අනුව ගෙවීම් කරන language-model සේවාවක් අවශ්‍ය නොවේ.

**වැදගත් සීමාව:** දැනට “Agent” ලෙස නම් කර ඇති ප්‍රධාන කොටස් හතර ක්‍රියා කරන්නේ පෙර ලියා ඇති නීති සහ ගණනය කිරීම් අනුවය. ඊළඟ tool එක තෝරන live LLM එකක්, ReAct reasoning loop එකක් හෝ සම්පූර්ණ generative RAG එකක් මෙහි නැත. LangGraph භාවිත කිරීම පමණින් එය ස්වයංක්‍රීයව LLM agent එකක් වන්නේ නැත. නිවැරදි විස්තරය වන්නේ **ස්වාධීන validation සහ මානව අනුමැතිය සහිත specialist workflows** යන්නයි.

ගෙවීම් නොකර local model එකක් භාවිත කිරීම ඉදිරියේදී කළ හැකි තේරීමකි. නමුත් එවැනි runtime/model එකක් මෙහි ස්ථාපනය කර පරීක්ෂා කර නැත. වාර්තාවෙන් සියලු ලකුණු ලැබෙන බව, සියලු screens පරීක්ෂා කළ බව හෝ පද්ධතිය විදුලි ස්ථාපනයකට සහතිකයක් බව අදහස් නොවේ.

**තත්ත්ව සලකුණු:** ✓ දැනට තිබේ = source code තුළ හමු විය; ✓ එක් කළා = මෙම සංශෝධනයෙන් ක්‍රියාත්මක කළා; △ අර්ධ වශයෙන් = තව සීමා තිබේ; ○ විකල්පයක් = සෑම ව්‍යාපෘතියකටම අනිවාර්ය නොවේ. පිටු අංක PDF viewer එකේ පිටු අංකයි. `lec5 part2` තුළ Lecture 06 ද, `lec5 part3` තුළ Lecture 07 ද ඇතුළත් වේ.

## 2. එක් එක් දේශනයේ න්‍යාය යොදා ඇති ආකාරය

### Lecture 1 — Frameworks සහ Inversion of Control

- **✓ දැනට තිබේ — IoC, පිටුව 13.** ASP.NET HTTP request එක ලබාගෙන controller එක කැඳවයි. React component එක render කරන්නේ React runtime එකයි. Flutter widget lifecycle එක පාලනය කරන්නේ Flutter framework එකයි. අපගේ code එක framework එක ලබා දෙන extension points තුළ ක්‍රියා කරයි. `Program.cs` සහ `App.tsx` උදාහරණ ලෙස පෙන්වන්න.
- **✓ දැනට තිබේ — වගකීම් වෙන් කිරීම.** Controllers request භාර ගනී; services business rules පවත්වා ගනී; DTOs හරහා data හුවමාරු වේ; EF entities මඟින් database records නිරූපණය වේ. මෙයින් code වෙනස් කිරීම සහ testing පහසු වේ.
- **✓ එක් කළා — තාක්ෂණික තේරීම් සාධාරණීකරණය, පිටු 29–31.** ADR-007 තුළ paid model නොභාවිත කිරීම, සරල lexical retrieval තේරීම, සීමා සහ වෙනත් විකල්ප ලියා ඇත. ADR යනු තීරණයට හේතුව සටහන් කිරීමකි; එය performance benchmark එකක් නොවේ.
- **△ අර්ධ වශයෙන් — deployment, පිටුව 39.** Docker සහ CI configuration තිබුණත් ඒවා තිබීමෙන් public deployment එක සාර්ථක බව තහවුරු නොවේ. Public URLs, backup/recovery සහ අවසන් CI evidence අවශ්‍යය.
- **○ විකල්පයක් — microservices/serverless.** සෑම component එකකටම වෙනම service එකක් සෑදීම අනිවාර්ය නොවේ. දැනට business API එක සහ internal Python service එක වෙන් කිරීම පැහැදිලි සීමාවක් ලබා දෙයි.

### Lecture 2 — Advanced React

- **✓ දැනට තිබේ — composition සහ controlled forms, පිටු 8, 16–19.** Fields, search, photo gallery, record references සහ layout නැවත භාවිත කළ හැකි components ලෙස ඇත. Auth Context login state බෙදා ගනී.
- **✓ එක් කළා — UI / hook / service වෙන් කිරීම, පිටු 12, 20–23, 32.** `useInventoryCatalog.ts` තුළ inventory loading, error, data සහ 250 ms debounce එක ඇත. පෙර request එක අවලංගු කිරීමට AbortController භාවිත කරයි. එබැවින් පැරණි search response එකකට අලුත් results මත ලිවීමට නොහැක. Page එක UI පෙන්වන අතර service එක HTTP request කරයි.
- **✓ දැනට තිබේ — validation සහ keyboard search.** `AuthField`, `ValidatedForm`, `SearchBox` සහ shared validators තිබේ. නමුත් සියලු screens සඳහා සම්පූර්ණ accessibility certification එකක් ලබා දී නැත.
- **✓ එක් කළා — lazy routes සහ Suspense, පිටු 37, 44.** Workspace pages අවශ්‍ය වූ විට වෙනම chunks ලෙස load වේ. Build output තුළ ඒවා වෙන වෙනම ඇති බව තහවුරු විය. මිනුමක් නොකළ නිසා “මෙතරම් ප්‍රතිශතයකින් වේගවත් වුණා” යැයි පැවසිය නොහැක.
- **✓ එක් කළා — error boundary, පිටුව 39.** Page එක render වීම අසාර්ථක වූ විට reload/home options පෙන්වයි. Exception text එක screen එකට නොදමයි. මෙය සියලු asynchronous errors හසුරුවන එකක් නොවන නිසා API failures සඳහා වෙනම handling තවමත් අවශ්‍යය.
- **○ විකල්පයක් — Redux, Zustand, TanStack Query, Next.js, React Hook Form, Zod.** මේ සියල්ල එකවර දැමීම දේශනයේ අරමුණ නොවේ. ගැටලුවට ගැළපෙන එක තේරීම වැදගත්ය. දැනට Context, local state සහ reusable hooks/validators භාවිත කරයි. සම්පූර්ණ server-state caching framework එකක් තිබෙන බව නොකියන්න.

### Lecture 3 — C#, OOP, ASP.NET සහ REST

- **✓ දැනට තිබේ — encapsulation සහ interfaces, පිටු 16–19.** Business rules services තුළ ඇත. `IAgenticAiService` වැනි interfaces නිසා testing සඳහා වෙනත් implementation එකක් ලබා දිය හැක. අවශ්‍ය නැති inheritance hierarchy එකක් එකතු කිරීමෙන් OOP හොඳ වන්නේ නැත.
- **✓ දැනට තිබේ — Dependency Injection, පිටුව 26.** `Program.cs` services සහ DbContext register කරයි. Controllers constructor හරහා dependencies ලබා ගනී. Request එකකට scoped lifetime එක database context සඳහා ගැළපේ.
- **✓ දැනට තිබේ — middleware, පිටුව 27.** Authentication, authorization සහ exception handling request pipeline එකේ වගකීම් වේ. ඒවායේ අනුපිළිවෙළ වැදගත්ය.
- **✓ දැනට තිබේ — REST සහ layers, පිටු 30–42.** Surveys, field jobs, proposals සහ inventory සඳහා resource routes හා DTOs ඇත. Submit, approve, reserve වැනි operations සරල CRUD වලට වඩා business transitions වේ. UI එක database එකට සෘජුව සම්බන්ධ නොවේ.
- **✓ දැනට තිබේ — async සහ Swagger, පිටු 45–51.** Database/HTTP වැඩ async ලෙස සිදු වේ. Swagger API contract පෙන්වයි; එය පමණක් authorization නිවැරදි බවට සාක්ෂියක් නොවේ.
- **✓ එක් කළා — එකඟ error contract එකක්.** Middleware විසින් හසුරුවන exceptions දැන් Problem Details ලෙස ලබා දෙයි. පැරණි clients සඳහා `message` field එක තබා ඇත. නොදන්නා errors වල raw provider details පෙන්වන්නේ නැත.

### Lecture 4 — Database, transactions සහ ආරක්ෂාව

- **✓ දැනට තිබේ — relational design, පිටු 16–25, 31–37.** Users, surveys, jobs, inspections, proposals, decisions, equipment සහ quotes සඳහා entities හා relationships ඇත. UUID එක record identifier එකයි; SKU එක business identifier එකකි. Foreign keys සහ constraints මඟින් database මට්ටමින් සම්බන්ධතා රැකේ.
- **✓ දැනට තිබේ — ACID transaction උදාහරණය, පිටු 9–10.** Equipment reserve කරන විට quote, approval සහ stock නැවත පරීක්ෂා කර transaction එකක update කරයි. Concurrent requests දෙකකට එකම stock වැරදි ලෙස දෙවරක් වෙන් කිරීම වැළැක්වීමට isolation/concurrency checks ඇත. එකම successful request නැවත කිරීමෙන් stock නැවත අඩු නොවිය යුතුය.
- **△ අර්ධ වශයෙන් — database පරීක්ෂණ සාක්ෂි.** මෙම audit එකේ isolated PostgreSQL test එක skip විය. එය pass එකක් ලෙස ගණන් නොගන්න. කලින් වාර්තාවේ database run එක වෙනම දිනයක සාක්ෂියකි.
- **✓ දැනට තිබේ — authentication සහ authorization වෙන් කිරීම, පිටු 40–46, 49–53.** JWT මඟින් user හඳුනා ගනී. Role/ownership checks මඟින් කළ හැකි ක්‍රියාව තීරණය වේ. Button එක hide කිරීම security නොවේ; backend එකත් deny කළ යුතුය.
- **✓ එක් කළා — Problem Details, පිටුව 54.** `status`, `title`, `detail`, `instance`, `traceId` වැනි fields ඇත. Test එකක රහස් වැනි synthetic error text යැවූ විට එය response එකේ නොපෙන්වන බව පරීක්ෂා කර ඇත. සියලු controller-specific error responses මෙහි නැවත ලියා නැත.
- **△ අර්ධ වශයෙන් — production security.** Browser token storage, refresh/token lifecycle, private photo delivery, database permissions සහ backups තව review කළ යුතුය. Photo metadata endpoint එකට authorization තිබුණත් image URL එක public static URL එකක් නම් එය වෙනම ගැටලුවකි.
- **○ විකල්පයක් — CAP සහ sticky sessions, පිටු 11–12, 42.** PostgreSQL භාවිත කළ නිසා CAP තුනම සම්පූර්ණයෙන් ලැබෙන බව නොකියන්න. JWT API එකකට session affinity අනිවාර්ය නොවේ. මේවා තේරීම් විශ්ලේෂණය කිරීමට භාවිත කරන න්‍යාය වේ.

### Lecture 5 part 1 — LLM සහ agent පදනම

- **✓ දැනට තිබේ — structured inputs/outputs, validation සහ human approval.** Pydantic schemas සහ backend DTOs මඟින් data contract පාලනය කරයි. Specialist output එක independent validator එකකින් පරීක්ෂා කරයි.
- **△ අර්ධ වශයෙන් — සැබෑ autonomy, පිටු 22–25, 29, 32.** දේශනයේ agent එක tool result නිරීක්ෂණය කර ඊළඟ ක්‍රියාව model එකෙන් තෝරයි. මෙහි PlannerAgent එක දැනට පෙර ලියා ඇති පියවර අටක් ලබා දෙයි. එය dynamic supervisor හෝ ReAct agent එකක් නොවේ. Code comment එකත් එයට ගැළපෙන ලෙස නිවැරදි කර ඇත.
- **✓ යොදා ඇත — සරලම ගැළපෙන workflow එක තේරීම, පිටුව 25.** Cost calculation, stock update සහ approval වැනි අවදානම් ක්‍රියා සඳහා deterministic rules තබා ඇත. Model එකකට අනුමැතිය ලබා දීමට ඉඩ දී නැත.
- **△ අර්ධ වශයෙන් — framework components, පිටුව 36.** දේශනයේ components හයක් ඇත. Tools, state/history, monitoring සහ orchestration යම් මට්ටමකින් තිබුණත් live model inference සහ එයට runtime prompts නැත.

### Lecture 5 part 2 — RAG, retrieval සහ memory

- **✓ එක් කළා — source-backed retrieval, පිටු 6, 22, 25, 43.** `project_knowledge.py` තුළ project policies හයක කෙටි passages ඇත. Query වචන සමඟ ගැළපීමෙන් relevant passages තෝරා source ID, version සහ score ලබා දෙයි. Compliance workflow එක grid/inspection references notes තුළ ඇතුළත් කරයි.
- **✓ එක් කළා — evidence සීමාව.** Match එකක් නැති විට පිළිතුරක් ගොතා නොදමයි. Query දිග සීමා කර ඇත. Arbitrary files, URLs, uploads හෝ customer records මෙයට sources ලෙස නොගනී. මේවා project rules මිස නිල CEB/LECO නීති බව නොකියන්න.
- **✓ එක් කළා — කුඩා retrieval evaluation එකක්.** Queries හයක් සඳහා expected passage එක පළමු ස්ථානයේ ලැබෙන බව tests හයම තහවුරු කරයි. එම කුඩා fixture එකේ Hit@1 සහ MRR 1.0 වේ. එයින් සියලු natural-language queries හෝ සිංහල retrieval හොඳ බව තහවුරු නොවේ.
- **△ අර්ධ වශයෙන් — full RAG.** Embeddings, vector database, semantic search, reranking සහ model-generated answer මෙහි නැත. එබැවින් “full RAG කරලා” යැයි නොකියන්න. නිවැරදි නම lexical retrieval සහ cited project guidance යන්නයි. ගණනය කිරීම් සහ approval validator එක retrieved text නිසා වෙනස් නොවේ.
- **△ අර්ධ වශයෙන් — memory, පිටුව 47.** Graph state එක working memory ලෙසත්, saved decisions episodic history ලෙසත්, reviewed passages semantic facts ලෙසත්, rules procedural knowledge ලෙසත් සංකල්පමය වශයෙන් පැහැදිලි කළ හැක. නමුත් model එකක් ඒවා මතක තබාගෙන ස්වයංක්‍රීයව ඉගෙන ගන්නා memory system එකක් නොවේ.

### Lecture 5 part 3 — coordination, reliability සහ MCP

- **✓ දැනට තිබේ — pipeline, පිටු 12–16.** Survey → inspection → compliance → proposal → human approval → equipment යන dependencies නිසා pipeline එක ගැළපේ.
- **✓ දැනට තිබේ — structured handoffs, පිටු 19–20.** ASP.NET සහ Python අතර typed payloads හුවමාරු වේ. Survey/job/proposal/quote IDs මඟින් stages සම්බන්ධ වේ. එක දිගට memory තුළ ධාවනය වන LLM conversation එකක් ලෙස මෙය ක්‍රියා නොකරයි.
- **✓ එක් කළා — bounded retry, පිටුව 21.** Exchange-rate tool එක timeout/network error හෝ HTTP 429/502/503/504 සඳහා පමණක් තවත් එක් උත්සාහයක් කරයි. උත්සාහ අතර 200 ms විරාමයක් ඇත. Invalid response එකක් හෝ සාමාන්‍ය 4xx සඳහා එම retry එක නොකරයි. අවසානයේත් fail නම් ව්‍යාජ rate එකක් නොදමයි.
- **✓ එක් කළා — measured traces, පිටු 24, 27–31.** Sizing/compliance stages සඳහා actual start/end, duration, trace ID සහ span ID ඇත. Failed sizing stage එකේ log එක ඉතිරි වේ. Sizing graph එකට step limit එකක් ඇත. Proposal/pricing ඇතුළු මුළු පද්ධතියටම සම්පූර්ණ distributed tracing තිබෙන බව නොකියන්න.
- **✓ එක් කළා — missing evidence guardrail.** Inverter location suitable යන value එක නොදුන් විට එය කලින් තිබූ default true එකෙන් සාර්ථක නොවී unknown ලෙස සලකයි.
- **✓ දැනට තිබේ — least privilege, පිටු 23, 30.** Python agent එකට stock වෙනස් කිරීමට හෝ proposal approve කිරීමට බලය නැත. Backend සහ authorized human action ඒවා පාලනය කරයි.
- **○ විකල්පයක් — MCP, පිටු 33–36.** මෙහි internal FastAPI connection එක REST වේ. එය MCP server එකක් නොවේ. දේශනයේ නම සඳහන් වූ නිසා පමණක් MCP එකතු කිරීම අවශ්‍ය නැත.

## 3. මෙම සංශෝධනයෙන් කළ දේ

1. Inventory fetching එක reusable hook එකකට වෙන් කර debounce/cancellation තබා ගත්තා.
2. Workspace routes lazy load කිරීම, loading fallback සහ page error recovery එක් කළා.
3. Backend exception middleware එක Problem Details contract එකට ගෙන ආවා.
4. Versioned project-policy retrieval සහ compliance references එක් කළා.
5. Sizing/compliance සඳහා සැබෑ stage timing සහ failed-event retention එක් කළා.
6. Exchange tool එකට සීමිත transient retry එකක් එක් කළා; fake fallback rate එකක් නැත.
7. NaN/Infinity වැනි sizing input ප්‍රතික්ෂේප කිරීම සහ missing inverter evidence වැරදි ලෙස pass නොවීම තහවුරු කළා.
8. Regression tests, ADR-007 සහ මෙම භාෂා දෙකේ වාර්තා එක් කළා. Paid inference dependency, database migration, commit හෝ push එකක් නොකළා.

## 4. සම්පූර්ණ workflow එක සම්බන්ධ වන ආකාරය

**React / Flutter → ASP.NET API → business services → PostgreSQL.** Calculation/screening අවශ්‍ය තැනදී ASP.NET විසින් **internal FastAPI → specialist → independent validator** කැඳවයි. Structured result එක ලැබුණු පසු business state save කරයි. Client එක Python හෝ PostgreSQL වෙත සෘජුව නොයයි.

Engineer approval එක database තුළ සුරකින business pause එකකි. එය Python process එකක් දිගටම බලා සිටින තත්ත්වයක් නොවේ. Approval පසුව pricing සහ reservation වෙනම authorized operations ලෙස ක්‍රියාත්මක වේ. Phone සහ web එකම record IDs/API භාවිත කරන නිසා එකම installation එකේ තත්ත්වය දැකිය හැක.

### උදාහරණය — මාසයකට 600 kWh භාවිත කරන පරීක්ෂණ නිවසක්

මෙය synthetic test example එකකි; සැබෑ electrical design උපදෙසක් නොවේ.

1. **Homeowner:** 600 kWh, 80 m², ThreePhase සහ test address එකක් දමා survey submit කරන්න. Sizing rule එක **600 ÷ 120 = 5 kW** ලබා දෙයි. දැනට preliminary 400 W assumption එක සහ rounding අනුව **panels 12** පෙන්වයි. Survey reference එක සටහන් කරගන්න.
2. **Administrator / engineer:** එම survey එකට field job එකක් සාදා technician assign කරන්න. අලුත් අසම්බන්ධ survey එකක් සාදන්න එපා.
3. **Technician:** එම job එකේ measurements සහ photos ඇතුළත් කරන්න. Synthetic compliant example එක සඳහා **400 V, 50 Hz, 63 A, inverter location suitable** භාවිත කළ හැක. Form එකේ අනෙක් required fields ද සම්පූර්ණ කරන්න.
4. **Compliance:** input validation → project references → rule screening → independent check. මෙම example එක project rules අනුව **COMPLIANT / LOW** විය යුතුය. Missing/unsafe data තිබුණොත් issues ලැබේ.
5. **Proposal:** completed compliance assessment එකෙන් proposal request කරන්න. Inspection ට පෙර සෑදූ proposal එකේ old snapshot එක තිබිය හැක. එවිට validation bypass නොකර completed assessment භාවිත කර අලුත් proposal එකක් ගන්න.
6. **Engineer:** technical details, technician photos සහ findings බලන්න. Approve, reject හෝ revision request කරන්න. “Safe” result එකක් තිබීම human approval එක නොවේ. Invalid proposal එක blocked විය යුතුය.
7. **Inventory officer:** approved proposal එකේ equipment price ගණනය කරන්න. Catalog policy එක **500 W panels** නිසා 5 kW සඳහා **panels 10** සහ compatible inverter එකක් තෝරයි. උදාහරණයක් ලෙස panels USD 100 × 10 සහ inverter USD 500 නම් USD 1,500 වේ. උදාහරණ rate එක 300 LKR/USD නම් **LKR 450,000** වේ. සැබෑ screen එකේ rate සහ prices වෙනස් විය හැක; installation/taxes මෙයට ඇතුළත් නොවේ.
8. **Reserve:** backend එක approval, quote expiry සහ available stock transaction එක තුළ නැවත පරීක්ෂා කරයි. Success වූ විට reserved/available stock වෙනස් වේ. එකම reservation නැවත කිරීමෙන් stock දෙවරක් අඩු නොවිය යුතුය.

**Panel ගණන පිළිබඳ සීමාව:** preliminary stage එකේ 400 W සහ catalog stage එකේ 500 W යන වෙනස් assumptions ඇත. ඒ නිසා 12 සහ 10 එකම bill of materials එක නොවේ. තවද 12 × 400 W = 4.8 kW වන නිසා preliminary rounding එක exact 5 kW final design එකක් සහතික නොකරයි. මෙය presentation එකේ පැහැදිලි කර, අවසන් engineering design ලෙස ප්‍රකාශ කිරීමට පෙර එකඟ policy එකකට ගෙන ආ යුතුය.

### පෙන්විය යුතු failure examples

- Required inspection value එකක් නැති විට clearance නොලැබීම.
- Homeowner කෙනෙකු engineer approval request කළ විට backend deny කිරීම.
- Old proposal එකේ validation තවම blocked වීම සහ fresh proposal එකක් අවශ්‍ය වීම.
- Exchange service unavailable නම් bounded retry පසුව pricing fail වීම; fake rate/reservation නොමැති වීම.
- Quote පසු stock වෙනස් වූ විට reserve කරන මොහොතේ නැවත stock පරීක්ෂා කිරීම.
- Invalid sizing input එක successful result වෙනුවට failed stage එකක් ලබා දීම.

## 5. “හතර” යන්නෙන් අදහස් කරන වෙනස් කාණ්ඩ

### දේශනයේ coordination patterns හතර

`lec5 part3.pdf`, පිටුව 12:

1. **Router:** request එකට ගැළපෙන specialist එක තෝරයි. සාමාන්‍ය HTTP routing තිබීම LLM router එකක් තිබීමේ සාක්ෂියක් නොවේ.
2. **Pipeline:** පෙර stage output එක ඊළඟ stage එක භාවිත කරයි. ව්‍යාපෘතියේ ප්‍රධාන ක්‍රමය මෙයයි.
3. **Parallel:** ස්වාධීන වැඩ කිහිපයක් එකවර කර ප්‍රතිඵල එකතු කරයි. Approval සහ stock reservation වැනි dependent stages එසේ එකවර කළ යුතු නැත. දැනට parallel-agent runtime එකක් කියා නොපෙන්වන්න.
4. **Supervisor:** ප්‍රතිඵල අනුව ඊළඟ specialist/step එක තීරණය කරයි. Fixed PlannerAgent එක එවැනි dynamic supervisor එකක් නොවේ.

මේ patterns හතරම සෑම project එකකම තිබිය යුතු යැයි දේශනයෙන් අදහස් නොවේ.

### ව්‍යාපෘතියේ specialist කොටස් හතර

1. **SolarSizingAgent:** electricity usage එකෙන් preliminary system size ලබා දෙයි.
2. **GridComplianceAgent:** technician measurements project rules සමඟ පරීක්ෂා කරයි.
3. **SafetyGuardrailAgent:** proposal risks සහ escalation flags ලබා දෙයි; human approval ලබා නොදෙයි.
4. **EquipmentPricingAgent:** compatible equipment සහ exchange rate එකෙන් quotation ගණනය කරයි; stock ලියන්නේ නැත.

PlannerAgent අමතර fixed roadmap එක ලබා දෙයි. Validators outputs පරීක්ෂා කරයි. Agent නම ඇති classes හතරක් තිබීම LLM agents හතරක් තිබීමේ සාක්ෂියක් නොවේ.

### Memory හතර සහ framework components හය

`lec5 part2.pdf`, පිටුව 47 හි **working, episodic, semantic, procedural** memory වර්ග හතර ඇත. මෙහි graph state, stored decisions, reviewed passages සහ business rules සමඟ ඒවා සංකල්පමය වශයෙන් සම්බන්ධ කළ හැක.

`lec5 part1.pdf`, පිටුව 36 හි ඇත්තේ **Models, Tools, Memory, Monitoring, Prompts, Middleware/Orchestration** යන components **හයයි**. එය හතරක් ලෙස presentation එකේ නොකියන්න. Model inference සහ runtime prompting දැනට නැත.

සරල demo story එකක් සඳහා **assess → inspect → review → prepare equipment** ලෙස stages හතරක් භාවිත කළ හැක. ඒවා business stages ලෙස නම් කරන්න.

## 6. සාමාජිකයන් හතර සඳහා වගකීම් බෙදීම

මෙය ඉදිරියට යෝජිත බෙදීමකි. දැනට වැඩ කළේ ඔබ තනිව බව ඔබ පැවසූ නිසා මේවා කලින් කළ contributions ලෙස වාර්තා නොකරන්න. එක් අයෙකු backend පමණක්, තවත් අයෙකු UI පමණක් ලෙස බෙදනවාට වඩා සෑම අයෙකුටම තම component එක end-to-end භාර දෙන්න.

### Member 1 — Customer assessment සහ sizing

Survey/profile assessment inputs, ownership rules, survey data සහ SolarSizingAgent භාර ගන්න. React survey review, Flutter homeowner survey/photo/status flow, API, database සහ tests ඇතුළත් වේ. Demo එකේ 600 kWh → 5 kW සහ invalid input rejection පෙන්වන්න. ඉදිරියේදී panel assumptions එකඟ කිරීම සහ structured plan dependencies වැඩි දියුණු කිරීම සුදුසුය.

### Member 2 — Field operations සහ compliance

Technician assignment, inspections, measurements, photos/GPS සහ GridComplianceAgent භාර ගන්න. React dispatch/review සහ Flutter field capture දෙකම ඇතුළත් වේ. Compliant example එකක් සහ missing measurement example එකක් පෙන්වන්න. ඉදිරියේදී protected photo delivery සහ physical-device camera/GPS testing කරන්න.

### Member 3 — Proposal සහ engineer approval

Proposal lifecycle, safety findings, technician evidence review, approve/reject/revise සහ audit history භාර ගන්න. React engineer screen, Flutter homeowner result, backend authorization සහ SafetyGuardrailAgent ඇතුළත් වේ. Invalid proposal block වීම සහ wrong-role approval deny වීම පෙන්වන්න. Stale proposal refresh පැහැදිලි කිරීම සහ full timing traces වැඩි දියුණු කිරීම ඉදිරි වැඩ ලෙස ගන්න.

### Member 4 — Inventory, pricing සහ reservation

Catalog CRUD/search, stock, quotations, exchange tool, reservation/release සහ EquipmentPricingAgent භාර ගන්න. React inventory UI, Flutter equipment summary, backend transactions සහ database tests ඇතුළත් වේ. Correct totals, tool failure සහ repeated reservation එකෙන් double deduction නොවීම පෙන්වන්න. Isolated PostgreSQL concurrency test සහ tool-attempt traces වැඩි දියුණු කරන්න.

සෑම සාමාජිකයෙකුම සැබෑ issue, commit, test සහ peer review evidence එකතු කළ යුතුය. තමන් කළ දේ පිළිබඳ reflection තමන් ලියන්න. අතීත contributions, signatures හෝ marks evidence ගොතා නොදමන්න.

## 7. පරීක්ෂණ සහ ඒවායේ සීමා

- Python tests **55ක් pass** විය. Retrieval queries හය, safe failures, missing evidence, timing සහ bounded retries ඇතුළත් වේ. Dependency deprecation warning එකක් ඇත.
- ASP.NET tests **98ක් pass**, PostgreSQL integration test **1ක් skip** විය. එය fresh database concurrency proof එකක් නොවේ.
- React tests **47ක් pass** විය. Error boundary test එක හිතාමතා render error එකක් ඇති කරයි. Account test router එකේ dashboard route නැති බවට පැරණි warning එකක්ද ඇත.
- TypeScript/Vite production build සාර්ථක විය; lazy route chunks නිපදවිය.
- Flutter සඳහා සැප්තැම්බර් 19 දින tests **20ක් pass** විය; `flutter analyze` එකේ issues නොමැත. Package-update notices analyzer failures නොවේ. මෙම lecture audit එකේ Flutter source වෙනස් කර නැත.

මෙම automated checks වලින් real-device permissions, public deployment, load capacity හෝ සම්පූර්ණ phone-to-browser demo එකක් තහවුරු නොවේ. කලින් දිනයක තිබූ test evidence මෙවර run එක ලෙස ඉදිරිපත් නොකරන්න.

## 8. වැඩි ලකුණු සඳහා තව අවශ්‍ය දේ

1. Lecturer බලාපොරොත්තු වන්නේ LLM විසින් tools තෝරන agent එකක් නම් එම කොටස තව අර්ධ වශයෙන් බව පැහැදිලි කරන්න. No-paid-model constraint එකට local model එකක් ගැළපිය හැකි නමුත් එය නිසි contracts, resource limits සහ tests සමඟ වෙනම ක්‍රියාත්මක කළ යුතුය.
2. සියලු components සඳහා tracing සහ interrupted-run recovery එකඟ කරන්න. දැනට measured improvements sizing/compliance සඳහා පමණි.
3. Photo protection, token lifecycle, HTTPS, database permissions සහ backup/recovery පරීක්ෂා කරන්න.
4. එකම survey ID එකෙන් Flutter submit → React assignment/approval → pricing/reservation → mobile status යන demo එක record කරන්න. Failure cases ද පෙන්වන්න.
5. Sizing/catalog assumptions එකඟ කර project thresholds නිල utility certification ලෙස නොපෙන්වන්න.
6. සැබෑ public URLs, අවසන් mobile build, demo video, genuine member contributions, reflections සහ assignment report format සම්පූර්ණ කරන්න. Tests pass වූ පමණින් full marks සහතික නොවේ.

### Presentation එකේ කියන්න පුළුවන් කෙටි විස්තරය

“අපේ පද්ධතිය homeowner survey එක, technician inspection එක, engineer approval එක සහ equipment preparation එක secured API එකකින් සම්බන්ධ කරනවා. Specialists හතර structured results ලබා දෙනවා. Independent validators ඒවා පරීක්ෂා කරනවා. Human approval සහ database transactions අවදානම් ක්‍රියා පාලනය කරනවා. React hooks/composition, ASP.NET DI/middleware, EF relationships/transactions සහ workflow logging අපි භාවිත කරනවා. දැනට no-paid-model version එක deterministic pipeline එකක් සහ cited project guidance එකක්. Autonomous LLM reasoning හෝ full RAG තියෙනවා කියලා අපි කියන්නේ නැහැ.”

## 9. මූලාශ්‍ර

ඔබ ලබා දුන් `lec1.pdf` (පිටු 47), `lec2.pdf` (52), `lec3.pdf` (57), `lec4.pdf` (60), `lec5 part1.pdf` (40), `lec5 part2.pdf` (57), `lec5 part3.pdf` (37) භාවිත කර ඇත. ඉහත sections තුළ අදාළ PDF පිටු සඳහන් කර ඇත. Source-to-code mapping එක මෙම audit එකේ විශ්ලේෂණයයි. සම්පූර්ණ technical file references සහ rerun commands ඉංග්‍රීසි වාර්තාවේ ඇත. External electrical standards හෝ නීතිමය certification මෙම audit එකෙන් තහවුරු කර නැත.
