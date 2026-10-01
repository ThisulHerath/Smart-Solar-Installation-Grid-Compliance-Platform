import { divIcon } from 'leaflet';

export const solarMapMarkerIcon = divIcon({
  className: 'solar-map-marker',
  html: '<span aria-hidden="true">●</span>',
  iconSize: [34, 34],
  iconAnchor: [17, 30],
});

type RouteOrigin = { latitude: number; longitude: number };

export function externalDirectionsUrl(latitude?: number, longitude?: number, address?: string, origin?: RouteOrigin) {
  const destination = latitude != null && longitude != null ? `${latitude},${longitude}` : address || '';
  let parameters = `api=1&destination=${encodeURIComponent(destination)}`;
  if (origin) {
    parameters += `&origin=${encodeURIComponent(`${origin.latitude},${origin.longitude}`)}`;
    parameters += '&travelmode=driving&dir_action=navigate';
  }
  return `https://www.google.com/maps/dir/?${parameters}`;
}
