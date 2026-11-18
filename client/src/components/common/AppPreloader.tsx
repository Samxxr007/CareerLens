import React, { useEffect, useState } from "react";
import { Sparkles, Database, Binary, CheckCircle } from "lucide-react";

interface AppPreloaderProps {
  onComplete: () => void;
}

export const AppPreloader: React.FC<AppPreloaderProps> = ({ onComplete }) => {
  const [progress, setProgress] = useState(0);
  const [stepIndex, setStepIndex] = useState(0);
  const [fadeOut, setFadeOut] = useState(false);

  const steps = [
    "Mounting R 4.6.1 Plumber statistical service...",
    "Loading 6,000 clean Indian tech job postings...",
    "Pre-calculating multiple linear & logistic models...",
    "Synthesizing candidate skill graph & transferability index...",
    "CareerLens 2.0 Engine Ready."
  ];

  useEffect(() => {
    const timer = setInterval(() => {
      setProgress((prev) => {
        if (prev >= 100) {
          clearInterval(timer);
          setTimeout(() => {
            setFadeOut(true);
            setTimeout(onComplete, 400);
          }, 300);
          return 100;
        }
        const inc = Math.floor(Math.random() * 25) + 15;
        const next = Math.min(100, prev + inc);
        if (next > 20 && next <= 45) setStepIndex(1);
        else if (next > 45 && next <= 75) setStepIndex(2);
        else if (next > 75 && next < 100) setStepIndex(3);
        else if (next === 100) setStepIndex(4);
        return next;
      });
    }, 120);

    return () => clearInterval(timer);
  }, [onComplete]);

  return (
    <div
      className={`fixed inset-0 z-50 flex flex-col items-center justify-center bg-navy-950 text-white transition-opacity duration-500 ${
        fadeOut ? "opacity-0 pointer-events-none" : "opacity-100"
      }`}
    >
      {/* Background glow effects */}
      <div className="absolute w-[500px] h-[500px] rounded-full bg-brand-blue/10 blur-3xl pointer-events-none animate-pulse" />
      <div className="absolute w-[300px] h-[300px] rounded-full bg-brand-teal/10 blur-2xl pointer-events-none" />

      {/* Main card */}
      <div className="relative z-10 w-full max-w-md p-8 text-center space-y-6">
        {/* Animated Brand Emblem */}
        <div className="relative inline-flex items-center justify-center">
          <div className="w-20 h-20 rounded-2xl bg-gradient-to-tr from-brand-blue to-brand-teal p-[2px] shadow-lg shadow-brand-teal/20 animate-spin-slow">
            <div className="w-full h-full bg-navy-900 rounded-2xl flex items-center justify-center">
              <Sparkles className="w-9 h-9 text-brand-teal animate-pulse" />
            </div>
          </div>
          <div className="absolute -bottom-1 -right-1 w-6 h-6 rounded-full bg-emerald-500 border-2 border-navy-950 flex items-center justify-center">
            <Binary className="w-3.5 h-3.5 text-navy-950" />
          </div>
        </div>

        {/* Brand Text */}
        <div className="space-y-1">
          <h1 className="text-2xl font-black tracking-tight text-white flex items-center justify-center gap-2">
            <span>CareerLens</span>
            <span className="text-xs px-2 py-0.5 rounded-full bg-brand-teal text-navy-950 font-bold tracking-normal">
              2.0
            </span>
          </h1>
          <p className="text-xs text-slate-400 font-medium tracking-wide">
            Job Market Intelligence & Career Decision Engine
          </p>
        </div>

        {/* Progress Bar */}
        <div className="space-y-2">
          <div className="w-full h-2 bg-navy-800 rounded-full overflow-hidden p-[1px] border border-slate-700/50">
            <div
              className="h-full bg-gradient-to-r from-brand-blue to-brand-teal rounded-full transition-all duration-200"
              style={{ width: `${progress}%` }}
            />
          </div>
          <div className="flex justify-between items-center text-[11px] text-slate-400 font-mono">
            <span className="truncate pr-2 flex items-center gap-1.5">
              {progress === 100 ? (
                <CheckCircle className="w-3.5 h-3.5 text-emerald-400 shrink-0" />
              ) : (
                <Database className="w-3.5 h-3.5 text-brand-teal animate-pulse shrink-0" />
              )}
              <span>{steps[stepIndex]}</span>
            </span>
            <span className="font-bold text-brand-teal">{progress}%</span>
          </div>
        </div>

        {/* Academic Course watermark */}
        <div className="text-[10px] text-slate-500 pt-2 border-t border-slate-800 flex justify-between items-center">
          <span>ITA04 Statistics with R</span>
          <span>6,000 Postings Benchmark</span>
        </div>
      </div>
    </div>
  );
};
