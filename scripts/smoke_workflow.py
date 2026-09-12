"""Run against the local demo API. Creates labelled demo records; never alters existing records.
Run: .venv/Scripts/python scripts/smoke_workflow.py --output <evidence.json>
Requires the standard seeded demo staff accounts and running API + Python service.
"""
import argparse
import concurrent.futures
import json
import statistics
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path
import httpx

parser = argparse.ArgumentParser()
parser.add_argument('--base-url', default='http://127.0.0.1:5116')
parser.add_argument('--output', required=True)
args = parser.parse_args()
base = args.base_url.rstrip('/')
if not base.startswith(('http://127.0.0.1:', 'http://localhost:')):
    raise SystemExit('This demo runner only targets a local API.')
tag = 'DEMO-' + uuid.uuid4().hex[:8].upper()
client = httpx.Client(base_url=base, timeout=60)
tokens = {}
events = []

def call(role, method, path, body=None, expected=(200, 201, 204)):
    start = time.perf_counter()
    response = client.request(method, path, json=body,
        headers={'Authorization': 'Bearer ' + tokens[role]} if role else {})
    elapsed = round((time.perf_counter()-start)*1000, 2)
    events.append({'method': method, 'path': path, 'status': response.status_code, 'durationMs': elapsed})
    if response.status_code not in expected:
        raise RuntimeError(f'{method} {path}: {response.status_code}: {response.text[:700]}')
    return response.json() if response.content else None

evidence = {'startedAt': datetime.now(timezone.utc).isoformat(), 'tag': tag, 'events': events}
try:
    for role in ('engineer', 'technician', 'inventory', 'homeowner'):
        auth = call(None, 'POST', '/api/auth/login', {'email': role+'@smartsolar.local', 'password': 'Password@123'})
        tokens[role] = auth['token']
    # Registration is exercised separately through an injected test mailbox in the API tests.
    # This live workflow uses an existing local test identity and never bypasses OTP verification.
    survey = call('homeowner', 'POST', '/api/surveys', {'monthlyKwh': 600, 'roofAreaSqm': 80,
        'gridType': 'ThreePhase', 'roofOrientation': 'South', 'roofTilt': 20,
        'propertyAddress': tag+' Synthetic demonstration site, Colombo', 'notes': 'Synthetic demonstration only.'})
    sid = survey['id']; evidence['surveyId'] = sid
    survey = call('homeowner', 'POST', f'/api/surveys/{sid}/submit', {})
    assert survey['surveyStatus'] == 'AnalysisComplete', survey
    job = call('engineer', 'POST', '/api/field-jobs', {'solarSurveyId': sid,
        'technicianId': 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'priority': 'Medium'})
    jid = job['id']; evidence['jobId'] = jid
    call('technician', 'POST', f'/api/technician/jobs/{jid}/check-in', {'latitude': 6.9, 'longitude': 79.8})
    call('technician', 'PUT', f'/api/technician/jobs/{jid}/inspection', {
        'roofAreaMeasuredSqm': 80, 'roofOrientation': 'South', 'roofTilt': 20, 'gridTypeObserved': 'ThreePhase',
        'phaseCount': 3, 'mainBreakerRating': 63, 'inverterLocationSuitable': True,
        'safetyNotes': 'Synthetic readings for software demonstration.', 'technicianNotes': tag})
    for measurement, value, unit in [('GridVoltage',400,'V'),('GridFrequency',50,'Hz'),('Voc',48,'V'),('Isc',12,'A')]:
        call('technician', 'POST', f'/api/technician/jobs/{jid}/telemetry',
             {'measurementType':measurement, 'measurementValue':value, 'unit':unit})
    inspection = call('technician', 'POST', f'/api/technician/jobs/{jid}/submit', {})
    assert inspection['complianceAssessment']['complianceStatus'] == 'COMPLIANT', inspection
    proposal = call('homeowner', 'POST', '/api/proposals', {'solarSurveyId': sid, 'notes': tag})
    pid = proposal['id']; evidence['proposalId'] = pid
    assert proposal['proposalStatus'] == 'PendingApproval'
    call('homeowner', 'POST', f'/api/proposals/{pid}/approve', {'comment':'Unauthorized'}, expected=(403,))
    proposal = call('engineer', 'POST', f'/api/proposals/{pid}/approve', {'comment': tag+' Software demo approval; not utility authorization.'})
    assert proposal['proposalStatus'] == 'Approved'
    for category, watts, stock, price in [('PANEL',500,30,100),('INVERTER',5000,4,500)]:
        call('inventory', 'POST', '/api/inventory', {'sku':tag+'-'+category, 'name':tag+' '+category,
            'category':category, 'capacityWatts':watts, 'quantityInStock':stock, 'reorderLevel':2,
            'unitPriceUsd':price, 'manufacturer':'Demonstration catalog', 'model':'Demo', 'active':True})
    quote = call('inventory','POST',f'/api/inventory/proposals/{pid}/price',{})
    assert quote['status'] == 'VALIDATED', quote
    qid=quote['id']; evidence['quoteId']=qid; evidence['pricing']=quote['result']
    call('inventory','POST','/api/inventory/reserve',{'quoteId':qid})
    call('inventory','POST','/api/inventory/reserve',{'quoteId':qid})
    quotes=call('homeowner','GET',f'/api/inventory/proposals/{pid}/equipment')
    assert quotes[0]['status']=='RESERVED'
    overview=call('homeowner','GET',f'/api/workflows/surveys/{sid}')
    evidence['overview']=overview
    call('inventory','POST',f'/api/inventory/{qid}/release',{})
    call('inventory','POST','/api/inventory/reserve',{'quoteId':qid},expected=(400,409))
    def read_report(_):
        start=time.perf_counter()
        r=httpx.get(base+'/api/reports/overview',headers={'Authorization':'Bearer '+tokens['engineer']},timeout=30)
        return {'status':r.status_code,'ms':round((time.perf_counter()-start)*1000,2)}
    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:
        samples=list(pool.map(read_report,range(20)))
    assert all(x['status']==200 for x in samples), samples
    timings=sorted(x['ms'] for x in samples)
    evidence['performance']={'endpoint':'GET /api/reports/overview','requests':20,'concurrency':5,
        'medianMs':statistics.median(timings),'p95Ms':timings[18],'maxMs':max(timings), 'samples':samples}
    evidence['status']='PASSED'
except Exception as error:
    evidence['status']='FAILED'; evidence['error']=str(error)
    raise
finally:
    evidence['completedAt']=datetime.now(timezone.utc).isoformat()
    target=Path(args.output); target.parent.mkdir(parents=True,exist_ok=True)
    target.write_text(json.dumps(evidence,indent=2),encoding='utf-8')
    print(json.dumps({'status':evidence['status'],'tag':tag,'output':str(target)}))
