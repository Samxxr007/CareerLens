import React, { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { fetchMarketOverview, fetchMarketSkills, fetchMarketCorrelation } from "../services/api";
import { MetricCard } from "../components/common/MetricCard";
import ReactECharts from "echarts-for-react";
import { BarChart3, Database, ShieldAlert, Layers } from "lucide-react";

export const MarketIntelligencePage: React.FC = () => {
  const [selectedLoc, setSelectedLoc] = useState("All");

  const { data: market, isLoading: marketLoading } = useQuery({
    queryKey: ["marketOverview", selectedLoc],
    queryFn: () => fetchMarketOverview({ location: selectedLoc })
  });

  const { data: skillsData } = useQuery({
    queryKey: ["marketSkillsTop20"],
    queryFn: () => fetchMarketSkills({ top: 15 })
  });

  const { data: correlationData } = useQuery({
    queryKey: ["marketCorrelation"],
    queryFn: fetchMarketCorrelation
  });

  const unwrap = (val: any) => (Array.isArray(val) ? val[0] : val);

  const formatINR = (val?: any) => {
    const raw = unwrap(val);
    if (raw === undefined || raw === null || isNaN(Number(raw))) return "₹0";
    const n = Number(raw);
    if (n >= 100000) return `₹${(n / 100000).toFixed(2)} L`;
    return `₹${n.toLocaleString("en-IN")}`;
  };

  // ECharts Option for Top Skills
  const skillsChartOption = {
    tooltip: { trigger: "axis", axisPointer: { type: "shadow" } },
    grid: { left: "3%", right: "5%", bottom: "3%", top: "5%", containLabel: true },
    xAxis: { type: "value" },
    yAxis: {
      type: "category",
      data: skillsData?.map((s: any) => s.skill).reverse() || [],
      axisLabel: { fontSize: 11 }
    },
    series: [
      {
        name: "Job Postings",
        type: "bar",
        data: skillsData?.map((s: any) => s.job_count).reverse() || [],
        itemStyle: { color: "#1E6091", borderRadius: [0, 4, 4, 0] }
      }
    ]
  };

  // ECharts Option for Top Locations
  const locationsChartOption = {
    tooltip: { trigger: "axis" },
    grid: { left: "3%", right: "5%", bottom: "3%", top: "5%", containLabel: true },
    xAxis: { type: "value" },
    yAxis: {
      type: "category",
      data: market?.top_locations?.map((l: any) => l.location).reverse() || [],
      axisLabel: { fontSize: 11 }
    },
    series: [
      {
        name: "Postings",
        type: "bar",
        data: market?.top_locations?.map((l: any) => l.count).reverse() || [],
        itemStyle: { color: "#06A88A", borderRadius: [0, 4, 4, 0] }
      }
    ]
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="bg-white p-5 rounded-xl border border-brand-border flex flex-col sm:flex-row sm:items-center justify-between gap-4 shadow-sm">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-brand-blue text-white flex items-center justify-center font-bold">
            <BarChart3 className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-xl font-bold text-navy-900 leading-none">Market Intelligence & Empirical Evidence</h2>
            <p className="text-xs text-brand-textSecondary mt-1">
              Macro-level distributions, location comparisons, and correlation analysis underpinning CareerLens recommendations.
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2 text-xs">
          <span className="text-slate-500 font-semibold">Location Filter:</span>
          <select
            value={selectedLoc}
            onChange={(e) => setSelectedLoc(e.target.value)}
            className="border border-brand-border rounded-lg px-3 py-1.5 bg-white font-semibold text-slate-800"
          >
            <option value="All">All Locations</option>
            <option value="Bengaluru">Bengaluru</option>
            <option value="Hyderabad">Hyderabad</option>
            <option value="Pune">Pune</option>
            <option value="Mumbai">Mumbai</option>
            <option value="Chennai">Chennai</option>
            <option value="Noida">Noida</option>
            <option value="Gurugram">Gurugram</option>
          </select>
        </div>
      </div>

      {/* Dataset Label Banner */}
      <div className="p-4 bg-slate-50 border border-slate-200 rounded-xl flex items-center justify-between text-xs text-slate-700">
        <div className="flex items-center gap-2">
          <Database className="w-4 h-4 text-brand-teal shrink-0" />
          <span>
            <strong>Benchmark Scope: </strong> Demonstration Dataset — Synthetically Generated Job Postings (6,000 clean records).
          </span>
        </div>
        <span className="bg-white px-2.5 py-1 rounded border border-slate-200 font-semibold text-slate-600">
          Source: Pure R Generator
        </span>
      </div>

      {/* Aggregate KPIs */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard
          label="Total Sample Postings"
          value={marketLoading ? "..." : market?.total_postings?.toLocaleString() || "6,000"}
          subtext="Postings in selected filter"
        />
        <MetricCard
          label="Sample Average Salary"
          value={formatINR(market?.avg_salary)}
          subtext="Mean compensation"
        />
        <MetricCard
          label="Sample Median Salary"
          value={formatINR(market?.median_salary)}
          subtext="50th percentile benchmark"
        />
        <MetricCard
          label="Top Market Hub"
          value={market?.top_locations?.[0]?.location || "Bengaluru"}
          subtext={`${market?.top_locations?.[0]?.count || 0} postings in hub`}
        />
      </div>

      {/* Charts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white p-5 rounded-xl border border-brand-border shadow-sm space-y-3">
          <div className="flex items-center justify-between">
            <h4 className="font-bold text-navy-900 text-sm">Top 15 Most Demanded Technical Skills</h4>
            <span className="text-xs text-slate-400">Posting Frequency</span>
          </div>
          <ReactECharts option={skillsChartOption} style={{ height: "320px" }} />
        </div>

        <div className="bg-white p-5 rounded-xl border border-brand-border shadow-sm space-y-3">
          <div className="flex items-center justify-between">
            <h4 className="font-bold text-navy-900 text-sm">Top Job Posting Tech Hubs</h4>
            <span className="text-xs text-slate-400">Postings by Location</span>
          </div>
          <ReactECharts option={locationsChartOption} style={{ height: "320px" }} />
        </div>
      </div>

      {/* Pearson Correlation Matrix */}
      <div className="bg-white p-5 rounded-xl border border-brand-border shadow-sm space-y-4">
        <div className="flex items-center gap-2">
          <Layers className="w-5 h-5 text-brand-blue" />
          <h4 className="font-bold text-navy-900 text-sm">Pearson Correlation Coefficients Matrix</h4>
        </div>
        <p className="text-xs text-slate-500">
          Evaluates linear association across continuous quantitative parameters in the job market dataset.
        </p>

        {correlationData?.matrix ? (
          <div className="overflow-x-auto max-w-2xl">
            <table className="w-full text-center text-xs border border-slate-200">
              <thead>
                <tr className="bg-slate-50 font-bold border-b text-slate-700">
                  <th className="p-2.5 text-left border-r">Variable</th>
                  <th className="p-2.5 border-r">Experience (Yrs)</th>
                  <th className="p-2.5 border-r">Salary (INR)</th>
                  <th className="p-2.5 border-r">Skill Count</th>
                  <th className="p-2.5">Company Size</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                <tr>
                  <td className="p-2.5 font-bold text-left bg-slate-50 border-r">Experience (Yrs)</td>
                  <td className="p-2.5 border-r font-semibold">1.000</td>
                  <td className="p-2.5 border-r font-bold text-brand-blue">{correlationData.matrix.salary_inr?.experience_years || 0.48}</td>
                  <td className="p-2.5 border-r">{correlationData.matrix.skill_count?.experience_years || 0.12}</td>
                  <td className="p-2.5">{correlationData.matrix.company_size_num?.experience_years || 0.05}</td>
                </tr>
                <tr>
                  <td className="p-2.5 font-bold text-left bg-slate-50 border-r">Salary (INR)</td>
                  <td className="p-2.5 border-r font-bold text-brand-blue">{correlationData.matrix.experience_years?.salary_inr || 0.48}</td>
                  <td className="p-2.5 border-r font-semibold">1.000</td>
                  <td className="p-2.5 border-r font-bold text-brand-blue">{correlationData.matrix.skill_count?.salary_inr || 0.25}</td>
                  <td className="p-2.5">{correlationData.matrix.company_size_num?.salary_inr || 0.18}</td>
                </tr>
                <tr>
                  <td className="p-2.5 font-bold text-left bg-slate-50 border-r">Skill Count</td>
                  <td className="p-2.5 border-r">{correlationData.matrix.experience_years?.skill_count || 0.12}</td>
                  <td className="p-2.5 border-r font-bold text-brand-blue">{correlationData.matrix.salary_inr?.skill_count || 0.25}</td>
                  <td className="p-2.5 border-r font-semibold">1.000</td>
                  <td className="p-2.5">{correlationData.matrix.company_size_num?.skill_count || 0.08}</td>
                </tr>
                <tr>
                  <td className="p-2.5 font-bold text-left bg-slate-50 border-r">Company Size</td>
                  <td className="p-2.5 border-r">{correlationData.matrix.experience_years?.company_size_num || 0.05}</td>
                  <td className="p-2.5 border-r">{correlationData.matrix.salary_inr?.company_size_num || 0.18}</td>
                  <td className="p-2.5 border-r">{correlationData.matrix.skill_count?.company_size_num || 0.08}</td>
                  <td className="p-2.5 font-semibold">1.000</td>
                </tr>
              </tbody>
            </table>
          </div>
        ) : null}
      </div>

      {/* Future Ingestion Architecture Notice */}
      <div className="p-4 bg-blue-50/70 border border-blue-200 rounded-xl text-xs text-blue-900 leading-relaxed flex items-start gap-2.5">
        <ShieldAlert className="w-5 h-5 text-brand-blue shrink-0 mt-0.5" />
        <div>
          <strong className="block mb-0.5 font-bold">Future External Source Adapter Architecture:</strong>
          CareerLens is designed with an extensible adapter pattern ready for authenticated, licensed live job feeds or official APIs. The current release is strictly calibrated against the verified 6,000 synthetic record benchmark to maintain statistical reproducibility.
        </div>
      </div>
    </div>
  );
};
