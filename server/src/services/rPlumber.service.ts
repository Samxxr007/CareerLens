import axios, { AxiosInstance } from "axios";
import { config } from "../config/env.js";

class RPlumberService {
  private client: AxiosInstance;
  private cache: Map<string, { data: any; expiry: number }> = new Map();

  constructor() {
    this.client = axios.create({
      baseURL: config.rPlumberUrl,
      timeout: 10000,
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json"
      }
    });
  }

  async checkHealth(): Promise<any> {
    try {
      const res = await this.client.get("/health");
      return res.data;
    } catch (err: any) {
      return { status: "unreachable", error: err.message };
    }
  }

  async getMetadata(): Promise<any> {
    return this.getCachedOrFetch("/metadata", 60000, () => this.client.get("/metadata"));
  }

  async getMarketOverview(params?: { location?: string; role?: string; industry?: string }): Promise<any> {
    const key = `/market/overview?${new URLSearchParams(params as any).toString()}`;
    return this.getCachedOrFetch(key, 30000, () => this.client.get("/market/overview", { params }));
  }

  async getMarketSkills(params?: { top?: number; role?: string }): Promise<any> {
    const key = `/market/skills?${new URLSearchParams(params as any).toString()}`;
    return this.getCachedOrFetch(key, 30000, () => this.client.get("/market/skills", { params }));
  }

  async getMarketSalary(): Promise<any> {
    return this.getCachedOrFetch("/market/salary", 60000, () => this.client.get("/market/salary"));
  }

  async getMarketCorrelation(): Promise<any> {
    return this.getCachedOrFetch("/market/correlation", 60000, () => this.client.get("/market/correlation"));
  }

  async analyzeCareerMatches(payload: { skills: string[]; min_postings?: number }): Promise<any> {
    const res = await this.client.post("/analyze/career-matches", payload);
    return res.data;
  }

  async getCareerDetail(payload: { skills: string[]; role: string; experience?: number }): Promise<any> {
    const res = await this.client.post("/analyze/career-detail", payload);
    return res.data;
  }

  async compareCareers(payload: { skills: string[]; role_a: string; role_b: string }): Promise<any> {
    const res = await this.client.post("/analyze/career-comparison", payload);
    return res.data;
  }

  async analyzeSkillGap(payload: { skills: string[]; role: string }): Promise<any> {
    const res = await this.client.post("/analyze/skill-gap", payload);
    return res.data;
  }

  async simulateSkills(payload: { current_skills: string[]; proposed_skills: string[]; role: string }): Promise<any> {
    const res = await this.client.post("/simulate/skills", payload);
    return res.data;
  }

  async analyzeJobDescription(payload: { text: string; candidate_skills?: string[]; target_role?: string }): Promise<any> {
    const res = await this.client.post("/analyze/job-description", payload);
    return res.data;
  }

  async predictSalary(payload: { experience: number; skill_count: number; education: string; company_size: string; location_tier: string }): Promise<any> {
    const res = await this.client.post("/predict/salary", payload);
    return res.data;
  }

  async getDataQuality(): Promise<any> {
    return this.getCachedOrFetch("/data-quality", 60000, () => this.client.get("/data-quality"));
  }

  private async getCachedOrFetch(key: string, ttlMs: number, fetcher: () => Promise<any>): Promise<any> {
    const cached = this.cache.get(key);
    if (cached && cached.expiry > Date.now()) {
      return cached.data;
    }
    const res = await fetcher();
    this.cache.set(key, { data: res.data, expiry: Date.now() + ttlMs });
    return res.data;
  }
}

export const rPlumberService = new RPlumberService();
