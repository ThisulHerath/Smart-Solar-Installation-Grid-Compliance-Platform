import type { CSSProperties } from 'react';

type SnowflakeStyle = CSSProperties & {
  '--snow-left': string;
  '--snow-size': string;
  '--snow-delay': string;
  '--snow-duration': string;
  '--snow-drift': string;
  '--snow-opacity': number;
};

const snowflakes = Array.from({ length: 34 }, (_, index) => {
  const seed = index + 1;
  return {
    left: `${(seed * 37) % 101}%`,
    size: `${5 + ((seed * 7) % 9)}px`,
    delay: `${-((seed * 13) % 17)}s`,
    duration: `${11 + ((seed * 11) % 13)}s`,
    drift: `${-34 + ((seed * 19) % 69)}px`,
    opacity: 0.34 + ((seed * 9) % 55) / 100,
  };
});

function SnowCoveredSolarGraphic() {
  return (
    <svg
      className="festive-solar-scene"
      viewBox="0 0 330 230"
      aria-hidden="true"
      focusable="false"
    >
      <defs>
        <linearGradient id="festivePanel" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#165b73" />
          <stop offset="1" stopColor="#0a384d" />
        </linearGradient>
        <linearGradient id="festiveSnow" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#ffffff" />
          <stop offset="1" stopColor="#dceef2" />
        </linearGradient>
        <filter id="festiveShadow" x="-30%" y="-30%" width="160%" height="180%">
          <feDropShadow dx="0" dy="10" stdDeviation="9" floodColor="#052c38" floodOpacity=".2" />
        </filter>
      </defs>

      <ellipse cx="170" cy="207" rx="138" ry="18" fill="#d7eaee" opacity=".55" />
      <path d="M18 207C54 186 88 194 120 202C164 214 205 187 242 194C271 199 292 210 322 202V230H18Z" fill="url(#festiveSnow)" />

      <g filter="url(#festiveShadow)" transform="translate(47 67)">
        <path d="M115 111V142M61 143H170" fill="none" stroke="#395a5e" strokeWidth="7" strokeLinecap="round" />
        <path d="M24 26H221L195 119H0Z" fill="url(#festivePanel)" stroke="#d4edf1" strokeWidth="3" />
        <path d="M65 26L50 119M106 26L98 119M148 26L146 119M189 26L194 119M12 72H209" fill="none" stroke="#70a8b5" strokeWidth="2" opacity=".62" />
        <path d="M22 25C47 12 67 25 90 18C113 12 127 23 149 17C176 10 193 23 223 14L218 35C190 44 172 29 147 38C123 46 109 31 88 38C64 46 44 33 18 43Z" fill="url(#festiveSnow)" />
        <path d="M20 25C49 13 66 26 90 18C114 11 128 23 149 17C177 9 194 22 222 14" fill="none" stroke="#ffffff" strokeWidth="4" strokeLinecap="round" />
      </g>

      <g className="festive-solar-scene__tree" transform="translate(254 77)">
        <path d="M28 0L3 44H16L0 71H22V100H35V71H57L41 44H54Z" fill="#1d7856" />
        <path d="M28 0L3 44H16L0 71H22V100" fill="none" stroke="#c9e894" strokeWidth="2" opacity=".5" />
        <circle cx="14" cy="53" r="3" fill="#e5484d" />
        <circle cx="40" cy="42" r="3" fill="#f0bd4c" />
        <circle cx="29" cy="67" r="3" fill="#e5484d" />
        <circle cx="42" cy="76" r="3" fill="#f0bd4c" />
        <path d="M28-9L31-2L39-1L33 4L35 12L28 8L21 12L23 4L17-1L25-2Z" fill="#f3c958" />
        <path d="M8 38C19 32 32 42 48 34M4 64C22 56 36 70 51 60" fill="none" stroke="#eff9f7" strokeWidth="3" strokeLinecap="round" />
      </g>

      <g className="festive-solar-scene__sparkles" fill="#ffffff">
        <circle cx="35" cy="58" r="3" />
        <circle cx="104" cy="28" r="2" />
        <circle cx="173" cy="45" r="3" />
        <circle cx="251" cy="39" r="2" />
        <circle cx="309" cy="65" r="3" />
      </g>
    </svg>
  );
}

/** Global decorative Christmas layer. It never receives pointer input. */
export function FestiveSolarOverlay() {
  return (
    <div className="festive-overlay" aria-hidden="true">
      <div className="festive-lights">
        {Array.from({ length: 12 }, (_, index) => (
          <i key={index} className={`festive-light festive-light--${index % 4}`} />
        ))}
      </div>

      <div className="festive-ornament festive-ornament--left"><i /></div>
      <div className="festive-ornament festive-ornament--right"><i /></div>

      <div className="festive-snow" role="presentation">
        {snowflakes.map((flake, index) => (
          <i
            className={`festive-snowflake festive-snowflake--${index % 3}`}
            key={index}
            style={{
              '--snow-left': flake.left,
              '--snow-size': flake.size,
              '--snow-delay': flake.delay,
              '--snow-duration': flake.duration,
              '--snow-drift': flake.drift,
              '--snow-opacity': flake.opacity,
            } as SnowflakeStyle}
          />
        ))}
      </div>

      <div className="festive-solar-float">
        <SnowCoveredSolarGraphic />
        <span className="festive-solar-float__label">
          <b>Season powered by sunshine</b>
          <small>Smart Solar wishes you a bright Christmas</small>
        </span>
      </div>
    </div>
  );
}
