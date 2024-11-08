import React from 'react';
import { createRoot } from 'react-dom/client';
import IOPerformanceDashboard from './IOPerformanceDashboard';

const root = createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <IOPerformanceDashboard />
  </React.StrictMode>
);