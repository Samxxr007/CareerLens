import React from "react";

interface MetricCardProps {
  label: string;
  value: string | number;
  subtext?: string;
  trend?: "positive" | "negative" | "neutral";
  trendValue?: string;
  className?: string;
}

export const MetricCard: React.FC<MetricCardProps> = ({
  label,
  value,
  subtext,
  trend,
  trendValue,
  className = ""
}) => {
  return (
    <div className={`bg-white border border-brand-border rounded-lg p-4 shadow-sm ${className}`}>
      <div className="flex items-center justify-between mb-1">
        <span className="text-xs font-semibold tracking-wider text-brand-textSecondary uppercase">
          {label}
        </span>
        {trendValue && (
          <span
            className={`text-xs font-bold px-1.5 py-0.5 rounded ${
              trend === "positive"
                ? "bg-emerald-50 text-emerald-700 border border-emerald-200"
                : trend === "negative"
                ? "bg-rose-50 text-rose-700 border border-rose-200"
                : "bg-slate-100 text-slate-700"
            }`}
          >
            {trendValue}
          </span>
        )}
      </div>
      <div className="text-2xl font-bold text-navy-900 tracking-tight">{value}</div>
      {subtext && <div className="text-xs text-brand-textSecondary mt-1">{subtext}</div>}
    </div>
  );
};
