import { render, screen } from '@testing-library/react';
import { afterEach, expect, it, vi } from 'vitest';
import { PageErrorBoundary } from '../../components/PageErrorBoundary';

afterEach(() => vi.restoreAllMocks());

it('offers recovery without exposing the rendering exception', () => {
  vi.spyOn(console, 'error').mockImplementation(() => {});
  function BrokenPage(): never { throw new Error('private-token-value'); }
  render(<PageErrorBoundary><BrokenPage /></PageErrorBoundary>);
  expect(screen.getByRole('alert')).toHaveTextContent('This page could not open');
  expect(screen.getByRole('button', { name: 'Reload page' })).toBeVisible();
  expect(screen.getByRole('link', { name: 'Return home' })).toHaveAttribute('href', '/');
  expect(screen.queryByText(/private-token-value/)).not.toBeInTheDocument();
});
