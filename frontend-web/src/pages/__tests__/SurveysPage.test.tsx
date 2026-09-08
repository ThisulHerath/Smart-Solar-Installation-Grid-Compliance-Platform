import { render, screen, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { SurveysPage } from '../SurveysPage';
import { api } from '../../services/api';
import { AuthProvider } from '../../context/AuthContext';
import { ProtectedRoute } from '../../components/ProtectedRoute';
import { Survey } from '../../types/auth';

// Mock the API service
vi.mock('../../services/api', () => ({
  api: {
    getSurveys: vi.fn(),
    getMe: vi.fn(),
  },
}));

const mockSurveys: Survey[] = [
  {
    id: 'survey-101',
    customerId: 'cust-1',
    monthlyKwh: 1200,
    roofAreaSqm: 80,
    gridType: 'SinglePhase',
    roofOrientation: 'South',
    propertyAddress: '123 Solar Way, Colombo',
    surveyStatus: 'AnalysisComplete',
    createdAt: '2026-09-08T10:00:00Z',
    updatedAt: '2026-09-08T10:05:00Z',
    images: [{ id: 'img-1', imageType: 'RoofSite', fileUrl: '/uploads/roof.jpg', fileName: 'roof.jpg' }],
    workflows: [
      {
        workflowId: 'wf-1',
        status: 'Completed',
        resultJson: JSON.stringify({
          recommended_kw: 10.0,
          estimated_panel_count: 25,
          estimated_inverter_kw: 10.0,
          reason: 'Calculated from 1200 kWh monthly usage.',
        }),
        validationJson: JSON.stringify({
          valid: true,
          checks: {
            monthly_kwh_valid: true,
            roof_area_valid: true,
            recommended_kw_consistent: true,
            panel_count_reasonable: true,
            inverter_size_consistent: true,
            schema_valid: true,
          },
        }),
      },
    ],
  },
];

describe('SurveysPage & Staff Protection Tests', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders loading state initially', () => {
    (api.getSurveys as any).mockReturnValue(new Promise(() => {})); // pending promise
    render(<SurveysPage />);
    expect(screen.getByText(/Loading customer solar surveys/i)).toBeInTheDocument();
  });

  it('renders empty state when no surveys exist', async () => {
    (api.getSurveys as any).mockResolvedValue([]);
    render(<SurveysPage />);
    await waitFor(() => {
      expect(screen.getByText(/No customer surveys found/i)).toBeInTheDocument();
    });
  });

  it('renders error state on API failure', async () => {
    (api.getSurveys as any).mockRejectedValue(new Error('Network error loading surveys'));
    render(<SurveysPage />);
    await waitFor(() => {
      expect(screen.getByText(/Survey Load Error/i)).toBeInTheDocument();
      expect(screen.getByText(/Network error loading surveys/i)).toBeInTheDocument();
    });
  });

  it('renders survey page, workflow status, AI result & validation checks', async () => {
    (api.getSurveys as any).mockResolvedValue(mockSurveys);
    render(<SurveysPage />);

    await waitFor(() => {
      expect(screen.getByText(/Staff Solar Survey Dashboard/i)).toBeInTheDocument();
      expect(screen.getAllByText('123 Solar Way, Colombo').length).toBeGreaterThan(0);
      expect(screen.getAllByText(/Analysis Complete/i).length).toBeGreaterThan(0);
      expect(screen.getByText(/Recommended Array Capacity/i)).toBeInTheDocument();
      expect(screen.getByText(/Estimated Panel Count/i)).toBeInTheDocument();
      expect(screen.getByText(/PASSED ALL CHECKS/i)).toBeInTheDocument();
    });
  });

  it('renders safe failure message when survey workflow failed', async () => {
    const failedSurvey: Survey[] = [
      {
        ...mockSurveys[0],
        surveyStatus: 'Failed',
        workflows: [
          {
            workflowId: 'wf-err',
            status: 'Failed',
            errorMessage: 'AI Agentic service was unreachable.',
          },
        ],
      },
    ];
    (api.getSurveys as any).mockResolvedValue(failedSurvey);
    render(<SurveysPage />);

    await waitFor(() => {
      expect(screen.getAllByText(/Workflow Failed/i).length).toBeGreaterThan(0);
      expect(screen.getByText(/AI Agentic service was unreachable/i)).toBeInTheDocument();
    });
  });

  it('restricts non-staff users from accessing protected staff survey route', async () => {
    const homeownerUser = {
      id: 'user-homeowner',
      email: 'user@example.com',
      fullName: 'Homeowner User',
      roles: ['HOMEOWNER'],
      createdAt: '2026-09-08T00:00:00Z',
    };

    localStorage.setItem('smartsolar_token', 'mock-token');
    (api.getMe as any).mockResolvedValue(homeownerUser);

    render(
      <AuthProvider>
        <MemoryRouter initialEntries={['/surveys']}>
          <Routes>
            <Route element={<ProtectedRoute allowedRoles={['ADMINISTRATOR', 'SENIOR_ENGINEER']} />}>
              <Route path="/surveys" element={<div>Staff Survey Content</div>} />
            </Route>
            <Route path="/unauthorized" element={<div>Access Denied Page</div>} />
          </Routes>
        </MemoryRouter>
      </AuthProvider>
    );

    await waitFor(() => {
      expect(screen.getByText('Access Denied Page')).toBeInTheDocument();
      expect(screen.queryByText('Staff Survey Content')).not.toBeInTheDocument();
    });
  });
});
