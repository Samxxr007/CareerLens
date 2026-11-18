import React, { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useProfileStore } from "../../stores/useProfileStore";
import { useAuthStore } from "../../stores/useAuthStore";
import { fetchMetadata } from "../../services/api";
import {
  User,
  Compass,
  GraduationCap,
  MapPin,
  CheckCircle2,
  ArrowRight,
  ArrowLeft,
  X,
  Plus,
  Sparkles
} from "lucide-react";

export const OnboardingModal: React.FC = () => {
  const { profile, setProfile } = useProfileStore();
  const { user, login, isOnboardingModalOpen, closeOnboardingModal, setCompletedOnboarding } = useAuthStore();

  const { data: meta } = useQuery({
    queryKey: ["metadata"],
    queryFn: fetchMetadata
  });

  const [step, setStep] = useState<1 | 2 | 3 | 4>(1);

  // Form State initialized from current profile & user
  const [fullName, setFullName] = useState(user?.name || profile.fullName || "Alex Morgan");
  const [email, setEmail] = useState(user?.email || "alex.morgan@careerlens.io");
  const [targetRole, setTargetRole] = useState(profile.targetRole || "Data Analyst");
  const [alternativeRole, setAlternativeRole] = useState(profile.alternativeRole || "Data Scientist");
  const [experience, setExperience] = useState(profile.experience || 2);
  const [education, setEducation] = useState(profile.education || "B.Tech");
  const [location, setLocation] = useState(profile.location || "Bengaluru");
  const [workArrangement, setWorkArrangement] = useState(profile.workArrangement || "Hybrid");
  const [companySize, setCompanySize] = useState("Large");
  const [skills, setSkills] = useState<string[]>(
    profile.skills.length > 0 ? [...profile.skills] : ["Python", "SQL", "Excel"]
  );
  const [customSkillInput, setCustomSkillInput] = useState("");

  if (!isOnboardingModalOpen) return null;

  const popularSkills = [
    "Python",
    "SQL",
    "Excel",
    "Tableau",
    "Power BI",
    "R",
    "Pandas",
    "NumPy",
    "AWS",
    "Git",
    "Machine Learning",
    "scikit-learn",
    "Docker",
    "JavaScript",
    "Communication"
  ];

  const handleToggleSkill = (skill: string) => {
    if (skills.includes(skill)) {
      setSkills(skills.filter((s) => s !== skill));
    } else {
      setSkills([...skills, skill]);
    }
  };

  const handleAddCustomSkill = (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = customSkillInput.trim();
    if (trimmed && !skills.includes(trimmed)) {
      setSkills([...skills, trimmed]);
      setCustomSkillInput("");
    }
  };

  const handleSubmit = () => {
    // Save to Profile Store
    setProfile({
      fullName,
      targetRole,
      alternativeRole,
      experience,
      education,
      location,
      workArrangement,
      skills: [...skills]
    });

    // Update Auth user name/email
    if (user) {
      login(fullName, email);
    }

    setCompletedOnboarding(true);
    closeOnboardingModal();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-navy-950/70 backdrop-blur-xs animate-fade-in">
      <div className="bg-white rounded-2xl shadow-2xl border border-brand-border w-full max-w-2xl overflow-hidden flex flex-col max-h-[90vh]">
        {/* Header with Step Progress */}
        <div className="bg-navy-900 text-white p-6 relative">
          <button
            onClick={closeOnboardingModal}
            className="absolute top-5 right-5 text-slate-400 hover:text-white p-1 rounded-lg hover:bg-navy-800 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>

          <div className="flex items-center gap-2 mb-2">
            <span className="w-7 h-7 rounded-lg bg-brand-blue flex items-center justify-center text-xs font-bold text-white shadow-xs">
              CL
            </span>
            <span className="text-xs font-bold text-brand-teal uppercase tracking-widest">
              Candidate Profile Setup
            </span>
          </div>

          <h2 className="text-xl font-bold tracking-tight">
            {step === 1 && "Personal Identity & Target Role"}
            {step === 2 && "Education & Experience Profile"}
            {step === 3 && "Technical Skill Repertoire"}
            {step === 4 && "Work & Workplace Preferences"}
          </h2>
          <p className="text-xs text-slate-300 mt-1">
            Step {step} of 4 — Calibrating your baseline for 6,000 live market postings.
          </p>

          {/* Stepper bar */}
          <div className="grid grid-cols-4 gap-2 mt-4">
            {[1, 2, 3, 4].map((s) => (
              <div
                key={s}
                className={`h-1.5 rounded-full transition-all ${
                  s <= step ? "bg-brand-teal" : "bg-navy-800"
                }`}
              />
            ))}
          </div>
        </div>

        {/* Step Contents */}
        <div className="p-6 overflow-y-auto flex-1 space-y-5">
          {/* STEP 1: IDENTITY & TARGET */}
          {step === 1 && (
            <div className="space-y-4 animate-fade-in">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">Full Name</label>
                  <div className="relative">
                    <User className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
                    <input
                      type="text"
                      value={fullName}
                      onChange={(e) => setFullName(e.target.value)}
                      placeholder="e.g. Alex Morgan"
                      className="w-full text-xs pl-9 pr-3 py-2 border border-brand-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-blue"
                    />
                  </div>
                </div>

                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">Email Address</label>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="e.g. alex@example.com"
                    className="w-full text-xs px-3 py-2 border border-brand-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-blue"
                  />
                </div>
              </div>

              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">
                  Primary Target Career Role
                </label>
                <div className="relative">
                  <Compass className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
                  <select
                    value={targetRole}
                    onChange={(e) => setTargetRole(e.target.value)}
                    className="w-full text-xs pl-9 pr-3 py-2 border border-brand-border rounded-lg bg-white font-medium focus:outline-none focus:ring-2 focus:ring-brand-blue"
                  >
                    {meta?.roles ? (
                      meta.roles.map((r: string) => (
                        <option key={r} value={r}>
                          {r}
                        </option>
                      ))
                    ) : (
                      <>
                        <option value="Data Analyst">Data Analyst</option>
                        <option value="Data Scientist">Data Scientist</option>
                        <option value="Software Engineer">Software Engineer</option>
                        <option value="Frontend Developer">Frontend Developer</option>
                        <option value="Backend Developer">Backend Developer</option>
                        <option value="Devops Engineer">Devops Engineer</option>
                        <option value="Business Analyst">Business Analyst</option>
                      </>
                    )}
                  </select>
                </div>
                <span className="text-[11px] text-slate-400 mt-1 block">
                  All match percentages and skill gap priorities are evaluated against this role.
                </span>
              </div>

              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">
                  Alternative Career Interest (for Side-by-Side Comparison)
                </label>
                <select
                  value={alternativeRole}
                  onChange={(e) => setAlternativeRole(e.target.value)}
                  className="w-full text-xs px-3 py-2 border border-brand-border rounded-lg bg-white font-medium"
                >
                  {meta?.roles ? (
                    meta.roles.map((r: string) => (
                      <option key={r} value={r}>
                        {r}
                      </option>
                    ))
                  ) : (
                    <>
                      <option value="Data Scientist">Data Scientist</option>
                      <option value="Software Engineer">Software Engineer</option>
                      <option value="Business Analyst">Business Analyst</option>
                    </>
                  )}
                </select>
              </div>
            </div>
          )}

          {/* STEP 2: EDUCATION & EXPERIENCE */}
          {step === 2 && (
            <div className="space-y-5 animate-fade-in">
              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">
                  Highest Completed or Pursued Degree
                </label>
                <div className="relative">
                  <GraduationCap className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
                  <select
                    value={education}
                    onChange={(e) => setEducation(e.target.value)}
                    className="w-full text-xs pl-9 pr-3 py-2 border border-brand-border rounded-lg bg-white font-medium"
                  >
                    <option value="B.Tech">B.Tech (Bachelor of Technology)</option>
                    <option value="B.E.">B.E. (Bachelor of Engineering)</option>
                    <option value="MCA">MCA (Master of Computer Applications)</option>
                    <option value="BCA">BCA (Bachelor of Computer Applications)</option>
                    <option value="M.Tech">M.Tech (Master of Technology)</option>
                    <option value="MBA">MBA (Master of Business Administration)</option>
                    <option value="B.Sc">B.Sc (Bachelor of Science)</option>
                    <option value="M.Sc">M.Sc (Master of Science)</option>
                    <option value="Ph.D">Ph.D (Doctorate)</option>
                  </select>
                </div>
              </div>

              <div>
                <div className="flex justify-between items-center text-xs font-bold text-slate-700 mb-1.5">
                  <span>Total Professional Experience</span>
                  <span className="text-brand-blue font-extrabold text-sm">{experience} Years</span>
                </div>
                <input
                  type="range"
                  min="0"
                  max="20"
                  value={experience}
                  onChange={(e) => setExperience(parseInt(e.target.value))}
                  className="w-full h-2 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-brand-blue"
                />
                <div className="flex justify-between text-[11px] text-slate-400 mt-1">
                  <span>0 yrs (Fresh Graduate)</span>
                  <span>5 yrs (Mid-Level)</span>
                  <span>10+ yrs (Senior)</span>
                  <span>20 yrs</span>
                </div>
              </div>

              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">Preferred Location Hub</label>
                <div className="relative">
                  <MapPin className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
                  <select
                    value={location}
                    onChange={(e) => setLocation(e.target.value)}
                    className="w-full text-xs pl-9 pr-3 py-2 border border-brand-border rounded-lg bg-white font-medium"
                  >
                    <option value="Bengaluru">Bengaluru (Tier 1)</option>
                    <option value="Hyderabad">Hyderabad (Tier 1)</option>
                    <option value="Pune">Pune (Tier 2)</option>
                    <option value="Mumbai">Mumbai (Tier 1)</option>
                    <option value="Delhi NCR">Delhi NCR (Tier 1)</option>
                    <option value="Chennai">Chennai (Tier 2)</option>
                    <option value="Kolkata">Kolkata (Tier 2)</option>
                    <option value="Remote">Pan-India Remote</option>
                  </select>
                </div>
              </div>
            </div>
          )}

          {/* STEP 3: TECHNICAL SKILLS */}
          {step === 3 && (
            <div className="space-y-4 animate-fade-in">
              <div className="flex justify-between items-center">
                <label className="text-xs font-bold text-slate-700">
                  Select Your Current Verified Skills ({skills.length} selected):
                </label>
                <span className="text-[11px] text-brand-blue font-semibold">
                  Click to add/remove
                </span>
              </div>

              {/* Popular skills clicker */}
              <div className="flex flex-wrap gap-1.5 max-h-44 overflow-y-auto p-2 bg-slate-50 rounded-lg border border-slate-200">
                {popularSkills.map((sk) => {
                  const isSelected = skills.includes(sk);
                  return (
                    <button
                      key={sk}
                      type="button"
                      onClick={() => handleToggleSkill(sk)}
                      className={`text-xs px-3 py-1.5 rounded-lg font-medium transition-all flex items-center gap-1.5 border ${
                        isSelected
                          ? "bg-brand-blue text-white border-brand-blue shadow-2xs font-semibold"
                          : "bg-white text-slate-700 border-slate-200 hover:border-slate-400"
                      }`}
                    >
                      {isSelected && <CheckCircle2 className="w-3.5 h-3.5 text-brand-teal" />}
                      <span>{sk}</span>
                    </button>
                  );
                })}
              </div>

              {/* Custom skill input */}
              <form onSubmit={handleAddCustomSkill} className="flex gap-2">
                <input
                  type="text"
                  value={customSkillInput}
                  onChange={(e) => setCustomSkillInput(e.target.value)}
                  placeholder="Add custom skill (e.g. PyTorch, Kubernetes, GCP)..."
                  className="flex-1 text-xs px-3 py-2 border border-brand-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-blue"
                />
                <button
                  type="submit"
                  className="bg-brand-teal hover:bg-emerald-600 text-white px-3.5 py-2 rounded-lg text-xs font-semibold flex items-center gap-1 transition-colors"
                >
                  <Plus className="w-3.5 h-3.5" />
                  <span>Add Skill</span>
                </button>
              </form>

              {/* Selected skills preview */}
              <div>
                <span className="text-[11px] text-slate-500 uppercase tracking-wider font-bold block mb-1">
                  Active Repertoire:
                </span>
                <div className="flex flex-wrap gap-1">
                  {skills.map((s) => (
                    <span
                      key={s}
                      className="px-2 py-0.5 rounded bg-slate-200 text-slate-800 text-[11px] font-semibold flex items-center gap-1"
                    >
                      <span>{s}</span>
                      <button
                        type="button"
                        onClick={() => handleToggleSkill(s)}
                        className="hover:text-rose-600 text-slate-500 text-xs ml-0.5"
                      >
                        ×
                      </button>
                    </span>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* STEP 4: PREFERENCES */}
          {step === 4 && (
            <div className="space-y-5 animate-fade-in">
              <div>
                <label className="text-xs font-bold text-slate-700 block mb-2">
                  Preferred Work Arrangement
                </label>
                <div className="grid grid-cols-3 gap-3">
                  {["Hybrid", "Remote", "On-site"].map((m) => (
                    <button
                      key={m}
                      type="button"
                      onClick={() => setWorkArrangement(m)}
                      className={`p-3 rounded-xl border text-center text-xs font-semibold transition-all ${
                        workArrangement === m
                          ? "bg-brand-blue/10 border-brand-blue text-brand-blue shadow-2xs"
                          : "border-slate-200 text-slate-600 hover:bg-slate-50"
                      }`}
                    >
                      {m}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="text-xs font-bold text-slate-700 block mb-2">
                  Target Company Scale
                </label>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                  {[
                    { label: "Small", sub: "< 50 team" },
                    { label: "Medium", sub: "50-250 team" },
                    { label: "Large", sub: "250-1000 team" },
                    { label: "Enterprise", sub: "1000+ global" }
                  ].map((c) => (
                    <button
                      key={c.label}
                      type="button"
                      onClick={() => setCompanySize(c.label)}
                      className={`p-2.5 rounded-xl border text-center transition-all ${
                        companySize === c.label
                          ? "bg-brand-blue/10 border-brand-blue text-brand-blue font-bold shadow-2xs"
                          : "border-slate-200 text-slate-600 hover:bg-slate-50"
                      }`}
                    >
                      <div className="text-xs font-semibold">{c.label}</div>
                      <div className="text-[10px] text-slate-400">{c.sub}</div>
                    </button>
                  ))}
                </div>
              </div>

              {/* Profile Summary Card */}
              <div className="p-4 bg-emerald-50/70 border border-emerald-200 rounded-xl text-xs space-y-1.5">
                <div className="font-bold text-emerald-950 flex items-center gap-1.5">
                  <CheckCircle2 className="w-4 h-4 text-emerald-700" />
                  <span>Ready to Calibrate Career Intelligence Platform</span>
                </div>
                <p className="text-emerald-900 leading-relaxed text-[11px]">
                  Configuring statistical engine for <strong>{fullName}</strong> targeting <strong>{targetRole}</strong> with <strong>{skills.length} skills</strong> and <strong>{experience} years experience</strong>.
                </p>
              </div>
            </div>
          )}
        </div>

        {/* Footer Navigation */}
        <div className="bg-slate-50 p-4 border-t border-slate-200 flex items-center justify-between">
          {step > 1 ? (
            <button
              type="button"
              onClick={() => setStep((prev) => (prev - 1) as any)}
              className="inline-flex items-center gap-1 px-4 py-2 rounded-lg border border-slate-300 text-slate-700 text-xs font-semibold hover:bg-slate-100 transition-colors"
            >
              <ArrowLeft className="w-3.5 h-3.5" />
              <span>Back</span>
            </button>
          ) : (
            <div />
          )}

          {step < 4 ? (
            <button
              type="button"
              onClick={() => setStep((prev) => (prev + 1) as any)}
              className="inline-flex items-center gap-1.5 px-5 py-2 rounded-lg bg-brand-blue text-white text-xs font-semibold hover:bg-navy-800 transition-colors shadow-sm"
            >
              <span>Continue</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          ) : (
            <button
              type="button"
              onClick={handleSubmit}
              className="inline-flex items-center gap-1.5 px-6 py-2 rounded-lg bg-emerald-600 text-white text-xs font-bold hover:bg-emerald-700 transition-colors shadow-sm"
            >
              <Sparkles className="w-3.5 h-3.5 text-white" />
              <span>Save & Launch Career Intelligence</span>
            </button>
          )}
        </div>
      </div>
    </div>
  );
};
