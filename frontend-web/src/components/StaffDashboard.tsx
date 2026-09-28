import { ArrowRight, Box, ClipboardList, FileCheck2, HardHat, PackageCheck } from 'lucide-react';
import { Link } from 'react-router-dom';
import { User } from '../types/auth';

type Report = { surveyCount: number; pendingApprovals: number; approvedProposals: number; lowStockItems: number; reservedEquipmentValueLkr: number };

export function StaffDashboard({ user, report, error }: { user: User; report: Report | null; error: string }) {
  const role = user.roles.includes('SENIOR_ENGINEER') ? 'SENIOR_ENGINEER' : user.roles.includes('INVENTORY_OFFICER') ? 'INVENTORY_OFFICER' : 'FIELD_TECHNICIAN';
  const settings = role === 'SENIOR_ENGINEER'
    ? { eyebrow: 'ENGINEERING WORKSPACE', title: 'Design decisions, clearly organized.', copy: 'Review incoming solar work and move approved systems confidently toward installation.', metrics: report ? [['New surveys', report.surveyCount], ['Awaiting approval', report.pendingApprovals], ['Approved systems', report.approvedProposals]] : [], actions: [{ to: '/surveys', title: 'Review surveys', copy: 'Assess submitted property and roof data.', icon: ClipboardList }, { to: '/field-jobs', title: 'Field operations', copy: 'Coordinate inspections and technician visits.', icon: HardHat }, { to: '/proposals/pending', title: 'Approval queue', copy: 'Make engineering decisions with context.', icon: FileCheck2 }] }
    : role === 'INVENTORY_OFFICER'
      ? { eyebrow: 'INVENTORY WORKSPACE', title: 'Stock and pricing, in view.', copy: 'Keep equipment availability and proposal reservations aligned with the work pipeline.', metrics: report ? [['Low stock items', report.lowStockItems], ['Approved systems', report.approvedProposals], ['Reserved value', `LKR ${report.reservedEquipmentValueLkr.toLocaleString('en-LK')}`]] : [], actions: [{ to: '/inventory', title: 'Equipment catalog', copy: 'Manage stock levels, suppliers, and pricing.', icon: Box }, { to: '/inventory', title: 'Proposal pricing', copy: 'Prepare equipment estimates and reserve stock.', icon: PackageCheck }] }
      : { eyebrow: 'FIELD WORKSPACE', title: 'Every site visit, ready for action.', copy: 'Keep your assigned inspections, site evidence, and compliance steps organized in one place.', metrics: [['Site work', 'My assignments'], ['Evidence', 'Photo-ready'], ['Compliance', 'Track status']], actions: [{ to: '/technician-jobs', title: 'My assignments', copy: 'Open the jobs assigned to you today.', icon: HardHat }, { to: '/profile', title: 'My profile', copy: 'Review your contact details and access.', icon: ClipboardList }] };

  return <main className={`staff-dashboard staff-dashboard--${role.toLowerCase().replace(/_/g, '-')}`}>
    <section className="staff-dashboard-hero"><p>{settings.eyebrow}</p><h1>Welcome back, {user.fullName}</h1><h2>{settings.title}</h2><span>{settings.copy}</span></section>
    {error && <p className="staff-dashboard-error" role="alert">{error}</p>}
    {settings.metrics.length > 0 && <section className="staff-dashboard-metrics">{settings.metrics.map(([label, value]) => <article key={label}><span>{label}</span><strong>{value}</strong></article>)}</section>}
    <section className="staff-dashboard-tools"><header><div><p>ROLE TOOLS</p><h2>Keep work moving</h2></div><span>Focused actions for your role</span></header><div>{settings.actions.map(({ to, title, copy, icon: Icon }) => <Link key={title} to={to}><span><Icon size={22} /></span><h3>{title}</h3><p>{copy}</p><b>Open <ArrowRight size={15} /></b></Link>)}</div></section>
  </main>;
}
