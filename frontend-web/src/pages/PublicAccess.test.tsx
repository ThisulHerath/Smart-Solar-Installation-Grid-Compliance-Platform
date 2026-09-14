import { afterEach, beforeEach, expect, it, vi } from 'vitest';
import { cleanup, fireEvent, render, screen } from '@testing-library/react';
import { App } from '../App';
import { api } from '../services/api';

vi.mock('../services/api', () => ({ api: { getMe: vi.fn(), login: vi.fn() } }));
afterEach(cleanup);
beforeEach(() => { localStorage.clear(); vi.clearAllMocks(); window.history.replaceState({}, '', '/'); });

it('opens a public landing page and sends guests to authentication for services', async () => {
  render(<App />);
  expect(await screen.findByRole('heading', { name: /Good for your home/ })).toBeInTheDocument();
  fireEvent.click(screen.getByRole('link', { name: 'Know your rooftop — open services' }));
  expect(await screen.findByRole('heading', { name: 'Sign in to Smart Solar' })).toBeInTheDocument();
  expect(screen.getByLabelText('Email address')).toHaveValue('');
  expect(screen.getByLabelText('Password')).toHaveValue('');
});

it.each(['/dashboard', '/profile', '/account', '/inventory', '/surveys', '/proposals'])('protects direct access to %s', async path => {
  window.history.replaceState({}, '', path);
  render(<App />);
  expect(await screen.findByRole('heading', { name: 'Sign in to Smart Solar' })).toBeInTheDocument();
});

it('loads the signed-in profile and links to separate security settings', async () => {
  localStorage.setItem('smartsolar_token', 'test-token');
  vi.mocked(api.getMe).mockResolvedValue({ id: 'owner', fullName: 'Solar Owner', email: 'owner@example.com', phoneNumber: '+94770000000', roles: ['HOMEOWNER'], createdAt: '2026-01-01T00:00:00Z' });
  window.history.replaceState({}, '', '/profile');
  render(<App />);
  expect(await screen.findByRole('heading', { name: 'My profile' })).toBeInTheDocument();
  expect(screen.getByText('+94770000000')).toBeInTheDocument();
  expect(screen.getByRole('link', { name: /Account & security/ })).toHaveAttribute('href', '/account');
  fireEvent.click(screen.getByRole('button', { name: /Logout/ }));
  expect(await screen.findByRole('heading', { name: 'Sign in to Smart Solar' })).toBeInTheDocument();
  expect(localStorage.getItem('smartsolar_token')).toBeNull();
});
