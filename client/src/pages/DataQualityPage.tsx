import React from "react";
import { useQuery } from "@tanstack/react-query";
import { fetchDataQuality } from "../services/api";
import { MetricCard } from "../components/common/MetricCard";
import { ShieldCheck, Download, CheckCircle2 } from "lucide-react";

export const DataQualityPage: React.FC = () => {
  const { data: dqData, isLoading } = useQuery({
    queryKey: ["dataQuality"],
    queryFn: fetchDataQuality
  });

  const summary = dqData?.summary;
  const missingByCol = dqData?.missing_by_column || [];
  const preview = dqData?.preview || [];

  const formatINR = (val?: number) => {
    if (!val) return "—";
    return `₹${val.toLocaleString("en-IN")}`;
  };

  const handleDownloadDataset = (type: "raw" | "clean") => {
    const filename = type === "raw" ? "job_market_raw.csv" : "job_market_clean.csv";
    const link = document.createElement("a");
    link.href = `/api/data-quality/download/${type}`;
    link.setAttribute("download", filename);
    document.body.appendChild(link);
    link.click();
    link.remove();
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="bg-white p-5 rounded-xl border border-brand-border flex flex-col sm:flex-row sm:items-center justify-between gap-4 shadow-sm">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-emerald-700 text-white flex items-center justify-center font-bold">
            <ShieldCheck className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-xl font-bold text-navy-900 leading-none">Data Quality & Analytical Audit</h2>
            <p className="text-xs text-brand-textSecondary mt-1">
              Complete transparency into raw dataset characteristics, transformation rules, and missing value treatment.
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={() => handleDownloadDataset("raw")}
            className="text-xs font-semibold px-3 py-1.5 rounded-lg border border-brand-border bg-slate-50 hover:bg-slate-100 text-slate-700 transition-colors flex items-center gap-1.5"
          >
            <Download className="w-3.5 h-3.5" />
            <span>Raw CSV (6,030 rows)</span>
          </button>
          <button
            type="button"
            onClick={() => handleDownloadDataset("clean")}
            className="text-xs font-semibold px-3 py-1.5 rounded-lg bg-brand-blue text-white hover:bg-navy-800 transition-colors flex items-center gap-1.5 shadow-sm"
          >
            <Download className="w-3.5 h-3.5" />
            <span>Clean CSV (6,000 rows)</span>
          </button>
        </div>
      </div>

      {isLoading ? (
        <div className="bg-white p-12 text-center text-slate-400 rounded-xl border border-brand-border">
          Loading data quality summary from R engine...
        </div>
      ) : summary ? (
        <>
          {/* Quality KPIs */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <MetricCard
              label="Raw Records Generated"
              value={summary.raw_rows.toLocaleString()}
              subtext="Initial synthetic generation"
            />
            <MetricCard
              label="Duplicate Postings Removed"
              value={summary.duplicates_removed}
              subtext="Based on title, company & location"
              trend="positive"
            />
            <MetricCard
              label="Clean Records Analyzed"
              value={summary.clean_rows.toLocaleString()}
              subtext="Used across all analytical modules"
              trend="positive"
            />
            <MetricCard
              label="Preserved Missing Salaries"
              value={summary.missing_salaries_preserved}
              subtext="Retained as NA (leak-free)"
            />
          </div>

          {/* Missing Values Breakdown & Pipeline Documentation */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            <div className="lg:col-span-6 bg-white p-5 rounded-xl border border-brand-border shadow-sm space-y-3">
              <h4 className="font-bold text-navy-900 text-sm">Missing Values Breakdown by Column</h4>
              <p className="text-xs text-slate-500">
                Identifies columns with missing values in raw data and how the R pipeline handled each.
              </p>
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs border border-slate-100">
                  <thead>
                    <tr className="border-b bg-slate-50 text-slate-600 font-semibold">
                      <th className="p-2.5">Column Name</th>
                      <th className="p-2.5">Missing Count</th>
                      <th className="p-2.5">Missing %</th>
                      <th className="p-2.5">Handling Rule</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {missingByCol.map((col) => (
                      <tr key={col.column} className="hover:bg-slate-50/50">
                        <td className="p-2.5 font-mono font-bold text-slate-800">{col.column}</td>
                        <td className="p-2.5 font-semibold text-rose-700">{col.missing_count}</td>
                        <td className="p-2.5 text-slate-600">{col.missing_pct}%</td>
                        <td className="p-2.5 text-slate-500 text-[11px]">
                          {col.column.includes("salary")
                            ? "Preserved as NA (Excluded from regression)"
                            : "Imputed using group mode"}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            <div className="lg:col-span-6 bg-white p-5 rounded-xl border border-brand-border shadow-sm space-y-4 text-xs text-slate-700">
              <h4 className="font-bold text-navy-900 text-sm border-b pb-2">Pre-processing Pipeline Rules</h4>
              <div className="space-y-3">
                <div className="flex items-start gap-2">
                  <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                  <div>
                    <strong className="text-slate-900">Text Normalization: </strong>
                    All company names, titles, and locations are standardized into title case and trimmed of extraneous whitespace.
                  </div>
                </div>
                <div className="flex items-start gap-2">
                  <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                  <div>
                    <strong className="text-slate-900">Strict Skill Deduplication: </strong>
                    Exploded skills are deduplicated by distinct <code>(job_id, skill)</code> pairs, preventing inflated demand counts from repeated skill mentions in text.
                  </div>
                </div>
                <div className="flex items-start gap-2">
                  <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                  <div>
                    <strong className="text-slate-900">Zero Data Leakage: </strong>
                    Missing salaries remain <code>NA</code> in the clean dataset rather than imputed with group medians, ensuring linear and logistic regression models evaluate honest holdout predictions.
                  </div>
                </div>
                <div className="flex items-start gap-2">
                  <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                  <div>
                    <strong className="text-slate-900">52 Fictional Tech Employers: </strong>
                    Employer pool uses diverse, fictional enterprise identifiers to maintain complete legal independence from real companies.
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Clean Dataset Interactive Preview */}
          <div className="bg-white p-5 rounded-xl border border-brand-border shadow-sm space-y-3">
            <div className="flex items-center justify-between">
              <h4 className="font-bold text-navy-900 text-sm">Clean Dataset Preview (Sample of First 50 Records)</h4>
              <span className="text-xs text-slate-400">Total: 6,000 clean records</span>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs whitespace-nowrap">
                <thead>
                  <tr className="border-b bg-slate-50 text-slate-600 font-semibold">
                    <th className="p-2">Job ID</th>
                    <th className="p-2">Role Title</th>
                    <th className="p-2">Employer</th>
                    <th className="p-2">Location</th>
                    <th className="p-2">Exp</th>
                    <th className="p-2">Education</th>
                    <th className="p-2">Salary (INR)</th>
                    <th className="p-2">Type</th>
                    <th className="p-2">Key Skills</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {preview.map((row: any) => (
                    <tr key={row.job_id} className="hover:bg-slate-50">
                      <td className="p-2 font-mono text-slate-500">{row.job_id}</td>
                      <td className="p-2 font-bold text-navy-900">{row.job_title}</td>
                      <td className="p-2 text-slate-700">{row.company}</td>
                      <td className="p-2 text-slate-600">{row.location}</td>
                      <td className="p-2">{row.experience_years}y</td>
                      <td className="p-2">{row.education}</td>
                      <td className="p-2 font-semibold text-brand-blue">{formatINR(row.salary_inr)}</td>
                      <td className="p-2 text-slate-500">{row.employment_type}</td>
                      <td className="p-2 text-slate-500 max-w-xs truncate">{row.skills}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </>
      ) : null}
    </div>
  );
};
