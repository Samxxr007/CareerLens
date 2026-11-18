import React from "react";
import { NavLink } from "react-router-dom";
import {
  LayoutDashboard,
  UserCheck,
  Compass,
  Sparkles,
  FileSearch,
  BadgeDollarSign,
  BarChart3,
  ShieldCheck,
  Database,
  HelpCircle,
  FlaskConical,
  Target
} from "lucide-react";

export const AppSidebar: React.FC = () => {
  const navItems = [
    { label: "Overview", to: "/", icon: LayoutDashboard },
    { label: "1. Candidate Profile", to: "/profile", icon: UserCheck },
    { label: "2. Market Evidence", to: "/market-intelligence", icon: BarChart3 },
    { label: "3. Career Fit Engine", to: "/career-explorer", icon: Compass },
    { label: "4-5. Skill Gaps & Recs", to: "/skill-intelligence", icon: Sparkles },
    { label: "6. What-If Scenario Lab", to: "/what-if-lab", icon: FlaskConical },
    { label: "7. Job Description Analyzer", to: "/job-analyzer", icon: FileSearch },
    { label: "8. Salary & Prediction Lab", to: "/salary-lab", icon: BadgeDollarSign },
    { label: "9. Informed Career Decision", to: "/career-decision", icon: Target },
    { label: "AI Roadmap Generator", to: "/roadmap", icon: Sparkles },
    { label: "Data Quality & Audit", to: "/data-quality", icon: ShieldCheck }
  ];

  return (
    <aside className="w-[250px] bg-navy-900 text-white flex flex-col shrink-0 min-h-screen border-r border-slate-800">
      {/* Brand header */}
      <div className="h-[68px] flex items-center gap-3 px-6 border-b border-slate-800">
        <div className="w-8 h-8 rounded-lg bg-brand-blue flex items-center justify-center font-bold text-white shadow-sm">
          CL
        </div>
        <div>
          <div className="font-bold tracking-tight text-white leading-tight">CareerLens</div>
          <div className="text-[10px] text-slate-400 font-medium">Intelligence Platform 2.0</div>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 py-4 px-3 space-y-1">
        {navItems.map((item) => {
          const Icon = item.icon;
          return (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                `flex items-center gap-3 px-3 py-2.5 rounded-md text-sm font-medium transition-all ${
                  isActive
                    ? "bg-brand-blue text-white shadow-sm font-semibold"
                    : "text-slate-300 hover:bg-navy-800 hover:text-white"
                }`
              }
            >
              <Icon className="w-4 h-4 shrink-0" />
              <span>{item.label}</span>
            </NavLink>
          );
        })}
      </nav>

      {/* Dataset & Academic badge */}
      <div className="p-4 border-t border-slate-800 text-xs text-slate-400 space-y-2">
        <div className="flex items-center gap-2">
          <Database className="w-3.5 h-3.5 text-brand-teal" />
          <span className="font-medium text-slate-300">Dataset Source:</span>
        </div>
        <div className="text-[11px] leading-tight text-slate-400 bg-navy-800 p-2 rounded border border-slate-700">
          6,000 Clean Postings (Synthetic Benchmark in R)
        </div>
        <div className="flex items-center justify-between text-[10px] text-slate-500 pt-1">
          <span>Course: ITA04 Statistics</span>
          <HelpCircle className="w-3.5 h-3.5 hover:text-slate-300 cursor-pointer" />
        </div>
      </div>
    </aside>
  );
};
