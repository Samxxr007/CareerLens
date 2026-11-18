import { create } from "zustand";

export interface User {
  id: string;
  name: string;
  email: string;
  avatar?: string;
  headline?: string;
  isGuest?: boolean;
}

interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
  hasCompletedOnboarding: boolean;
  isAuthModalOpen: boolean;
  isOnboardingModalOpen: boolean;
  login: (name: string, email: string) => void;
  loginAsGuest: () => void;
  logout: () => void;
  setCompletedOnboarding: (val: boolean) => void;
  openAuthModal: () => void;
  closeAuthModal: () => void;
  openOnboardingModal: () => void;
  closeOnboardingModal: () => void;
}

const STORAGE_AUTH_KEY = "careerlens_auth_v2";
const STORAGE_ONBOARDING_KEY = "careerlens_onboarded_v2";

const loadInitialUser = (): User | null => {
  try {
    const raw = localStorage.getItem(STORAGE_AUTH_KEY);
    if (raw) return JSON.parse(raw);
  } catch (e) {
    console.error("Error loading user session:", e);
  }
  // Default demo user so everything is pre-warmed for immediate evaluation
  return {
    id: "usr_demo",
    name: "Alex Morgan",
    email: "alex.morgan@careerlens.io",
    headline: "Aspiring Data Professional",
    isGuest: false
  };
};

const loadInitialOnboarded = (): boolean => {
  try {
    const raw = localStorage.getItem(STORAGE_ONBOARDING_KEY);
    return raw ? JSON.parse(raw) : false;
  } catch (e) {
    return false;
  }
};

export const useAuthStore = create<AuthState>((set) => ({
  user: loadInitialUser(),
  isAuthenticated: true,
  hasCompletedOnboarding: loadInitialOnboarded(),
  isAuthModalOpen: false,
  isOnboardingModalOpen: false,

  login: (name: string, email: string) => {
    const newUser: User = {
      id: "usr_" + Date.now().toString(36),
      name,
      email,
      headline: "Career Strategist",
      isGuest: false
    };
    try {
      localStorage.setItem(STORAGE_AUTH_KEY, JSON.stringify(newUser));
    } catch (e) {}
    set((state) => ({
      user: newUser,
      isAuthenticated: true,
      isAuthModalOpen: false,
      isOnboardingModalOpen: !state.hasCompletedOnboarding
    }));
  },

  loginAsGuest: () => {
    const guestUser: User = {
      id: "usr_guest",
      name: "Guest Explorer",
      email: "guest@careerlens.io",
      headline: "Exploring Tech Career Paths",
      isGuest: true
    };
    try {
      localStorage.setItem(STORAGE_AUTH_KEY, JSON.stringify(guestUser));
    } catch (e) {}
    set((state) => ({
      user: guestUser,
      isAuthenticated: true,
      isAuthModalOpen: false,
      isOnboardingModalOpen: !state.hasCompletedOnboarding
    }));
  },

  logout: () => {
    try {
      localStorage.removeItem(STORAGE_AUTH_KEY);
      localStorage.removeItem(STORAGE_ONBOARDING_KEY);
    } catch (e) {}
    set({
      user: null,
      isAuthenticated: false,
      isAuthModalOpen: true,
      hasCompletedOnboarding: false
    });
  },

  setCompletedOnboarding: (val: boolean) => {
    try {
      localStorage.setItem(STORAGE_ONBOARDING_KEY, JSON.stringify(val));
    } catch (e) {}
    set({ hasCompletedOnboarding: val, isOnboardingModalOpen: false });
  },

  openAuthModal: () => set({ isAuthModalOpen: true }),
  closeAuthModal: () => set({ isAuthModalOpen: false }),
  openOnboardingModal: () => set({ isOnboardingModalOpen: true }),
  closeOnboardingModal: () => set({ isOnboardingModalOpen: false })
}));
