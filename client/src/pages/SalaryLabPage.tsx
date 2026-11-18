import React, { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { fetchSalaryPrediction, fetchMarketSalary } from "../services/api";
import { MetricCard } from "../components/common/MetricCard";
import ReactECharts from "echarts-for-react";
import { BadgeDollarSign, Calculator, AlertTriangle, Layers, LineChart } from "lucide-react";

export const SalaryLabPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState<"simulator" | "mlr" | "logistic" | "slr">("simulator");

  // Scenario Simulator Inputs
  const [simExp, setSimExp] = useState(4);
  const [simSkills, setSimSkills] = useState(6);
  const [simEdu, setSimEdu] = useState("B.Tech");
  const [simSize, setSimSize] = useState("Large");
  const [simLocTier, setSimLocTier] = useState("Tier 1");

  const { data: salaryData, isLoading } = useQuery({
    queryKey: ["salaryPrediction", simExp, simSkills, simEdu, simSize, simLocTier],
    queryFn: () =>
      fetchSalaryPrediction({
        experience: simExp,
        skill_count: simSkills,
        education: simEdu,
        company_size: simSize,
        location_tier: simLocTier
      })
  });

  const { data: marketSalary } = useQuery({
    queryKey: ["marketSalary"],
    queryFn: fetchMarketSalary
  });

  const unwrap = (v: any) => (Array.isArray(v) ? v[0] : v);

  const formatINR = (val?: any) => {
    const raw = unwrap(val);
    if (raw === undefined || raw === null || isNaN(Number(raw))) return "₹0";
    const n = Number(raw);
    if (n >= 100000) return `₹${(n / 100000).toFixed(2)} L`;
    return `₹${n.toLocaleString("en-IN")}`;
  };

  // ECharts Option for Market Salary Distribution by Role
  const salaryBoxOption = {
    tooltip: {
      trigger: "item",
      formatter: (param: any) => {
        const item = marketSalary?.find((s: any) => unwrap(s.role) === param.name);
        if (!item) return "";
        return `<strong>${unwrap(item.role)}</strong><br/>
Median: ${formatINR(item.median)}<br/>
Mean: ${formatINR(item.mean)}<br/>
Q1: ${formatINR(item.q1)} | Q3: ${formatINR(item.q3)}<br/>
Min: ${formatINR(item.min)} | Max: ${formatINR(item.max)}`;
      }
    },
    grid: { left: "3%", right: "4%", bottom: "3%", top: "8%", containLabel: true },
    xAxis: {
      type: "category",
      data: marketSalary?.map((s: any) => unwrap(s.role)) || [],
      axisLabel: { interval: 0, rotate: 25, fontSize: 10 }
    },
    yAxis: {
      type: "value",
      axisLabel: { formatter: (val: number) => `₹${val / 100000}L` }
    },
    series: [
      {
        name: "Median Benchmark Salary",
        type: "bar",
        data: marketSalary?.map((s: any) => Number(unwrap(s.median))) || [],
        itemStyle: { color: "#1E6091", borderRadius: [4, 4, 0, 0] }
      }
    ]
  };

  const pred = salaryData?.prediction;
  const slr = salaryData?.slr_summary;
  const mlr = salaryData?.mlr_summary;
  const logit = salaryData?.logit_summary;

  return (
    <div className="space-y-6">
      {/* Sub-Tabs Navigation */}
      <div className="flex border-b border-brand-border bg-white rounded-t-xl px-4 pt-3 gap-2">
        <button
          onClick={() => setActiveTab("simulator")}
          className={`flex items-center gap-2 pb-3 px-3 font-semibold text-sm border-b-2 transition-all ${
            activeTab === "simulator"
              ? "border-brand-blue text-brand-blue"
              : "border-transparent text-slate-500 hover:text-slate-800"
          }`}
        >
          <Calculator className="w-4 h-4" />
          <span>Interactive Salary Simulator</span>
        </button>
        <button
          onClick={() => setActiveTab("mlr")}
          className={`flex items-center gap-2 pb-3 px-3 font-semibold text-sm border-b-2 transition-all ${
            activeTab === "mlr"
              ? "border-brand-blue text-brand-blue"
              : "border-transparent text-slate-500 hover:text-slate-800"
          }`}
        >
          <Layers className="w-4 h-4" />
          <span>Multiple Linear Regression (MLR)</span>
        </button>
        <button
          onClick={() => setActiveTab("logistic")}
          className={`flex items-center gap-2 pb-3 px-3 font-semibold text-sm border-b-2 transition-all ${
            activeTab === "logistic"
              ? "border-brand-blue text-brand-blue"
              : "border-transparent text-slate-500 hover:text-slate-800"
          }`}
        >
          <BadgeDollarSign className="w-4 h-4" />
          <span>Logistic Classification</span>
        </button>
        <button
          onClick={() => setActiveTab("slr")}
          className={`flex items-center gap-2 pb-3 px-3 font-semibold text-sm border-b-2 transition-all ${
            activeTab === "slr"
              ? "border-brand-blue text-brand-blue"
              : "border-transparent text-slate-500 hover:text-slate-800"
          }`}
        >
          <LineChart className="w-4 h-4" />
          <span>Simple Linear Regression</span>
        </button>
      </div>

      {/* TAB 1: INTERACTIVE SIMULATOR */}
      {activeTab === "simulator" && (
        <div className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            {/* Input Controls */}
            <div className="lg:col-span-5 bg-white p-5 rounded-xl border border-brand-border shadow-sm space-y-4">
              <h3 className="font-bold text-navy-900 text-sm border-b pb-2">Scenario Predictor Inputs</h3>

              <div>
                <div className="flex justify-between text-xs font-semibold mb-1">
                  <span>Experience</span>
                  <span className="text-brand-blue font-bold">{simExp} years</span>
                </div>
                <input
                  type="range"
                  min="0"
                  max="25"
                  value={simExp}
                  onChange={(e) => setSimExp(parseInt(e.target.value))}
                  className="w-full h-2 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-brand-blue"
                />
              </div>

              <div>
                <div className="flex justify-between text-xs font-semibold mb-1">
                  <span>Repertoire Skill Count</span>
                  <span className="text-brand-blue font-bold">{simSkills} skills</span>
                </div>
                <input
                  type="range"
                  min="1"
                  max="15"
                  value={simSkills}
                  onChange={(e) => setSimSkills(parseInt(e.target.value))}
                  className="w-full h-2 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-brand-blue"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs font-semibold text-slate-700 block mb-1">Education Level</label>
                  <select
                    value={simEdu}
                    onChange={(e) => setSimEdu(e.target.value)}
                    className="w-full text-xs border border-brand-border rounded-lg p-2 bg-white"
                  >
                    <option value="B.Tech">B.Tech</option>
                    <option value="B.E.">B.E.</option>
                    <option value="MCA">MCA</option>
                    <option value="BCA">BCA</option>
                    <option value="M.Tech">M.Tech</option>
                    <option value="MBA">MBA</option>
                    <option value="Ph.D">Ph.D</option>
                  </select>
                </div>
                <div>
                  <label className="text-xs font-semibold text-slate-700 block mb-1">Company Size</label>
                  <select
                    value={simSize}
                    onChange={(e) => setSimSize(e.target.value)}
                    className="w-full text-xs border border-brand-border rounded-lg p-2 bg-white"
                  >
                    <option value="Small">Small (&lt;50)</option>
                    <option value="Medium">Medium (50-250)</option>
                    <option value="Large">Large (250-1000)</option>
                    <option value="Enterprise">Enterprise (1000+)</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="text-xs font-semibold text-slate-700 block mb-1">Location Tier</label>
                <select
                  value={simLocTier}
                  onChange={(e) => setSimLocTier(e.target.value)}
                  className="w-full text-xs border border-brand-border rounded-lg p-2 bg-white"
                >
                  <option value="Tier 1">Tier 1 (Bengaluru, Hyderabad, Mumbai, Delhi)</option>
                  <option value="Tier 2">Tier 2 (Pune, Chennai, Kolkata, Ahmedabad)</option>
                  <option value="Tier 3">Tier 3 (Other Cities)</option>
                </select>
              </div>
            </div>

            {/* Prediction Outputs */}
            <div className="lg:col-span-7 space-y-4">
              {isLoading ? (
                <div className="bg-white p-12 text-center text-slate-400 rounded-xl border border-brand-border">
                  Running regression models and computing prediction intervals...
                </div>
              ) : pred ? (
                <>
                  {typeof unwrap(pred.extrap_warn) === "string" && unwrap(pred.extrap_warn).trim().length > 0 && (
                    <div className="p-3 bg-amber-50 border border-amber-300 text-amber-900 rounded-lg text-xs flex items-center gap-2">
                      <AlertTriangle className="w-4 h-4 text-amber-700 shrink-0" />
                      <span>{unwrap(pred.extrap_warn)}</span>
                    </div>
                  )}

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    {/* MLR Point Estimate Card */}
                    <div className="bg-white p-5 rounded-xl border border-brand-border shadow-sm text-center">
                      <span className="text-xs uppercase font-semibold text-slate-500 tracking-wider">
                        Estimated Annual Compensation
                      </span>
                      <div className="text-3xl font-extrabold text-navy-900 my-2">
                        {formatINR(pred.mlr_estimate)}
                      </div>
                      <div className="text-xs text-brand-textSecondary">
                        95% Prediction Interval:
                        <br />
                        <strong className="text-slate-800">
                          {formatINR(pred.mlr_lwr)} — {formatINR(pred.mlr_upr)}
                        </strong>
                      </div>
                    </div>

                    {/* Logistic Probability Card */}
                    <div className="bg-white p-5 rounded-xl border border-brand-border shadow-sm text-center">
                      <span className="text-xs uppercase font-semibold text-slate-500 tracking-wider">
                        High Salary Probability (≥ Median)
                      </span>
                      <div className="text-3xl font-extrabold text-brand-blue my-2">
                        {unwrap(pred.high_sal_prob)}%
                      </div>
                      <div className="text-xs text-brand-textSecondary">
                        Classification: <strong className="text-slate-800">{unwrap(pred.high_sal_label)}</strong>
                      </div>
                    </div>
                  </div>

                  <div className="p-4 bg-slate-50 rounded-xl border border-slate-200 text-xs text-slate-600 space-y-1">
                    <strong>Statistical Reliability Notice: </strong>
                    Predictions are derived from a Multiple Linear Regression model with holdout test R² = {unwrap(mlr?.test_r2) ?? "—"} and test RMSE = {formatINR(mlr?.test_rmse)}. Prediction intervals account for regression parameter variance and individual disturbance error.
                  </div>
                </>
              ) : null}
            </div>
          </div>

          {/* Median Salary by Role Chart */}
          <div className="bg-white p-5 rounded-xl border border-brand-border shadow-sm space-y-2">
            <h4 className="font-bold text-navy-900 text-sm">Median Salary by Role Benchmark</h4>
            <ReactECharts option={salaryBoxOption} style={{ height: "260px" }} />
          </div>
        </div>
      )}

      {/* TAB 2: MULTIPLE LINEAR REGRESSION */}
      {activeTab === "mlr" && mlr && (
        <div className="space-y-6">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <MetricCard label="Training Partition R²" value={unwrap(mlr.train_r2)} subtext="Model fit on 80% train split" />
            <MetricCard label="Adjusted R²" value={unwrap(mlr.adj_r2)} subtext="Penalized for 5 predictors" />
            <MetricCard label="Holdout Test R²" value={unwrap(mlr.test_r2)} subtext="Evaluated on 20% holdout" trend="positive" />
            <MetricCard label="Test RMSE" value={formatINR(mlr.test_rmse)} subtext="Root Mean Square Error" />
          </div>

          <div className="bg-white p-5 rounded-xl border border-brand-border shadow-sm text-xs space-y-3">
            <h4 className="font-bold text-navy-900 text-sm">Model Specification & Evaluation</h4>
            <div className="p-3 bg-slate-50 font-mono text-xs rounded border border-slate-200 text-brand-blue font-bold">
              salary_inr ~ experience_years + skill_count + education + company_size_num + location_tier
            </div>
            <p className="text-slate-600 leading-relaxed">
              Trained using deterministic 80/20 partitioning with zero data leakage. Missing salary observations were excluded from training to avoid artificial variance deflation. F-Statistic = <strong>{unwrap(mlr.f_stat)}</strong> (p &lt; 0.001), indicating strong collective predictive significance.
            </p>
          </div>
        </div>
      )}

      {/* TAB 3: LOGISTIC CLASSIFICATION */}
      {activeTab === "logistic" && logit && (
        <div className="space-y-6">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <MetricCard label="Holdout Test Accuracy" value={`${unwrap(logit.test_metrics.accuracy)}%`} subtext="20% test partition" trend="positive" />
            <MetricCard label="Sensitivity / Recall" value={`${unwrap(logit.test_metrics.sensitivity)}%`} subtext="True High Salary Detection" />
            <MetricCard label="Precision" value={`${unwrap(logit.test_metrics.precision)}%`} subtext="Positive Predictive Value" />
            <MetricCard label="F1 Score" value={`${unwrap(logit.test_metrics.f1_score)}%`} subtext="Harmonic Mean of P & R" />
          </div>

          <div className="bg-white p-5 rounded-xl border border-brand-border shadow-sm text-xs space-y-4">
            <h4 className="font-bold text-navy-900 text-sm">Out-of-Sample Confusion Matrix (20% Test Holdout)</h4>
            <div className="text-slate-600">
              High-salary threshold: <strong>{formatINR(logit.threshold)}</strong> (determined exclusively from training partition median to prevent test leakage).
            </div>
            <div className="overflow-x-auto max-w-md">
              <table className="w-full text-center border border-slate-200">
                <thead>
                  <tr className="bg-slate-50 font-bold border-b">
                    <th className="p-2 border-r">Actual \ Predicted</th>
                    <th className="p-2 border-r">Pred: Standard (0)</th>
                    <th className="p-2">Pred: High (1)</th>
                  </tr>
                </thead>
                <tbody>
                  <tr className="border-b">
                    <td className="p-2 font-bold bg-slate-50 border-r">Actual: Standard (0)</td>
                    <td className="p-2 border-r font-semibold text-emerald-800">{unwrap(logit.test_cm?.["0"]?.["0"]) ?? "—"}</td>
                    <td className="p-2 font-semibold text-rose-800">{unwrap(logit.test_cm?.["0"]?.["1"]) ?? "—"}</td>
                  </tr>
                  <tr>
                    <td className="p-2 font-bold bg-slate-50 border-r">Actual: High (1)</td>
                    <td className="p-2 border-r font-semibold text-rose-800">{unwrap(logit.test_cm?.["1"]?.["0"]) ?? "—"}</td>
                    <td className="p-2 font-semibold text-emerald-800">{unwrap(logit.test_cm?.["1"]?.["1"]) ?? "—"}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* TAB 4: SIMPLE LINEAR REGRESSION */}
      {activeTab === "slr" && slr && (
        <div className="space-y-6">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <MetricCard label="Training R²" value={unwrap(slr.train_r2)} subtext="Experience-only fit" />
            <MetricCard label="Holdout Test R²" value={unwrap(slr.test_r2)} subtext="Out-of-sample R²" />
            <MetricCard label="Test RMSE" value={formatINR(slr.test_rmse)} subtext="Root Mean Sq Error" />
            <MetricCard label="Test MAE" value={formatINR(slr.test_mae)} subtext="Mean Absolute Error" />
          </div>

          <div className="bg-white p-5 rounded-xl border border-brand-border shadow-sm text-xs space-y-3">
            <h4 className="font-bold text-navy-900 text-sm">Fitted Equation</h4>
            <div className="p-3 bg-slate-50 font-mono text-sm rounded border border-slate-200 text-brand-blue font-bold">
              {unwrap(slr.equation)}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
