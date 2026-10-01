import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { User } from '../types/auth';
import { api, resolveAssetUrl } from '../services/api';

interface AuthContextType {
  user: User | null;
  token: string | null;
  profilePhoto: string | null;
  isLoading: boolean;
  login: (token: string, user: User, remember?: boolean) => void;
  logout: () => void;
  setProfilePhoto: (photo: string | null) => void;
  hasRole: (role: string) => boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [token, setToken] = useState<string | null>(() =>
    localStorage.getItem('smartsolar_token') ??
    sessionStorage.getItem('smartsolar_token'),
  );
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [profilePhoto, setProfilePhotoState] = useState<string | null>(null);

  useEffect(() => {
    setProfilePhotoState(resolveAssetUrl(
      user?.profileImageUrl ?? (user ? localStorage.getItem(`smartsolar_profile_photo_${user.id}`) : null),
    ));
  }, [user?.id]);

  useEffect(() => {
    const initializeAuth = async () => {
      const storedToken =
        localStorage.getItem('smartsolar_token') ??
        sessionStorage.getItem('smartsolar_token');
      if (storedToken) {
        try {
          const currentUser = await api.getMe();
          setUser(currentUser);
          setToken(storedToken);
        } catch {
          localStorage.removeItem('smartsolar_token');
          setUser(null);
          setToken(null);
        }
      }
      setIsLoading(false);
    };

    initializeAuth();
  }, []);

  const login = (newToken: string, newUser: User, remember = true) => {
    localStorage.removeItem('smartsolar_token');
    sessionStorage.removeItem('smartsolar_token');
    (remember ? localStorage : sessionStorage).setItem(
      'smartsolar_token',
      newToken,
    );
    setToken(newToken);
    setUser(newUser);
  };

  const logout = () => {
    localStorage.removeItem('smartsolar_token');
    sessionStorage.removeItem('smartsolar_token');
    setToken(null);
    setUser(null);
  };

  const setProfilePhoto = (photo: string | null) => {
    if (!user) return;
    const key = `smartsolar_profile_photo_${user.id}`;
    const resolvedPhoto = resolveAssetUrl(photo);
    if (resolvedPhoto) localStorage.setItem(key, resolvedPhoto);
    else localStorage.removeItem(key);
    setProfilePhotoState(resolvedPhoto);
  };

  const hasRole = (role: string): boolean => {
    return !!user?.roles?.includes(role);
  };

  return (
    <AuthContext.Provider value={{ user, token, profilePhoto, isLoading, login, logout, setProfilePhoto, hasRole }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
