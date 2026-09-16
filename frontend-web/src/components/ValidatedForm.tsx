import { FormHTMLAttributes, useId, useRef } from 'react';
import './interaction.css';
type Field = HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement;
// Delegate native constraints so every business form shares the same feedback timing.
export function ValidatedForm(props: FormHTMLAttributes<HTMLFormElement>) {
  const failed = useRef(new WeakSet<Field>()), prefix = useId();
  function validate(field: Field) {
    if (!field.willValidate) return;
    field.setCustomValidity(field.required && !field.value.trim() ? 'Please complete this field.' : '');
    if (!field.id) field.id = `${prefix}-${Array.from(field.form?.elements || []).indexOf(field)}`;
    const id = `${field.id}-validation`;
    let message = document.getElementById(id);
    if (!message) { message = document.createElement('span'); message.id = id; message.className = 'field-message field-message-error'; message.setAttribute('aria-live', 'polite'); (field.closest('label') || field).insertAdjacentElement('afterend', message); }
    const invalid = !field.validity.valid;
    if (invalid) failed.current.add(field);
    field.setAttribute('aria-invalid', String(invalid));
    field.setAttribute('aria-describedby', [...new Set([...(field.getAttribute('aria-describedby') || '').split(' ').filter(Boolean), id])].join(' '));
    message.textContent = invalid ? `⚠ ${field.validationMessage}` : '';
  }
  const isField = (target: EventTarget): target is Field => target instanceof HTMLInputElement || target instanceof HTMLSelectElement || target instanceof HTMLTextAreaElement;
  return <form {...props} noValidate onBlurCapture={e => { if (isField(e.target)) validate(e.target); }} onChangeCapture={e => { if (isField(e.target) && failed.current.has(e.target)) validate(e.target); }} onSubmitCapture={e => {
    const fields = Array.from(e.currentTarget.elements).filter((f): f is Field => isField(f));
    fields.forEach(validate);
    const invalid = fields.find(f => f.willValidate && !f.validity.valid);
    if (invalid) { e.preventDefault(); e.stopPropagation(); invalid.scrollIntoView?.({ block: 'center', behavior: 'smooth' }); invalid.focus({ preventScroll: true }); }
  }} />;
}
