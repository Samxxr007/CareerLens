import React, { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useProfileStore } from "../stores/useProfileStore";
import { fetchSkillGap, fetchSkillsSimulation, fetchMarketSkills } from "../services/api";
import { MetricCard } from "../components/common/MetricCard";
import { StatusBadge } from "../components/common/StatusBadge";
import { SkillChip } from "../components/common/SkillChip";
import ReactECharts from "echarts-for-react";
import { Sparkles, Plus, RotateCcw, Download, Info } from "lucide-react";

export const SkillIntelligencePage: React.FC = () => {
  const { profile } = useProfileStore();

  // What-If Proposed Skills State (Independent of saved profile!)
  const [proposedSkills, setProposedSkills] = useState<string[]>([...profile.skills, "Power BI"]);
  const [newSimSkill, setNewSimSkill] = useState("");

  const { data: gapData, isLoading: gapLoading } = useQuery({
    queryKey: ["skillGap", profile.skills, profile.targetRole],
    queryFn: () => fetchSkillGap(profile.skills, profile.targetRole)
  });

  const { data: simData, isLoading: simLoading } = useQuery({
    queryKey: ["skillsSimulation", profile.skills, proposedSkills, profile.targetRole],
    queryFn: () => fetchSkillsSimulation(profile.skills, proposedSkills, profile.targetRole)
  });

  const { data: roleSkillsData } = useQuery({
    queryKey: ["marketSkills", profile.targetRole],
    queryFn: () => fetchMarketSkills({ top: 15, role: profile.targetRole })
  });

  const handleAddProposedSkill = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newSimSkill.trim()) return;
    if (!proposedSkills.includes(newSimSkill.trim())) {
      setProposedSkills([...proposedSkills, newSimSkill.trim()]);
    }
    setNewSimSkill("");
  };

  const handleRemoveProposedSkill = (sk: string) => {
    setProposedSkills(proposedSkills.filter((s) => s !== sk));
  };

  const handleResetSimulation = () => {
    setProposedSkills([...profile.skills]);
  };

  const handleDownloadCSV = () => {
    if (!gapData?.recommendations_tbl) return;
    const headers = [
      "Skill",
      "Priority_Category",
      "Priority_Index",
      "Role_Demand_Pct",
      "Role_Postings",
      "Market_Demand_Pct",
      "Observed_Cooccurrence",
      "Evidence_Explanation"
    ];
    const rows = gapData.recommendations_tbl.map((r) => [
      `"${r.skill}"`,
      `"${r.priority_category}"`,
      r.priority_index,
      r.role_demand_pct,
      r.role_postings,
      r.market_demand_pct,
      `"${r.cooccurring_skills}"`,
      `"${r.narrative_explanation.replace(/"/g, '""')}"`
    ]);

    const csvContent = "data:text/csv;charset=utf-8," + [headers.join(","), ...rows.map((e) => e.join(","))].join("\n");
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `careerlens_recommendations_${profile.targetRole.replace(/\s+/g, "_")}.csv`);
    document.body.appendChild(link);
    link.click();
    link.remove();
  };

  // ECharts Option for Role Skills Demand
  const skillChartOption = {
    tooltip: {
      trigger: "axis",
      formatter: (params: any) => {
        const item = params[0];
        return `${item.name}: <strong>${item.value}% demand</strong>`;
      }
    },
    grid: { left: "3%", right: "6%", bottom: "3%", top: "4%", containLabel: true },
    xAxis: { type: "value", max: 100, axisLabel: { formatter: "{value}%" } },
    yAxis: {
      type: "category",
      data: roleSkillsData?.map((s: any) => s.skill).reverse() || [],
      axisLabel: { fontSize: 11 }
    },
    series: [
      {
        name: "Role Demand",
        type: "bar",
        data: roleSkillsData?.map((s: any) => ({
          value: s.demand_pct,
          itemStyle: {
            color: profile.skills.includes(s.skill) ? "#16865D" : "#1E6091",
            borderRadius: [0, 4, 4, 0]
          }
        })).reverse() || []
      }
    ]
  };

  return (
    <div className="space-y-6">
      {/* Target Role Context Header */}
      <div className="bg-white p-5 rounded-xl border border-brand-border flex flex-col sm:flex-row sm:items-center justify-between gap-4 shadow-sm">
        <div>
          <h2 className="text-xl font-bold text-navy-900 leading-none">
            Skill Intelligence for <span className="text-brand-blue">{profile.targetRole}</span>
          </h2>
          <p className="text-xs text-brand-textSecondary mt-1">
            Analyzing requirement overlap, priority learning recommendations, and what-if simulation deltas.
          </p>
        </div>
        <button
          onClick={handleDownloadCSV}
          className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-lg bg-brand-blue text-white text-xs font-semibold hover:bg-navy-800 transition-colors shadow-sm self-start sm:self-auto"
        >
          <Download className="w-3.5 h-3.5" />
          <span>Export Recommendation Report (CSV)</span>
        </button>
      </div>

      {/* SECTION 1: WHAT-IF SKILL SIMULATOR */}
      <div className="bg-white p-6 rounded-xl border border-brand-border shadow-sm space-y-6">
        <div className="flex items-center justify-between border-b pb-3">
          <div className="flex items-center gap-2">
            <Sparkles className="w-5 h-5 text-brand-teal" />
            <h3 className="font-bold text-navy-900 text-base">What-If Skill Simulator</h3>
          </div>
          <button
            onClick={handleResetSimulation}
            className="text-xs font-semibold text-slate-500 hover:text-slate-800 flex items-center gap-1 border border-slate-200 px-2.5 py-1 rounded"
          >
            <RotateCcw className="w-3 h-3" />
            <span>Reset to Baseline</span>
          </button>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          {/* Proposed Skills Editor */}
          <div className="lg:col-span-5 space-y-4">
            <div className="text-xs text-slate-600 leading-relaxed">
              Add or remove skills in this sandbox to test the effect on your coverage and posting overlap without modifying your saved profile.
            </div>

            <form onSubmit={handleAddProposedSkill} className="flex gap-2">
              <input
                type="text"
                value={newSimSkill}
                onChange={(e) => setNewSimSkill(e.target.value)}
                placeholder="Test a skill (e.g., Tableau, Docker)..."
                className="flex-1 text-sm border border-brand-border rounded-lg px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-brand-blue"
              />
              <button
                type="submit"
                className="bg-brand-teal hover:bg-emerald-600 text-white px-3.5 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1 transition-colors"
              >
                <Plus className="w-3.5 h-3.5" />
                <span>Simulate</span>
              </button>
            </form>

            <div>
              <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wider block mb-2">
                Simulated Skill Repertoire ({proposedSkills.length} skills):
              </span>
              <div className="p-3 bg-slate-50 rounded-lg border border-slate-200 flex flex-wrap gap-1.5 min-h-[90px]">
                {proposedSkills.map((s) => (
                  <SkillChip
                    key={s}
                    skill={s}
                    onRemove={() => handleRemoveProposedSkill(s)}
                    variant={profile.skills.includes(s) ? "default" : "proposed"}
                  />
                ))}
              </div>
              <span className="text-[11px] text-brand-blue font-medium mt-1 block">
                Blue badges indicate simulated skills not present in your baseline profile.
              </span>
            </div>
          </div>

          {/* Simulation Output Deltas */}
          <div className="lg:col-span-7 space-y-4">
            {simLoading ? (
              <div className="h-48 flex items-center justify-center text-sm text-slate-400">Recalculating simulation...</div>
            ) : simData ? (
              <>
                <div className="grid grid-cols-3 gap-3">
                  <MetricCard
                    label="Skill Coverage Delta"
                    value={`${simData.coverage_delta >= 0 ? "+" : ""}${simData.coverage_delta}%`}
                    subtext={`Baseline: ${simData.baseline_coverage}% → Proposed: ${simData.proposed_coverage}%`}
                    trend={simData.coverage_delta > 0 ? "positive" : "neutral"}
                  />
                  <MetricCard
                    label="Overlap (≥80%) Delta"
                    value={`${simData.overlap_delta >= 0 ? "+" : ""}${simData.overlap_delta}%`}
                    subtext={`Baseline: ${simData.baseline_overlap}% → Proposed: ${simData.proposed_overlap}%`}
                    trend={simData.overlap_delta > 0 ? "positive" : "neutral"}
                  />
                  <MetricCard
                    label="Newly Satisfied Postings"
                    value={`+${simData.newly_satisfied_postings}`}
                    subtext="Elevated to ≥80% requirement overlap"
                    trend="positive"
                  />
                </div>

                {/* What Changed Summary */}
                <div className="p-4 bg-emerald-50/60 border border-emerald-200 rounded-lg text-xs space-y-2">
                  <div className="font-bold text-emerald-950 flex items-center gap-1.5">
                    <Info className="w-4 h-4 text-emerald-700" />
                    <span>What Changed With This Simulation?</span>
                  </div>
                  {simData.newly_matched_role_skills.length > 0 ? (
                    <p className="text-emerald-900">
                      Adding <strong>{simData.newly_matched_role_skills.join(", ")}</strong> directly satisfies missing requirements for {profile.targetRole}.
                    </p>
                  ) : (
                    <p className="text-slate-600">
                      None of the newly added skills match recognized requirements for {profile.targetRole}.
                    </p>
                  )}
                </div>
              </>
            ) : null}
          </div>
        </div>
      </div>

      {/* SECTION 2: PRIORITY RECOMMENDATION ENGINE */}
      <div className="bg-white p-6 rounded-xl border border-brand-border shadow-sm space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b pb-3">
          <div>
            <h3 className="font-bold text-navy-900 text-base">Priority Learning Recommendations</h3>
            <p className="text-xs text-brand-textSecondary mt-0.5">
              Ranked by explainable heuristic: <code>Priority Index = 0.70 × Role Demand + 0.30 × Market Demand</code>
            </p>
          </div>
        </div>

        {gapLoading ? (
          <div className="py-12 text-center text-sm text-slate-400">Loading recommendations from R engine...</div>
        ) : !gapData?.recommendations_tbl || gapData.recommendations_tbl.length === 0 ? (
          <div className="py-8 text-center text-sm text-emerald-800 bg-emerald-50 rounded-lg border border-emerald-200">
            ✓ Your profile covers all recognized skills for {profile.targetRole}!
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="border-b border-slate-200 text-slate-500 font-semibold bg-slate-50">
                  <th className="py-2.5 px-3">Skill</th>
                  <th className="py-2.5 px-3">Priority Tier</th>
                  <th className="py-2.5 px-3">Priority Index</th>
                  <th className="py-2.5 px-3">Role Demand</th>
                  <th className="py-2.5 px-3">Global Demand</th>
                  <th className="py-2.5 px-3">Observed Co-occurrence</th>
                  <th className="py-2.5 px-3">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {gapData.recommendations_tbl.map((rec) => (
                  <tr key={rec.skill} className="hover:bg-slate-50/50">
                    <td className="py-2.5 px-3 font-bold text-slate-900">{rec.skill}</td>
                    <td className="py-2.5 px-3">
                      <StatusBadge status={rec.priority_category} />
                    </td>
                    <td className="py-2.5 px-3 font-extrabold text-navy-900">{rec.priority_index}</td>
                    <td className="py-2.5 px-3 text-slate-700">
                      <strong>{rec.role_demand_pct}%</strong> ({rec.role_postings} postings)
                    </td>
                    <td className="py-2.5 px-3 text-slate-600">{rec.market_demand_pct}%</td>
                    <td className="py-2.5 px-3 text-slate-500 max-w-xs truncate">{rec.cooccurring_skills || "—"}</td>
                    <td className="py-2.5 px-3">
                      <button
                        type="button"
                        onClick={() => {
                          if (!proposedSkills.includes(rec.skill)) {
                            setProposedSkills([...proposedSkills, rec.skill]);
                          }
                        }}
                        className="text-xs font-semibold text-brand-blue hover:text-navy-900 hover:underline"
                      >
                        + Test in Sim
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* SECTION 3: ROLE SKILLS DEMAND CHART */}
      <div className="bg-white p-6 rounded-xl border border-brand-border shadow-sm space-y-3">
        <div className="flex items-center justify-between">
          <h3 className="font-bold text-navy-900 text-base">Top Skill Requirements for {profile.targetRole}</h3>
          <span className="text-xs text-slate-400">Green indicates skills currently matched by your profile</span>
        </div>
        <ReactECharts option={skillChartOption} style={{ height: "300px" }} />
      </div>
    </div>
  );
};
