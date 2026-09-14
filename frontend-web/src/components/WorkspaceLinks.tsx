import { Link } from 'react-router-dom';
import { ArrowUpRight, ClipboardList, HardHat, FileCheck2, Package, ShieldCheck, UserRound, Info } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import '../styles/workspace.css';

export function WorkspaceLinks() {
  const { user } = useAuth();
  const engineer = user?.roles.some(role => ['ADMINISTRATOR', 'SENIOR_ENGINEER'].includes(role));
  const staff = user?.roles.some(role => ['ADMINISTRATOR', 'SENIOR_ENGINEER', 'INVENTORY_OFFICER'].includes(role));
  const links = [
    { to: '/surveys', title: 'Customer surveys', description: 'Review properties and submitted roof assessments.', action: 'View surveys', icon: ClipboardList, color: 'emerald', show: engineer },
    { to: '/field-jobs', title: 'Field operations', description: 'Coordinate site visits, technicians, and inspections.', action: 'Manage field jobs', icon: HardHat, color: 'cyan', show: engineer },
    { to: '/proposals/pending', title: 'Review proposals', description: 'Check solar plans awaiting an engineering decision.', action: 'Open approvals', icon: FileCheck2, color: 'amber', show: engineer },
    { to: '/inventory', title: 'Equipment & pricing', description: 'Manage stock, equipment quotes, and reservations.', action: 'Explore inventory', icon: Package, color: 'violet', show: staff },
    { to: '/profile', title: 'My profile', description: 'View your personal information and account role.', action: 'View profile', icon: UserRound, color: 'emerald', show: true },
    { to: '/account', title: 'Account & security', description: 'Protect your access and manage your password.', action: 'Manage security', icon: ShieldCheck, color: 'neutral', show: true },
  ];
  return <><section className="workspace-panel" aria-labelledby="workspace-title"><header className="workspace-heading"><div><p>QUICK ACCESS</p><h2 id="workspace-title">Your workspace</h2><span>Everything you need to keep your solar projects moving.</span></div><span className="workspace-label">Tools for your role</span></header>
    <nav className="workspace-grid" aria-label="Workspace tools">{links.filter(item => item.show).map(({ to, title, description, action, icon: Icon, color }) => <Link key={to} className={`workspace-card ${color}`} to={to}><span className="workspace-icon"><Icon /></span><ArrowUpRight className="workspace-arrow" size={18} /><h3>{title}</h3><p>{description}</p><span className="workspace-open">{action}<span>→</span></span></Link>)}</nav>
    {!staff && !user?.roles.includes('HOMEOWNER') && <p className="workspace-mobile-note">Open the mobile app to complete your assigned site inspections.</p>}
    </section><aside className="workspace-disclaimer"><Info size={18} /><p>Assessments support planning. Final grid connection and installation approval remain with the authorized engineers and utility.</p></aside></>;
}
