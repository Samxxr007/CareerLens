import { useState } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useAuthStore } from './stores/useAuthStore';
import { AppLayout } from './components/layout/AppLayout';
import { AppPreloader } from './components/common/AppPreloader';
import { AuthModal } from './components/common/AuthModal';
import { OnboardingModal } from './components/common/OnboardingModal';

import { OverviewPage } from './pages/OverviewPage';
import { ProfilePage } from './pages/ProfilePage';
import { CareerExplorerPage } from './pages/CareerExplorerPage';
import { SkillIntelligencePage } from './pages/SkillIntelligencePage';
import { WhatIfLabPage } from './pages/WhatIfLabPage';
import { JobAnalyzerPage } from './pages/JobAnalyzerPage';
import { SalaryLabPage } from './pages/SalaryLabPage';
import { CareerDecisionPage } from './pages/CareerDecisionPage';
import { RoadmapPage } from './pages/RoadmapPage';
import { MarketIntelligencePage } from './pages/MarketIntelligencePage';
import { DataQualityPage } from './pages/DataQualityPage';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes cache
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
});

export default function App() {
  const [showPreloader, setShowPreloader] = useState(true);
  const { hasCompletedOnboarding, openOnboardingModal } = useAuthStore();

  const handlePreloaderComplete = () => {
    setShowPreloader(false);
    // Automatically present the Personal Details Form if onboarding not yet completed!
    if (!hasCompletedOnboarding) {
      setTimeout(() => {
        openOnboardingModal();
      }, 200);
    }
  };

  if (showPreloader) {
    return <AppPreloader onComplete={handlePreloaderComplete} />;
  }

  return (
    <QueryClientProvider client={queryClient}>
      <AuthModal />
      <OnboardingModal />

      <BrowserRouter>
        <AppLayout>
          <Routes>
            <Route path="/" element={<OverviewPage />} />
            <Route path="/profile" element={<ProfilePage />} />
            <Route path="/market-intelligence" element={<MarketIntelligencePage />} />
            <Route path="/career-explorer" element={<CareerExplorerPage />} />
            <Route path="/skill-intelligence" element={<SkillIntelligencePage />} />
            <Route path="/what-if-lab" element={<WhatIfLabPage />} />
            <Route path="/job-analyzer" element={<JobAnalyzerPage />} />
            <Route path="/salary-lab" element={<SalaryLabPage />} />
            <Route path="/career-decision" element={<CareerDecisionPage />} />
            <Route path="/roadmap" element={<RoadmapPage />} />
            <Route path="/data-quality" element={<DataQualityPage />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </AppLayout>
      </BrowserRouter>
    </QueryClientProvider>
  );
}
