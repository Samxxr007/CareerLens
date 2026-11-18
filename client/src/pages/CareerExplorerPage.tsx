import React, { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useProfileStore } from "../stores/useProfileStore";
import { fetchCareerMatches, fetchCareerDetail, fetchCareerComparison } from "../services/api";
import { MetricCard } from "../components/common/MetricCard";
import { StatusBadge } from "../components/common/StatusBadge";
import { Compass, GitCompare, ChevronRight, CheckCircle2, XCircle } from "lucide-react";

export const CareerExplorerPage: React.FC = () => {
  const { profile } = useProfileStore();
  const [selectedRole, setSelectedRole] = useState(profile.targetRole || "Data Analyst");
  const [activeTab, setActiveTab] = useState<"ranking" | "detail" | "compare">("ranking");

  // Comparison states
  const [compareA, setCompareA] = useState(profile.targetRole || "Data Analyst");
  const [compareB, setCompareB] = useState("Data Scientist");

  const { data: matches, isLoading: matchesLoading } = useQuery({
    queryKey: ["careerMatches", profile.skills],
    queryFn: () => fetchCareerMatches(profile.skills)
  });

  const { data: roleDetail, isLoading: detailLoading } = useQuery({
    queryKey: ["careerDetail", profile.skills, selectedRole, profile.experience],
    queryFn: () => fetchCareerDetail(profile.skills, selectedRole, profile.experience),
    enabled: !!selectedRole
  });

  const { data: comparison, isLoading: compareLoading } = useQuery({
    queryKey: ["careerComparison", profile.skills, compareA, compareB],
    queryFn: () => fetchCareerComparison(profile.skills, compareA, compareB),
    enabled: activeTab === "compare" && !!compareA && !!compareB
  });

  const unwrap = (val: any) => (Array.isArray(val) ? val[0] : val);

  const formatINR = (val?: any) => {
    const raw = unwrap(val);
    if (raw === undefined || raw === null || isNaN(Number(raw))) return "₹0";
    const n = Number(raw);
    if (n >= 100000) return `₹${(n / 100000).toFixed(2)} L`;
    return `₹${n.toLocaleString("en-IN")}`;
  };

  return (
    <div className="space-y-6">
      {/* Navigation Sub-Tabs */}
      <div className="flex border-b border-brand-border bg-white rounded-t-xl px-4 pt-3 gap-2">
        <button
          onClick={() => setActiveTab("ranking")}
          className={`flex items-center gap-2 pb-3 px-3 font-semibold text-sm border-b-2 transition-all ${
            activeTab === "ranking"
              ? "border-brand-blue text-brand-blue"
              : "border-transparent text-slate-500 hover:text-slate-800"
          }`}
        >
          <Compass className="w-4 h-4" />
          <span>Career Matches Shortlist</span>
        </button>
        <button
          onClick={() => setActiveTab("detail")}
          className={`flex items-center gap-2 pb-3 px-3 font-semibold text-sm border-b-2 transition-all ${
            activeTab === "detail"
              ? "border-brand-blue text-brand-blue"
              : "border-transparent text-slate-500 hover:text-slate-800"
          }`}
        >
          <span>Detailed Role Match ({selectedRole})</span>
        </button>
        <button
          onClick={() => setActiveTab("compare")}
          className={`flex items-center gap-2 pb-3 px-3 font-semibold text-sm border-b-2 transition-all ${
            activeTab === "compare"
              ? "border-brand-blue text-brand-blue"
              : "border-transparent text-slate-500 hover:text-slate-800"
          }`}
        >
          <GitCompare className="w-4 h-4" />
          <span>Side-by-Side Path Comparison</span>
        </button>
      </div>

      {/* TAB 1: RANKED CAREER SHORTLIST */}
      {activeTab === "ranking" && (
        <div className="space-y-4">
          <div className="p-4 bg-slate-50 border border-slate-200 rounded-lg text-xs text-slate-600 flex items-center justify-between">
            <div>
              <strong>Ranking Rule: </strong> Roles with ≥50 postings evaluated against your {profile.skills.length} skills. Ranked primarily by <strong>Posting Overlap (≥80%)</strong>, secondarily by <strong>Demand-Weighted Coverage</strong>.
            </div>
            <span className="text-slate-500 font-medium">Candidate: {profile.skills.join(", ")}</span>
          </div>

          {matchesLoading ? (
            <div className="bg-white p-12 text-center text-slate-400 rounded-xl border border-brand-border">
              Computing career fit scores from R...
            </div>
          ) : !matches || matches.length === 0 ? (
            <div className="bg-white p-8 text-center text-slate-400 rounded-xl border border-brand-border">
              No matching career roles found.
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {matches.map((m) => (
                <div
                  key={m.Job_Role}
                  className="bg-white border border-brand-border rounded-xl p-5 hover:border-brand-blue transition-all shadow-sm flex flex-col justify-between"
                >
                  <div>
                    <div className="flex items-start justify-between gap-2 mb-2">
                      <h4 className="font-bold text-navy-900 text-base leading-tight">{m.Job_Role}</h4>
                      <span className="text-xs bg-blue-50 text-brand-blue border border-blue-200 font-bold px-2 py-0.5 rounded">
                        {m.Posting_Count} postings
                      </span>
                    </div>

                    <div className="grid grid-cols-2 gap-2 my-3 p-3 bg-slate-50 rounded-lg text-xs">
                      <div>
                        <span className="text-slate-500 block text-[11px]">Overlap (≥80%)</span>
                        <strong className="text-sm font-bold text-brand-blue">{m.Posting_Overlap_80}%</strong>
                      </div>
                      <div>
                        <span className="text-slate-500 block text-[11px]">Weighted Coverage</span>
                        <strong className="text-sm font-bold text-slate-800">{m.Weighted_Coverage}%</strong>
                      </div>
                      <div>
                        <span className="text-slate-500 block text-[11px]">Distinct Coverage</span>
                        <span className="font-semibold text-slate-700">{m.Distinct_Coverage}%</span>
                      </div>
                      <div>
                        <span className="text-slate-500 block text-[11px]">Role Median</span>
                        <span className="font-semibold text-slate-700">{formatINR(m.Median_Salary)}</span>
                      </div>
                    </div>
                  </div>

                  <div className="pt-3 border-t border-slate-100 flex items-center justify-between">
                    <span className="text-xs text-slate-500">
                      {m.Matched_Count} matched • {m.Missing_Count} missing
                    </span>
                    <button
                      type="button"
                      onClick={() => {
                        setSelectedRole(m.Job_Role);
                        setActiveTab("detail");
                      }}
                      className="text-xs font-bold text-brand-blue hover:text-navy-900 flex items-center gap-1"
                    >
                      <span>Explore Fit</span>
                      <ChevronRight className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* TAB 2: DETAILED ROLE MATCH */}
      {activeTab === "detail" && (
        <div className="space-y-6">
          <div className="flex items-center justify-between bg-white p-4 rounded-xl border border-brand-border">
            <div className="flex items-center gap-3">
              <span className="text-sm font-bold text-navy-900">Select Role to Inspect:</span>
              <select
                value={selectedRole}
                onChange={(e) => setSelectedRole(e.target.value)}
                className="text-sm border border-brand-border rounded-lg px-3 py-1.5 bg-white font-semibold text-brand-blue focus:outline-none"
              >
                {matches?.map((m) => (
                  <option key={m.Job_Role} value={m.Job_Role}>
                    {m.Job_Role}
                  </option>
                ))}
              </select>
            </div>
            <span className="text-xs text-slate-500">
              Evaluated on {roleDetail?.n_postings || 0} recognized postings in dataset
            </span>
          </div>

          {detailLoading ? (
            <div className="bg-white p-12 text-center text-slate-400 rounded-xl border border-brand-border">
              Computing detailed role requirements...
            </div>
          ) : roleDetail ? (
            <>
              {/* Detailed Metrics */}
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <MetricCard
                  label="Distinct Skill Coverage"
                  value={`${roleDetail.skill_coverage}%`}
                  subtext={`${roleDetail.matched_skills.length} of ${roleDetail.matched_skills.length + roleDetail.missing_skills.length} role skills`}
                />
                <MetricCard
                  label="Demand-Weighted Coverage"
                  value={`${roleDetail.weighted_coverage}%`}
                  subtext="Weighted by role demand %"
                />
                <MetricCard
                  label="Posting Overlap (≥80%)"
                  value={`${roleDetail.overlap_ge_80}%`}
                  subtext={`≥50% overlap: ${roleDetail.overlap_ge_50}%`}
                />
                <MetricCard
                  label="Role Median Compensation"
                  value={formatINR(roleDetail.salary_context.median)}
                  subtext={`IQR: ${formatINR(roleDetail.salary_context.q1)} - ${formatINR(roleDetail.salary_context.q3)}`}
                />
              </div>

              {/* Skills Breakdown Table */}
              <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
                <div className="lg:col-span-8 bg-white p-5 rounded-xl border border-brand-border shadow-sm">
                  <h4 className="font-bold text-navy-900 text-sm mb-3">All Recognized Role Skills & Match Status</h4>
                  <div className="overflow-x-auto">
                    <table className="w-full text-left text-xs">
                      <thead>
                        <tr className="border-b border-slate-200 text-slate-500 font-semibold bg-slate-50">
                          <th className="py-2.5 px-3">Skill Name</th>
                          <th className="py-2.5 px-3">Category</th>
                          <th className="py-2.5 px-3">Your Status</th>
                          <th className="py-2.5 px-3">Role Postings</th>
                          <th className="py-2.5 px-3">Role Demand %</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100">
                        {roleDetail.skills_breakdown.map((item) => (
                          <tr key={item.skill} className="hover:bg-slate-50/50">
                            <td className="py-2.5 px-3 font-semibold text-slate-900">{item.skill}</td>
                            <td className="py-2.5 px-3 text-slate-500">{item.skill_category}</td>
                            <td className="py-2.5 px-3">
                              <StatusBadge status={item.status} />
                            </td>
                            <td className="py-2.5 px-3 text-slate-700">{item.postings_count}</td>
                            <td className="py-2.5 px-3 font-bold text-brand-blue">{item.demand_pct}%</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>

                {/* Compatibility Card */}
                <div className="lg:col-span-4 bg-white p-5 rounded-xl border border-brand-border shadow-sm space-y-4">
                  <h4 className="font-bold text-navy-900 text-sm border-b border-slate-100 pb-2">Experience & Compensation</h4>
                  <div className="space-y-3 text-xs text-slate-700">
                    <div>
                      <span className="text-slate-500 block mb-0.5">Experience Compatibility:</span>
                      <p>
                        Candidate has <strong>{profile.experience} years</strong> experience, qualifying for{" "}
                        <strong>{roleDetail.exp_compatibility.pct_qualified}%</strong> of postings for this role (role avg: {roleDetail.exp_compatibility.role_mean_exp} yrs).
                      </p>
                    </div>
                    <div className="pt-2 border-t border-slate-100">
                      <span className="text-slate-500 block mb-1">Observed Role Salary Percentiles:</span>
                      <ul className="space-y-1 text-slate-600">
                        <li>10th Percentile: <strong>{formatINR(roleDetail.salary_context.p10)}</strong></li>
                        <li>25th Percentile (Q1): <strong>{formatINR(roleDetail.salary_context.q1)}</strong></li>
                        <li>50th Percentile (Median): <strong>{formatINR(roleDetail.salary_context.median)}</strong></li>
                        <li>75th Percentile (Q3): <strong>{formatINR(roleDetail.salary_context.q3)}</strong></li>
                        <li>90th Percentile: <strong>{formatINR(roleDetail.salary_context.p90)}</strong></li>
                      </ul>
                    </div>
                  </div>
                </div>
              </div>
            </>
          ) : null}
        </div>
      )}

      {/* TAB 3: SIDE-BY-SIDE PATH COMPARISON */}
      {activeTab === "compare" && (
        <div className="space-y-6">
          <div className="bg-white p-5 rounded-xl border border-brand-border flex flex-wrap items-center justify-between gap-4">
            <div className="flex items-center gap-4">
              <div>
                <label className="text-xs font-bold text-slate-600 block mb-1">Career A</label>
                <select
                  value={compareA}
                  onChange={(e) => setCompareA(e.target.value)}
                  className="text-sm border border-brand-border rounded-lg px-3 py-1.5 bg-white font-semibold"
                >
                  {matches?.map((m) => (
                    <option key={m.Job_Role} value={m.Job_Role}>
                      {m.Job_Role}
                    </option>
                  ))}
                </select>
              </div>
              <span className="text-slate-400 font-bold self-end pb-2">vs</span>
              <div>
                <label className="text-xs font-bold text-slate-600 block mb-1">Career B</label>
                <select
                  value={compareB}
                  onChange={(e) => setCompareB(e.target.value)}
                  className="text-sm border border-brand-border rounded-lg px-3 py-1.5 bg-white font-semibold"
                >
                  {matches?.map((m) => (
                    <option key={m.Job_Role} value={m.Job_Role}>
                      {m.Job_Role}
                    </option>
                  ))}
                </select>
              </div>
            </div>
            <span className="text-xs text-slate-400">Discover transferable competencies across trajectories</span>
          </div>

          {compareA === compareB ? (
            <div className="p-4 bg-amber-50 border border-amber-200 text-amber-800 rounded-lg text-sm">
              Please choose two distinct roles to compare career trajectories.
            </div>
          ) : compareLoading ? (
            <div className="bg-white p-12 text-center text-slate-400 rounded-xl border border-brand-border">
              Computing comparative career trajectory statistics...
            </div>
          ) : Boolean(unwrap(comparison?.is_same_role)) ? (
            <div className="p-4 bg-amber-50 border border-amber-200 text-amber-800 rounded-lg text-sm">
              Please choose two distinct roles to compare career paths.
            </div>
          ) : comparison ? (
            <div className="space-y-6">
              {/* Comparison Cards */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="bg-white p-5 rounded-xl border border-brand-border shadow-sm">
                  <h4 className="font-bold text-navy-900 text-base mb-3 border-b pb-2">{unwrap(comparison.role_a)}</h4>
                  <div className="space-y-2 text-xs">
                    <div className="flex justify-between py-1 border-b border-slate-100">
                      <span className="text-slate-500">Postings Count</span>
                      <strong className="text-slate-900">{unwrap(comparison.postings_a)}</strong>
                    </div>
                    <div className="flex justify-between py-1 border-b border-slate-100">
                      <span className="text-slate-500">Median Salary</span>
                      <strong className="text-brand-blue">{formatINR(unwrap(comparison.salary_a?.median))}</strong>
                    </div>
                    <div className="flex justify-between py-1 border-b border-slate-100">
                      <span className="text-slate-500">Avg Required Experience</span>
                      <strong className="text-slate-900">{unwrap(comparison.exp_mean_a)} years</strong>
                    </div>
                    <div className="flex justify-between py-1 border-b border-slate-100">
                      <span className="text-slate-500">Your Distinct Coverage</span>
                      <strong className="text-emerald-700">{unwrap(comparison.fit_a?.skill_coverage)}%</strong>
                    </div>
                    <div className="flex justify-between py-1">
                      <span className="text-slate-500">Posting Overlap (≥80%)</span>
                      <strong className="text-brand-blue">{unwrap(comparison.fit_a?.overlap_ge_80)}%</strong>
                    </div>
                  </div>
                </div>

                <div className="bg-white p-5 rounded-xl border border-brand-border shadow-sm">
                  <h4 className="font-bold text-navy-900 text-base mb-3 border-b pb-2">{unwrap(comparison.role_b)}</h4>
                  <div className="space-y-2 text-xs">
                    <div className="flex justify-between py-1 border-b border-slate-100">
                      <span className="text-slate-500">Postings Count</span>
                      <strong className="text-slate-900">{unwrap(comparison.postings_b)}</strong>
                    </div>
                    <div className="flex justify-between py-1 border-b border-slate-100">
                      <span className="text-slate-500">Median Salary</span>
                      <strong className="text-brand-blue">{formatINR(unwrap(comparison.salary_b?.median))}</strong>
                    </div>
                    <div className="flex justify-between py-1 border-b border-slate-100">
                      <span className="text-slate-500">Avg Required Experience</span>
                      <strong className="text-slate-900">{unwrap(comparison.exp_mean_b)} years</strong>
                    </div>
                    <div className="flex justify-between py-1 border-b border-slate-100">
                      <span className="text-slate-500">Your Distinct Coverage</span>
                      <strong className="text-emerald-700">{unwrap(comparison.fit_b?.skill_coverage)}%</strong>
                    </div>
                    <div className="flex justify-between py-1">
                      <span className="text-slate-500">Posting Overlap (≥80%)</span>
                      <strong className="text-brand-blue">{unwrap(comparison.fit_b?.overlap_ge_80)}%</strong>
                    </div>
                  </div>
                </div>
              </div>

              {/* Shared Transferable Skills */}
              <div className="bg-white p-5 rounded-xl border border-brand-border shadow-sm">
                <h4 className="font-bold text-navy-900 text-sm mb-3">Shared Transferable Skills Across Both Roles</h4>
                <div className="flex flex-wrap gap-2">
                  {comparison.shared_skills?.map((s: string) => {
                    const isMatched = comparison.candidate_shared_matched?.includes(s);
                    return (
                      <span
                        key={s}
                        className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold border ${
                          isMatched
                            ? "bg-emerald-50 text-emerald-800 border-emerald-300"
                            : "bg-slate-100 text-slate-700 border-slate-200"
                        }`}
                      >
                        {isMatched ? <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" /> : <XCircle className="w-3.5 h-3.5 text-slate-400" />}
                        <span>{s}</span>
                      </span>
                    );
                  })}
                </div>
              </div>
            </div>
          ) : null}
        </div>
      )}
    </div>
  );
};
