import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { LoginPage } from './LoginPage';
import { RegisterPage } from './RegisterPage';
import { AccountPage } from './AccountPage';
import { accountApi } from '../services/account';
const auth = vi.hoisted(() => ({ user: null as any, login: vi.fn(), logout: vi.fn() }));
vi.mock('../context/AuthContext', () => ({ useAuth: () => auth }));
vi.mock('../services/account', () => ({ accountApi: { requestRegistration: vi.fn(), verifyRegistration: vi.fn(), requestAction: vi.fn(), confirmAction: vi.fn() } }));
const challenge = { challengeId: 'challenge', maskedEmail: 'o•••@example.com', expiresAt: new Date(Date.now() + 600000).toISOString(), resendAfterSeconds: 60 };
const mount = (element: React.ReactNode) => render(<MemoryRouter><Routes><Route path="/" element={element} /><Route path="/login" element={<p>Signed out</p>} /></Routes></MemoryRouter>);
afterEach(cleanup);
beforeEach(() => { vi.clearAllMocks(); auth.user = null; vi.mocked(accountApi.requestRegistration).mockResolvedValue(challenge); vi.mocked(accountApi.requestAction).mockResolvedValue(challenge); });
describe('Public authentication', () => {
  it('shows and hides a password without submitting the form', () => {
    mount(<LoginPage />);
    const password = screen.getByLabelText('Password');
    expect(password).toHaveAttribute('type', 'password');
    fireEvent.click(screen.getByRole('button', { name: 'Show password' }));
    expect(password).toHaveAttribute('type', 'text');
    fireEvent.click(screen.getByRole('button', { name: 'Hide password' }));
    expect(password).toHaveAttribute('type', 'password');
    expect(auth.login).not.toHaveBeenCalled();
  });
  it('provides registration without embedded demo credentials', () => {
    mount(<LoginPage />); expect(screen.getByRole('link', { name: 'Create an account' })).toHaveAttribute('href', '/register');
    expect(screen.queryByText(/demonstration accounts/i)).not.toBeInTheDocument();
    expect(document.body.textContent).not.toContain('Password@123');
  });
  it('requires matching passwords before requesting an email', () => {
    mount(<RegisterPage />);
    fireEvent.change(screen.getByLabelText('Password'), { target: { value: 'One password123' } });
    fireEvent.change(screen.getByLabelText('Confirm password'), { target: { value: 'Different password' } });
    fireEvent.submit(screen.getByRole('button', { name: 'Continue with email verification' }).closest('form')!);
    expect(screen.getByText('Your passwords do not match.')).toBeInTheDocument(); expect(accountApi.requestRegistration).not.toHaveBeenCalled();
  });
  it('does not log in before a valid code and preserves errors for correction', async () => {
    mount(<RegisterPage />);
    fireEvent.change(screen.getByLabelText('Full name'), { target: { value: 'Owner' } });
    fireEvent.change(screen.getByLabelText('Email address'), { target: { value: 'owner@example.com' } });
    for (const label of ['Password', 'Confirm password']) fireEvent.change(screen.getByLabelText(label), { target: { value: 'A long password123' } });
    fireEvent.submit(screen.getByRole('button', { name: 'Continue with email verification' }).closest('form')!);
    await screen.findByLabelText('Email verification code'); expect(auth.login).not.toHaveBeenCalled();
    expect(screen.getByRole('button', { name: /Resend code in/ })).toBeDisabled();
    vi.mocked(accountApi.verifyRegistration).mockRejectedValueOnce(new Error('Incorrect code'));
    fireEvent.change(screen.getByLabelText('Email verification code'), { target: { value: '123456' } });
    fireEvent.click(screen.getByRole('button', { name: 'Verify email' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('Incorrect code'); expect(auth.login).not.toHaveBeenCalled();
    vi.mocked(accountApi.verifyRegistration).mockResolvedValueOnce({ token: 'verified-token', user: { id: 'owner' } } as any);
    fireEvent.click(screen.getByRole('button', { name: 'Verify email' }));
    await waitFor(() => expect(auth.login).toHaveBeenCalledWith('verified-token', { id: 'owner' }));
  });
});
describe('Account security', () => {
  beforeEach(() => { auth.user = { fullName: 'Owner', email: 'owner@example.com', roles: ['HOMEOWNER'] }; });
  it('changes password only after code verification and signs out', async () => {
    mount(<AccountPage />); fireEvent.click(screen.getByRole('button', { name: 'Change password' }));
    for (const label of ['New password', 'Confirm new password']) fireEvent.change(screen.getByLabelText(label), { target: { value: 'A newer password123' } });
    fireEvent.click(screen.getByRole('button', { name: 'Send verification code' }));
    await screen.findByLabelText('Email verification code'); expect(accountApi.confirmAction).not.toHaveBeenCalled();
    vi.mocked(accountApi.confirmAction).mockResolvedValue({ message: 'Password changed.' });
    fireEvent.change(screen.getByLabelText('Email verification code'), { target: { value: '123456' } });
    fireEvent.click(screen.getByRole('button', { name: 'Verify & change password' }));
    await screen.findByText('Signed out'); expect(auth.logout).toHaveBeenCalled();
    expect(accountApi.confirmAction).toHaveBeenCalledWith('password', 'challenge', '123456');
  });
  it('explains retained records and requires explicit deletion confirmation', async () => {
    mount(<AccountPage />); fireEvent.click(screen.getByRole('button', { name: 'Delete account' }));
    expect(screen.getByText(/Installation, survey, safety and approval records/)).toBeInTheDocument();
    expect(screen.getByRole('checkbox')).toBeRequired(); fireEvent.click(screen.getByRole('checkbox'));
    fireEvent.click(screen.getByRole('button', { name: 'Send verification code' }));
    await screen.findByLabelText('Email verification code'); expect(auth.logout).not.toHaveBeenCalled();
    vi.mocked(accountApi.confirmAction).mockResolvedValue({ message: 'Account deleted.' });
    fireEvent.change(screen.getByLabelText('Email verification code'), { target: { value: '654321' } });
    fireEvent.click(screen.getByRole('button', { name: 'Verify & delete my account' }));
    await screen.findByText('Signed out'); expect(accountApi.confirmAction).toHaveBeenCalledWith('account-deletion', 'challenge', '654321');
  });
});
