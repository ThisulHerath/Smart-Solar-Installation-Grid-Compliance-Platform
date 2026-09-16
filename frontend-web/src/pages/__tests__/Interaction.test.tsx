import { useState } from 'react';
import { fireEvent, render, screen } from '@testing-library/react';
import { beforeEach, expect, it, vi } from 'vitest';
import { SearchBox } from '../../components/SearchBox';
import { ValidatedForm } from '../../components/ValidatedForm';

beforeEach(() => localStorage.clear());
it('supports shortcuts, suggestion selection, recents and clearing', () => {
  function Demo() { const [value, setValue] = useState(''); return <SearchBox label="Search stock" scope="test" value={value} onChange={setValue} suggestions={['Panel 500 W', 'Panel 600 W']} />; }
  render(<Demo />);
  fireEvent.keyDown(window, { key: 'k', ctrlKey: true });
  const search = screen.getByRole('combobox');
  expect(search).toHaveFocus();
  fireEvent.change(search, { target: { value: 'Panel' } });
  fireEvent.keyDown(search, { key: 'ArrowDown' });
  fireEvent.keyDown(search, { key: 'Enter' });
  expect(search).toHaveValue('Panel 500 W');
  expect(JSON.parse(localStorage.getItem('smartsolar-search-test')!)).toEqual(['Panel 500 W']);
  fireEvent.click(screen.getByRole('button', { name: 'Clear search' }));
  expect(search).toHaveValue('');
  fireEvent.focus(search);
  expect(screen.getByRole('option')).toHaveTextContent('Panel 500 W');
  fireEvent.keyDown(search, { key: 'Escape' });
  expect(search).toHaveAttribute('aria-expanded', 'false');
});
it('validates on blur, clears failed errors while typing and focuses invalid submission', () => {
  const submit = vi.fn();
  render(<ValidatedForm onSubmit={e => { e.preventDefault(); submit(); }}><label>Email<input required type="email" /></label><button>Save</button></ValidatedForm>);
  const input = screen.getByLabelText('Email');
  fireEvent.change(input, { target: { value: 'bad' } });
  expect(input).not.toHaveAttribute('aria-invalid', 'true');
  fireEvent.blur(input);
  expect(input).toHaveAttribute('aria-invalid', 'true');
  expect(input).toHaveAttribute('aria-describedby');
  fireEvent.change(input, { target: { value: 'solar@example.com' } });
  expect(input).toHaveAttribute('aria-invalid', 'false');
  fireEvent.change(input, { target: { value: '' } });
  fireEvent.click(screen.getByText('Save'));
  expect(submit).not.toHaveBeenCalled();
  expect(input).toHaveFocus();
});
