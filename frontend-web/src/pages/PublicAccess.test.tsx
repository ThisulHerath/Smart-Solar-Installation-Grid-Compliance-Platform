import {
  afterEach,
  beforeEach,
  expect,
  it,
  vi,
} from 'vitest';
import {
  cleanup,
  fireEvent,
  render,
  screen,
} from '@testing-library/react';

import { App } from '../App';
import { api } from '../services/api';

vi.mock('../services/api', () => ({
  resolveAssetUrl: (value: string | null | undefined) => value ?? null,
  api: {
    getMe: vi.fn(),
    login: vi.fn(),
  },
}));

afterEach(cleanup);

beforeEach(() => {
  localStorage.clear();
  vi.clearAllMocks();
  window.history.replaceState({}, '', '/');
});

it(
  'opens a public landing page and sends guests to authentication for services',
  async () => {
    render(<App />);

    expect(
      await screen.findByRole('heading', {
        name: /Greening our future/,
      })
    ).toBeInTheDocument();

    fireEvent.click(
      screen.getByRole('link', {
        name: /Explore solar planning/,
      })
    );

    expect(
      await screen.findByRole('heading', {
        name: 'Create your account',
      })
    ).toBeInTheDocument();

    expect(
      screen.getByLabelText('Email address')
    ).toHaveValue('');

    expect(
      screen.getByLabelText('Password')
    ).toHaveValue('');
  }
);

it.each([
  '/dashboard',
  '/profile',
  '/account',
  '/inventory',
  '/surveys',
  '/proposals',
])('protects direct access to %s', async (path) => {
  window.history.replaceState({}, '', path);

  render(<App />);

  expect(
    await screen.findByRole('heading', {
      name: 'Welcome back',
    })
  ).toBeInTheDocument();
});

it('shows a direct dashboard link in the landing navigation for signed-in roles', async () => {
  localStorage.setItem('smartsolar_token', 'test-token');
  vi.mocked(api.getMe).mockResolvedValue({
    id: 'admin',
    fullName: 'System Administrator',
    email: 'admin@smartsolar.local',
    phoneNumber: '+94770000001',
    roles: ['ADMINISTRATOR'],
    createdAt: '2026-01-01T00:00:00Z',
  });

  render(<App />);

  expect(await screen.findByRole('link', { name: 'Dashboard' })).toHaveAttribute('href', '/dashboard');
  expect(screen.queryByRole('link', { name: 'Projects' })).not.toBeInTheDocument();

  fireEvent.click(screen.getByRole('button', { name: 'Logout' }));
  expect(screen.getByRole('dialog', { name: 'Are you sure you want to log out?' })).toBeInTheDocument();

  fireEvent.click(screen.getByRole('button', { name: 'Cancel' }));
  expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  expect(localStorage.getItem('smartsolar_token')).toBe('test-token');
});

it(
  'loads the signed-in profile and links to separate security settings',
  async () => {
    localStorage.setItem(
      'smartsolar_token',
      'test-token'
    );

    vi.mocked(api.getMe).mockResolvedValue({
      id: 'owner',
      fullName: 'Solar Owner',
      email: 'owner@example.com',
      phoneNumber: '+94770000000',
      roles: ['HOMEOWNER'],
      createdAt: '2026-01-01T00:00:00Z',
    });

    window.history.replaceState({}, '', '/profile');

    render(<App />);

    expect(
      await screen.findByRole('heading', {
        name: 'My profile',
      })
    ).toBeInTheDocument();

    expect(
      screen.getByText('+94770000000')
    ).toBeInTheDocument();

    expect(
      screen.getByRole('link', {
        name: /Account & security/,
      })
    ).toHaveAttribute('href', '/account');

    screen.getAllByRole('link', { name: 'Dashboard' }).forEach((dashboardLink) => {
      expect(dashboardLink).not.toHaveClass('is-active');
    });
    expect(screen.getByRole('link', { name: 'Open my profile' })).toHaveClass('is-active');

    fireEvent.click(
      screen.getByRole('button', {
        name: /Logout/,
      })
    );

    expect(
      screen.getByText(
        'Are you sure you want to log out?'
      )
    ).toBeInTheDocument();

    fireEvent.click(
      screen.getByRole('button', {
        name: 'Log out',
      })
    );

    expect(
      await screen.findByRole('heading', {
        name: 'Welcome back',
      })
    ).toBeInTheDocument();

    expect(
      localStorage.getItem('smartsolar_token')
    ).toBeNull();
  }
);
