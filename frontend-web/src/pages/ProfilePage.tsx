import { ChangeEvent, useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  ArrowUpRight,
  Camera,
  Mail,
  Phone,
  ShieldCheck,
  Trash2,
  UserRound,
} from 'lucide-react';

import { useAuth } from '../context/AuthContext';
import { api } from '../services/api';
import '../styles/profile.css';

export function ProfilePage() {
  const { user, profilePhoto, setProfilePhoto } = useAuth();
  const photoInput = useRef<HTMLInputElement>(null);
  const [draftPhoto, setDraftPhoto] = useState<string | null>(null);
  const [draftFile, setDraftFile] = useState<File | null>(null);
  const [hasPhotoDraft, setHasPhotoDraft] = useState(false);
  const [photoError, setPhotoError] = useState('');
  const [savingPhoto, setSavingPhoto] = useState(false);

  useEffect(() => {
    setDraftPhoto(profilePhoto);
    setDraftFile(null);
    setHasPhotoDraft(false);
  }, [profilePhoto]);

  if (!user) {
    return null;
  }

  const photo = hasPhotoDraft ? draftPhoto : profilePhoto;

  const handlePhotoChange = (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    event.target.value = '';
    setPhotoError('');

    if (!file) return;
    if (!file.type.startsWith('image/')) {
      setPhotoError('Choose an image file to use as your profile photo.');
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      setPhotoError('Choose an image smaller than 5 MB.');
      return;
    }

    const reader = new FileReader();
    reader.onload = () => {
      const image = typeof reader.result === 'string' ? reader.result : null;
      if (!image) return;
      try {
        setDraftPhoto(image);
        setDraftFile(file);
        setHasPhotoDraft(true);
      } catch {
        setPhotoError('This image is too large to save in this browser.');
      }
    };
    reader.onerror = () => setPhotoError('Unable to read this image. Please try another one.');
    reader.readAsDataURL(file);
  };

  const removePhoto = () => {
    setDraftPhoto(null);
    setDraftFile(null);
    setHasPhotoDraft(true);
    setPhotoError('');
  };

  const savePhoto = async () => {
    setSavingPhoto(true);
    try {
      if (draftFile) {
        const result = await api.uploadProfileImage(draftFile);
        setProfilePhoto(result.profileImageUrl);
      } else {
        await api.deleteProfileImage();
        setProfilePhoto(null);
      }
      setHasPhotoDraft(false);
      setPhotoError('');
    } catch (err) {
      setPhotoError(err instanceof Error ? err.message : 'Unable to save your profile image.');
    } finally {
      setSavingPhoto(false);
    }
  };

  const initials = user.fullName
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((name) => name[0])
    .join('')
    .toUpperCase();

  const joined = new Date(user.createdAt);

  return (
    <div className="profile-page">
      <header>
        <p className="eyebrow">YOUR PERSONAL SPACE</p>

        <h1>My profile</h1>

        <p>
          Your details, your access, and your next step.
        </p>
      </header>

      <div className="profile-grid">
        <section className="glass-panel profile-identity">
          <div className="profile-photo-control">
            <div className="profile-avatar" aria-hidden="true">
              {photo ? <img src={photo} alt="" /> : initials || <UserRound />}
            </div>
            <button
              className="profile-photo-upload"
              type="button"
              aria-label="Choose profile photo"
              title="Choose profile photo"
              onClick={() => photoInput.current?.click()}
            >
              <Camera size={16} />
            </button>
            <input
              ref={photoInput}
              className="profile-photo-input"
              type="file"
              accept="image/png,image/jpeg,image/webp"
              onChange={handlePhotoChange}
            />
          </div>

          {photo && (
            <button className="profile-photo-remove" type="button" onClick={removePhoto}>
              <Trash2 size={14} /> Remove photo
            </button>
          )}

          {hasPhotoDraft && (
            <button className="btn btn-primary profile-photo-save" type="button" onClick={() => void savePhoto()} disabled={savingPhoto}>
              {savingPhoto ? 'Saving...' : 'Save changes'}
            </button>
          )}

          {photoError && <p className="profile-photo-error" role="alert">{photoError}</p>}

          <h2>{user.fullName}</h2>

          <p className="profile-email">
            {user.email}
          </p>

          <div className="profile-roles">
            {user.roles.map((role) => (
              <span
                className="badge badge-emerald"
                key={role}
              >
                {role.replace(/_/g, ' ')}
              </span>
            ))}
          </div>

          <Link
            className="btn btn-primary"
            to="/dashboard"
          >
            Open my workspace
            <ArrowUpRight size={17} />
          </Link>
        </section>

        <section className="glass-panel profile-info">
          <h2>Personal information</h2>

          <p>
            These are the details associated with your account.
          </p>

          <dl>
            <div>
              <dt>
                <UserRound size={16} />
                Full name
              </dt>

              <dd>{user.fullName}</dd>
            </div>

            <div>
              <dt>
                <Mail size={16} />
                Email address
              </dt>

              <dd>{user.email}</dd>
            </div>

            <div>
              <dt>
                <Phone size={16} />
                Phone number
              </dt>

              <dd>
                {user.phoneNumber || 'Not provided'}
              </dd>
            </div>

            <div>
              <dt>Member since</dt>

              <dd>
                {Number.isNaN(joined.getTime())
                  ? 'Not available'
                  : joined.toLocaleDateString('en-GB', {
                      day: 'numeric',
                      month: 'long',
                      year: 'numeric',
                    })}
              </dd>
            </div>
          </dl>

        </section>
      </div>

      <section className="glass-panel profile-security">
        <div className="profile-security-icon">
          <ShieldCheck size={28} />
        </div>

        <div>
          <h2>Keep your account protected</h2>

          <p>
            Manage your password and account access using email
            verification.
          </p>
        </div>

        <Link
          className="btn btn-secondary"
          to="/account"
        >
          Account &amp; security
          <ArrowUpRight size={17} />
        </Link>
      </section>
    </div>
  );
};
