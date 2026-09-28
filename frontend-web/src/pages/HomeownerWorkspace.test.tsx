import { afterEach, expect, it, vi } from 'vitest';
import {
  cleanup,
  fireEvent,
  render,
  screen,
  waitFor,
} from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';

import { HomeownerWorkspace } from './HomeownerWorkspace';
import { api } from '../services/api';

vi.mock('../services/api', () => ({
  api: {
    getSurveys: vi.fn(),
  },
}));

afterEach(() => {
  cleanup();
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});

it('lets a homeowner create a draft with their actual survey inputs', async () => {
  vi.mocked(api.getSurveys).mockResolvedValue([]);

  const fetchMock = vi.fn().mockResolvedValue({
    ok: true,
    json: async () => ({
      id: 'survey',
    }),
  });

  vi.stubGlobal('fetch', fetchMock);

  render(
    <MemoryRouter>
      <HomeownerWorkspace />
    </MemoryRouter>
  );

  await screen.findByText('Your solar journey starts here');

  fireEvent.click(
    screen.getByRole('button', {
      name: 'Start a solar assessment',
    })
  );

  fireEvent.change(screen.getByLabelText('Property address'), {
    target: {
      value: 'Test roof, Colombo',
    },
  });

  fireEvent.change(
    screen.getByLabelText('Monthly electricity use (kWh)'),
    {
      target: {
        value: '600',
      },
    }
  );

  fireEvent.change(
    screen.getByLabelText('Available roof area (m²)'),
    {
      target: {
        value: '80',
      },
    }
  );

  fireEvent.click(
    screen.getByRole('button', {
      name: 'Save assessment draft',
    })
  );

  await waitFor(() => {
    expect(fetchMock).toHaveBeenCalled();
  });

  expect(
    JSON.parse(fetchMock.mock.calls[0][1].body)
  ).toMatchObject({
    monthlyKwh: 600,
    roofAreaSqm: 80,
    gridType: 'SinglePhase',
    propertyAddress: 'Test roof, Colombo',
  });
});

it('shows an actionable error when project loading fails', async () => {
  vi.mocked(api.getSurveys).mockRejectedValue(
    new Error('Unable to load surveys')
  );

  render(
    <MemoryRouter>
      <HomeownerWorkspace />
    </MemoryRouter>
  );

  expect(
    await screen.findByRole('alert')
  ).toHaveTextContent('Unable to load surveys');
})