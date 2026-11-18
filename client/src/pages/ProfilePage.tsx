import React, { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useProfileStore } from "../stores/useProfileStore";
import { useAuthStore } from "../stores/useAuthStore";
import { fetchMetadata } from "../services/api";
import { SkillChip } from "../components/common/SkillChip";
import { Plus, RotateCcw, Download, Upload, CheckCircle2, UserCheck, FormInput } from "lucide-react";

export const ProfilePage: React.FC = () => {
  const { profile, setProfile, addSkill, removeSkill, resetProfile } = useProfileStore();
  const { openOnboardingModal } = useAuthStore();
  const [newSkillInput, setNewSkillInput] = useState("");
  const [saveToast, setSaveToast] = useState(false);

  const { data: metadata } = useQuery({
    queryKey: ["metadata"],
    queryFn: fetchMetadata
  });

  const availableRoles = Array.isArray(metadata?.roles) && metadata.roles.length > 0
    ? metadata.roles
    : [
        "Data Analyst",
        "Data Scientist",
        "Data Engineer",
        "Business Analyst",
        "Software Engineer",
        "Frontend Developer",
        "Backend Developer",
        "Full Stack Developer",
        "DevOps Engineer",
        "Machine Learning Engineer"
      ];

  const availableLocations = Array.isArray(metadata?.locations) && metadata.locations.length > 0
    ? metadata.locations
    : ["Bengaluru", "Hyderabad", "Pune", "Mumbai", "Chennai", "Delhi NCR"];

  const availableEducations = Array.isArray(metadata?.educations) && metadata.educations.length > 0
    ? metadata.educations
    : ["B.Tech", "B.E.", "BCA", "MCA", "M.Tech", "MBA", "B.Sc", "M.Sc", "Ph.D"];

  const handleAddSkill = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newSkillInput.trim()) return;
    addSkill(newSkillInput.trim());
    setNewSkillInput("");
    triggerSaveToast();
  };

  const handleSkillClickFromSuggestions = (sk: string) => {
    addSkill(sk);
    triggerSaveToast();
  };

  const triggerSaveToast = () => {
    setSaveToast(true);
    setTimeout(() => setSaveToast(false), 2500);
  };

  const handleExportJSON = () => {
    const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(profile, null, 2));
    const downloadAnchor = document.createElement("a");
    downloadAnchor.setAttribute("href", dataStr);
    downloadAnchor.setAttribute("download", `careerlens_profile_${profile.targetRole.replace(/\s+/g, "_")}.json`);
    document.body.appendChild(downloadAnchor);
    downloadAnchor.click();
    downloadAnchor.remove();
  };

  const handleImportJSON = (e: React.ChangeEvent<HTMLInputElement>) => {
    const fileReader = new FileReader();
    if (e.target.files && e.target.files[0]) {
      fileReader.readAsText(e.target.files[0], "UTF-8");
      fileReader.onload = (event) => {
        try {
          const parsed = JSON.parse(event.target?.result as string);
          if (parsed && Array.isArray(parsed.skills)) {
            setProfile(parsed);
            triggerSaveToast();
          }
        } catch (err) {
          alert("Invalid profile JSON file format.");
        }
      };
    }
  };

  const popularSuggestions = [
    "Python", "SQL", "Excel", "Power BI", "Tableau", "R", "Pandas", "NumPy",
    "AWS", "Docker", "Machine Learning", "Statistics", "Git", "Java", "React"
  ].filter((s) => !profile.skills.includes(s));

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-5 rounded-xl border border-brand-border shadow-sm">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-brand-blue text-white flex items-center justify-center font-bold">
            <UserCheck className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-xl font-bold text-navy-900 leading-none">Candidate Profile & Skill Inventory</h2>
            <p className="text-xs text-brand-textSecondary mt-1">
              Changes update analytical insights reactively without requiring full page refreshes.
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={openOnboardingModal}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-brand-teal text-navy-950 text-xs font-bold hover:bg-emerald-400 transition-colors shadow-2xs"
          >
            <FormInput className="w-3.5 h-3.5" />
            <span>Launch Details Form</span>
          </button>
          <label className="cursor-pointer inline-flex items-center gap-1.5 px-3 py-1.5 border border-brand-border rounded-lg text-xs font-semibold text-slate-700 bg-slate-50 hover:bg-slate-100 transition-colors">
            <Upload className="w-3.5 h-3.5" />
            <span>Import JSON</span>
            <input type="file" accept=".json" onChange={handleImportJSON} className="hidden" />
          </label>
          <button
            type="button"
            onClick={handleExportJSON}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 border border-brand-border rounded-lg text-xs font-semibold text-slate-700 bg-slate-50 hover:bg-slate-100 transition-colors"
          >
            <Download className="w-3.5 h-3.5" />
            <span>Export</span>
          </button>
          <button
            type="button"
            onClick={() => {
              if (confirm("Reset profile to default demo settings?")) resetProfile();
            }}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 border border-brand-border rounded-lg text-xs font-semibold text-rose-700 bg-rose-50 hover:bg-rose-100 transition-colors"
          >
            <RotateCcw className="w-3.5 h-3.5" />
            <span>Reset</span>
          </button>
        </div>
      </div>

      {saveToast && (
        <div className="bg-emerald-50 border border-emerald-300 text-emerald-800 text-xs font-semibold px-4 py-2.5 rounded-lg flex items-center gap-2 shadow-sm animate-fade-in">
          <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
          <span>Profile saved! Real-time analytical models recalculated.</span>
        </div>
      )}

      {/* Profile Form */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Core Parameters */}
        <div className="bg-white p-5 rounded-xl border border-brand-border shadow-sm space-y-4">
          <h3 className="font-bold text-navy-900 text-sm border-b border-slate-100 pb-2">Target Career Role</h3>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">Primary Target Role</label>
            <select
              value={profile.targetRole}
              onChange={(e) => {
                setProfile({ targetRole: e.target.value });
                triggerSaveToast();
              }}
              className="w-full text-sm border border-brand-border rounded-lg px-3 py-2 bg-white focus:outline-none focus:ring-2 focus:ring-brand-blue"
            >
              {availableRoles.map((r: string) => (
                <option key={r} value={r}>
                  {r}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">Alternative Career Interest</label>
            <select
              value={profile.alternativeRole || ""}
              onChange={(e) => {
                setProfile({ alternativeRole: e.target.value });
                triggerSaveToast();
              }}
              className="w-full text-sm border border-brand-border rounded-lg px-3 py-2 bg-white focus:outline-none focus:ring-2 focus:ring-brand-blue"
            >
              <option value="">None / Open to suggestions</option>
              {availableRoles.map((r: string) => (
                <option key={r} value={r}>
                  {r}
                </option>
              ))}
            </select>
          </div>

          <div className="pt-2 border-t border-slate-100">
            <div className="flex items-center justify-between mb-1">
              <label className="text-xs font-semibold text-slate-700">Years of Experience</label>
              <span className="text-sm font-bold text-brand-blue">{profile.experience} years</span>
            </div>
            <input
              type="range"
              min="0"
              max="20"
              value={profile.experience}
              onChange={(e) => {
                setProfile({ experience: parseInt(e.target.value, 10) });
                triggerSaveToast();
              }}
              className="w-full h-2 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-brand-blue"
            />
            <div className="flex justify-between text-[10px] text-slate-400 mt-1">
              <span>0 (Fresher)</span>
              <span>5 yrs</span>
              <span>10 yrs</span>
              <span>20+ yrs</span>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3 pt-2">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Highest Education</label>
              <select
                value={profile.education}
                onChange={(e) => {
                  setProfile({ education: e.target.value });
                  triggerSaveToast();
                }}
                className="w-full text-sm border border-brand-border rounded-lg px-3 py-2 bg-white focus:outline-none focus:ring-2 focus:ring-brand-blue"
              >
                {availableEducations.map((e: string) => (
                  <option key={e} value={e}>
                    {e}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Preferred Location</label>
              <select
                value={profile.location}
                onChange={(e) => {
                  setProfile({ location: e.target.value });
                  triggerSaveToast();
                }}
                className="w-full text-sm border border-brand-border rounded-lg px-3 py-2 bg-white focus:outline-none focus:ring-2 focus:ring-brand-blue"
              >
                {availableLocations.map((l: string) => (
                  <option key={l} value={l}>
                    {l}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>

        {/* Skill Inventory */}
        <div className="bg-white p-5 rounded-xl border border-brand-border shadow-sm space-y-4">
          <div className="flex items-center justify-between border-b border-slate-100 pb-2">
            <h3 className="font-bold text-navy-900 text-sm">Skills & Tool Repertoire</h3>
            <span className="text-xs bg-slate-100 text-slate-700 font-bold px-2 py-0.5 rounded-full">
              {profile.skills.length} Skills
            </span>
          </div>

          {/* Add Skill Input */}
          <form onSubmit={handleAddSkill} className="flex gap-2">
            <input
              type="text"
              value={newSkillInput}
              onChange={(e) => setNewSkillInput(e.target.value)}
              placeholder="Add skill (e.g., Power BI, Docker, PyTorch)..."
              className="flex-1 text-sm border border-brand-border rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-blue"
            />
            <button
              type="submit"
              className="bg-brand-blue hover:bg-navy-800 text-white px-4 py-2 rounded-lg text-xs font-semibold flex items-center gap-1 transition-colors"
            >
              <Plus className="w-3.5 h-3.5" />
              <span>Add</span>
            </button>
          </form>

          {/* Current Skills List */}
          <div className="min-h-[120px] p-3 rounded-lg border border-slate-200 bg-slate-50/50 flex flex-wrap gap-2 content-start">
            {profile.skills.length === 0 ? (
              <span className="text-xs text-slate-400 italic">No skills added yet. Add your current competencies above.</span>
            ) : (
              profile.skills.map((s) => (
                <SkillChip
                  key={s}
                  skill={s}
                  onRemove={() => {
                    removeSkill(s);
                    triggerSaveToast();
                  }}
                  variant="matched"
                />
              ))
            )}
          </div>

          {/* Quick Suggestions */}
          {popularSuggestions.length > 0 && (
            <div>
              <span className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider block mb-1.5">
                Quick Add Suggestions:
              </span>
              <div className="flex flex-wrap gap-1.5">
                {popularSuggestions.slice(0, 8).map((s) => (
                  <button
                    key={s}
                    type="button"
                    onClick={() => handleSkillClickFromSuggestions(s)}
                    className="text-xs bg-white border border-brand-border hover:border-brand-blue hover:text-brand-blue px-2 py-0.5 rounded transition-all flex items-center gap-1"
                  >
                    <Plus className="w-3 h-3 text-slate-400" />
                    <span>{s}</span>
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
