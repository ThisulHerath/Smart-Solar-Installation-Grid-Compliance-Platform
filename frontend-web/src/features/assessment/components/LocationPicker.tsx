import { useEffect, useState } from 'react';
import { Crosshair, LocateFixed, MapPin, Search, Trash2 } from 'lucide-react';
import { LatLngExpression } from 'leaflet';
import { MapContainer, Marker, TileLayer, useMap, useMapEvents } from 'react-leaflet';
import { api } from '../../../services/api';
import { LocationSearchResult } from '../../../types/auth';
import { solarMapMarkerIcon } from '../../../utils/maps';
import 'leaflet/dist/leaflet.css';
import '../../../styles/location-map.css';

export type SelectedLocation = { latitude: number; longitude: number };

const sriLankaCenter: LatLngExpression = [7.8731, 80.7718];
function MapController({ location, onChange }: { location?: SelectedLocation; onChange: (value: SelectedLocation) => void }) {
  const map = useMap();
  useMapEvents({
    click(event) {
      onChange({ latitude: event.latlng.lat, longitude: event.latlng.lng });
    },
  });
  useEffect(() => {
    if (location) map.setView([location.latitude, location.longitude], 16);
  }, [location, map]);
  return location ? (
    <Marker
      position={[location.latitude, location.longitude]}
      icon={solarMapMarkerIcon}
      draggable
      eventHandlers={{
        dragend(event) {
          const point = event.target.getLatLng();
          onChange({ latitude: point.lat, longitude: point.lng });
        },
      }}
    />
  ) : null;
}

interface LocationPickerProps {
  address: string;
  location?: SelectedLocation;
  disabled?: boolean;
  onAddressChange: (address: string) => void;
  onLocationChange: (location?: SelectedLocation) => void;
}

export function LocationPicker({ address, location, disabled, onAddressChange, onLocationChange }: LocationPickerProps) {
  const [expanded, setExpanded] = useState(false);
  const [results, setResults] = useState<LocationSearchResult[]>([]);
  const [searching, setSearching] = useState(false);
  const [message, setMessage] = useState('');

  const chooseResult = (result: LocationSearchResult) => {
    onAddressChange(result.displayName);
    onLocationChange({ latitude: result.latitude, longitude: result.longitude });
    setExpanded(true);
    setResults([]);
    setMessage('Location selected. Drag the marker if the rooftop position needs adjustment.');
  };

  const findAddress = async () => {
    if (address.trim().length < 3) {
      setMessage('Enter at least 3 characters in the property address first.');
      return;
    }
    setSearching(true);
    setMessage('');
    try {
      const matches = await api.searchLocations(address.trim());
      setResults(matches);
      if (!matches.length) setMessage('No matching address was found. Choose the location directly on the map.');
      else if (matches.length === 1) chooseResult(matches[0]);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Address search is unavailable. Choose the location on the map.');
    } finally {
      setSearching(false);
    }
  };

  const useCurrentLocation = () => {
    if (!navigator.geolocation) {
      setMessage('This browser does not provide location access. Choose the location on the map.');
      setExpanded(true);
      return;
    }
    setMessage('Requesting your current location…');
    navigator.geolocation.getCurrentPosition(
      position => {
        onLocationChange({ latitude: position.coords.latitude, longitude: position.coords.longitude });
        setExpanded(true);
        setMessage('Current location selected. Confirm that the marker is on your property.');
      },
      () => {
        setExpanded(true);
        setMessage('Location permission was not granted. You can still tap the map to place the marker.');
      },
      { enableHighAccuracy: true, timeout: 10000 }
    );
  };

  return (
    <section className="location-picker" aria-label="Property map location">
      <div className="location-picker__actions">
        <button type="button" onClick={() => void findAddress()} disabled={disabled || searching}><Search size={17} />{searching ? 'Finding…' : 'Find address on map'}</button>
        <button type="button" onClick={useCurrentLocation} disabled={disabled}><LocateFixed size={17} />Use my current location</button>
        <button type="button" onClick={() => setExpanded(value => !value)} disabled={disabled}><MapPin size={17} />{expanded ? 'Hide map' : 'Choose on map'}</button>
      </div>

      {results.length > 1 && <div className="location-picker__results" aria-label="Address matches">
        <strong>Select the correct address</strong>
        {results.map(result => <button type="button" key={`${result.latitude}-${result.longitude}`} onClick={() => chooseResult(result)}>{result.displayName}</button>)}
      </div>}

      {message && <p className="location-picker__message" role="status">{message}</p>}
      {location && <div className="location-picker__selected"><span><Crosshair size={17} />Location selected for technician navigation</span><button type="button" aria-label="Clear selected location" onClick={() => onLocationChange(undefined)} disabled={disabled}><Trash2 size={15} /> Clear</button></div>}

      {expanded && <div className="location-picker__map">
        <MapContainer center={location ? [location.latitude, location.longitude] : sriLankaCenter} zoom={location ? 16 : 8} scrollWheelZoom>
          <TileLayer attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap contributors</a>' url="https://tile.openstreetmap.org/{z}/{x}/{y}.png" />
          <MapController location={location} onChange={onLocationChange} />
        </MapContainer>
        <p>Tap the map or drag the marker to the exact rooftop location.</p>
      </div>}
    </section>
  );
}
