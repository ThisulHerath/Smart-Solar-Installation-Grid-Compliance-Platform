import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { User } from '../types/auth';
import { api } from '../services/api';

interface AuthContextType {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  login: (token: string, user: User) => void;
  logout: () => void;
  hasRole: (role: string) => boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [token, setToken] = useState<string | null>(() => localStorage.getItem('smartsolar_token'));
  const [isLoading, setIsLoading] = useState<boolean>(true);

  useEffect(() => {
    const initializeAuth = async () => {
      const storedToken = localStorage.getItem('smartsolar_token');
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

  const login = (newToken: string, newUser: User) => {
    localStorage.setItem('smartsolar_token', newToken);
    setToken(newToken);
    setUser(newUser);
  };

  const logout = () => {
    localStorage.removeItem('smartsolar_token');
    setToken(null);
    setUser(null);
  };

  const hasRole = (role: string): boolean => {
    return !!user?.roles?.includes(role);
  };

  return (
    <AuthContext.Provider value={{ user, token, isLoading, login, logout, hasRole }}>
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
