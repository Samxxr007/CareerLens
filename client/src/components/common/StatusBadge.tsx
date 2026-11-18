import React from "react";

interface StatusBadgeProps {
  status: "Matched" | "Missing" | "Satisfied" | "HIGH PRIORITY" | "MEDIUM PRIORITY" | "ADDITIONAL SKILL" | string;
  className?: string;
}

export const StatusBadge: React.FC<StatusBadgeProps> = ({ status, className = "" }) => {
  const getStyle = () => {
    switch (status) {
      case "Matched":
      case "Satisfied":
        return "bg-emerald-50 text-emerald-800 border-emerald-300 font-semibold";
      case "Missing":
      case "HIGH PRIORITY":
        return "bg-rose-50 text-rose-800 border-rose-300 font-bold";
      case "MEDIUM PRIORITY":
        return "bg-amber-50 text-amber-800 border-amber-300 font-semibold";
      case "ADDITIONAL SKILL":
        return "bg-slate-100 text-slate-700 border-slate-300 font-medium";
      default:
        return "bg-slate-100 text-slate-700 border-slate-200";
    }
  };

  return (
    <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs border ${getStyle()} ${className}`}>
      {status}
    </span>
  );
};
