import React from "react";
import { X } from "lucide-react";

interface SkillChipProps {
  skill: string;
  onRemove?: () => void;
  variant?: "default" | "matched" | "missing" | "proposed";
}

export const SkillChip: React.FC<SkillChipProps> = ({ skill, onRemove, variant = "default" }) => {
  const getVariantStyles = () => {
    switch (variant) {
      case "matched":
        return "bg-emerald-50 text-emerald-800 border-emerald-300";
      case "missing":
        return "bg-rose-50 text-rose-800 border-rose-300";
      case "proposed":
        return "bg-blue-50 text-brand-blue border-blue-300 font-semibold";
      default:
        return "bg-slate-100 text-slate-800 border-slate-300";
    }
  };

  return (
    <span
      className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs border ${getVariantStyles()} transition-all`}
    >
      <span>{skill}</span>
      {onRemove && (
        <button
          type="button"
          onClick={onRemove}
          className="text-slate-400 hover:text-slate-700 transition-colors"
          title={`Remove ${skill}`}
        >
          <X className="w-3 h-3" />
        </button>
      )}
    </span>
  );
};
