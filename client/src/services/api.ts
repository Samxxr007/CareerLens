import axios from "axios";
import type {
  ApiResponse,
  CareerMatchSummary,
  RoleDetailResponse,
  SkillGapResponse,
  SimulationResponse,
  JobDescriptionAnalysisResponse,
  SalaryPredictionResponse,
  DataQualityResponse
} from "../types";

export const api = axios.create({
  baseURL: "/api",
  headers: {
    "Content-Type": "application/json"
  }
});

export const fetchMetadata = async () => {
  const res = await api.get<ApiResponse<any>>("/metadata");
  return res.data.data;
};

export const fetchMarketOverview = async (params?: { location?: string; role?: string; industry?: string }) => {
  const res = await api.get<ApiResponse<any>>("/market/overview", { params });
  return res.data.data;
};

export const fetchMarketSkills = async (params?: { top?: number; role?: string }) => {
  const res = await api.get<ApiResponse<any>>("/market/skills", { params });
  return res.data.data;
};

export const fetchMarketSalary = async () => {
  const res = await api.get<ApiResponse<any>>("/market/salary");
  return res.data.data;
};

export const fetchMarketCorrelation = async () => {
  const res = await api.get<ApiResponse<any>>("/market/correlation");
  return res.data.data;
};

export const fetchCareerMatches = async (skills: string[], minPostings = 50) => {
  const res = await api.post<ApiResponse<CareerMatchSummary[]>>("/career/matches", {
    skills,
    min_postings: minPostings
  });
  return res.data.data;
};

export const fetchCareerDetail = async (skills: string[], role: string, experience?: number) => {
  const res = await api.post<ApiResponse<RoleDetailResponse>>("/career/detail", {
    skills,
    role,
    experience
  });
  return res.data.data;
};

export const fetchCareerComparison = async (skills: string[], roleA: string, roleB: string) => {
  const res = await api.post<ApiResponse<any>>("/career/compare", {
    skills,
    role_a: roleA,
    role_b: roleB
  });
  return res.data.data;
};

export const fetchSkillGap = async (skills: string[], role: string) => {
  const res = await api.post<ApiResponse<SkillGapResponse>>("/skills/gap", {
    skills,
    role
  });
  return res.data.data;
};

export const fetchSkillsSimulation = async (currentSkills: string[], proposedSkills: string[], role: string) => {
  const res = await api.post<ApiResponse<SimulationResponse>>("/skills/simulate", {
    current_skills: currentSkills,
    proposed_skills: proposedSkills,
    role
  });
  return res.data.data;
};

export const fetchJobDescriptionAnalysis = async (text: string, candidateSkills: string[], targetRole: string) => {
  const res = await api.post<ApiResponse<JobDescriptionAnalysisResponse>>("/job-description/analyze", {
    text,
    candidate_skills: candidateSkills,
    target_role: targetRole
  });
  return res.data.data;
};

export const fetchSalaryPrediction = async (params: {
  experience: number;
  skill_count: number;
  education: string;
  company_size: string;
  location_tier: string;
}) => {
  const res = await api.post<ApiResponse<SalaryPredictionResponse>>("/salary/predict", params);
  return res.data.data;
};

export const fetchDataQuality = async () => {
  const res = await api.get<ApiResponse<DataQualityResponse>>("/data-quality");
  return res.data.data;
};

export const fetchAiRoadmap = async (payload: {
  target_role: string;
  current_skills: string[];
  missing_skills: string[];
  timeline_weeks?: number;
  focus_area?: string;
}) => {
  const res = await api.post<ApiResponse<any>>("/ai/roadmap", payload);
  return res.data.data;
};
