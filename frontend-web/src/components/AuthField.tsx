import { FormHTMLAttributes, InputHTMLAttributes, useEffect, useRef, useState } from 'react';
import { Eye, EyeOff, CircleAlert, Check } from 'lucide-react';

type Props = InputHTMLAttributes<HTMLInputElement> & {
  label: string;
  hint?: string;
  matchValue?: string;
};

export function AuthField({ label, hint, matchValue, ...props }: Props) {
  const input = useRef<HTMLInputElement>(null);
  const [visible, setVisible] = useState(false);
  const [touched, setTouched] = useState(false);
  const value = String(props.value ?? '');
  const password = props.type === 'password';
  let error = '';
  if (props.required && !value.trim()) error = `Please enter ${label.toLowerCase().includes('confirm') ? 'your password again' : label.toLowerCase() === 'full name' ? 'your full name' : label.toLowerCase().includes('email') ? 'your email address' : 'your password'}.`;
  else if (props.type === 'email' && value && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim())) error = 'Enter a valid email, such as you@example.com.';
  else if (props.type === 'tel' && value.trim() && (!/^\+?[0-9().\s-]+$/.test(value.trim()) || value.replace(/\D/g, '').length < 7 || value.replace(/\D/g, '').length > 15)) error = 'Enter a phone number, such as +94 77 123 4567, or leave this blank.';
  else if (props.minLength && value.length < props.minLength) error = `Use at least ${props.minLength} characters for your password.`;
  else if (props.maxLength && value.length > props.maxLength) error = `Use no more than ${props.maxLength} characters.`;
  else if (password && props.minLength && new TextEncoder().encode(value).length > 72) error = 'This password is too long in bytes. Use fewer special characters.';
  else if (matchValue !== undefined && value !== matchValue) error = 'Your passwords do not match.';
  useEffect(() => { input.current?.setCustomValidity(error); }, [error]);
  const invalid = touched && !!error;
  const matching = matchValue !== undefined && value.length > 0 && !error;
  const messageId = `${props.id}-message`;
  return <div className={`account-form-field ${invalid ? 'field-invalid' : ''}`}>
    <label htmlFor={props.id}>{label}</label>
    <div className="auth-input-wrap">
      <input {...props} ref={input} className={`input-field ${password ? 'password-input' : ''}`} type={password && visible ? 'text' : props.type}
        aria-invalid={invalid} aria-describedby={invalid || hint || matching ? messageId : undefined}
        onInvalid={event => { event.preventDefault(); setTouched(true); }}
        onBlur={event => { setTouched(true); props.onBlur?.(event); }} />
      {password && <button className="password-toggle" type="button" aria-label={`${visible ? 'Hide' : 'Show'} ${label.toLowerCase()}`} aria-pressed={visible}
        aria-controls={props.id} disabled={props.disabled} onClick={() => setVisible(!visible)}>
        {visible ? <EyeOff size={18} aria-hidden="true" /> : <Eye size={18} aria-hidden="true" />}
      </button>}
    </div>
    <div id={messageId} className={`field-message ${invalid ? 'field-message-error' : matching ? 'field-message-success' : ''}`} aria-live="polite">
      {invalid ? <><CircleAlert size={14} aria-hidden="true" /><span>{error}</span></> : matching ? <><Check size={14} aria-hidden="true" /><span>Passwords match</span></> : hint ? <span>{hint}</span> : null}
    </div>
  </div>;
}

export function AuthForm(props: FormHTMLAttributes<HTMLFormElement>) {
  return <form {...props} noValidate onSubmitCapture={event => {
    if (!event.currentTarget.checkValidity()) {
      event.preventDefault(); event.stopPropagation();
      event.currentTarget.querySelector<HTMLElement>(':invalid')?.focus();
    }
  }} />;
}
