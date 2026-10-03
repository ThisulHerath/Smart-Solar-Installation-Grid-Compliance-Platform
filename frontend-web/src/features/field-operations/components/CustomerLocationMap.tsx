import { useEffect, useMemo, useState } from 'react';
import { LatLngBoundsExpression } from 'leaflet';
import { MapContainer, Marker, Popup, TileLayer, useMap } from 'react-leaflet';
import { api } from '../../../services/api';
import { Survey } from '../../../types/auth';
import { externalDirectionsUrl, solarMapMarkerIcon } from '../../../utils/maps';
import 'leaflet/dist/leaflet.css';
import '../../../styles/location-map.css';

function FitLocations({ surveys }: { surveys: Survey[] }) {
  const map = useMap();
  useEffect(() => {
    const bounds = surveys.map(survey => [survey.latitude!, survey.longitude!] as [number, number]) as LatLngBoundsExpression;
    if (surveys.length === 1) map.setView([surveys[0].latitude!, surveys[0].longitude!], 15);
    else if (surveys.length > 1) map.fitBounds(bounds, { padding: [34, 34], maxZoom: 14 });
  }, [map, surveys]);
  return null;
}

export function CustomerLocationMap() {
  const [surveys, setSurveys] = useState<Survey[]>([]);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.getSurveys()
      .then(setSurveys)
      .catch(requestError => setError(requestError instanceof Error ? requestError.message : 'Unable to load customer locations.'))
      .finally(() => setLoading(false));
  }, []);

  const located = useMemo(() => surveys.filter(survey => Number.isFinite(survey.latitude) && Number.isFinite(survey.longitude)), [surveys]);

  return <section className="customer-location-panel">
    <header><div><h2>Customer installation locations</h2><p>Authorized survey locations for planning and field coordination.</p></div><span>{located.length} mapped</span></header>
    {loading ? <p role="status">Loading customer locations…</p> : error ? <p role="alert">{error}</p> : located.length === 0 ? <p>No surveys have a confirmed map location yet.</p> : <div className="customer-location-panel__map">
      <MapContainer center={[7.8731, 80.7718]} zoom={8} scrollWheelZoom>
        <TileLayer attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap contributors</a>' url="https://tile.openstreetmap.org/{z}/{x}/{y}.png" />
        <FitLocations surveys={located} />
        {located.map(survey => <Marker key={survey.id} position={[survey.latitude!, survey.longitude!]} icon={solarMapMarkerIcon}>
          <Popup><div className="customer-map-popup"><strong>{survey.projectName || survey.propertyAddress}</strong><span>{survey.customerName || 'Solar customer'}</span><span>{survey.propertyAddress}</span><span>Status: {survey.surveyStatus}</span><code>Survey: {survey.id}</code><a href={externalDirectionsUrl(survey.latitude!, survey.longitude!)} target="_blank" rel="noreferrer">Open directions</a></div></Popup>
        </Marker>)}
      </MapContainer>
    </div>}
  </section>;
}
