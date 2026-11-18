import React, { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useProfileStore } from "../stores/useProfileStore";
import {
  fetchSkillsSimulation,
  fetchSkillGap,
  fetchMetadata,
  fetchSalaryPrediction
} from "../services/api";
import { SkillChip } from "../components/common/SkillChip";
import {
  Sparkles,
  Plus,
  RotateCcw,
  CheckCircle2,
  Info,
  Save,
  Compass,
  Zap
} from "lucide-react";

export const WhatIfLabPage: React.FC = () => {
  const { profile, setProfile } = useProfileStore();

  const { data: meta } = useQuery({
    queryKey: ["metadata"],
    queryFn: fetchMetadata
  });

  // Selected role for simulation
  const [selectedRole, setSelectedRole] = useState<string>(profile.targetRole || "Data Analyst");

  // Simulated repertoire state
  const [proposedSkills, setProposedSkills] = useState<string[]>([
    ...profile.skills,
    "Power BI"
  ]);
  const [simExp, setSimExp] = useState<number>(profile.experience);
  const [newSkillInput, setNewSkillInput] = useState<string>("");
  const [commitMessage, setCommitMessage] = useState<string | null>(null);

  // Fetch skill gap for current role to get recommendations to suggest
  const { data: gapData } = useQuery({
    queryKey: ["skillGap", profile.skills, selectedRole],
    queryFn: () => fetchSkillGap(profile.skills, selectedRole)
  });

  // Fetch simulation results from R Plumber
  const { data: simData, isLoading: simLoading } = useQuery({
    queryKey: ["skillsSimulation", profile.skills, proposedSkills, selectedRole],
    queryFn: () => fetchSkillsSimulation(profile.skills, proposedSkills, selectedRole)
  });

  // Fetch baseline salary prediction
  const { data: baseSalaryData } = useQuery({
    queryKey: [
      "salaryPredictionBase",
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

  // Fetch simulated salary prediction
  const { data: simSalaryData } = useQuery({
    queryKey: [
      "salaryPredictionSim",
      simExp,
      proposedSkills.length,
      profile.education
    ],
    queryFn: () =>
      fetchSalaryPrediction({
        experience: simExp,
        skill_count: proposedSkills.length,
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

  const baseMlr = baseSalaryData?.prediction?.mlr_estimate;
  const simMlr = simSalaryData?.prediction?.mlr_estimate;
  const baseSalaryVal = Number(Array.isArray(baseMlr) ? baseMlr[0] : baseMlr || 0);
  const simSalaryVal = Number(Array.isArray(simMlr) ? simMlr[0] : simMlr || 0);
  const salaryDelta = simSalaryVal && baseSalaryVal ? simSalaryVal - baseSalaryVal : 0;

  const handleAddProposedSkill = (skill: string) => {
    const trimmed = skill.trim();
    if (!trimmed) return;
    if (!proposedSkills.includes(trimmed)) {
      setProposedSkills([...proposedSkills, trimmed]);
    }
    setNewSkillInput("");
  };

  const handleRemoveProposedSkill = (sk: string) => {
    setProposedSkills(proposedSkills.filter((s) => s !== sk));
  };

  const handleResetToBaseline = () => {
    setProposedSkills([...profile.skills]);
    setSimExp(profile.experience);
    setCommitMessage(null);
  };

  const handleCommitToProfile = () => {
    setProfile({
      skills: [...proposedSkills],
      experience: simExp,
      targetRole: selectedRole
    });
    setCommitMessage("✓ Profile updated with simulated repertoire!");
    setTimeout(() => setCommitMessage(null), 4000);
  };

  const handleQuickAddTopRecommendations = () => {
    if (!gapData?.recommendations_tbl) return;
    const topSkills = gapData.recommendations_tbl
      .slice(0, 3)
      .map((r) => r.skill)
      .filter((s) => !proposedSkills.includes(s));
    setProposedSkills([...proposedSkills, ...topSkills]);
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="bg-white p-5 rounded-xl border border-brand-border flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-sm">
        <div>
          <div className="flex items-center gap-2">
            <span className="w-6 h-6 rounded-md bg-brand-teal/20 text-brand-teal flex items-center justify-center text-xs font-bold">
              6
            </span>
            <h2 className="text-xl font-bold text-navy-900 leading-none">
              What-If Scenario Lab
            </h2>
          </div>
          <p className="text-xs text-brand-textSecondary mt-1">
            Simulate hypothetical skill acquisitions and experience progression. Observe real-time statistical deltas against 6,000 market postings without modifying your saved profile.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={handleResetToBaseline}
            className="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg border border-slate-300 text-slate-700 text-xs font-semibold hover:bg-slate-50 transition-colors"
          >
            <RotateCcw className="w-3.5 h-3.5 text-slate-500" />
            <span>Reset to Baseline</span>
          </button>
          <button
            onClick={handleCommitToProfile}
            className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-lg bg-brand-blue text-white text-xs font-semibold hover:bg-navy-800 transition-colors shadow-sm"
          >
            <Save className="w-3.5 h-3.5" />
            <span>Apply to Active Profile</span>
          </button>
        </div>
      </div>

      {commitMessage && (
        <div className="p-3 bg-emerald-50 border border-emerald-300 text-emerald-900 rounded-lg text-xs flex items-center gap-2 animate-fade-in">
          <CheckCircle2 className="w-4 h-4 text-emerald-600" />
          <span>{commitMessage}</span>
        </div>
      )}

      {/* Primary Simulator Workspace */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Controls Column (Left, 5 cols) */}
        <div className="lg:col-span-5 space-y-5">
          {/* Target Role & Experience Configuration */}
          <div className="bg-white p-5 rounded-xl border border-brand-border shadow-sm space-y-4">
            <h3 className="font-bold text-navy-900 text-sm border-b pb-2 flex items-center gap-2">
              <Compass className="w-4 h-4 text-brand-blue" />
              <span>Simulation Target & Parameters</span>
            </h3>

            <div>
              <label className="text-xs font-semibold text-slate-700 block mb-1">
                Target Benchmark Role
              </label>
              <select
                value={selectedRole}
                onChange={(e) => setSelectedRole(e.target.value)}
                className="w-full text-xs border border-brand-border rounded-lg p-2 bg-white font-medium text-slate-800"
              >
                {meta?.roles ? (
                  meta.roles.map((r: string) => (
                    <option key={r} value={r}>
                      {r}
                    </option>
                  ))
                ) : (
                  <option value={selectedRole}>{selectedRole}</option>
                )}
              </select>
            </div>

            <div>
              <div className="flex justify-between text-xs font-semibold mb-1">
                <span className="text-slate-700">Simulated Experience</span>
                <span className="text-brand-blue font-bold">
                  {simExp} yrs{" "}
                  {simExp !== profile.experience && (
                    <span className="text-xs text-brand-teal">
                      ({simExp > profile.experience ? "+" : ""}
                      {simExp - profile.experience} from profile)
                    </span>
                  )}
                </span>
              </div>
              <input
                type="range"
                min="0"
                max="20"
                value={simExp}
                onChange={(e) => setSimExp(parseInt(e.target.value))}
                className="w-full h-2 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-brand-blue"
              />
              <div className="flex justify-between text-[10px] text-slate-400 mt-0.5">
                <span>0 yrs (Entry)</span>
                <span>Baseline: {profile.experience} yrs</span>
                <span>20 yrs (Principal)</span>
              </div>
            </div>
          </div>

          {/* Simulated Skills Repertoire */}
          <div className="bg-white p-5 rounded-xl border border-brand-border shadow-sm space-y-4">
            <div className="flex items-center justify-between border-b pb-2">
              <h3 className="font-bold text-navy-900 text-sm flex items-center gap-2">
                <Sparkles className="w-4 h-4 text-brand-teal" />
                <span>Simulated Skill Repertoire ({proposedSkills.length})</span>
              </h3>
              {gapData?.recommendations_tbl && gapData.recommendations_tbl.length > 0 && (
                <button
                  type="button"
                  onClick={handleQuickAddTopRecommendations}
                  className="text-[11px] text-brand-teal hover:underline font-semibold flex items-center gap-1"
                >
                  <Zap className="w-3 h-3" />
                  <span>+ Quick Add Top 3</span>
                </button>
              )}
            </div>

            {/* Input to test new skill */}
            <form
              onSubmit={(e) => {
                e.preventDefault();
                handleAddProposedSkill(newSkillInput);
              }}
              className="flex gap-2"
            >
              <input
                type="text"
                value={newSkillInput}
                onChange={(e) => setNewSkillInput(e.target.value)}
                placeholder="Type a skill to test (e.g. AWS, Docker, PyTorch)..."
                className="flex-1 text-xs border border-brand-border rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-blue"
              />
              <button
                type="submit"
                className="bg-brand-teal hover:bg-emerald-600 text-white px-3.5 py-2 rounded-lg text-xs font-semibold flex items-center gap-1 transition-colors"
              >
                <Plus className="w-3.5 h-3.5" />
                <span>Add</span>
              </button>
            </form>

            {/* Quick recommendable skills from R engine */}
            {gapData?.recommendations_tbl && gapData.recommendations_tbl.length > 0 && (
              <div>
                <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wider block mb-1.5">
                  Top Missing Role Requirements to Test:
                </span>
                <div className="flex flex-wrap gap-1.5">
                  {gapData.recommendations_tbl.slice(0, 5).map((rec) => {
                    const isAlreadyIn = proposedSkills.includes(rec.skill);
                    return (
                      <button
                        key={rec.skill}
                        type="button"
                        disabled={isAlreadyIn}
                        onClick={() => handleAddProposedSkill(rec.skill)}
                        className={`text-xs px-2.5 py-1 rounded-md border text-left transition-colors flex items-center gap-1 ${
                          isAlreadyIn
                            ? "bg-slate-100 border-slate-200 text-slate-400 cursor-default"
                            : "bg-white border-brand-teal/40 text-brand-teal hover:bg-teal-50"
                        }`}
                      >
                        <span>+ {rec.skill}</span>
                        <span className="text-[10px] text-slate-500 font-mono">
                          ({rec.role_demand_pct}%)
                        </span>
                      </button>
                    );
                  })}
                </div>
              </div>
            )}

            {/* Active Sandbox Badges */}
            <div>
              <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wider block mb-2">
                Active Sandbox Skills:
              </span>
              <div className="p-3 bg-slate-50 rounded-lg border border-slate-200 flex flex-wrap gap-1.5 max-h-56 overflow-y-auto">
                {proposedSkills.map((s) => {
                  const isBaseline = profile.skills.includes(s);
                  return (
                    <SkillChip
                      key={s}
                      skill={s}
                      onRemove={() => handleRemoveProposedSkill(s)}
                      variant={isBaseline ? "default" : "proposed"}
                    />
                  );
                })}
              </div>
              <div className="flex items-center justify-between text-[11px] text-slate-500 mt-1.5">
                <span>Grey = Profile Baseline</span>
                <span className="text-brand-blue font-semibold">Blue = Hypothetical Acquisition</span>
              </div>
            </div>
          </div>
        </div>

        {/* Results & Deltas Column (Right, 7 cols) */}
        <div className="lg:col-span-7 space-y-5">
          {/* Key Simulation Deltas Grid */}
          <div className="bg-white p-5 rounded-xl border border-brand-border shadow-sm space-y-4">
            <h3 className="font-bold text-navy-900 text-sm border-b pb-2 flex items-center justify-between">
              <span>Observable Market Deltas for {selectedRole}</span>
              {simLoading && (
                <span className="text-xs text-brand-blue font-normal">
                  Recalculating via R engine...
                </span>
              )}
            </h3>

            {simData ? (
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                {/* Coverage Delta */}
                <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200 text-center">
                  <span className="text-[11px] uppercase font-semibold text-slate-500 tracking-wider block">
                    Skill Coverage
                  </span>
                  <div className="text-2xl font-black text-navy-900 my-1">
                    {simData.proposed_coverage}%
                  </div>
                  <div
                    className={`text-xs font-bold ${
                      simData.coverage_delta > 0
                        ? "text-brand-teal"
                        : simData.coverage_delta < 0
                        ? "text-rose-600"
                        : "text-slate-500"
                    }`}
                  >
                    {simData.coverage_delta >= 0 ? "+" : ""}
                    {simData.coverage_delta}% Δ
                  </div>
                  <span className="text-[10px] text-slate-400">
                    Base: {simData.baseline_coverage}%
                  </span>
                </div>

                {/* Overlap Delta */}
                <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200 text-center">
                  <span className="text-[11px] uppercase font-semibold text-slate-500 tracking-wider block">
                    Overlap (≥80%)
                  </span>
                  <div className="text-2xl font-black text-brand-blue my-1">
                    {simData.proposed_overlap}%
                  </div>
                  <div
                    className={`text-xs font-bold ${
                      simData.overlap_delta > 0
                        ? "text-brand-teal"
                        : simData.overlap_delta < 0
                        ? "text-rose-600"
                        : "text-slate-500"
                    }`}
                  >
                    {simData.overlap_delta >= 0 ? "+" : ""}
                    {simData.overlap_delta}% Δ
                  </div>
                  <span className="text-[10px] text-slate-400">
                    Base: {simData.baseline_overlap}%
                  </span>
                </div>

                {/* Newly Satisfied Postings */}
                <div className="p-3.5 bg-emerald-50/60 rounded-xl border border-emerald-200 text-center">
                  <span className="text-[11px] uppercase font-semibold text-emerald-800 tracking-wider block">
                    Newly Qualified
                  </span>
                  <div className="text-2xl font-black text-emerald-800 my-1">
                    +{simData.newly_satisfied_postings}
                  </div>
                  <span className="text-[10px] text-emerald-700 font-medium">
                    Postings crossing 80% threshold
                  </span>
                </div>

                {/* Predicted Salary Delta */}
                <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200 text-center">
                  <span className="text-[11px] uppercase font-semibold text-slate-500 tracking-wider block">
                    MLR Est. Comp
                  </span>
                  <div className="text-xl font-black text-navy-900 my-1">
                    {formatINR(simSalaryVal)}
                  </div>
                  <div
                    className={`text-xs font-bold ${
                      salaryDelta >= 0 ? "text-brand-teal" : "text-rose-600"
                    }`}
                  >
                    {salaryDelta >= 0 ? "+" : ""}
                    {formatINR(salaryDelta)} Δ
                  </div>
                  <span className="text-[10px] text-slate-400">
                    Base: {formatINR(baseSalaryVal)}
                  </span>
                </div>
              </div>
            ) : null}

            {/* Impact Narrative */}
            {simData && (
              <div className="p-4 bg-slate-50 rounded-lg border border-slate-200 text-xs text-slate-700 space-y-2">
                <div className="font-bold text-navy-900 flex items-center gap-1.5">
                  <Info className="w-4 h-4 text-brand-blue" />
                  <span>Analytical Impact Summary</span>
                </div>
                {simData.newly_matched_role_skills && simData.newly_matched_role_skills.length > 0 ? (
                  <p className="leading-relaxed">
                    Adding <strong className="text-brand-blue">{simData.newly_matched_role_skills.join(", ")}</strong> directly closes role requirements for <strong>{selectedRole}</strong>. This elevates your profile into the top qualifying tier for an additional <strong>{simData.newly_satisfied_postings} postings</strong> and increases your multiple regression salary point estimate by <strong>{formatINR(salaryDelta)}</strong>.
                  </p>
                ) : (
                  <p className="leading-relaxed text-slate-500">
                    None of the newly added skills match unmet core requirements for {selectedRole}. While they expand your general repertoire, your target role qualification metrics remain steady.
                  </p>
                )}
              </div>
            )}
          </div>

          {/* Detailed Requirements Transition Matrix */}
          <div className="bg-white p-5 rounded-xl border border-brand-border shadow-sm space-y-3">
            <h4 className="font-bold text-navy-900 text-sm">
              Requirements Transition Matrix ({selectedRole})
            </h4>
            <p className="text-xs text-slate-500">
              Evaluated against postings in dataset to show how your simulated skills change matching status.
            </p>

            {gapData?.recommendations_tbl && (
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead>
                    <tr className="border-b border-slate-200 text-slate-500 font-semibold bg-slate-50">
                      <th className="py-2 px-3">Role Requirement</th>
                      <th className="py-2 px-3">Role Demand</th>
                      <th className="py-2 px-3">Baseline Status</th>
                      <th className="py-2 px-3">Simulated Status</th>
                      <th className="py-2 px-3">Delta Impact</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {gapData.recommendations_tbl.slice(0, 8).map((rec) => {
                      const isBaseMatched = profile.skills.includes(rec.skill);
                      const isSimMatched = proposedSkills.includes(rec.skill);
                      const justAcquired = !isBaseMatched && isSimMatched;

                      return (
                        <tr
                          key={rec.skill}
                          className={justAcquired ? "bg-emerald-50/50" : "hover:bg-slate-50"}
                        >
                          <td className="py-2 px-3 font-bold text-slate-900">
                            {rec.skill}
                          </td>
                          <td className="py-2 px-3 text-slate-600">
                            {rec.role_demand_pct}% ({rec.role_postings} jobs)
                          </td>
                          <td className="py-2 px-3">
                            <span
                              className={`px-2 py-0.5 rounded text-[10px] font-semibold ${
                                isBaseMatched
                                  ? "bg-emerald-100 text-emerald-800"
                                  : "bg-slate-100 text-slate-600"
                              }`}
                            >
                              {isBaseMatched ? "Matched" : "Missing"}
                            </span>
                          </td>
                          <td className="py-2 px-3">
                            <span
                              className={`px-2 py-0.5 rounded text-[10px] font-semibold ${
                                isSimMatched
                                  ? "bg-emerald-100 text-emerald-800"
                                  : "bg-amber-100 text-amber-800"
                              }`}
                            >
                              {isSimMatched ? "Matched" : "Missing"}
                            </span>
                          </td>
                          <td className="py-2 px-3 font-semibold text-xs">
                            {justAcquired ? (
                              <span className="text-emerald-700 flex items-center gap-1 font-bold">
                                <CheckCircle2 className="w-3.5 h-3.5" />
                                <span>Requirement Satisfied!</span>
                              </span>
                            ) : isBaseMatched ? (
                              <span className="text-slate-400">Already Satisfied</span>
                            ) : (
                              <span className="text-amber-700">Still Unmet Gap</span>
                            )}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
