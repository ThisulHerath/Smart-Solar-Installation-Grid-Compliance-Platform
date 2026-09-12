import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import { Layout } from './components/Layout';
import { ProtectedRoute } from './components/ProtectedRoute';
import { LoginPage } from './pages/LoginPage';
import { RegisterPage } from './pages/RegisterPage';
import { AccountPage } from './pages/AccountPage';
import { OperationsDashboard } from './pages/OperationsDashboard';
import { UnauthorizedPage } from './pages/UnauthorizedPage';
import { NotFoundPage } from './pages/NotFoundPage';
import { SurveysPage } from './pages/SurveysPage';
import { FieldJobsPage } from './pages/FieldJobsPage';
import { FieldJobDetailPage } from './pages/FieldJobDetailPage';
import { ProposalsPage } from './pages/ProposalsPage';
import { PendingApprovalsPage } from './pages/PendingApprovalsPage';
import { ProposalDetailPage } from './pages/ProposalDetailPage';
import { InventoryPage } from './pages/InventoryPage';

export const App: React.FC = () => {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          {/* Public Routes */}
          <Route path="/login" element={<LoginPage />} />
          <Route path="/register" element={<RegisterPage />} />

          {/* Protected Routes Layout */}
          <Route element={<ProtectedRoute />}>
            <Route element={<Layout />}>
              <Route element={<ProtectedRoute allowedRoles={['ADMINISTRATOR', 'INVENTORY_OFFICER', 'SENIOR_ENGINEER']} />}>
                <Route path="/inventory" element={<InventoryPage />} />
              </Route>
              <Route path="/" element={<OperationsDashboard />} />
              <Route path="/account" element={<AccountPage />} />
              <Route path="/dashboard" element={<Navigate to="/" replace />} />
              <Route element={<ProtectedRoute allowedRoles={['ADMINISTRATOR', 'SENIOR_ENGINEER']} />}>
                <Route path="/surveys" element={<SurveysPage />} />
                <Route path="/field-jobs" element={<FieldJobsPage />} />
                <Route path="/field-jobs/:jobId" element={<FieldJobDetailPage />} />
                <Route path="/proposals" element={<ProposalsPage />} />
                <Route path="/proposals/pending" element={<PendingApprovalsPage />} />
              </Route>
              {/* Proposal detail accessible to any authenticated user (homeowner, engineer) */}
              <Route path="/proposals/:id" element={<ProposalDetailPage />} />
            </Route>
          </Route>

          {/* Error Pages */}
          <Route element={<Layout />}>
            <Route path="/unauthorized" element={<UnauthorizedPage />} />
            <Route path="/404" element={<NotFoundPage />} />
            <Route path="*" element={<NotFoundPage />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
};

