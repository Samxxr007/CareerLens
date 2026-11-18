import { Router, Request, Response } from "express";
import axios from "axios";
import { config } from "../config/env.js";
import { rPlumberService } from "../services/rPlumber.service.js";

export const apiRouter = Router();

const wrapResponse = (data: any, startTime: number) => ({
  success: true,
  data,
  meta: {
    source: "synthetic",
    generated_at: new Date().toISOString(),
    processing_time_ms: Date.now() - startTime
  }
});

const handleError = (res: Response, err: any, code = "SERVER_ERROR") => {
  console.error(`[API Error] ${code}:`, err.message || err);
  res.status(500).json({
    success: false,
    error: {
      code,
      message: err.message || "An unexpected error occurred while communicating with the statistical engine."
    }
  });
};

// Health Check
apiRouter.get("/health", async (req: Request, res: Response) => {
  const start = Date.now();
  const rHealth = await rPlumberService.checkHealth();
  res.json({
    node_server: "healthy",
    r_plumber: rHealth,
    timestamp: new Date().toISOString()
  });
});

// Metadata
apiRouter.get("/metadata", async (req: Request, res: Response) => {
  const start = Date.now();
  try {
    const data = await rPlumberService.getMetadata();
    res.json(wrapResponse(data, start));
  } catch (err: any) {
    handleError(res, err, "METADATA_FETCH_FAILED");
  }
});

// Market Overview
apiRouter.get("/market/overview", async (req: Request, res: Response) => {
  const start = Date.now();
  try {
    const { location, role, industry } = req.query as any;
    const data = await rPlumberService.getMarketOverview({ location, role, industry });
    res.json(wrapResponse(data, start));
  } catch (err: any) {
    handleError(res, err, "MARKET_OVERVIEW_FAILED");
  }
});

// Market Skills
apiRouter.get("/market/skills", async (req: Request, res: Response) => {
  const start = Date.now();
  try {
    const { top, role } = req.query as any;
    const data = await rPlumberService.getMarketSkills({ top: top ? parseInt(top) : 25, role });
    res.json(wrapResponse(data, start));
  } catch (err: any) {
    handleError(res, err, "MARKET_SKILLS_FAILED");
  }
});

// Market Salary
apiRouter.get("/market/salary", async (req: Request, res: Response) => {
  const start = Date.now();
  try {
    const data = await rPlumberService.getMarketSalary();
    res.json(wrapResponse(data, start));
  } catch (err: any) {
    handleError(res, err, "MARKET_SALARY_FAILED");
  }
});

// Market Correlation
apiRouter.get("/market/correlation", async (req: Request, res: Response) => {
  const start = Date.now();
  try {
    const data = await rPlumberService.getMarketCorrelation();
    res.json(wrapResponse(data, start));
  } catch (err: any) {
    handleError(res, err, "MARKET_CORRELATION_FAILED");
  }
});

// Career Matches Shortlist
apiRouter.post("/career/matches", async (req: Request, res: Response) => {
  const start = Date.now();
  try {
    const { skills, min_postings } = req.body;
    const data = await rPlumberService.analyzeCareerMatches({ skills: skills || [], min_postings });
    res.json(wrapResponse(data, start));
  } catch (err: any) {
    handleError(res, err, "CAREER_MATCHES_FAILED");
  }
});

// Detailed Role Match
apiRouter.post("/career/detail", async (req: Request, res: Response) => {
  const start = Date.now();
  try {
    const { skills, role, experience } = req.body;
    if (!role) {
      return res.status(400).json({ success: false, error: { code: "VALIDATION_ERROR", message: "A target role is required." } });
    }
    const data = await rPlumberService.getCareerDetail({ skills: skills || [], role, experience });
    res.json(wrapResponse(data, start));
  } catch (err: any) {
    handleError(res, err, "CAREER_DETAIL_FAILED");
  }
});

// Career Comparison
apiRouter.post("/career/compare", async (req: Request, res: Response) => {
  const start = Date.now();
  try {
    const { skills, role_a, role_b } = req.body;
    if (!role_a || !role_b) {
      return res.status(400).json({ success: false, error: { code: "VALIDATION_ERROR", message: "Both Role A and Role B are required for comparison." } });
    }
    const data = await rPlumberService.compareCareers({ skills: skills || [], role_a, role_b });
    res.json(wrapResponse(data, start));
  } catch (err: any) {
    handleError(res, err, "CAREER_COMPARISON_FAILED");
  }
});

// Skill Gap
apiRouter.post("/skills/gap", async (req: Request, res: Response) => {
  const start = Date.now();
  try {
    const { skills, role } = req.body;
    if (!role) {
      return res.status(400).json({ success: false, error: { code: "VALIDATION_ERROR", message: "A target role is required." } });
    }
    const data = await rPlumberService.analyzeSkillGap({ skills: skills || [], role });
    res.json(wrapResponse(data, start));
  } catch (err: any) {
    handleError(res, err, "SKILL_GAP_FAILED");
  }
});

// What-If Simulation
apiRouter.post("/skills/simulate", async (req: Request, res: Response) => {
  const start = Date.now();
  try {
    const { current_skills, proposed_skills, role } = req.body;
    if (!role) {
      return res.status(400).json({ success: false, error: { code: "VALIDATION_ERROR", message: "A target role is required." } });
    }
    const data = await rPlumberService.simulateSkills({
      current_skills: current_skills || [],
      proposed_skills: proposed_skills || [],
      role
    });
    res.json(wrapResponse(data, start));
  } catch (err: any) {
    handleError(res, err, "SKILLS_SIMULATION_FAILED");
  }
});

// Job Description Analysis
apiRouter.post("/job-description/analyze", async (req: Request, res: Response) => {
  const start = Date.now();
  try {
    const { text, candidate_skills, target_role } = req.body;
    const data = await rPlumberService.analyzeJobDescription({
      text: text || "",
      candidate_skills: candidate_skills || [],
      target_role: target_role || "Data Analyst"
    });
    res.json(wrapResponse(data, start));
  } catch (err: any) {
    handleError(res, err, "JD_ANALYSIS_FAILED");
  }
});

// Salary Prediction
apiRouter.post("/salary/predict", async (req: Request, res: Response) => {
  const start = Date.now();
  try {
    const { experience, skill_count, education, company_size, location_tier } = req.body;
    const data = await rPlumberService.predictSalary({
      experience: experience !== undefined ? Number(experience) : 4,
      skill_count: skill_count !== undefined ? Number(skill_count) : 6,
      education: education || "B.Tech",
      company_size: company_size || "Large",
      location_tier: location_tier || "Tier 1"
    });
    res.json(wrapResponse(data, start));
  } catch (err: any) {
    handleError(res, err, "SALARY_PREDICTION_FAILED");
  }
});

// Data Quality
apiRouter.get("/data-quality", async (req: Request, res: Response) => {
  const start = Date.now();
  try {
    const data = await rPlumberService.getDataQuality();
    res.json(wrapResponse(data, start));
  } catch (err: any) {
    handleError(res, err, "DATA_QUALITY_FAILED");
  }
});

// Groq AI Roadmap Generator
apiRouter.post("/ai/roadmap", async (req: Request, res: Response) => {
  const start = Date.now();
  const {
    target_role = "Data Analyst",
    current_skills = ["Python", "SQL"],
    missing_skills = ["Tableau", "Power BI"],
    timeline_weeks = 12,
    focus_area = "Balanced & Project-Driven"
  } = req.body;

  try {
    const prompt = `You are a Principal Career Architect and Data Science Mentor.
Generate a comprehensive, evidence-backed, step-by-step career learning roadmap for a candidate targeting the role of "${target_role}".

Candidate Profile:
- Current Validated Skills: ${current_skills.join(", ") || "Beginner / Foundational"}
- Unmet Priority Skill Gaps (identified from 6,000 real job postings): ${missing_skills.join(", ") || "Core role stack"}
- Target Timeline: ${timeline_weeks} Weeks
- Learning Strategy Focus: ${focus_area}

IMPORTANT REQUIREMENTS:
1. Every single milestone MUST include genuine, 100% FREE learning resources (official documentation, top free courses like FreeCodeCamp, Harvard CS50, Mode Analytics, Kaggle, official GitHub repos, free books, or YouTube series).
2. Include exact URLs or recognized official platform names for free resources.
3. Structure the roadmap logically into 3 or 4 progressive phases covering Weeks 1 to ${timeline_weeks}.
4. Provide a practical capstone project for each phase with clear deliverables.
5. Return ONLY a valid JSON object matching this schema, without markdown formatting or surrounding text:
{
  "role": "${target_role}",
  "duration_weeks": ${timeline_weeks},
  "summary": "string",
  "estimated_hours_per_week": 10,
  "phases": [
    {
      "phase_number": 1,
      "title": "string",
      "weeks": "string",
      "objective": "string",
      "core_skills": ["string"],
      "milestones": [
        {
          "title": "string",
          "description": "string",
          "free_resources": [
            {
              "title": "string",
              "type": "Course" | "Documentation" | "Book" | "Project" | "YouTube",
              "url": "string",
              "description": "string"
            }
          ]
        }
      ],
      "capstone_project": {
        "title": "string",
        "description": "string",
        "deliverable": "string"
      }
    }
  ],
  "interview_prep_checklist": ["string"],
  "free_resource_highlights": [
    { "name": "string", "category": "string", "url": "string" }
  ]
}`;

    const groqResponse = await axios.post(
      "https://api.groq.com/openai/v1/chat/completions",
      {
        model: "openai/gpt-oss-120b",
        messages: [
          { role: "system", content: "You are an expert career intelligence engine that outputs only strictly valid JSON matching the requested schema." },
          { role: "user", content: prompt }
        ],
        temperature: 0.3,
        max_tokens: 3500
      },
      {
        headers: {
          Authorization: `Bearer ${config.groqApiKey}`,
          "Content-Type": "application/json"
        },
        timeout: 45000
      }
    );

    const rawContent = groqResponse.data.choices[0]?.message?.content || "";
    // Clean potential markdown blocks
    const jsonStr = rawContent.replace(/```json\s*/gi, "").replace(/```\s*/g, "").trim();
    const roadmap = JSON.parse(jsonStr);

    res.json(wrapResponse(roadmap, start));
  } catch (err: any) {
    console.error("[Groq AI Error] Generating fallback roadmap:", err.message);

    // Fallback deterministic evidence-based roadmap
    const fallbackRoadmap = {
      role: target_role,
      duration_weeks: timeline_weeks,
      summary: `A high-impact evidence-backed roadmap designed to transition from ${current_skills.slice(0, 2).join(" & ")} into a job-ready ${target_role} through targeted skill acquisition and portfolio projects.`,
      estimated_hours_per_week: 10,
      phases: [
        {
          phase_number: 1,
          title: "Phase 1: Closing High-Priority Core Gaps",
          weeks: `Weeks 1-${Math.round(timeline_weeks / 3)}`,
          objective: `Master the essential competencies identified in over 60% of ${target_role} postings.`,
          core_skills: missing_skills.slice(0, 2),
          milestones: [
            {
              title: `Foundations of ${missing_skills[0] || "Advanced Data Analysis"}`,
              description: `Deep dive into syntax, query structures, and industry-standard workflows.`,
              free_resources: [
                {
                  title: "Official Documentation & Interactive Tutorials",
                  type: "Documentation",
                  url: "https://devdocs.io",
                  description: "Fast, searchable API and language documentation."
                },
                {
                  title: "FreeCodeCamp Comprehensive Course",
                  type: "Course",
                  url: "https://www.freecodecamp.org/learn",
                  description: "Free 100% interactive curriculum with verifiable certificates."
                }
              ]
            }
          ],
          capstone_project: {
            title: `${target_role} Benchmark Pipeline`,
            description: "Analyze, clean, and model public domain datasets using the newly acquired stack.",
            deliverable: "Clean GitHub repository with reproducible README and interactive outputs."
          }
        },
        {
          phase_number: 2,
          title: "Phase 2: Tooling Differentiation & Business Intelligence",
          weeks: `Weeks ${Math.round(timeline_weeks / 3) + 1}-${Math.round((timeline_weeks * 2) / 3)}`,
          objective: "Develop specialized dashboarding and exploratory analytical depth.",
          core_skills: missing_skills.slice(2, 4).length > 0 ? missing_skills.slice(2, 4) : ["Data Visualization", "Git Workflow"],
          milestones: [
            {
              title: "Executive Reporting & Visual Storytelling",
              description: "Build interactive KPI dashboards that communicate business value to non-technical stakeholders.",
              free_resources: [
                {
                  title: "Kaggle Learn Interactive Tutorials",
                  type: "Course",
                  url: "https://www.kaggle.com/learn",
                  description: "Bite-sized machine learning and visualization modules."
                },
                {
                  title: "Storytelling with Data Free Resources",
                  type: "Book",
                  url: "https://www.storytellingwithdata.com/blog",
                  description: "Guide to effective data visualization and communication."
                }
              ]
            }
          ],
          capstone_project: {
            title: "Executive Business Intelligence Suite",
            description: "End-to-end dashboard tracking revenue, churn, and operational KPIs.",
            deliverable: "Published dashboard portfolio piece with slide deck."
          }
        },
        {
          phase_number: 3,
          title: "Phase 3: Production Delivery & Interview Readiness",
          weeks: `Weeks ${Math.round((timeline_weeks * 2) / 3) + 1}-${timeline_weeks}`,
          objective: "Interview preparation, live problem solving, and portfolio finalization.",
          core_skills: ["System Architecture", "Behavioral Interviewing", "Portfolio Packaging"],
          milestones: [
            {
              title: "Technical Assessment & Live Coding Preparation",
              description: "Practice real-world interview assessments and problem-solving patterns.",
              free_resources: [
                {
                  title: "LeetCode & HackerRank Free Problem Sets",
                  type: "Project",
                  url: "https://www.hackerrank.com/domains/sql",
                  description: "Curated practice problems for technical screens."
                },
                {
                  title: "StatQuest with Josh Starmer",
                  type: "YouTube",
                  url: "https://www.youtube.com/@statquest",
                  description: "Clear visual breakdowns of machine learning and statistical concepts."
                }
              ]
            }
          ],
          capstone_project: {
            title: "Production Portfolio Showcase",
            description: "Compile case studies, technical documentation, and code samples into a unified site.",
            deliverable: "Live portfolio URL and resume with demonstrable metrics."
          }
        }
      ],
      interview_prep_checklist: [
        "Explain end-to-end data pipelines with STAR format",
        "Demonstrate query performance optimization on large datasets",
        "Walk through trade-offs between precision and recall in predictive models",
        "Communicate technical findings clearly to non-technical business leaders"
      ],
      free_resource_highlights: [
        { name: "FreeCodeCamp", category: "Comprehensive Courses", url: "https://www.freecodecamp.org/" },
        { name: "Kaggle Learn", category: "Interactive Labs", url: "https://www.kaggle.com/learn" },
        { name: "StatQuest", category: "Conceptual Visuals", url: "https://www.youtube.com/@statquest" },
        { name: "PostgreSQL Tutorial", category: "Database Mastery", url: "https://www.postgresqltutorial.com/" }
      ]
    };

    res.json(wrapResponse(fallbackRoadmap, start));
  }
});
