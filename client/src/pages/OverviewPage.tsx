import React from "react";
import { useQuery } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { useProfileStore } from "../stores/useProfileStore";
import { fetchCareerMatches, fetchSkillGap, fetchMarketOverview } from "../services/api";
import { MetricCard } from "../components/common/MetricCard";
import { StatusBadge } from "../components/common/StatusBadge";
import ReactECharts from "echarts-for-react";
import { ArrowRight, Compass, Sparkles, TrendingUp, AlertCircle } from "lucide-react";

export const OverviewPage: React.FC = () => {
  const { profile } = useProfileStore();

  const { data: matches, isLoading: matchesLoading } = useQuery({
    queryKey: ["careerMatches", profile.skills],
    queryFn: () => fetchCareerMatches(profile.skills)
  });

  const { data: gaps, isLoading: gapsLoading } = useQuery({
    queryKey: ["skillGap", profile.skills, profile.targetRole],
    queryFn: () => fetchSkillGap(profile.skills, profile.targetRole)
  });

  const { data: market, isLoading: marketLoading } = useQuery({
    queryKey: ["marketOverview"],
    queryFn: () => fetchMarketOverview()
  });

  // Top matches
  const topMatches = matches ? matches.slice(0, 3) : [];
  const topGaps = gaps?.recommendations_tbl ? gaps.recommendations_tbl.slice(0, 5) : [];

  // Match for target role
  const targetMatch = matches?.find((m) => m.Job_Role === profile.targetRole);

  const unwrap = (val: any) => (Array.isArray(val) ? val[0] : val);

  const formatINR = (val?: any) => {
    const raw = unwrap(val);
    if (raw === undefined || raw === null || isNaN(Number(raw))) return "₹0";
    const n = Number(raw);
    if (n >= 100000) return `₹${(n / 100000).toFixed(2)} L`;
    return `₹${n.toLocaleString("en-IN")}`;
  };

  // ECharts Option for Top Roles
  const rolesChartOption = {
    tooltip: { trigger: "axis" },
    grid: { left: "3%", right: "4%", bottom: "3%", top: "8%", containLabel: true },
    xAxis: { type: "value", boundaryGap: [0, 0.01] },
    yAxis: {
      type: "category",
      data: market?.top_roles?.slice(0, 6).map((r: any) => r.job_title).reverse() || [],
      axisLabel: { fontSize: 11 }
    },
    series: [
      {
        name: "Postings",
        type: "bar",
        data: market?.top_roles?.slice(0, 6).map((r: any) => r.count).reverse() || [],
        itemStyle: { color: "#1E6091", borderRadius: [0, 4, 4, 0] }
      }
    ]
  };

  return (
    <div className="space-y-6">
      {/* Hero Banner */}
      <div className="bg-gradient-to-r from-navy-900 to-navy-800 text-white rounded-xl p-6 shadow-sm flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div>
          <span className="inline-block bg-brand-blue text-white text-[11px] font-semibold px-2.5 py-0.5 rounded-full mb-2 uppercase tracking-wider">
            ITA04 Capstone Intelligence
          </span>
          <h2 className="text-2xl font-bold tracking-tight">Welcome back. Let's understand where you stand.</h2>
          <p className="text-slate-300 text-sm mt-1 max-w-2xl">
            Target role: <strong className="text-white">{profile.targetRole}</strong> • Profile has{" "}
            <strong className="text-white">{profile.skills.length} skills</strong> recorded across{" "}
            <strong className="text-white">{profile.experience} years</strong> experience.
          </p>
        </div>
        <Link
          to="/profile"
          className="bg-brand-teal hover:bg-emerald-600 text-white font-semibold text-sm px-4 py-2.5 rounded-lg transition-all flex items-center gap-2 shrink-0 shadow-sm"
        >
          <span>Edit Candidate Profile</span>
          <ArrowRight className="w-4 h-4" />
        </Link>
      </div>

      {/* KPI Cards Row */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard
          label="Target Role Coverage"
          value={targetMatch ? `${targetMatch.Distinct_Coverage}%` : "—"}
          subtext={`Weighted: ${targetMatch ? targetMatch.Weighted_Coverage : 0}%`}
          trend={targetMatch && targetMatch.Distinct_Coverage >= 50 ? "positive" : "neutral"}
        />
        <MetricCard
          label="Posting Overlap (>=80%)"
          value={targetMatch ? `${targetMatch.Posting_Overlap_80}%` : "—"}
          subtext="Postings with 80%+ skills matched"
        />
        <MetricCard
          label="High Priority Gaps"
          value={gaps?.high_priority?.length || 0}
          subtext="Priority index >= 35%"
          trend={gaps?.high_priority?.length ? "negative" : "positive"}
        />
        <MetricCard
          label="Target Role Median"
          value={formatINR(targetMatch?.Median_Salary)}
          subtext="Annual INR Benchmark"
        />
      </div>

      {/* Main Two-Column Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Left Column: Career Match Snapshot */}
        <div className="lg:col-span-7 space-y-6">
          <div className="bg-white border border-brand-border rounded-xl p-5 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <Compass className="w-5 h-5 text-brand-blue" />
                <h3 className="font-bold text-navy-900">Career Match Snapshot</h3>
              </div>
              <Link to="/career-explorer" className="text-xs font-semibold text-brand-blue hover:underline flex items-center gap-1">
                View All Matches <ArrowRight className="w-3.5 h-3.5" />
              </Link>
            </div>

            {matchesLoading ? (
              <div className="py-8 text-center text-sm text-brand-textSecondary">Calculating career matches from R...</div>
            ) : topMatches.length === 0 ? (
              <div className="py-8 text-center text-sm text-brand-textSecondary">No career matches available.</div>
            ) : (
              <div className="space-y-3">
                {topMatches.map((m) => (
                  <div key={m.Job_Role} className="p-4 rounded-lg border border-brand-border hover:border-slate-300 transition-all bg-slate-50/50">
                    <div className="flex items-center justify-between">
                      <div>
                        <div className="font-bold text-navy-900 text-sm">{m.Job_Role}</div>
                        <div className="text-xs text-brand-textSecondary mt-0.5">
                          {m.Posting_Count} postings • Median {formatINR(m.Median_Salary)}
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="text-sm font-bold text-brand-blue">{m.Posting_Overlap_80}%</div>
                        <div className="text-[11px] text-brand-textSecondary">&gt;=80% overlap</div>
                      </div>
                    </div>
                    <div className="mt-2.5 pt-2.5 border-t border-slate-200/60 flex items-center justify-between text-xs">
                      <span className="text-slate-600">
                        Coverage: <strong>{m.Distinct_Coverage}%</strong> distinct ({m.Matched_Count} matched, {m.Missing_Count} missing)
                      </span>
                      <Link to={`/career-explorer`} className="text-brand-blue font-semibold hover:underline">
                        Explore →
                      </Link>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Market Overview Chart */}
          <div className="bg-white border border-brand-border rounded-xl p-5 shadow-sm">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <TrendingUp className="w-5 h-5 text-brand-blue" />
                <h3 className="font-bold text-navy-900">Top In-Demand Career Roles</h3>
              </div>
              <span className="text-xs text-slate-400">Sample of 6,000 Postings</span>
            </div>
            {marketLoading ? (
              <div className="h-56 flex items-center justify-center text-sm text-slate-400">Loading chart...</div>
            ) : (
              <ReactECharts option={rolesChartOption} style={{ height: "230px" }} />
            )}
          </div>
        </div>

        {/* Right Column: Skills to Prioritize */}
        <div className="lg:col-span-5 space-y-6">
          <div className="bg-white border border-brand-border rounded-xl p-5 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <Sparkles className="w-5 h-5 text-amber-600" />
                <h3 className="font-bold text-navy-900">Skills to Prioritize</h3>
              </div>
              <Link to="/skill-intelligence" className="text-xs font-semibold text-brand-blue hover:underline flex items-center gap-1">
                Full Lab <ArrowRight className="w-3.5 h-3.5" />
              </Link>
            </div>

            {gapsLoading ? (
              <div className="py-8 text-center text-sm text-brand-textSecondary">Calculating recommendation index...</div>
            ) : topGaps.length === 0 ? (
              <div className="py-6 text-center text-sm text-emerald-700 bg-emerald-50 rounded-lg border border-emerald-200">
                ✓ No missing high-priority skills found for {profile.targetRole}!
              </div>
            ) : (
              <div className="space-y-3">
                {topGaps.map((g) => (
                  <div key={g.skill} className="p-3.5 rounded-lg border border-brand-border bg-white hover:bg-slate-50 transition-colors">
                    <div className="flex items-center justify-between mb-1.5">
                      <span className="font-bold text-sm text-navy-900">{g.skill}</span>
                      <StatusBadge status={g.priority_category} />
                    </div>
                    <div className="text-xs text-brand-textSecondary space-y-1">
                      <div>
                        Target Role Demand: <strong className="text-slate-800">{g.role_demand_pct}%</strong> ({g.role_postings} postings)
                      </div>
                      {g.cooccurring_skills && g.cooccurring_skills !== "N/A" && (
                        <div className="text-[11px] text-slate-500">
                          Co-occurs with: <span className="font-medium text-slate-700">{g.cooccurring_skills}</span>
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Academic Transparency Note */}
          <div className="p-4 rounded-xl border border-amber-200 bg-amber-50/70 text-xs text-amber-900 leading-relaxed">
            <div className="flex items-center gap-1.5 font-bold mb-1">
              <AlertCircle className="w-4 h-4 text-amber-700 shrink-0" />
              <span>Statistical Decision Support Notice</span>
            </div>
            All recommendations, overlap percentages, and salary estimates are derived purely through R algorithms applied to our synthetic 6,000-job benchmark dataset. They represent historical training distributions and do not constitute hiring guarantees.
          </div>
        </div>
      </div>
    </div>
  );
};
