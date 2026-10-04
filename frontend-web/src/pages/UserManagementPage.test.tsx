import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { UserManagementPage } from './UserManagementPage';

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  create: vi.fn(),
  updateStatus: vi.fn(),
  deleteUser: vi.fn(),
}));

vi.mock('../context/AuthContext', () => ({
  useAuth: () => ({ user: { id: 'current-admin' } }),
}));

vi.mock('../services/userManagementService', () => ({
  userManagementService: {
    list: mocks.list,
    create: mocks.create,
    updateStatus: mocks.updateStatus,
    delete: mocks.deleteUser,
  },
}));

const managedUser = {
  id: 'staff-1',
  fullName: 'Nimal Perera',
  email: 'nimal@smartsolar.lk',
  phoneNumber: '+94771234567',
  roles: ['SENIOR_ENGINEER'],
  isActive: true,
  emailVerified: false,
  mustChangePassword: true,
  createdAt: '2026-10-03T00:00:00Z',
};

describe('UserManagementPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.list.mockResolvedValue([managedUser]);
    mocks.create.mockResolvedValue(managedUser);
    mocks.deleteUser.mockResolvedValue(undefined);
  });

  it('shows consistent validation and creates a secured staff account', async () => {
    render(<UserManagementPage />);
    await screen.findByText('Nimal Perera');
    fireEvent.click(screen.getByRole('button', { name: 'Add team member' }));
    fireEvent.click(screen.getByRole('button', { name: 'Create staff account' }));
    expect(await screen.findByText(/Enter 2–100 letters/)).toBeVisible();
    expect(screen.getByLabelText(/Full name/)).toHaveFocus();

    fireEvent.change(screen.getByLabelText(/Full name/), { target: { value: 'Kasun Silva' } });
    fireEvent.change(screen.getByLabelText(/Email address/), { target: { value: 'KASUN@SMARTSOLAR.LK' } });
    const phoneInput = screen.getByLabelText(/Phone number/);
    fireEvent.change(phoneInput, { target: { value: '12345678901234567890' } });
    expect(phoneInput).toHaveValue('123456789012345');
    fireEvent.change(phoneInput, { target: { value: '+94 77 555 1234' } });
    fireEvent.change(screen.getByPlaceholderText('Create or generate a secure password'), { target: { value: 'TemporaryPass!123' } });
    fireEvent.click(screen.getByRole('button', { name: 'Create staff account' }));

    await waitFor(() => expect(mocks.create).toHaveBeenCalledWith(expect.objectContaining({
      fullName: 'Kasun Silva',
      email: 'kasun@smartsolar.lk',
      password: 'TemporaryPass!123',
      phoneNumber: '+94 77 555 1234',
      role: 'SENIOR_ENGINEER',
    })));
  });

  it('requires confirmation before deleting a staff account', async () => {
    render(<UserManagementPage />);
    await screen.findByText('Nimal Perera');
    fireEvent.click(screen.getByRole('button', { name: 'Delete Nimal Perera' }));
    expect(screen.getByRole('alertdialog', { name: 'Delete staff account?' })).toBeVisible();
    expect(mocks.deleteUser).not.toHaveBeenCalled();
    fireEvent.click(screen.getByRole('button', { name: 'Delete account' }));
    await waitFor(() => expect(mocks.deleteUser).toHaveBeenCalledWith('staff-1'));
  });
});
