import { create } from "zustand";
import type { CandidateProfile } from "../types";

interface ProfileState {
  profile: CandidateProfile;
  isUpdating: boolean;
  setProfile: (newProfile: Partial<CandidateProfile>) => void;
  addSkill: (skill: string) => void;
  removeSkill: (skill: string) => void;
  setTargetRole: (role: string) => void;
  setExperience: (years: number) => void;
  setEducation: (edu: string) => void;
  setLocation: (loc: string) => void;
  resetProfile: () => void;
}

const DEFAULT_PROFILE: CandidateProfile = {
  fullName: "Demo Candidate",
  targetRole: "Data Analyst",
  alternativeRole: "Data Scientist",
  skills: ["Python", "SQL", "Excel"],
  experience: 2,
  education: "B.Tech",
  location: "Bengaluru",
  industry: "Information Technology",
  employmentType: "Full-Time",
  workArrangement: "Hybrid"
};

const STORAGE_KEY = "careerlens_candidate_profile_v2";

const loadStoredProfile = (): CandidateProfile => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) {
      return { ...DEFAULT_PROFILE, ...JSON.parse(raw) };
    }
  } catch (e) {
    console.error("Failed to load profile from localStorage:", e);
  }
  return DEFAULT_PROFILE;
};

export const useProfileStore = create<ProfileState>((set, get) => ({
  profile: loadStoredProfile(),
  isUpdating: false,

  setProfile: (newProfile) => {
    const updated = { ...get().profile, ...newProfile };
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
    } catch (e) {}
    set({ profile: updated });
  },

  addSkill: (skill) => {
    const trimmed = skill.trim();
    if (!trimmed || get().profile.skills.includes(trimmed)) return;
    const updatedSkills = [...get().profile.skills, trimmed];
    const updated = { ...get().profile, skills: updatedSkills };
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
    } catch (e) {}
    set({ profile: updated });
  },

  removeSkill: (skillToRemove) => {
    const updatedSkills = get().profile.skills.filter((s) => s !== skillToRemove);
    const updated = { ...get().profile, skills: updatedSkills };
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
    } catch (e) {}
    set({ profile: updated });
  },

  setTargetRole: (role) => {
    const updated = { ...get().profile, targetRole: role };
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
    } catch (e) {}
    set({ profile: updated });
  },

  setExperience: (years) => {
    const updated = { ...get().profile, experience: years };
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
    } catch (e) {}
    set({ profile: updated });
  },

  setEducation: (edu) => {
    const updated = { ...get().profile, education: edu };
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
    } catch (e) {}
    set({ profile: updated });
  },

  setLocation: (loc) => {
    const updated = { ...get().profile, location: loc };
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
    } catch (e) {}
    set({ profile: updated });
  },

  resetProfile: () => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(DEFAULT_PROFILE));
    } catch (e) {}
    set({ profile: DEFAULT_PROFILE });
  }
}));
