import React, { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useProfileStore } from "../stores/useProfileStore";
import { fetchJobDescriptionAnalysis } from "../services/api";
import { MetricCard } from "../components/common/MetricCard";
import { StatusBadge } from "../components/common/StatusBadge";
import { FileSearch, PlusCircle, CheckCircle2, RotateCcw, Download, Sparkles } from "lucide-react";

export const JobAnalyzerPage: React.FC = () => {
  const { profile, addSkill } = useProfileStore();

  const SAMPLE_JD = `We are seeking a senior Data Analyst / Analytics Engineer to join our growing data platform team.
Key Responsibilities:
- Build and optimize data pipelines using SQL, Python, and Airflow.
- Develop interactive dashboards and reporting systems in Power BI and Tableau.
- Collaborate with engineering teams using Docker, Git, and AWS cloud services.
- Conduct statistical analysis, A/B testing, and predictive modeling using R and Pandas.
Qualifications:
- Bachelor's or Master's degree in Computer Science, Statistics, or related quantitative field.
- Proficiency in C++, Linux, and REST APIs is a plus.
- Excellent communication and cross-functional problem-solving skills.`;

  const [jdText, setJdText] = useState(SAMPLE_JD);
  const [submittedText, setSubmittedText] = useState(SAMPLE_JD);
  const [targetRole, setTargetRole] = useState(profile.targetRole || "Data Analyst");

  const { data: analysis, isLoading } = useQuery({
    queryKey: ["jobDescriptionAnalysis", submittedText, profile.skills, targetRole],
    queryFn: () => fetchJobDescriptionAnalysis(submittedText, profile.skills, targetRole),
    enabled: !!submittedText.trim()
  });

  const handleAnalyze = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmittedText(jdText);
  };

  const handleLoadSample = () => {
    setJdText(SAMPLE_JD);
    setSubmittedText(SAMPLE_JD);
  };

  const handleClear = () => {
    setJdText("");
    setSubmittedText("");
  };

  const handleAddExtractedSkillToProfile = (skill: string) => {
    addSkill(skill);
  };

  const handleExportResults = () => {
    if (!analysis?.breakdown_tbl) return;
    const jsonStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(analysis, null, 2));
    const link = document.createElement("a");
    link.setAttribute("href", jsonStr);
    link.setAttribute("download", `careerlens_jd_analysis_${Date.now()}.json`);
    document.body.appendChild(link);
    link.click();
    link.remove();
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="bg-white p-5 rounded-xl border border-brand-border flex flex-col sm:flex-row sm:items-center justify-between gap-4 shadow-sm">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-brand-blue text-white flex items-center justify-center font-bold">
            <FileSearch className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-xl font-bold text-navy-900 leading-none">Job Description Analyzer</h2>
            <p className="text-xs text-brand-textSecondary mt-1">
              Offline boundary-aware skill extraction cross-referenced against your profile and market benchmarks.
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={handleLoadSample}
            className="text-xs font-semibold px-3 py-1.5 rounded-lg border border-brand-border bg-slate-50 hover:bg-slate-100 text-slate-700 transition-colors"
          >
            Load Sample JD
          </button>
          <button
            type="button"
            onClick={handleClear}
            className="text-xs font-semibold px-3 py-1.5 rounded-lg border border-brand-border bg-slate-50 hover:bg-slate-100 text-slate-700 transition-colors flex items-center gap-1"
          >
            <RotateCcw className="w-3 h-3" />
            <span>Clear</span>
          </button>
          {analysis && analysis.has_skills && (
            <button
              type="button"
              onClick={handleExportResults}
              className="text-xs font-semibold px-3 py-1.5 rounded-lg bg-brand-blue text-white hover:bg-navy-800 transition-colors flex items-center gap-1"
            >
              <Download className="w-3 h-3" />
              <span>Export Analysis</span>
            </button>
          )}
        </div>
      </div>

      {/* Editor & Parameters */}
      <div className="bg-white p-5 rounded-xl border border-brand-border shadow-sm space-y-4">
        <div className="flex items-center justify-between">
          <label className="text-xs font-bold text-slate-700 uppercase tracking-wider">
            Paste Job Posting Text (Word-Boundary Tokenizer with C++, Node.js, and R handling):
          </label>
          <div className="flex items-center gap-2 text-xs">
            <span className="text-slate-500 font-medium">Benchmark Role:</span>
            <select
              value={targetRole}
              onChange={(e) => setTargetRole(e.target.value)}
              className="border border-brand-border rounded px-2 py-1 bg-white font-semibold text-brand-blue"
            >
              <option value="Data Analyst">Data Analyst</option>
              <option value="Data Scientist">Data Scientist</option>
              <option value="Data Engineer">Data Engineer</option>
              <option value="Software Engineer">Software Engineer</option>
              <option value="Full Stack Developer">Full Stack Developer</option>
            </select>
          </div>
        </div>

        <form onSubmit={handleAnalyze} className="space-y-3">
          <textarea
            value={jdText}
            onChange={(e) => setJdText(e.target.value)}
            rows={7}
            placeholder="Paste complete raw job description text here..."
            className="w-full text-xs font-mono p-3.5 border border-brand-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-blue bg-slate-50/50"
          />
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-400">
              {jdText.length} characters • {jdText.split(/\s+/).filter(Boolean).length} words
            </span>
            <button
              type="submit"
              className="bg-brand-blue hover:bg-navy-800 text-white font-semibold text-xs px-5 py-2 rounded-lg transition-colors flex items-center gap-1.5 shadow-sm"
            >
              <Sparkles className="w-3.5 h-3.5" />
              <span>Analyze Requirements</span>
            </button>
          </div>
        </form>
      </div>

      {/* Analysis Results */}
      {isLoading ? (
        <div className="bg-white p-12 text-center text-slate-400 rounded-xl border border-brand-border">
          Parsing job description and benchmarking against dataset...
        </div>
      ) : analysis && analysis.has_skills ? (
        <div className="space-y-6">
          {/* Metrics Row */}
          <div className="grid grid-cols-3 gap-4">
            <MetricCard
              label="Extracted Recognized Skills"
              value={analysis.extracted_count}
              subtext="Matched against canonical dictionary"
            />
            <MetricCard
              label="Matched with Profile"
              value={analysis.matched_skills.length}
              subtext={`Profile covers ${Math.round((analysis.matched_skills.length / analysis.extracted_count) * 100)}% of requirements`}
              trend="positive"
            />
            <MetricCard
              label="Missing Requirements"
              value={analysis.missing_skills.length}
              subtext="Unsatisfied extracted competencies"
              trend={analysis.missing_skills.length > 0 ? "negative" : "positive"}
            />
          </div>

          {/* Breakdown Table */}
          <div className="bg-white p-5 rounded-xl border border-brand-border shadow-sm space-y-4">
            <h3 className="font-bold text-navy-900 text-sm">Extracted Skill Breakdown & Benchmarking</h3>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="border-b border-slate-200 text-slate-500 font-semibold bg-slate-50">
                    <th className="py-2.5 px-3">Skill</th>
                    <th className="py-2.5 px-3">Category</th>
                    <th className="py-2.5 px-3">Candidate Status</th>
                    <th className="py-2.5 px-3">Role Demand %</th>
                    <th className="py-2.5 px-3">Market Demand %</th>
                    <th className="py-2.5 px-3">Priority Level</th>
                    <th className="py-2.5 px-3">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {analysis.breakdown_tbl.map((row) => (
                    <tr key={row.Skill} className="hover:bg-slate-50/50">
                      <td className="py-2.5 px-3 font-bold text-slate-900">{row.Skill}</td>
                      <td className="py-2.5 px-3 text-slate-500">{row.Category}</td>
                      <td className="py-2.5 px-3">
                        <StatusBadge status={row.Status} />
                      </td>
                      <td className="py-2.5 px-3 font-semibold text-slate-800">{row["Role Demand %"]}%</td>
                      <td className="py-2.5 px-3 text-slate-600">{row["Market Demand %"]}%</td>
                      <td className="py-2.5 px-3">
                        <StatusBadge status={row["Priority Level"]} />
                      </td>
                      <td className="py-2.5 px-3">
                        {row.Status === "Missing" ? (
                          <button
                            type="button"
                            onClick={() => handleAddExtractedSkillToProfile(row.Skill)}
                            className="text-xs font-semibold text-brand-teal hover:underline flex items-center gap-1"
                          >
                            <PlusCircle className="w-3.5 h-3.5" />
                            <span>Add to Profile</span>
                          </button>
                        ) : (
                          <span className="text-emerald-700 flex items-center gap-1 font-medium">
                            <CheckCircle2 className="w-3.5 h-3.5" />
                            <span>Covered</span>
                          </span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div className="text-[11px] text-slate-400 pt-2 border-t border-slate-100">
              {analysis.disclaimer}
            </div>
          </div>
        </div>
      ) : analysis && !analysis.has_skills ? (
        <div className="bg-amber-50 border border-amber-200 text-amber-900 p-6 rounded-xl text-center text-sm">
          {analysis.disclaimer}
        </div>
      ) : null}
    </div>
  );
};
