import React, { lazy, Suspense } from 'react';
import { BrowserRouter, Route, Routes } from 'react-router-dom';

import { PageErrorBoundary } from './components/PageErrorBoundary';

import { AuthProvider } from './context/AuthContext';
import { Layout } from './components/Layout';
import { ProtectedRoute } from './components/ProtectedRoute';

import { LandingPage } from './pages/LandingPage';
import { LoginPage } from './pages/LoginPage';
import { ForgotPasswordPage } from './pages/ForgotPasswordPage';
import { NotFoundPage } from './pages/NotFoundPage';
import { RegisterPage } from './pages/RegisterPage';

import { UnauthorizedPage } from './pages/UnauthorizedPage';


const ProfilePage = lazy(() =>
  import('./pages/ProfilePage').then((module) => ({
    default: module.ProfilePage,
  }))
);

const AccountPage = lazy(() =>
  import('./pages/AccountPage').then((module) => ({
    default: module.AccountPage,
  }))
);

const OperationsDashboard = lazy(() =>
  import('./pages/OperationsDashboard').then((module) => ({
    default: module.OperationsDashboard,
  }))
);

const SurveysPage = lazy(() =>
  import('./pages/SurveysPage').then((module) => ({
    default: module.SurveysPage,
  }))
);

const FieldJobsPage = lazy(() =>
  import('./pages/FieldJobsPage').then((module) => ({
    default: module.FieldJobsPage,
  }))
);

const FieldJobDetailPage = lazy(() =>
  import('./pages/FieldJobDetailPage').then((module) => ({
    default: module.FieldJobDetailPage,
  }))
);

const ProposalsPage = lazy(() =>
  import('./pages/ProposalsPage').then((module) => ({
    default: module.ProposalsPage,
  }))
);

const PendingApprovalsPage = lazy(() =>
  import('./pages/PendingApprovalsPage').then((module) => ({
    default: module.PendingApprovalsPage,
  }))
);

const ProposalDetailPage = lazy(() =>
  import('./pages/ProposalDetailPage').then((module) => ({
    default: module.ProposalDetailPage,
  }))
);

const InventoryPage = lazy(() =>
  import('./pages/InventoryPage').then((module) => ({
    default: module.InventoryPage,
  }))
);

const UserManagementPage = lazy(() =>
  import('./pages/UserManagementPage').then((module) => ({
    default: module.UserManagementPage,
  }))
);

const TechnicianJobsPage = lazy(() =>
  import('./pages/TechnicianJobsPage').then((module) => ({ default: module.TechnicianJobsPage }))
);

export const App: React.FC = () => {
  return (
    <AuthProvider>
      <BrowserRouter>
        <PageErrorBoundary>
          <Suspense
            fallback={
              <main
                className="account-page"
                role="status"
              >
                Opening your workspace…
              </main>
            }
          >
            <Routes>
              {/* Public Routes */}
              <Route path="/" element={<LandingPage />} />
              <Route path="/login" element={<LoginPage />} />
              <Route path="/forgot-password" element={<ForgotPasswordPage />} />
              <Route
                path="/register"
                element={<RegisterPage />}
              />

              {/* Protected Routes Layout */}
              <Route element={<ProtectedRoute />}>
                <Route element={<Layout />}>
                  <Route
                    element={
                      <ProtectedRoute
                        allowedRoles={[
                          'ADMINISTRATOR',
                          'INVENTORY_OFFICER',
                          'SENIOR_ENGINEER',
                        ]}
                      />
                    }
                  >
                    <Route
                      path="/inventory"
                      element={<InventoryPage />}
                    />
                  </Route>

                  <Route
                    path="/dashboard"
                    element={<OperationsDashboard />}
                  />

                  <Route
                    element={<ProtectedRoute allowedRoles={['ADMINISTRATOR']} />}
                  >
                    <Route
                      path="/users"
                      element={<UserManagementPage />}
                    />
                  </Route>

                  <Route
                    path="/profile"
                    element={<ProfilePage />}
                  />

                  <Route
                    path="/account"
                    element={<AccountPage />}
                  />

                  <Route element={<ProtectedRoute allowedRoles={['FIELD_TECHNICIAN']} />}>
                    <Route path="/technician-jobs" element={<TechnicianJobsPage />} />
                  </Route>

                  <Route
                    element={
                      <ProtectedRoute
                        allowedRoles={[
                          'ADMINISTRATOR',
                          'SENIOR_ENGINEER',
                        ]}
                      />
                    }
                  >
                    <Route
                      path="/surveys"
                      element={<SurveysPage />}
                    />

                    <Route
                      path="/field-jobs"
                      element={<FieldJobsPage />}
                    />

                    <Route
                      path="/field-jobs/:jobId"
                      element={<FieldJobDetailPage />}
                    />

                    <Route
                      path="/proposals"
                      element={<ProposalsPage />}
                    />

                    <Route
                      path="/proposals/pending"
                      element={<PendingApprovalsPage />}
                    />
                  </Route>

                  {/* Proposal detail accessible to any authenticated user (homeowner, engineer) */}
                  <Route
                    path="/proposals/:id"
                    element={<ProposalDetailPage />}
                  />
                </Route>
              </Route>

              {/* Error Pages */}
              <Route element={<Layout />}>
                <Route
                  path="/unauthorized"
                  element={<UnauthorizedPage />}
                />

                <Route
                  path="/404"
                  element={<NotFoundPage />}
                />

                <Route
                  path="*"
                  element={<NotFoundPage />}
                />
              </Route>
            </Routes>
          </Suspense>
        </PageErrorBoundary>
      </BrowserRouter>
    </AuthProvider>
  );
}
