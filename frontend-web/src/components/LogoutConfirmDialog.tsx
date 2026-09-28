import { useEffect } from 'react';
import { LogOut } from 'lucide-react';
import '../styles/navigation.css';

interface LogoutConfirmDialogProps {
  onCancel: () => void;
  onConfirm: () => void;
}

export function LogoutConfirmDialog({ onCancel, onConfirm }: LogoutConfirmDialogProps) {
  useEffect(() => {
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onCancel();
    };

    window.addEventListener('keydown', closeOnEscape);
    return () => window.removeEventListener('keydown', closeOnEscape);
  }, [onCancel]);

  return (
    <div
      className="logout-modal-overlay"
      role="dialog"
      aria-modal="true"
      aria-labelledby="logout-dialog-title"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget) onCancel();
      }}
    >
      <div className="logout-modal-card">
        <div className="logout-modal-header">
          <div className="logout-modal-icon"><LogOut size={22} /></div>
          <div>
            <h3 id="logout-dialog-title">Are you sure you want to log out?</h3>
            <p>You will need to sign in again to access your solar projects, surveys, and workspace.</p>
          </div>
        </div>
        <div className="logout-modal-actions">
          <button type="button" className="btn btn-secondary" onClick={onCancel} autoFocus>Cancel</button>
          <button type="button" className="btn logout-confirm-button" onClick={onConfirm}>Log out</button>
        </div>
      </div>
    </div>
  );
}
