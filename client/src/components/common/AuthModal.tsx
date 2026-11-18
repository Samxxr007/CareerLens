import React, { useState } from "react";
import { useAuthStore } from "../../stores/useAuthStore";
import { User, Lock, Mail, Sparkles, X, ShieldCheck } from "lucide-react";

export const AuthModal: React.FC = () => {
  const { isAuthModalOpen, closeAuthModal, login, loginAsGuest, openOnboardingModal } = useAuthStore();
  const [isRegister, setIsRegister] = useState(false);
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  if (!isAuthModalOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const finalName = name.trim() || (isRegister ? "New Professional" : "Alex Morgan");
    const finalEmail = email.trim() || "alex.morgan@careerlens.io";
    login(finalName, finalEmail);
    // If registering, also trigger the onboarding questionnaire
    if (isRegister) {
      setTimeout(() => openOnboardingModal(), 300);
    }
  };

  const handleGuest = () => {
    loginAsGuest();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-navy-950/70 backdrop-blur-xs animate-fade-in">
      <div className="bg-white rounded-2xl shadow-2xl border border-brand-border w-full max-w-md overflow-hidden flex flex-col">
        {/* Header */}
        <div className="bg-navy-900 text-white p-6 relative">
          <button
            onClick={closeAuthModal}
            className="absolute top-5 right-5 text-slate-400 hover:text-white p-1 rounded-lg hover:bg-navy-800 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>

          <div className="flex items-center gap-2 mb-2">
            <div className="w-7 h-7 rounded-lg bg-brand-blue flex items-center justify-center font-bold text-xs text-white">
              CL
            </div>
            <span className="text-xs font-bold text-brand-teal uppercase tracking-widest">
              CareerLens 2.0 Auth
            </span>
          </div>

          <h2 className="text-xl font-bold tracking-tight">
            {isRegister ? "Create Career Account" : "Welcome Back"}
          </h2>
          <p className="text-xs text-slate-300 mt-1">
            Access your personalized career match metrics and predictive salary benchmarks.
          </p>
        </div>

        {/* Body */}
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {isRegister && (
            <div>
              <label className="text-xs font-bold text-slate-700 block mb-1">Full Name</label>
              <div className="relative">
                <User className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
                <input
                  type="text"
                  required
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="e.g. Alex Morgan"
                  className="w-full text-xs pl-9 pr-3 py-2 border border-brand-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-blue"
                />
              </div>
            </div>
          )}

          <div>
            <label className="text-xs font-bold text-slate-700 block mb-1">Work Email</label>
            <div className="relative">
              <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="alex.morgan@careerlens.io"
                className="w-full text-xs pl-9 pr-3 py-2 border border-brand-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-blue"
              />
            </div>
          </div>

          <div>
            <label className="text-xs font-bold text-slate-700 block mb-1">Passcode / Password</label>
            <div className="relative">
              <Lock className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full text-xs pl-9 pr-3 py-2 border border-brand-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-blue"
              />
            </div>
          </div>

          <button
            type="submit"
            className="w-full py-2.5 bg-brand-blue hover:bg-navy-800 text-white rounded-lg text-xs font-bold transition-colors shadow-sm flex items-center justify-center gap-1.5"
          >
            <span>{isRegister ? "Register & Setup Profile" : "Sign In to Platform"}</span>
          </button>

          <div className="relative flex items-center justify-center my-3">
            <div className="border-t border-slate-200 w-full" />
            <span className="bg-white px-2 text-[10px] text-slate-400 uppercase font-bold shrink-0">
              or continue directly
            </span>
          </div>

          <button
            type="button"
            onClick={handleGuest}
            className="w-full py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg text-xs font-semibold transition-colors flex items-center justify-center gap-2 border border-slate-200"
          >
            <Sparkles className="w-3.5 h-3.5 text-brand-teal" />
            <span>Instant Guest Access (Pre-loaded Profile)</span>
          </button>

          <div className="text-center pt-2">
            <button
              type="button"
              onClick={() => setIsRegister(!isRegister)}
              className="text-xs text-brand-blue font-semibold hover:underline"
            >
              {isRegister ? "Already have an account? Sign In" : "Don't have an account? Register & Setup Profile"}
            </button>
          </div>
        </form>

        <div className="bg-slate-50 p-3 border-t border-slate-200 text-[10px] text-slate-500 text-center flex items-center justify-center gap-1">
          <ShieldCheck className="w-3.5 h-3.5 text-brand-teal" />
          <span>Local session storage only. No credentials transmitted to external servers.</span>
        </div>
      </div>
    </div>
  );
};
