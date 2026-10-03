import '@fontsource/shippori-mincho-b1/latin-600.css';
import '@fontsource/shippori-mincho-b1/latin-800.css';
import '@fontsource/zen-kaku-gothic-new/latin-400.css';
import '@fontsource/zen-kaku-gothic-new/latin-500.css';
import '@fontsource/zen-kaku-gothic-new/latin-700.css';
import './styles/tokens.css';
import './styles/base.css';
import './styles/background.css';
import './styles/controls.css';
import './styles/auth.css';
import './styles/shell.css';
import './styles/pages.css';

import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { App } from './App';
import { AuthProvider } from './auth/AuthContext';
import { ToastProvider } from './components/Toasts';

// Pas de menu contextuel « navigateur » dans le launcher (sauf champs de saisie).
document.addEventListener('contextmenu', (e) => {
  const target = e.target as HTMLElement;
  if (!target.closest('input, textarea')) e.preventDefault();
});

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <ToastProvider>
      <AuthProvider>
        <App />
      </AuthProvider>
    </ToastProvider>
  </StrictMode>,
);
