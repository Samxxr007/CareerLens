export interface CandidateProfile {
  fullName?: string;
  targetRole: string;
  alternativeRole?: string;
  skills: string[];
  experience: number;
  education: string;
  location: string;
  industry?: string;
  employmentType?: string;
  workArrangement?: string;
}

export interface CareerMatchSummary {
  Job_Role: string;
  Posting_Count: number;
  Posting_Overlap_80: number;
  Weighted_Coverage: number;
  Distinct_Coverage: number;
  Overlap_50: number;
  Matched_Count: number;
  Missing_Count: number;
  Median_Salary: number;
}

export interface RoleSkillItem {
  skill: string;
  skill_category: string;
  postings_count: number;
  demand_pct: number;
  status: "Matched" | "Missing";
}

export interface RoleDetailResponse {
  target_role: string;
  n_postings: number;
  skill_coverage: number;
  weighted_coverage: number;
  overlap_ge_50: number;
  overlap_ge_80: number;
  overlap_eq_100: number;
  median_overlap: number;
  matched_skills: string[];
  missing_skills: string[];
  skills_breakdown: RoleSkillItem[];
  salary_context: {
    n: number;
    mean: number;
    median: number;
    q1: number;
    q3: number;
    p10: number;
    p90: number;
    iqr: number;
  };
  exp_compatibility: {
    candidate_exp: number;
    pct_qualified: number;
    role_mean_exp: number;
  };
  warning_msg?: string;
}

export interface RecommendationItem {
  skill: string;
  priority_category: "HIGH PRIORITY" | "MEDIUM PRIORITY" | "ADDITIONAL SKILL";
  priority_index: number;
  role_demand_pct: number;
  role_postings: number;
  market_demand_pct: number;
  cooccurring_skills: string;
  transferable_roles_count: number;
  narrative_explanation: string;
}

export interface SkillGapResponse {
  target_role: string;
  n_role: number;
  total_jobs: number;
  recommendations_tbl: RecommendationItem[];
  high_priority: string[];
  med_priority: string[];
  add_priority: string[];
}

export interface SimulationResponse {
  target_role: string;
  baseline_coverage: number;
  proposed_coverage: number;
  coverage_delta: number;
  baseline_weighted_cov: number;
  proposed_weighted_cov: number;
  weighted_coverage_delta: number;
  baseline_overlap: number;
  proposed_overlap: number;
  overlap_delta: number;
  baseline_overlap_50: number;
  proposed_overlap_50: number;
  baseline_overlap_100: number;
  proposed_overlap_100: number;
  baseline_matched_count: number;
  proposed_matched_count: number;
  newly_added_skills: string[];
  newly_removed_skills: string[];
  newly_matched_role_skills: string[];
  newly_satisfied_postings: number;
  remaining_missing_tbl: any[];
}

export interface JobDescriptionAnalysisResponse {
  has_skills: boolean;
  extracted_count: number;
  matched_skills: string[];
  missing_skills: string[];
  breakdown_tbl: {
    Skill: string;
    Category: string;
    Status: "Matched" | "Missing";
    "Role Demand %": number;
    "Market Demand %": number;
    "Priority Index": number;
    "Priority Level": string;
  }[];
  recommendations: string[];
  disclaimer: string;
}

export interface SalaryPredictionResponse {
  prediction: {
    extrap_warn: string | null;
    slr_estimate: number;
    slr_lwr: number;
    slr_upr: number;
    mlr_estimate: number;
    mlr_lwr: number;
    mlr_upr: number;
    high_sal_prob: number;
    high_sal_label: string;
  };
  slr_summary: {
    equation: string;
    train_r2: number;
    test_r2: number;
    test_rmse: number;
    test_mae: number;
  };
  mlr_summary: {
    train_r2: number;
    adj_r2: number;
    test_r2: number;
    test_rmse: number;
    test_mae: number;
    f_stat: number;
  };
  logit_summary: {
    threshold: number;
    test_metrics: {
      accuracy: number;
      sensitivity: number;
      specificity: number;
      precision: number;
      f1_score: number;
    };
    test_cm: Record<string, Record<string, number>>;
    aic: number;
  };
}

export interface DataQualityResponse {
  summary: {
    raw_rows: number;
    raw_cols: number;
    clean_rows: number;
    clean_cols: number;
    duplicates_removed: number;
    total_missing_handled: number;
    missing_salaries_preserved: number;
    valid_salaries_analyzed: number;
  };
  missing_by_column: {
    column: string;
    missing_count: number;
    missing_pct: number;
  }[];
  preview: any[];
}

export interface ApiResponse<T> {
  success: boolean;
  data: T;
  meta: {
    source: string;
    generated_at: string;
    processing_time_ms: number;
  };
}
