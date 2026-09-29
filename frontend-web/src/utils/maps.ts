import { divIcon } from 'leaflet';

export const solarMapMarkerIcon = divIcon({
  className: 'solar-map-marker',
  html: '<span aria-hidden="true">●</span>',
  iconSize: [34, 34],
  iconAnchor: [17, 30],
});

export function externalDirectionsUrl(latitude?: number, longitude?: number, address?: string) {
  const destination = latitude != null && longitude != null ? `${latitude},${longitude}` : address || '';
  return `https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(destination)}`;
}
