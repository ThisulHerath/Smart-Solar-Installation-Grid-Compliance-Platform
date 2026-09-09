import { render, screen, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { FieldJobsPage } from '../FieldJobsPage';
import { FieldJobDetailPage } from '../FieldJobDetailPage';
import { api } from '../../services/api';
import { AuthProvider } from '../../context/AuthContext';
import { ProtectedRoute } from '../../components/ProtectedRoute';
import { FieldJob } from '../../types/auth';

// Mock API service
vi.mock('../../services/api', () => ({
  api: {
    getFieldJobs: vi.fn(),
    getFieldJob: vi.fn(),
    evaluateJobCompliance: vi.fn(),
    getMe: vi.fn(),
  },
}));

const mockJobs: FieldJob[] = [
  {
    id: 'job-101',
    solarSurveyId: 'survey-101',
    technicianId: 'tech-1',
    technicianName: 'Lead Field Technician',
    customerName: 'Kamal Perera',
    customerPhone: '+94771234567',
    propertyAddress: '45 Galle Road, Colombo 03',
    monthlyKwh: 1200,
    roofAreaSqm: 85,
    status: 'ComplianceComplete',
    priority: 'High',
    assignedAt: '2026-09-09T08:00:00Z',
    createdAt: '2026-09-09T08:00:00Z',
    updatedAt: '2026-09-09T09:30:00Z',
    hasInspection: true,
    inspectionStatus: 'Submitted',
    compliance: {
      id: 'comp-101',
      siteInspectionId: 'insp-101',
      workflowId: 'wf-comp-01',
      gridCompliant: true,
      complianceStatus: 'COMPLIANT',
      riskLevel: 'LOW',
      complianceNotes: 'All electrical telemetry complies with CEB standard.',
      validationStatus: 'PASSED',
      createdAt: '2026-09-09T09:30:00Z',
      updatedAt: '2026-09-09T09:30:00Z',
    },
  },
];

describe('FieldJobsPage & FieldJobDetailPage Tests', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders loading state initially', () => {
    (api.getFieldJobs as any).mockReturnValue(new Promise(() => {}));
    render(
      <MemoryRouter>
        <FieldJobsPage />
      </MemoryRouter>
    );
    expect(screen.getByText(/Loading field technician jobs/i)).toBeInTheDocument();
  });

  it('renders field jobs list with status badges and compliance summary', async () => {
    (api.getFieldJobs as any).mockResolvedValue(mockJobs);
    render(
      <MemoryRouter>
        <FieldJobsPage />
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(screen.getByText(/Field Technician Operations & Compliance/i)).toBeInTheDocument();
      expect(screen.getByText('Kamal Perera')).toBeInTheDocument();
      expect(screen.getByText('45 Galle Road, Colombo 03')).toBeInTheDocument();
      expect(screen.getByText('Lead Field Technician')).toBeInTheDocument();
      expect(screen.getAllByText(/Compliance Complete/i).length).toBeGreaterThan(0);
    });
  });

  it('renders field job detail page with compliance assessment', async () => {
    (api.getFieldJob as any).mockResolvedValue(mockJobs[0]);
    render(
      <MemoryRouter initialEntries={['/field-jobs/job-101']}>
        <Routes>
          <Route path="/field-jobs/:jobId" element={<FieldJobDetailPage />} />
        </Routes>
      </MemoryRouter>
    );

    await waitFor(() => {
      expect(screen.getByText('45 Galle Road, Colombo 03')).toBeInTheDocument();
      expect(screen.getByText('CEB / LECO Grid Compliance Assessment')).toBeInTheDocument();
      expect(screen.getByText(/All electrical telemetry complies with CEB standard/i)).toBeInTheDocument();
      expect(screen.getByText(/Trigger Compliance Evaluation/i)).toBeInTheDocument();
    });
  });

  it('protects field jobs routes from unauthorized homeowner access', async () => {
    const homeownerUser = {
      id: 'user-homeowner',
      email: 'homeowner@example.com',
      fullName: 'Homeowner User',
      roles: ['HOMEOWNER'],
      createdAt: '2026-09-09T00:00:00Z',
    };

    localStorage.setItem('smartsolar_token', 'mock-token');
    (api.getMe as any).mockResolvedValue(homeownerUser);

    render(
      <AuthProvider>
        <MemoryRouter initialEntries={['/field-jobs']}>
          <Routes>
            <Route element={<ProtectedRoute allowedRoles={['ADMINISTRATOR', 'SENIOR_ENGINEER']} />}>
              <Route path="/field-jobs" element={<div>Staff Field Jobs Content</div>} />
            </Route>
            <Route path="/unauthorized" element={<div>Unauthorized Access</div>} />
          </Routes>
        </MemoryRouter>
      </AuthProvider>
    );

    await waitFor(() => {
      expect(screen.getByText('Unauthorized Access')).toBeInTheDocument();
      expect(screen.queryByText('Staff Field Jobs Content')).not.toBeInTheDocument();
    });
  });
});
