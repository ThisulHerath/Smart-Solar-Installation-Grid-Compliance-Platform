import { useEffect, useRef } from 'react';
import { useLocation } from 'react-router-dom';

const ROUTE_ANIMATION_MS = 340;

export function NavigationEffects() {
  const location = useLocation();
  const previousPath = useRef<string>();

  useEffect(() => {
    const reducedMotion = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches ?? false;
    const pathChanged = previousPath.current !== location.pathname;
    previousPath.current = location.pathname;

    let animationTimer: number | undefined;
    let targetTimer: number | undefined;
    let frame = 0;

    if (pathChanged) {
      document.body.classList.remove('route-is-entering');
      // Restart the transition even when two navigation events happen quickly.
      void document.body.offsetWidth;
      document.body.classList.add('route-is-entering');
      animationTimer = window.setTimeout(
        () => document.body.classList.remove('route-is-entering'),
        reducedMotion ? 0 : ROUTE_ANIMATION_MS,
      );
    }

    frame = window.requestAnimationFrame(() => {
      if (location.hash) {
        const id = decodeURIComponent(location.hash.slice(1));
        const target = document.getElementById(id);
        if (target) {
          target.scrollIntoView({ behavior: reducedMotion ? 'auto' : 'smooth', block: 'start' });
          target.classList.add('route-anchor-highlight');
          targetTimer = window.setTimeout(() => target.classList.remove('route-anchor-highlight'), 900);
        }
        return;
      }

      if (pathChanged && (window.scrollX !== 0 || window.scrollY !== 0)) {
        window.scrollTo({ top: 0, left: 0, behavior: 'auto' });
      }
    });

    return () => {
      window.cancelAnimationFrame(frame);
      if (animationTimer) window.clearTimeout(animationTimer);
      if (targetTimer) window.clearTimeout(targetTimer);
      document.body.classList.remove('route-is-entering');
    };
  }, [location.pathname, location.hash]);

  return null;
}
