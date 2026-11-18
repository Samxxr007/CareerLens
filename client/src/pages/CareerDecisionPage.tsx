import React from "react";
import { useQuery } from "@tanstack/react-query";
import { useProfileStore } from "../stores/useProfileStore";
import {
  fetchSkillGap,
  fetchCareerDetail,
  fetchSalaryPrediction
} from "../services/api";
import { MetricCard } from "../components/common/MetricCard";
import {
  CheckCircle2,
  Calendar,
  Download,
  Lightbulb,
  ExternalLink
} from "lucide-react";
import { Link } from "react-router-dom";

export const CareerDecisionPage: React.FC = () => {
  const { profile } = useProfileStore();

  const { data: gapData, isLoading: gapLoading } = useQuery({
    queryKey: ["skillGap", profile.skills, profile.targetRole],
    queryFn: () => fetchSkillGap(profile.skills, profile.targetRole)
  });

  const { data: detailData } = useQuery({
    queryKey: ["careerDetail", profile.skills, profile.targetRole, profile.experience],
    queryFn: () => fetchCareerDetail(profile.skills, profile.targetRole, profile.experience)
  });

  const { data: salaryData } = useQuery({
    queryKey: [
      "salaryPrediction",
      profile.experience,
      profile.skills.length,
      profile.education
    ],
    queryFn: () =>
      fetchSalaryPrediction({
        experience: profile.experience,
        skill_count: profile.skills.length,
        education: profile.education,
        company_size: "Large",
        location_tier: "Tier 1"
      })
  });

  const formatINR = (val?: any) => {
    const num = Array.isArray(val) ? val[0] : val;
    if (num === undefined || num === null || isNaN(Number(num))) return "₹0";
    const n = Number(num);
    if (n >= 100000) return `₹${(n / 100000).toFixed(2)} L`;
    return `₹${n.toLocaleString("en-IN")}`;
  };

  const highPrioritySkills = gapData?.recommendations_tbl?.filter(
    (r) => r.priority_category === "HIGH PRIORITY"
  ) || [];

  const medPrioritySkills = gapData?.recommendations_tbl?.filter(
    (r) => r.priority_category === "MEDIUM PRIORITY"
  ) || [];

  const addPrioritySkills = gapData?.recommendations_tbl?.filter(
    (r) => r.priority_category === "ADDITIONAL SKILL"
  ) || [];

  // Export Career Strategy Plan
  const handleExportStrategyReport = () => {
    const lines = [
      `# CareerLens 2.0 — Evidence-Backed Career Strategy & Learning Plan`,
      `Generated: ${new Date().toLocaleDateString()}`,
      `Target Role: ${profile.targetRole}`,
      `Candidate Experience: ${profile.experience} Years`,
      `Current Skills (${profile.skills.length}): ${profile.skills.join(", ")}`,
      ``,
      `## 1. Market Readiness Context`,
      `- Distinct Skill Coverage: ${detailData?.skill_coverage || 0}%`,
      `- High Overlap Postings (≥80% match): ${detailData?.overlap_ge_80 || 0}%`,
      `- Current Predicted Compensation (MLR): ${formatINR(salaryData?.prediction?.mlr_estimate)}`,
      ``,
      `## 2. 30-Day Sprint (Immediate Core Requirements)`,
      highPrioritySkills.length > 0
        ? highPrioritySkills
            .map(
              (s) =>
                `- ${s.skill} (Role Demand: ${s.role_demand_pct}%, Priority Index: ${s.priority_index})\n  ${s.narrative_explanation}`
            )
            .join("\n")
        : `- None! Core requirements already satisfied.`,
      ``,
      `## 3. 60-Day Expansion (High-Value Competencies)`,
      medPrioritySkills.length > 0
        ? medPrioritySkills
            .map(
              (s) =>
                `- ${s.skill} (Role Demand: ${s.role_demand_pct}%, Market Demand: ${s.market_demand_pct}%)\n  ${s.narrative_explanation}`
            )
            .join("\n")
        : `- None!`,
      ``,
      `## 4. 90-Day Specialization`,
      addPrioritySkills.length > 0
        ? addPrioritySkills.slice(0, 5).map((s) => `- ${s.skill}`).join("\n")
        : `- Repertoire fully complete.`,
      ``,
      `*Dataset Source: 6,000 Clean Indian Tech Postings (Synthetic Benchmark). Course: ITA04 Statistics.*`
    ];

    const blob = new Blob([lines.join("\n")], { type: "text/markdown;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = `careerlens_strategy_${profile.targetRole.replace(/\s+/g, "_")}.md`;
    document.body.appendChild(link);
    link.click();
    link.remove();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="bg-white p-5 rounded-xl border border-brand-border flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-sm">
        <div>
          <div className="flex items-center gap-2">
            <span className="w-6 h-6 rounded-md bg-navy-900 text-white flex items-center justify-center text-xs font-bold">
              9
            </span>
            <h2 className="text-xl font-bold text-navy-900 leading-none">
              Informed Career Decision Support
            </h2>
          </div>
          <p className="text-xs text-brand-textSecondary mt-1">
            Synthesizing candidate profile, market evidence, and regression models into an actionable, evidence-backed learning strategy for <strong className="text-brand-blue">{profile.targetRole}</strong>.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Link
            to="/what-if-lab"
            className="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg border border-brand-teal text-brand-teal text-xs font-semibold hover:bg-teal-50 transition-colors"
          >
            <span>Simulate in What-If Lab</span>
            <ExternalLink className="w-3.5 h-3.5" />
          </Link>
          <button
            onClick={handleExportStrategyReport}
            className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-lg bg-brand-blue text-white text-xs font-semibold hover:bg-navy-800 transition-colors shadow-sm"
          >
            <Download className="w-3.5 h-3.5" />
            <span>Download Strategy Plan</span>
          </button>
        </div>
      </div>

      {/* Readiness Summary Metrics */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard
          label="Target Role Readiness"
          value={`${detailData?.overlap_ge_80 || 0}%`}
          subtext="Postings with ≥80% match"
          trend={Number(detailData?.overlap_ge_80 || 0) >= 50 ? "positive" : "neutral"}
        />
        <MetricCard
          label="Skill Repertoire Coverage"
          value={`${detailData?.skill_coverage || 0}%`}
          subtext={`${detailData?.matched_skills?.length || 0} of ${(detailData?.matched_skills?.length || 0) + (detailData?.missing_skills?.length || 0)} skills`}
        />
        <MetricCard
          label="Unmet Skill Gaps"
          value={detailData?.missing_skills?.length || 0}
          subtext={`${highPrioritySkills.length} High Priority`}
          trend={highPrioritySkills.length === 0 ? "positive" : "negative"}
        />
        <MetricCard
          label="Predicted Baseline Comp"
          value={formatINR(salaryData?.prediction?.mlr_estimate)}
          subtext="Multiple regression estimate"
        />
      </div>

      {/* 30-60-90 DAY STRATEGIC LEARNING ROADMAP */}
      <div className="bg-white p-6 rounded-xl border border-brand-border shadow-sm space-y-6">
        <div className="border-b pb-3 flex items-center justify-between">
          <div>
            <h3 className="font-bold text-navy-900 text-base flex items-center gap-2">
              <Calendar className="w-5 h-5 text-brand-blue" />
              <span>Evidence-Backed 30-60-90 Day Learning Roadmap</span>
            </h3>
            <p className="text-xs text-brand-textSecondary mt-0.5">
              Prioritized by statistical impact on posting qualification and salary potential.
            </p>
          </div>
        </div>

        {gapLoading ? (
          <div className="py-12 text-center text-slate-400 text-sm">
            Generating optimal learning strategy from market evidence...
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {/* Phase 1: Days 1-30 */}
            <div className="bg-slate-50 p-5 rounded-xl border border-slate-200 flex flex-col justify-between space-y-4">
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="px-2.5 py-1 rounded bg-rose-100 text-rose-800 font-bold text-xs uppercase tracking-wider">
                    Phase 1: Days 1–30
                  </span>
                  <span className="text-[11px] font-semibold text-rose-700">Immediate Core</span>
                </div>
                <h4 className="font-bold text-navy-900 text-sm">
                  Close High-Priority Role Gaps
                </h4>
                <p className="text-xs text-slate-600 leading-relaxed">
                  Focus exclusively on essential competencies with <code>Priority Index ≥ 35%</code>. These appear most frequently in {profile.targetRole} postings.
                </p>

                <div className="space-y-2 pt-2">
                  {highPrioritySkills.length === 0 ? (
                    <div className="p-3 bg-emerald-50 rounded-lg text-emerald-800 text-xs font-semibold flex items-center gap-2">
                      <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                      <span>Zero high-priority gaps! You are core-ready.</span>
                    </div>
                  ) : (
                    highPrioritySkills.map((sk) => (
                      <div
                        key={sk.skill}
                        className="p-3 bg-white rounded-lg border border-slate-200 space-y-1 shadow-2xs"
                      >
                        <div className="flex items-center justify-between">
                          <span className="font-bold text-navy-900 text-xs">{sk.skill}</span>
                          <span className="text-[10px] font-bold text-brand-blue bg-blue-50 px-2 py-0.5 rounded">
                            {sk.role_demand_pct}% of jobs
                          </span>
                        </div>
                        <p className="text-[11px] text-slate-500 leading-tight">
                          {sk.cooccurring_skills ? `Frequently paired with ${sk.cooccurring_skills}` : sk.narrative_explanation}
                        </p>
                      </div>
                    ))
                  )}
                </div>
              </div>

              <div className="pt-3 border-t border-slate-200 text-[11px] text-slate-500">
                <strong>Goal:</strong> Elevate baseline qualification to cross the 50% overlap barrier.
              </div>
            </div>

            {/* Phase 2: Days 31-60 */}
            <div className="bg-slate-50 p-5 rounded-xl border border-slate-200 flex flex-col justify-between space-y-4">
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="px-2.5 py-1 rounded bg-amber-100 text-amber-800 font-bold text-xs uppercase tracking-wider">
                    Phase 2: Days 31–60
                  </span>
                  <span className="text-[11px] font-semibold text-amber-700">Differentiation</span>
                </div>
                <h4 className="font-bold text-navy-900 text-sm">
                  Acquire Medium-Priority Tools
                </h4>
                <p className="text-xs text-slate-600 leading-relaxed">
                  Competencies with <code>Priority Index 15%–35%</code>. They differentiate your profile against other applicants in shortlisted evaluations.
                </p>

                <div className="space-y-2 pt-2">
                  {medPrioritySkills.length === 0 ? (
                    <div className="p-3 bg-emerald-50 rounded-lg text-emerald-800 text-xs font-semibold flex items-center gap-2">
                      <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                      <span>No medium-priority gaps.</span>
                    </div>
                  ) : (
                    medPrioritySkills.slice(0, 3).map((sk) => (
                      <div
                        key={sk.skill}
                        className="p-3 bg-white rounded-lg border border-slate-200 space-y-1 shadow-2xs"
                      >
                        <div className="flex items-center justify-between">
                          <span className="font-bold text-navy-900 text-xs">{sk.skill}</span>
                          <span className="text-[10px] font-bold text-brand-teal bg-teal-50 px-2 py-0.5 rounded">
                            {sk.role_demand_pct}% demand
                          </span>
                        </div>
                        <p className="text-[11px] text-slate-500 leading-tight">
                          {sk.narrative_explanation}
                        </p>
                      </div>
                    ))
                  )}
                </div>
              </div>

              <div className="pt-3 border-t border-slate-200 text-[11px] text-slate-500">
                <strong>Goal:</strong> Achieve ≥80% posting overlap across the majority of market openings.
              </div>
            </div>

            {/* Phase 3: Days 61-90 */}
            <div className="bg-slate-50 p-5 rounded-xl border border-slate-200 flex flex-col justify-between space-y-4">
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="px-2.5 py-1 rounded bg-blue-100 text-brand-blue font-bold text-xs uppercase tracking-wider">
                    Phase 3: Days 61–90
                  </span>
                  <span className="text-[11px] font-semibold text-brand-blue">Cross-Functional</span>
                </div>
                <h4 className="font-bold text-navy-900 text-sm">
                  Cross-Role Portability & Depth
                </h4>
                <p className="text-xs text-slate-600 leading-relaxed">
                  Focus on versatile skills that transfer across adjacent roles (e.g. Data Science, Engineering) to maximize long-term career agility.
                </p>

                <div className="space-y-2 pt-2">
                  {addPrioritySkills.slice(0, 3).map((sk) => (
                    <div
                      key={sk.skill}
                      className="p-3 bg-white rounded-lg border border-slate-200 space-y-1 shadow-2xs"
                    >
                      <div className="flex items-center justify-between">
                        <span className="font-bold text-navy-900 text-xs">{sk.skill}</span>
                        <span className="text-[10px] font-medium text-slate-500">
                          {sk.market_demand_pct}% market-wide
                        </span>
                      </div>
                      <p className="text-[11px] text-slate-500 leading-tight">
                        Requested in {sk.transferable_roles_count || 1}+ other tech career tracks.
                      </p>
                    </div>
                  ))}
                </div>
              </div>

              <div className="pt-3 border-t border-slate-200 text-[11px] text-slate-500">
                <strong>Goal:</strong> Long-term promotion and compensation ceiling maximization.
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Decision Summary Card */}
      <div className="bg-gradient-to-r from-navy-900 to-navy-800 text-white p-6 rounded-xl shadow-md space-y-3">
        <div className="flex items-center gap-2">
          <Lightbulb className="w-5 h-5 text-amber-400" />
          <h3 className="font-bold text-base">Key Strategic Recommendation</h3>
        </div>
        <p className="text-xs text-slate-200 leading-relaxed max-w-4xl">
          Based on the 6,000 clean postings evaluated in R, your profile already possesses foundational capabilities in {profile.skills.slice(0, 3).join(", ")}. To maximize your career progression towards <strong>{profile.targetRole}</strong>, prioritize closing any Phase 1 gaps before branching into peripheral libraries. Use the <strong>What-If Scenario Lab</strong> to experiment with specific skill bundles and measure their exact statistical impact on compensation and posting overlap.
        </p>
      </div>
    </div>
  );
};
