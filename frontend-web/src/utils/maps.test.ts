import { describe, expect, it } from 'vitest';
import { externalDirectionsUrl } from './maps';

describe('externalDirectionsUrl', () => {
  it('prefers exact survey coordinates for navigation', () => {
    const url = externalDirectionsUrl(6.9271, 79.8612, 'Fallback address');
    expect(url).toContain('destination=6.9271%2C79.8612');
    expect(url).not.toContain('Fallback');
  });

  it('uses the property address when an older survey has no coordinates', () => {
    const url = externalDirectionsUrl(undefined, undefined, '45 Park Road, Colombo');
    expect(url).toContain('destination=45%20Park%20Road%2C%20Colombo');
  });
});
