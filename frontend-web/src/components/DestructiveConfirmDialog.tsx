import { useEffect, useId, useRef, type ReactNode } from 'react';
import { createPortal } from 'react-dom';

import '../styles/destructive-confirm-dialog.css';

interface DestructiveConfirmDialogProps {
  open: boolean;
  title: string;
  subject?: ReactNode;
  children: ReactNode;
  confirmLabel: string;
  pendingLabel?: string;
  pending?: boolean;
  error?: string;
  onCancel: () => void;
  onConfirm: () => void;
}

export function DestructiveConfirmDialog({
  open,
  title,
  subject,
  children,
  confirmLabel,
  pendingLabel = 'Working...',
  pending = false,
  error,
  onCancel,
  onConfirm,
}: DestructiveConfirmDialogProps) {
  const titleId = useId();
  const descriptionId = useId();
  const cancelButton = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (!open) return;

    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape' && !pending) onCancel();
    };

    window.addEventListener('keydown', closeOnEscape);
    cancelButton.current?.focus();
    return () => window.removeEventListener('keydown', closeOnEscape);
  }, [open, pending, onCancel]);

  if (!open) return null;

  return createPortal(
    <div
      className="destructive-dialog-backdrop"
      role="presentation"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget && !pending) onCancel();
      }}
    >
      <section
        className="destructive-dialog-card"
        role="alertdialog"
        aria-modal="true"
        aria-labelledby={titleId}
        aria-describedby={descriptionId}
      >
        <h2 id={titleId}>{title}</h2>
        {subject && <div className="destructive-dialog-subject">{subject}</div>}
        <div className="destructive-dialog-description" id={descriptionId}>
          {children}
        </div>
        {error && (
          <p className="destructive-dialog-error" role="alert">
            {error}
          </p>
        )}
        <div className="destructive-dialog-actions">
          <button
            ref={cancelButton}
            type="button"
            className="destructive-dialog-cancel"
            disabled={pending}
            onClick={onCancel}
          >
            Cancel
          </button>
          <button
            type="button"
            className="destructive-dialog-confirm"
            disabled={pending}
            onClick={onConfirm}
          >
            {pending ? pendingLabel : confirmLabel}
          </button>
        </div>
      </section>
    </div>,
    document.body,
  );
}
