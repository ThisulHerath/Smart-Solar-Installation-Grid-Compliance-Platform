import { useEffect, useState } from 'react';
import { Expand, X } from 'lucide-react';

type Photo = { id: string; fieldJobId: string; technicianName: string; photoType: string; fileUrl: string; fileName: string; createdAt: string };
type PhotoPreview = { url: string; label: string; fileName: string };
const base = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5116';
const categories: Record<string, string> = { Roof: 'Roof', Meter: 'Electricity meter', ElectricalPanel: 'Electrical panel', InverterLocation: 'Inverter location', SafetyIssue: 'Safety concern', Other: 'Other evidence' };

export function InspectionPhotoGallery({ surveyId, jobId }: { surveyId?: string; jobId?: string }) {
  const [photos, setPhotos] = useState<Photo[]>([]), [loading, setLoading] = useState(true), [error, setError] = useState('');
  const [refresh, setRefresh] = useState(0), [unavailable, setUnavailable] = useState<string[]>([]);
  const [preview, setPreview] = useState<PhotoPreview | null>(null);
  useEffect(() => {
    let active = true;
    setLoading(true); setError(''); setPhotos([]); setUnavailable([]);
    const route = jobId ? `${encodeURIComponent(jobId)}/photos` : `surveys/${encodeURIComponent(surveyId || '')}/photos`;
    fetch(`${base}/api/field-jobs/${route}`, { headers: { Authorization: `Bearer ${localStorage.getItem('smartsolar_token')}` } })
      .then(async response => { if (!response.ok) throw new Error('Unable to load site photos. Please refresh or sign in again.'); return response.json(); })
      .then(data => { if (active) setPhotos(data); })
      .catch(e => { if (active) setError(e.message); })
      .finally(() => { if (active) setLoading(false); });
    return () => { active = false; };
  }, [surveyId, jobId, refresh]);

  useEffect(() => {
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') setPreview(null);
    };
    window.addEventListener('keydown', closeOnEscape);
    return () => window.removeEventListener('keydown', closeOnEscape);
  }, []);

  return <section className="detail-card detail-card--wide inspection-gallery" aria-label="Site inspection photos">
    <div className="inspection-gallery__heading"><div><h2>Site inspection photos</h2><p>Review the technician’s site evidence before making your proposal decision.</p></div>
      <button type="button" className="btn btn-secondary" disabled={loading} onClick={() => setRefresh(x => x + 1)}>Refresh photos</button></div>
    {loading ? <p role="status">Loading site photos…</p> : error ? <p role="alert">{error}</p> : !photos.length ?
      <p className="inspection-gallery__empty">No technician photos have been uploaded for this {jobId ? 'field job' : 'survey'} yet. Ask the technician to upload the site evidence, then refresh.</p> :
      <div className="inspection-gallery__grid">{photos.map(photo => {
        let url: URL | undefined;
        try { const candidate = new URL(photo.fileUrl, base); if (candidate.origin === new URL(base).origin && candidate.pathname.startsWith('/uploads/')) url = candidate; } catch { /* Invalid stored URLs are shown as unavailable. */ }
        const label = categories[photo.photoType] || 'Site evidence';
        return <figure key={photo.id} className="inspection-gallery__photo">
          {url && !unavailable.includes(photo.id) ? <button type="button" className="inspection-gallery__thumbnail" onClick={() => setPreview({ url: url.href, label, fileName: photo.fileName })} aria-label={`View ${label.toLowerCase()} photo in full size`}>
            <img src={url.href} alt={`${label} uploaded by ${photo.technicianName}`} loading="lazy" onError={() => setUnavailable(current => [...current, photo.id])} />
            <span><Expand size={18} /> View photo</span>
          </button> : <div className="inspection-gallery__unavailable">Photo unavailable. Ask the technician to upload it again.</div>}
          <figcaption><strong>{label}</strong><span>{photo.technicianName}</span><time dateTime={photo.createdAt}>{new Date(photo.createdAt).toLocaleString()}</time>
            <small>Job {photo.fieldJobId.slice(0, 8)} · {photo.fileName}</small>{url && !unavailable.includes(photo.id) && <a href={url.href} target="_blank" rel="noopener noreferrer">Open full-size photo ↗</a>}</figcaption>
        </figure>;
      })}</div>}
    {preview && <div className="inspection-photo-modal" role="dialog" aria-modal="true" aria-label={`${preview.label} photo preview`} onMouseDown={() => setPreview(null)}>
      <div className="inspection-photo-modal__content" onMouseDown={event => event.stopPropagation()}>
        <div className="inspection-photo-modal__header"><div><strong>{preview.label}</strong><small>{preview.fileName}</small></div><button type="button" onClick={() => setPreview(null)} aria-label="Close photo preview"><X size={20} /></button></div>
        <img src={preview.url} alt={preview.label} />
      </div>
    </div>}
  </section>;
}
