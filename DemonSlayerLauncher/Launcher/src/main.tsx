import '@fontsource/shippori-mincho-b1/latin-600.css';
import '@fontsource/shippori-mincho-b1/latin-800.css';
import '@fontsource-variable/manrope/wght.css';
import './styles/tokens.css';
import './styles/base.css';
import './styles/scenery.css';
import './styles/controls.css';
import './styles/layout.css';
import './styles/auth.css';
import './styles/home.css';
import './styles/pages.css';

import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { App } from './App';
import { AuthProvider } from './auth/AuthContext';
import { ToastProvider } from './components/Toasts';
import { SettingsProvider } from './settings/SettingsContext';

// Pas de menu contextuel « navigateur » dans le launcher (sauf champs de saisie).
document.addEventListener('contextmenu', (e) => {
  const target = e.target as HTMLElement;
  if (!target.closest('input, textarea')) e.preventDefault();
});

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <SettingsProvider>
      <ToastProvider>
        <AuthProvider>
          <App />
        </AuthProvider>
      </ToastProvider>
    </SettingsProvider>
  </StrictMode>,
);
