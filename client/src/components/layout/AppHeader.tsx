import React from "react";
import { useLocation } from "react-router-dom";
import { useProfileStore } from "../../stores/useProfileStore";
import { useAuthStore } from "../../stores/useAuthStore";
import { ShieldCheck, Settings, LogIn, LogOut } from "lucide-react";

export const AppHeader: React.FC = () => {
  const location = useLocation();
  const { profile } = useProfileStore();
  const { user, isAuthenticated, logout, openAuthModal, openOnboardingModal } = useAuthStore();

  const getPageTitle = (path: string) => {
    switch (path) {
      case "/":
        return "Career Intelligence Overview";
      case "/profile":
        return "1. Candidate Profile & Inventory";
      case "/market-intelligence":
        return "2. Market Evidence & Intelligence";
      case "/career-explorer":
        return "3. Career Explorer & Match Rankings";
      case "/skill-intelligence":
        return "4-5. Skill Gaps & Recommendation Engine";
      case "/what-if-lab":
        return "6. What-If Scenario Lab";
      case "/job-analyzer":
        return "7. Job Description Analyzer";
      case "/salary-lab":
        return "8. Salary & Regression Prediction Lab";
      case "/career-decision":
        return "9. Informed Career Decision Support";
      case "/roadmap":
        return "AI Roadmap Generator (Groq Powered)";
      case "/data-quality":
        return "Data Quality & Analytical Audit";
      default:
        return "CareerLens 2.0";
    }
  };

  return (
    <header className="h-[68px] bg-white border-b border-brand-border px-8 flex items-center justify-between shrink-0">
      <div>
        <h1 className="text-lg font-bold text-navy-900 leading-none">
          {getPageTitle(location.pathname)}
        </h1>
        <p className="text-xs text-brand-textSecondary mt-1">
          Active Role: <span className="font-semibold text-brand-blue">{profile.targetRole}</span> | Skills:{" "}
          <span className="font-semibold text-slate-800">{profile.skills.length} tracked</span>
        </p>
      </div>

      <div className="flex items-center gap-3">
        {/* R Engine Badge */}
        <div className="hidden sm:flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs font-medium">
          <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
          <span>R Engine Connected</span>
        </div>

        {/* Onboarding / Personal Details Button */}
        <button
          onClick={openOnboardingModal}
          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-brand-teal text-navy-950 text-xs font-bold hover:bg-emerald-400 transition-all shadow-xs"
          title="Open guided form to update all personal and career details"
        >
          <Settings className="w-3.5 h-3.5" />
          <span>Personal Details Form</span>
        </button>

        {/* User Auth Section */}
        {isAuthenticated && user ? (
          <div className="flex items-center gap-2 pl-3 border-l border-brand-border">
            <div className="w-8 h-8 rounded-full bg-navy-900 text-white flex items-center justify-center font-bold text-xs ring-2 ring-brand-blue/30 shrink-0">
              {user.name.charAt(0).toUpperCase()}
            </div>
            <div className="text-left text-xs hidden lg:block">
              <div className="font-semibold text-navy-900 leading-none">{user.name}</div>
              <div className="text-[10px] text-brand-textSecondary mt-0.5">
                {profile.education} • {profile.experience}y exp
              </div>
            </div>
            <button
              onClick={() => logout()}
              title="Sign Out & Switch Account"
              className="flex items-center gap-1 text-slate-500 hover:text-rose-600 px-2.5 py-1.5 rounded-lg text-xs font-semibold hover:bg-rose-50 transition-colors ml-1 border border-slate-200"
            >
              <LogOut className="w-3.5 h-3.5 text-rose-500" />
              <span>Sign Out</span>
            </button>
          </div>
        ) : (
          <div className="pl-3 border-l border-brand-border">
            <button
              onClick={openAuthModal}
              className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-lg bg-navy-900 text-white text-xs font-bold hover:bg-navy-800 transition-colors shadow-sm"
            >
              <LogIn className="w-3.5 h-3.5 text-brand-teal" />
              <span>Sign In</span>
            </button>
          </div>
        )}
      </div>
    </header>
  );
};
